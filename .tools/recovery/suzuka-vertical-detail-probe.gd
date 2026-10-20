extends SceneTree
const TD = preload("res://scripts/track_data.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	TD.reset_selection()
	TD.select_track(TD.SUZUKA)
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	for i in 120:
		await physics_frame
	var car: CharacterBody3D = race.car
	var ui: CanvasLayer = race.controls
	var line: PackedVector3Array = load("res://scripts/track_data.gd").get_centerline()
	var nearest := 0
	var max_error := 0.0
	var airborne := 0
	var min_contacts := 4
	var wall_hits := 0
	var stationary_steps := 0
	# Los tres toques se guardan como puntos exactos porque se vuelven a pulsar
	# en cada tick: si la ventana pierde el foco, `touch_controls` suelta los
	# dedos a propósito (así no queda un acelerador atascado) y la sonda, como
	# haría una persona al volver a la ventana, los pisa otra vez. Sin esto, la
	# vuelta terminaba en un coche parado con el pedal a cero y parecía un fallo
	# del juego cuando era la ventana perdiendo el foco.
	var steer_point: Vector2 = ui._steer_center
	var tr: Rect2 = ui._pedal_rects["throttle"]
	var br: Rect2 = ui._pedal_rects["brake"]
	# Dentro del rectángulo: el borde inferior queda fuera del área sensible.
	# Los toques iniciales pisan puntos conocidos dentro de ambos paneles: gas
	# casi completo en su borde superior y freno liberado en el borde inferior.
	# La comprobación funcional exige gas sin freno antes de iniciar la vuelta.
	var throttle_point := Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5, tr.position.y + tr.size.y * 0.05)
	var brake_point := Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5, br.end.y - 1.0)
	var repress := 0
	# Si los controles no tienen su geometría calculada, el lienzo mide cero y
	# ningún toque entra en su zona: la vuelta se quedaría en un coche arrastrado
	# por la pendiente. Se dice en voz alta para no confundirlo con física.
	print("TOUCH_LAYOUT lienzo=", ui._viewport_size, " mando=", steer_point,
		" acelerador=", tr, " freno=", br)
	if tr.size.x <= 0.0 or br.size.x <= 0.0 or ui._viewport_size.x <= 0.0:
		push_error("La prueba de conducción necesita una ventana y un viewport con tamaño real")
		quit(2)
		return
	_press(ui, steer_point, throttle_point, brake_point, false)
	for i in 120:
		await physics_frame
		# Al arrancar sin foco la ventana suelta los dedos a propósito; la sonda
		# los vuelve a pisar en cada fotograma, igual que haría una persona.
		repress += _press(ui, steer_point, throttle_point, brake_point, true)
		ui._process(1.0 / 120.0)
	print("TOUCH_LAYOUT primer pedido: throttle=", car.throttle_input, " brake=", car.brake_input,
		" meta=", car.get_meta("touch_throttle", -1.0), "/", car.get_meta("touch_brake", -1.0),
		" valores=", ui._throttle_value, "/", ui._brake_value, " ids=", ui._throttle_touch_id, "/", ui._brake_touch_id,
		" velocidad=", car.speed_kph, " lienzo_ahora=", ui._viewport_size)
	if car.throttle_input < 0.9 or car.brake_input > 0.03:
		push_error("La cadena multitáctil debe entregar gas > 0.9 y freno = 0")
		quit(2)
		return
	for step in 120000:
		await physics_frame
		repress += _press(ui, steer_point, throttle_point, brake_point, true)
		var best := INF
		var search_origin := nearest
		for offset in range(-12, 30):
			var idx := posmod(search_origin + offset, line.size())
			var d := Vector2(car.global_position.x - line[idx].x, car.global_position.z - line[idx].z).length_squared()
			if d < best:
				best = d
				nearest = idx
		max_error = maxf(max_error, sqrt(best))
		min_contacts = mini(min_contacts, car.wheel_contacts)
		if not car.is_on_floor(): airborne += 1
		for c in car.get_slide_collision_count():
			if "WALL" in String(car.get_slide_collision(c).get_collider().name): wall_hits += 1
		var distance := 0.0
		var target_idx := nearest
		# El seguidor de trazada es un perseguidor puro. Con el coche antiguo, que
		# sólo giraba a 0.26 g, el lazo era estable por accidente: el coche no podía
		# ejecutar las órdenes grandes. Ahora que la dirección entrega 1.1 g, el
		# lazo necesita mirar más lejos y pedir menos, o se desestabiliza y acaba
		# dando vueltas fuera de la pista (un fallo de la sonda, no del coche).
		var lookahead: float = 8.0 + car.speed_mps * 0.7
		while distance < lookahead:
			var next := (target_idx + 1) % line.size()
			distance += line[target_idx].distance_to(line[next])
			target_idx = next
		var local := car.to_local(line[target_idx])
		var alpha := atan2(local.x, -local.z)
		var wheel_angle := atan2(2.0 * car.wheelbase_m * sin(alpha), lookahead)
		var steering_max := lerpf(car.steering_at_low_speed_rad, car.steering_at_high_speed_rad, pow(clampf(car.speed_mps / 100.0, 0.0, 1.0), 0.68))
		var demand := clampf(wheel_angle / steering_max * 0.55, -1.0, 1.0)
		# La inversa de la curva del mando vive en `touch_controls.gd`
		# (`steering_travel_for`): si la curva cambia, la sonda sigue pidiendo la misma
		# demanda física en vez de repetir aquí las constantes de la curva vieja.
		var raw: float = ui.steering_travel_for(demand)
		ui._handle_touch_motion(10, ui._steer_center + Vector2(raw * ui._steering_ring.size.x * 0.46, 0))
		var curvature: float = absf(wheel_angle) / car.wheelbase_m
		# El suelo de velocidad evita el lazo sin salida de la versión anterior:
		# con el coche muy desviado la curvatura pedida crecía, la sonda pedía
		# 4 m/s, el coche se arrastraba a 3 km/h y ya no volvía a la trazada.
		var target_speed := clampf(sqrt(1.0 / maxf(curvature, 0.001)), 6.0, 10.0)
		var speed_error: float = target_speed - car.speed_mps
		var throttle := clampf(speed_error * 0.18 + 0.05, 0.0, 1.0)
		var brake := clampf(-speed_error * 0.12, 0.0, 0.65)
		# Reacquire the same foot point within each visual panel and command gas
		# through the upper half of the pedal. At near-zero controller demand,
		# move just below the lower visual edge (still inside the enlarged hitbox)
		# to release analog pressure without lifting the pedal finger.
		var gas_point := Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5,
			pedal_point(ui, tr, maxf(0.45, throttle)).y)
		var brake_command_point := Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5,
			pedal_point(ui, br, brake).y)
		if throttle <= 0.03:
			gas_point.y = ui._throttle_pedal.position.y + ui._throttle_pedal.size.y + 4.0
		if brake <= 0.03:
			brake_command_point.y = ui._brake_pedal.position.y + ui._brake_pedal.size.y + 4.0
		ui._handle_touch_motion(11, gas_point)
		ui._handle_touch_motion(12, brake_command_point)
		ui._process(1.0 / 120.0)
		if step > 7200 and car.speed_mps < 0.25 and car.throttle_input > 0.8 and car.brake_input < 0.03:
			stationary_steps += 1
		else:
			stationary_steps = 0
		if stationary_steps >= 120:
			print("BLOCKED idx=", nearest, " speed=", car.speed_kph, " throttle=", car.throttle_input, " pos=", car.global_position, " contacts=", car.wheel_contacts, " error=", sqrt(best))
			for c in car.get_slide_collision_count():
				var hit := car.get_slide_collision(c)
				print("BLOCK HIT ", hit.get_collider().name, " class=", hit.get_collider().get_class(), " normal=", hit.get_normal(), " position=", hit.get_position(), " collider_pos=", hit.get_collider().global_position)
			break
		if nearest >= 1250 and nearest <= 1500 and step % 120 == 0:
			print("DETAIL t=", step/120.0, " idx=",nearest," y=",car.global_position.y," vy=",car.velocity.y," ride=",car.suspension.height," seated=",car.suspension.seated," wheel=",car.wheel_contacts," grounded=",car.suspension.grounded," road=",car.suspension.road," ref=",car._ride_reference," rr=",car._ride_ready)
		if step % 2400 == 0:
			print("DRIVE t=", step / 120.0, " idx=",nearest," speed=",car.speed_kph," error=",sqrt(best)," pos=",car.global_position," sectors=",car.lap_tracker.next_sector," valid=",car.lap_tracker.valid_lap)
		if step > 7200 and car.speed_mps < 0.1 and car.throttle_input < 0.05 and car.brake_input < 0.05:
			print("STALL throttle=",car.throttle_input," brake=",car.brake_input," velocity=",car.velocity," contacts=",car.wheel_contacts)
			for c in car.get_slide_collision_count():
				var hit := car.get_slide_collision(c)
				print("STALL HIT ",hit.get_collider().name," normal=",hit.get_normal()," position=",hit.get_position())
			break
		if sqrt(best) > 25.0 or car.global_position.y < -60:
			print("OFFTRACK idx=",nearest," local=",local," demand=",demand," speed=",car.speed_kph," angle=",car.steering_angle," pos=",car.global_position)
			break
		if car.lap_tracker.laps >= 1:
			break
	var passed: bool = car.lap_tracker.laps == 1 and car.lap_tracker.best_lap > 25.0 and max_error < 12.0 and wall_hits == 0
	print("FULL_LAP passed=",passed," laps=",car.lap_tracker.laps," previous=",car.lap_tracker.previous_lap," best=",car.lap_tracker.best_lap," max_error_m=",max_error," airborne_ticks=",airborne," min_wheel_contacts=",min_contacts," wall_hits=",wall_hits," reposiciones_de_toque=",repress)
	# Con el paso de la vuelta por la línea de meta el cronómetro arranca: es la
	# misma prueba que hace `verify.sh` sobre el dispositivo, aquí en el anfitrión.
	print("LAP_TIMER armado=",car.lap_tracker.armed," tiempo=",car.lap_tracker.lap_time," sectores=",car.lap_tracker.next_sector)
	race.queue_free()
	await process_frame
	quit(0 if passed else 1)

func _press(ui: CanvasLayer, steer: Vector2, throttle: Vector2, brake: Vector2, contar: bool) -> int:
	var repuestos := 0
	if ui._steer_touch_id < 0:
		ui._handle_touch_down(10, steer)
		repuestos += int(contar)
	if ui._throttle_touch_id < 0:
		ui._handle_touch_down(11, throttle)
		repuestos += int(contar)
	if ui._brake_touch_id < 0:
		ui._handle_touch_down(12, brake)
		repuestos += int(contar)
	return repuestos


# El recorrido del dedo para pedir una demanda sale de la curva DECLARADA del pedal
# (`touch_controls.pedal_travel_for`), no de una copia de la rampa. La copia que llevaba el 0,8
# de la rampa vieja colocaba el dedo demasiado abajo: pedir 0,45 dejaba el coche con 0,87 de
# gas. Mismo criterio que la demanda del mando, que ya usa `steering_travel_for`.
func pedal_point(ui: CanvasLayer, rect: Rect2, demand: float) -> Vector2:
	return rect.position + rect.size * Vector2(0.5, 1.0 - ui.pedal_travel_for(demand))
