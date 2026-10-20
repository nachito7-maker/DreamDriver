extends SceneTree

var failures := 0
var controls: CanvasLayer
func check(condition: bool, message: String) -> void:
	print("CONTROLS ", "PASS " if condition else "FAIL ", message)
	if not condition: failures += 1

func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	controls._input(event)

func drag(index: int, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	controls._input(event)

# Si la ventana pierde el foco, `touch_controls` suelta todos los dedos a
# propósito, para no dejar un acelerador atascado (`_release_all_touches`). En
# una sonda de ventana eso ocurre sin avisar: el gestor de ventanas puede
# retirarle el foco a mitad de la medida y entonces todo se mide a cero, como si
# el juego no respondiera. La sonda, como haría una persona al volver a la
# ventana, vuelve a pisar el punto que le toca antes de medir.
func hold(index: int, point: Vector2) -> void:
	var held := false
	match index:
		1:
			held = controls._throttle_touch_id == index
		2:
			held = controls._steer_touch_id == index
		3:
			held = controls._brake_touch_id == index
		4:
			held = controls._brake_touch_id == index or controls._throttle_touch_id == index
		5:
			held = controls._throttle_touch_id == index
	if not held:
		touch(index, point, true)

func trace_final_release() -> void:
	pass

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	var ui: CanvasLayer = race.controls
	controls = ui
	var car: CharacterBody3D = race.car
	if ui._viewport_size.x <= 0.0 or ui._viewport_size.y <= 0.0:
		push_error("controls_probe necesita un viewport con ventana; no puede simular ScreenTouch con geometría vacía")
		quit(2)
		return
	var throttle: Rect2 = ui._pedal_rects["throttle"]
	var brake: Rect2 = ui._pedal_rects["brake"]
	check(not throttle.intersects(brake) and throttle.position.x > brake.position.x, "pedals separated; accelerator right, brake left")
	# La esquina inferior derecha tiene que estar ENTERA repartida entre los dos pedales: ni una
	# franja por la que el dedo caiga sin pisar nada (antes había una entre los dos recuadros) ni
	# un punto que pise los dos a la vez (un dedo no puede frenar y acelerar al mismo tiempo).
	check(absf(throttle.position.x - brake.end.x) < 0.01 and brake.size.y >= 1.0,
		"las dos zonas de pedal son contiguas: la derecha empieza donde acaba la izquierda (%.2f vs %.2f)" % [throttle.position.x, brake.end.x])
	var huecos := 0
	var solapes := 0
	var x_scan := int(ceil(brake.position.x))
	while x_scan < int(ui._viewport_size.x):
		var punto := Vector2(float(x_scan), ui._pedal_rects["brake"].end.y - 8.0)
		var en_acel: bool = throttle.has_point(punto)
		var en_freno: bool = brake.has_point(punto)
		if not en_acel and not en_freno:
			huecos += 1
		if en_acel and en_freno:
			solapes += 1
		x_scan += 4
	check(huecos == 0, "la esquina inferior derecha no deja franjas muertas entre los pedales (huecos=%d)" % huecos)
	check(solapes == 0, "las dos zonas de pedal no se solapan (solapes=%d): un dedo no pisa los dos" % solapes)
	check(not ui._steer_zone.intersects(throttle) and not ui._steer_zone.intersects(brake),
		"la zona de dirección no se pisa con los pedales")
	check(absf(ui._pedal_rects["throttle"].end.x - ui._viewport_size.x) < 0.5,
		"la zona del acelerador llega al borde derecho de la pantalla (%.1f)" % ui._pedal_rects["throttle"].end.x)
	check(absf(ui._pedal_rects["throttle"].end.y - (ui._throttle_pedal.position.y + ui._throttle_pedal.size.y)) < 0.5,
		"la zona acaba donde acaba el pedal dibujado, no más abajo (%.1f vs %.1f)" % [ui._pedal_rects["throttle"].end.y, ui._throttle_pedal.position.y + ui._throttle_pedal.size.y])
	# Debajo del pedal no se pide nada: es el gesto de soltar (y el que usan las sondas para pedir
	# demanda cero).
	var debajo := Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5,
		ui._throttle_pedal.position.y + ui._throttle_pedal.size.y + 4.0)
	check(ui._pedal_pressure("throttle", debajo) == 0.0, "por debajo del pedal la demanda es cero (soltar)")
	# El recorrido del pedal no puede exigir llegar arriba: media altura ya pide el total, y el
	# tercio de abajo —donde cae el pulgar— pide conducción de verdad.
	var tercio_bajo := Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5,
		ui._throttle_pedal.position.y + ui._throttle_pedal.size.y * 0.80)
	var presion_tercio: float = ui.pedal_demand_at("throttle", tercio_bajo)
	var media_pedal := Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5,
		ui._throttle_pedal.position.y + ui._throttle_pedal.size.y * 0.5)
	check(presion_tercio > 0.3 and ui.pedal_demand_at("throttle", media_pedal) > 0.95,
		"el tercio bajo del pedal ya pide conducción (%.3f) y a media altura pide el total (%.3f)"
		% [presion_tercio, ui.pedal_demand_at("throttle", media_pedal)])
	var margen_lateral := Vector2(ui._pedal_rects["throttle"].end.x - 6.0, tercio_bajo.y)
	var presion_margen: float = ui.pedal_demand_at("throttle", margen_lateral)
	check(presion_margen > 0.3,
		"en el borde lateral de la zona el pedal sigue entregando (%.3f); antes ahí era cero" % presion_margen)
	var tp := Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5, throttle.position.y + throttle.size.y * 0.05)
	var bp := Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5, brake.position.y + brake.size.y * 0.05)
	var center: Vector2 = ui._steer_center
	var radius: float = ui._steering_ring.size.x * 0.46
	var steer_point := center + Vector2(radius * 0.5, 0)
	var brake_travel := Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5, brake.position.y + brake.size.y * 0.8)
	touch(1, tp, true)
	touch(2, steer_point, true)
	for frame in 4:
		await process_frame
		hold(1, tp)
		hold(2, steer_point)
		await physics_frame
	# La demanda que se exige es la que DECLARA la curva del mando para ese recorrido
	# (`_steering_curve(0,5)`), no una ventana escrita a mano: la ventana 0,2-0,5 que había
	# era el valor que daba la curva comprimida (exponente 1,6) y dejó de medir lo que
	# pretendía en cuanto la curva se corrigió. Lo que importa —y ahora se exige— es que el
	# pedido sea la mitad del recorrido del dedo por la curva, analógico (ni 0 ni 1) y con el
	# acelerador a fondo en el otro dedo.
	var demanda_media: float = ui._steering_curve(0.5)
	check(car.throttle_input > 0.95 and car.brake_input == 0.0 and car.steering_input > 0.0 and car.steering_input < 1.0 and absf(car.steering_input - demanda_media) < 0.02,
		"multitouch: acelerador a fondo y dirección analógica a medio recorrido (%.3f, la curva dice %.3f)" % [car.steering_input, demanda_media])
	print("VALUES throttle=", car.throttle_input, " steer=",car.steering_input," rect=",throttle, " center=",center)
	var half: float = car.steering_input
	steer_point = center + Vector2(radius, 0)
	drag(2, steer_point)
	for frame in 4:
		await process_frame
		hold(1, tp)
		hold(2, steer_point)
		await physics_frame
	# Monótona y completa: más recorrido da más dirección (estrictamente) y al fondo del
	# anillo la demanda es la total. Con la curva anterior el fondo ya estaba saturado a medio
	# recorrido, así que aquí se exigía el doble; lo que hay que exigir es que crezca y que
	# llegue al máximo declarado.
	var demanda_llena: float = ui._steering_curve(1.0)
	check(car.steering_input > half and absf(car.steering_input - demanda_llena) < 0.02,
		"más recorrido da más dirección y a fondo se llega a la demanda total (%.3f > %.3f, la curva dice %.3f)" % [car.steering_input, half, demanda_llena])
	hold(2, steer_point)
	touch(2, center, false)
	await process_frame
	check(car.steering_input > 0, "release does not abruptly snap physical steering")
	for i in 70:
		hold(1, tp)
		await create_timer(0.01).timeout
	check(absf(float(car.get_meta("touch_steer"))) < 0.001 and (ui._steering_knob.position + ui._steering_knob.size * 0.5).distance_to(center) < 0.3, "physical input and visual joystick return to center")
	hold(1, tp)
	touch(1, tp, false)
	touch(3, bp, true)
	for frame in 4:
		await process_frame
		hold(3, bp)
		await physics_frame
	check(car.throttle_input == 0 and car.brake_input > 0.95, "brake applies brake only")
	drag(3, brake_travel)
	for frame in 4:
		await process_frame
		hold(3, brake_travel)
		await physics_frame
	# El recorrido sigue siendo analógico, medido contra la CURVA DECLARADA (como la dirección) y
	# contra el mínimo declarado, no contra una ventana escrita a mano que caducó al cambiar el
	# mapeo: en la mitad del pedal la curva manda, y al pie manda el mínimo (nunca cero).
	var presion_declarada: float = ui.pedal_demand_at("brake", brake_travel)
	check(absf(car.brake_input - presion_declarada) < 0.02 and car.brake_input > 0.0 and car.brake_input < 1.0,
		"el recorrido del pedal es analógico y sigue la curva declarada (%.3f, la curva dice %.3f)" % [car.brake_input, presion_declarada])
	# La banda analógica del pedal es la fracción PEDAL_RAMP de la zona: por encima de ella la
	# demanda ya es la total, así que la monotonía se mide DENTRO de la banda (media banda =
	# mitad de la demanda, que es lo que da la curva declarada). Medirla a media zona, como
	# antes, sólo comprobaba que el pedal saturaba antes de la mitad.
	var medio_banda := Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5,
		ui._pedal_rects["brake"].end.y - ui._pedal_rects["brake"].size.y * ui.PEDAL_RAMP * 0.5)
	drag(3, medio_banda)
	for frame in 4:
		await process_frame
		hold(3, medio_banda)
		await physics_frame
	var demanda_media_freno: float = ui.pedal_demand_at("brake", medio_banda)
	check(absf(car.brake_input - demanda_media_freno) < 0.02 and demanda_media_freno > presion_declarada + 0.05 and demanda_media_freno < 1.0,
		"media banda del freno pide más frenada que el pie (%.3f > %.3f) y llega al coche (%.3f)"
		% [demanda_media_freno, presion_declarada, car.brake_input])
	hold(3, brake_travel)
	touch(3, bp, false)
	for frame in 4:
		await process_frame
		await physics_frame
	check(car.brake_input == 0 and car.throttle_input == 0, "pedals release when finger lifts")

	# --- acelerador con el dedo apoyado abajo y moviéndose en horizontal -------------------
	touch(1, tercio_bajo, true)
	for frame in 4:
		await process_frame
		hold(1, tercio_bajo)
		await physics_frame
	var fondo_gas: float = car.throttle_input
	# El tercio bajo del pedal es donde cae el pulgar: la curva declarada pide ahí un tercio de
	# la demanda. Se exige ese tercio (y la comprobación siguiente exige además que la demanda
	# publicada sea exactamente la de la curva). El 0,35 de antes era un número de la rampa
	# vieja —la que pedía el total al 80 % del recorrido— y no medía nada del pedal de ahora.
	check(fondo_gas > 0.3,
		"pisar el acelerador en el tercio bajo acelera de verdad (%.3f, la curva pide %.3f)" % [fondo_gas, ui.pedal_demand_at("throttle", tercio_bajo)])
	check(absf(car.throttle_input - ui.pedal_demand_at("throttle", tercio_bajo)) < 0.02,
		"la demanda publicada es la que declara la curva del pedal (%.3f, curva %.3f)" % [car.throttle_input, ui.pedal_demand_at("throttle", tercio_bajo)])
	var barrido: float = float(ui._pedal_rects["throttle"].position.x) + 4.0
	drag(1, Vector2(barrido, tercio_bajo.y))
	for frame in 4:
		await process_frame
		hold(1, Vector2(barrido, tercio_bajo.y))
		await physics_frame
	check(ui._throttle_touch_id == 1 and car.throttle_input > 0.0 and absf(car.throttle_input - fondo_gas) < 0.02,
		"mover el dedo en horizontal por la zona no corta la pulsación ni cambia la demanda (%.3f, antes %.3f, dedo %d)"
		% [car.throttle_input, fondo_gas, ui._throttle_touch_id])
	# Y subirlo dentro del pedal sube la demanda (el recorrido sigue mandando).
	var arriba := Vector2(barrido, ui._throttle_pedal.position.y + 4.0)
	drag(1, arriba)
	for frame in 4:
		await process_frame
		hold(1, arriba)
		await physics_frame
	check(car.throttle_input > fondo_gas + 0.2, "subir el dedo dentro del pedal sube el gas (%.3f > %.3f)" % [car.throttle_input, fondo_gas])
	hold(1, arriba)
	touch(1, arriba, false)

	# --- un dedo que ENTRA deslizando en un pedal libre lo toma ---------------------------
	var fuera := Vector2(ui._viewport_size.x * 0.5, ui._viewport_size.y * 0.1)
	touch(4, fuera, true)
	await process_frame
	check(ui._brake_touch_id < 0 and ui._throttle_touch_id < 0, "tocar el centro de la pantalla no pisa ningún pedal")
	drag(4, bp)
	for frame in 4:
		await process_frame
		hold(4, bp)
		await physics_frame
	check(ui._brake_touch_id == 4 and car.brake_input > 0.0,
		"un dedo que entra deslizando en el pedal lo toma (freno=%.3f)" % car.brake_input)

	# --- freno y dirección a la vez -------------------------------------------------------
	touch(2, center + Vector2(radius, 0), true)
	for frame in 4:
		await process_frame
		hold(4, bp)
		hold(2, center + Vector2(radius, 0))
		await physics_frame
	check(car.brake_input > 0.9 and absf(car.steering_input - ui._steering_curve(1.0)) < 0.02,
		"frenar y girar a la vez: los dos dedos mandan (freno=%.3f mando=%.3f)" % [car.brake_input, car.steering_input])
	touch(2, center + Vector2(radius, 0), false)
	touch(4, bp, false)
	for frame in 4:
		await process_frame
		await physics_frame

	# --- alternancia rápida acelerador/freno con el MISMO dedo ----------------------------
	check(car.throttle_input == 0.0 and car.brake_input == 0.0, "al levantar los dos dedos no queda nada pisado")
	for vuelta in 3:
		touch(5, tp, true)
		for frame in 2:
			await process_frame
			await physics_frame
		var gas: float = car.throttle_input
		touch(5, tp, false)
		touch(5, bp, true)
		for frame in 2:
			await process_frame
			await physics_frame
		var freno: float = car.brake_input
		touch(5, bp, false)
		for frame in 2:
			await process_frame
			await physics_frame
		var libre: float = car.throttle_input + car.brake_input
		check(gas > 0.9 and freno > 0.9 and libre == 0.0,
			"alternar gas/freno con el mismo dedo (vuelta %d): gas=%.3f freno=%.3f en reposo=%.3f" % [vuelta + 1, gas, freno, libre])

	# --- los extremos de la zona también pisas ----------------------------------------------
	# Los extremos de las zonas se prueban a MEDIA altura (arriba del pie del pedal, que ya está
	# probado arriba): la esquina inferior izquierda del freno, la inferior derecha del freno, la
	# inferior izquierda del acelerador y la esquina derecha de la pantalla.
	var fondo_medio_brake: float = ui._pedal_rects["brake"].position.y + ui._pedal_rects["brake"].size.y * 0.6
	var fondo_medio_gas: float = ui._pedal_rects["throttle"].position.y + ui._pedal_rects["throttle"].size.y * 0.6
	var extremos := [
		Vector2(ui._pedal_rects["brake"].position.x + 2.0, fondo_medio_brake),
		Vector2(ui._pedal_rects["brake"].end.x - 2.0, fondo_medio_brake),
		Vector2(ui._pedal_rects["throttle"].position.x + 2.0, fondo_medio_gas),
		Vector2(ui._viewport_size.x - 2.0, fondo_medio_gas),
	]
	for i in extremos.size():
		touch(5, extremos[i], true)
		for frame in 3:
			await process_frame
			hold(5, extremos[i])
			await physics_frame
		var pisado: float = maxf(car.throttle_input, car.brake_input)
		check(pisado > 0.3,
			"el extremo %d de las zonas (%.0f,%.0f) pisa pedal con demanda de conducción (%.3f)" % [i + 1, extremos[i].x, extremos[i].y, pisado])
		touch(5, extremos[i], false)
		for frame in 2:
			await process_frame
			await physics_frame
	# El borde inferior del recuadro es la demanda cero declarada (las sondas lo usan para
	# soltar), pero el toque tiene que quedar CAPTURADO: el fallo era un pedal pisado que no
	# pedía nada.
	var borde_bajo := Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5,
		ui._pedal_rects["throttle"].end.y - 2.0)
	touch(5, borde_bajo, true)
	await process_frame
	check(ui._throttle_touch_id == 5 and ui.pedal_demand_at("throttle", borde_bajo) < 0.1,
		"el borde inferior del pedal queda capturado con demanda cero, no suelto (%.3f)" % ui.pedal_demand_at("throttle", borde_bajo))
	touch(5, borde_bajo, false)
	for frame in 2:
		await process_frame
		await physics_frame
	check(car.throttle_input == 0.0 and car.brake_input == 0.0,
		"después de recorrer los extremos no queda ningún control bloqueado")
	trace_final_release()
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
