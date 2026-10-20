extends SceneTree

# CADENA DE DIRECCIÓN COMPLETA, con el joystick táctil de verdad.
#
# `steering_probe.gd` mide el MODELO inyectando la demanda por el canal del mando
# (`car.set_meta("touch_steer", ...)`), así que no pasa por la CURVA del joystick ni por el
# recorrido del dedo: mide lo que el coche haría si el mando entregase una cifra exacta.
# Ésta usa las funciones que usa un dedo de verdad (`_handle_touch_down` /
# `_handle_touch_motion` sobre el anillo del mando), de modo que mide la cadena entera:
#
#   recorrido del dedo (fracción del radio) -> mando (ui._steer_value)
#   -> demanda (car.steering_input) -> ángulo pedido (debug_target_steer)
#   -> ángulo aplicado (car.steering_angle) -> ángulo VISUAL de la rueda delantera
#   -> régimen de guiñada, aceleración lateral, radio, contactos,
#   y los topes que recortan el giro (lean / grip / máx y tope de guiñada).
#
# Recorre 60/120/180/240 km/h × recorridos 0,10 / 0,25 / 0,50 / 0,75 / 1,00 del radio a la
# derecha (y 0,25 y 1,00 a la izquierda), con la velocidad sostenida, acelerando y frenando.
# Todo sobre una losa de asfalto plana y sin obstáculos, para que la medida sea del modelo y
# no del circuito.
#
# Lo que se exige (son requisitos del encargo, no del modelo):
#   * el recorrido MEDIO del mando entrega al menos el 60 % del giro máximo a esa velocidad
#     (si no, el mando parece muerto a media carrera);
#   * a velocidad media y alta hay capacidad de giro real (≥ 0,95 g a 120 km/h y ≥ 1,0 g a
#     180 km/h), no una respuesta prácticamente anulada;
#   * el giro crece con el recorrido (progresivo) y no satura en el primer 10 %;
#   * izquierda y derecha responden igual (≤ 5 % de diferencia);
#   * el ángulo VISUAL de la rueda es el aplicado (± 0,5°): lo pedido llega a las ruedas;
#   * se gira con acelerador y con freno.
#
# Uso:  Godot --headless --path . --script res://scripts/steering_response_probe.gd

const TICK := 1.0 / 120.0
# Losa de asfalto plana y sin obstáculos (mismo montaje que `steering_probe.gd`): con el
# circuito real, 1,2 s de curva a 1,2 g acaban contra las barreras y la medida sale sucia.
const PAD_HEIGHT := 1500.0
const PAD_HALF := 4000.0
const SETTLE_TICKS := 90               # asentamiento tras colocar el coche a la velocidad pedida
const CORNER_TICKS := 144              # 1,2 s de curva
const SUSTAINED_FROM := 96             # la media se toma desde aquí: régimen establecido
const SPEED_TOLERANCE := 0.8           # m/s

const SPEEDS_KPH := [60.0, 120.0, 180.0, 240.0]
const FRACTIONS_RIGHT := [0.10, 0.25, 0.50, 0.75, 1.00]
const FRACTIONS_LEFT := [0.25, 1.00]
# Casos de pedal: (km/h, recorrido, sentido, acelerando/frenando)
const PEDAL_CASES := [
	{"kph": 60.0, "fraction": 1.00, "side": 1.0, "pedal": "acelerando"},
	{"kph": 120.0, "fraction": 0.50, "side": 1.0, "pedal": "acelerando"},
	{"kph": 180.0, "fraction": 1.00, "side": 1.0, "pedal": "frenando"},
	{"kph": 180.0, "fraction": 1.00, "side": -1.0, "pedal": "frenando"},
	# Frenar a tope desde 60 km/h deja el coche parado en medio segundo y un coche parado no
	# gira: la maniobra no mediría la dirección. La frenada que se mide es la que deja
	# velocidad durante la ventana de 1,2 s, y la de 180 km/h va a fondo y a los dos lados.
	{"kph": 240.0, "fraction": 0.50, "side": 1.0, "pedal": "frenando"},
]

# --- criterios declarados ----------------------------------------------------
const MEDIA_DEL_RECORRIDO_MIN := 0.60   # g(0,50) / g(1,00) mínimo
const SATURACION_PRIMER_DECIMO := 0.35  # g(0,10) / g(1,00) máximo
const MIN_G_SOSTENIDA := 0.95           # 120 km/h y 180 km/h
const MIN_G_LENTA := 0.70               # 60 km/h
const MIN_G_PEDAL := 0.50               # girando mientras se acelera o se frena
const MAX_DIFERENCIA_IZQ_DER := 0.05
const MAX_DESVIO_VISUAL_DEG := 0.5
const PROGRESIVO_TOLERANCIA := 0.05     # g de holgura para dar el giro por creciente

var failures := 0
var checks := 0
var race: Node3D
var car: CharacterBody3D
var ui: CanvasLayer
var steer_center := Vector2.ZERO
var steer_radius := 1.0
var visual_sign := 0.0                  # convención medida en la calibración (rueda vs modelo)
var rapido := false                      # --rapido: 6 casos y ninguna comprobación (para depurar)

func check(ok: bool, message: String) -> void:
	checks += 1
	print("DIRECCION ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func info(message: String) -> void:
	print("DIRECCION INFO ", message)

func _initialize() -> void:
	call_deferred("_run")

func _group_of(body: Node) -> String:
	if body == null:
		return "NONE"
	var upper := (String(body.name) + " " + String(body.get_meta("ac_surface", ""))).to_upper()
	for key in ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "GRAVEL", "SAND", "GRASS", "GREEN", "OUT", "CONCRETE", "WALL"]:
		if key in upper:
			return key
	return "OTHER"

func _run() -> void:
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 120:
		await physics_frame
	car = race.car
	ui = race.controls
	steer_center = ui._steer_center
	steer_radius = maxf(1.0, ui._steering_ring.size.x * 0.46)
	_build_pad()
	# El mando conserva su `_process`: es quien publica en la meta la demanda que lee el
	# coche. Lo que NO se hace es escribir esa demanda a mano: para medir la curva del mando
	# hay que empujar el dedo como lo empujaría una persona.
	ui.set_process(true)
	# Esta sonda empuja el mando con toques de verdad: con `--headless` el lienzo queda en
	# 64x64, el anillo del mando cae fuera de la pantalla y NINGÚN toque se captura (todos
	# los casos salen a cero). Antes de medir se comprueba, y si no hay ventana se avisa.
	if ui._viewport_size.x < 200.0 or ui._viewport_size.y < 200.0 or steer_radius < 20.0:
		printerr("DIRECCION ERROR lienzo=%s radio=%.1f px: hace falta ventana (sin --headless)" % [
			str(ui._viewport_size), steer_radius])
		quit(1)
		return
	info("lienzo=%s  centro del mando=%s  radio=%.1f px" % [str(ui._viewport_size), str(steer_center), steer_radius])
	info("recorrido del dedo -> demanda del mando: %s" % _curva_texto())
	rapido = OS.get_cmdline_user_args().has("--rapido")
	var speeds: Array = [60.0, 120.0] if rapido else SPEEDS_KPH
	var fractions_derecha: Array = [0.50, 1.00] if rapido else FRACTIONS_RIGHT
	var fractions_izquierda: Array = [1.00] if rapido else FRACTIONS_LEFT
	var pedal_cases: Array = [PEDAL_CASES[0]] if rapido else PEDAL_CASES
	if rapido:
		info("modo rápido: %d velocidades, %d recorridos, sin comprobaciones" % [speeds.size(), fractions_derecha.size()])

	var resultados: Array = []
	var tabla: Dictionary = {}
	for kph in speeds:
		var fractions: Array = fractions_derecha.duplicate()
		for fraction in fractions:
			var entry := {"kph": float(kph), "fraction": float(fraction), "side": 1.0, "pedal": "sostenido"}
			var result: Dictionary = await _measure(entry)
			resultados.append(result)
			tabla[_clave(kph, fraction, 1.0, "sostenido")] = result
	for kph in speeds:
		for fraction in fractions_izquierda:
			var entry := {"kph": float(kph), "fraction": float(fraction), "side": -1.0, "pedal": "sostenido"}
			var result: Dictionary = await _measure(entry)
			resultados.append(result)
			tabla[_clave(kph, fraction, -1.0, "sostenido")] = result
	for caso in pedal_cases:
		var entry := {"kph": float(caso["kph"]), "fraction": float(caso["fraction"]),
			"side": float(caso["side"]), "pedal": String(caso["pedal"])}
		var result: Dictionary = await _measure(entry)
		resultados.append(result)
		tabla[_clave(entry["kph"], entry["fraction"], float(caso["side"]), String(caso["pedal"]))] = result

	if rapido:
		print("DIRECCION modo rápido: %d casos medidos, sin comprobaciones" % resultados.size())
		quit(0)
		return

	# --- 0. el toque se captura y el mando entrega lo que dice su curva ---------
	var peor_demanda := 0.0
	for result in resultados:
		peor_demanda = maxf(peor_demanda, absf(float(result["input"]) - float(result["expected_input"])))
	check(peor_demanda <= 0.02,
		"el dedo se convierte en la demanda de la curva del mando (peor desvío %.4f ≤ 0,02)" % peor_demanda)

	# --- 1. el recorrido del mando se reparte y no está muerto por el medio -----
	for kph in speeds:
		var medio: float = float(tabla[_clave(kph, 0.50, 1.0, "sostenido")]["sustained_g"])
		var lleno: float = float(tabla[_clave(kph, 1.00, 1.0, "sostenido")]["sustained_g"])
		var decimo: float = float(tabla[_clave(kph, 0.10, 1.0, "sostenido")]["sustained_g"])
		check(medio >= lleno * MEDIA_DEL_RECORRIDO_MIN,
			"a %.0f km/h el recorrido medio del mando entrega al menos el %.0f %% del giro máximo (%.2f g de %.2f g)" % [
				kph, MEDIA_DEL_RECORRIDO_MIN * 100.0, medio, lleno])
		check(lleno > 0.05 and decimo <= lleno * SATURACION_PRIMER_DECIMO,
			"a %.0f km/h el primer 10 %% del recorrido no satura el giro (%.2f g de %.2f g)" % [kph, decimo, lleno])
		var anterior := -1.0
		var progresivo := true
		for fraction in fractions_derecha:
			var g: float = float(tabla[_clave(kph, fraction, 1.0, "sostenido")]["sustained_g"])
			if anterior >= 0.0 and g < anterior - PROGRESIVO_TOLERANCIA:
				progresivo = false
			anterior = g
		check(progresivo, "a %.0f km/h el giro crece con el recorrido del mando (progresivo)" % kph)

	# --- 2. capacidad de giro real a cada velocidad -----------------------------
	check(float(tabla[_clave(60.0, 1.0, 1.0, "sostenido")]["sustained_g"]) >= MIN_G_LENTA,
		"a 60 km/h gira de verdad (%.2f g ≥ %.2f g)" % [
			float(tabla[_clave(60.0, 1.0, 1.0, "sostenido")]["sustained_g"]), MIN_G_LENTA])
	for kph in [120.0, 180.0]:
		check(float(tabla[_clave(kph, 1.0, 1.0, "sostenido")]["sustained_g"]) >= MIN_G_SOSTENIDA,
			"a %.0f km/h gira de verdad (%.2f g ≥ %.2f g)" % [
				kph, float(tabla[_clave(kph, 1.0, 1.0, "sostenido")]["sustained_g"]), MIN_G_SOSTENIDA])

	# --- 3. izquierda y derecha iguales -----------------------------------------
	for kph in speeds:
		var derecha: float = float(tabla[_clave(kph, 1.0, 1.0, "sostenido")]["sustained_g"])
		var izquierda: float = float(tabla[_clave(kph, 1.0, -1.0, "sostenido")]["sustained_g"])
		var diferencia := absf(derecha - izquierda) / maxf(maxf(derecha, izquierda), 0.001)
		check(diferencia <= MAX_DIFERENCIA_IZQ_DER,
			"a %.0f km/h gira igual a izquierda y derecha (%.0f %% de diferencia)" % [kph, diferencia * 100.0])

	# --- 4. el ángulo pedido LLEGA a las ruedas (visual = aplicado) -------------
	var peor_visual := 0.0
	var sentido_ok := true
	for result in resultados:
		peor_visual = maxf(peor_visual, absf(absf(float(result["visual_deg"])) - absf(float(result["angle_deg"]))))
		if absf(float(result["angle_deg"])) > 0.2:
			if signf(float(result["visual_deg"])) != visual_sign * signf(float(result["angle_deg"])):
				sentido_ok = false
	check(peor_visual <= MAX_DESVIO_VISUAL_DEG,
		"el ángulo de la rueda en pantalla es el aplicado por el modelo (peor desvío %.2f° ≤ %.1f°)" % [
			peor_visual, MAX_DESVIO_VISUAL_DEG])
	check(sentido_ok, "la rueda gira hacia el lado que pide el mando (convención %+.0f)" % visual_sign)

	# --- 5. se gira con acelerador y con freno ----------------------------------
	for caso in pedal_cases:
		var clave := _clave(float(caso["kph"]), float(caso["fraction"]), float(caso["side"]), String(caso["pedal"]))
		check(float(tabla[clave]["sustained_g"]) >= MIN_G_PEDAL,
			"%s y girando a %.0f km/h a la %s (%.2f g ≥ %.2f g)" % [
				String(caso["pedal"]), float(caso["kph"]), "derecha" if float(caso["side"]) > 0.0 else "izquierda",
				float(tabla[clave]["sustained_g"]), MIN_G_PEDAL])

	# --- 6. sin muros durante la medida ----------------------------------------
	for result in resultados:
		check(int(result["walls"]) == 0, "sin contacto con muro en %s" % result["label"])

	print("DIRECCION comprobaciones=%d fallos=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _curva_texto() -> String:
	var piezas: Array = []
	for fraction in [0.10, 0.25, 0.50, 0.75, 1.00]:
		piezas.append("%.0f%%→%.3f" % [fraction * 100.0, ui._steering_curve(fraction)])
	return "  ".join(piezas)

func _clave(kph: float, fraction: float, side: float, pedal: String) -> String:
	return "%.0f|%.2f|%d|%s" % [kph, fraction, signi(roundi(side)), pedal]

# Losa de asfalto de pruebas, llamada TRM-BRC para que el coche la reconozca como asfalto.
func _build_pad() -> void:
	var pad := StaticBody3D.new()
	pad.name = "TRM-BRC banco de pruebas"
	pad.collision_layer = 1
	pad.collision_mask = 0
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(PAD_HALF * 2.0, 40.0, PAD_HALF * 2.0)
	collision.shape = box
	pad.add_child(collision)
	pad.position = Vector3(0.0, PAD_HEIGHT - 20.0, 0.0)
	race.add_child(pad)

# El pedal se mueve por el valor del propio mando, que es quien publica cada fotograma la
# meta que lee el coche: el dedo de la dirección es real, el del pedal lo representa el banco.
func _pedals(throttle: float, brake: float) -> void:
	ui._throttle_value = clampf(throttle, 0.0, 1.0)
	ui._brake_value = clampf(brake, 0.0, 1.0)

func _speed_control(target: float) -> void:
	var error: float = target - car.speed_mps
	var throttle := clampf(error * 0.4 + 0.1, 0.0, 1.0)
	var brake := clampf(-error * 0.3, 0.0, 1.0)
	_pedals(0.0 if throttle < 0.05 else throttle, 0.0 if brake < 0.05 else brake)

# Empuja el dedo del mando al recorrido pedido (las mismas funciones que usa un toque real).
func _push_stick(fraction: float, side: float) -> void:
	var punto := steer_center + Vector2(steer_radius * clampf(fraction, 0.0, 1.0) * side, 0.0)
	if ui._steer_touch_id < 0:
		ui._handle_touch_down(10, punto)
	else:
		ui._handle_touch_motion(10, punto)

func _release_stick() -> void:
	if ui._steer_touch_id >= 0:
		ui._handle_touch_up(ui._steer_touch_id)

# Ángulo de la rueda delantera RESPECTO AL COCHE tal y como lo deja `_update_visuals`:
#
#   rueda.basis = actitud * Basis(UP, -steering_angle) * Basis(RIGHT, -giro) * reposo
#
# El eje del neumático es la X del nodo y `Basis(RIGHT, ...)` (el giro de la rueda) la deja
# intacta, así que el eje del neumático en el espacio de su MALLA es `reposo⁻¹ · X`. Se
# lleva ese eje al mundo con la base de la rueda y se expresa en el sistema del COCHE: el
# ángulo de ese eje es el que lleva aplicado la rueda. Se mide en el sistema del coche para
# que el cabeceo y el balanceo de la carrocería no contaminen la lectura, y se resta la
# referencia recta medida con el mando centrado, porque la malla puede venir girada 180°.
func _visual_deg() -> float:
	if car._front_wheels.is_empty():
		return NAN
	var rueda: Node3D = car._front_wheels[0]
	if not is_instance_valid(rueda) or not car._wheel_rest.has(rueda):
		return NAN
	var reposo: Basis = car._wheel_rest[rueda]
	var eje_malla: Vector3 = reposo.inverse() * Vector3.RIGHT
	var eje_mundo: Vector3 = rueda.global_transform.basis * eje_malla
	var eje_coche: Vector3 = car.global_transform.basis.inverse() * eje_mundo
	return rad_to_deg(atan2(eje_coche.z, eje_coche.x))

func _measure(entry: Dictionary) -> Dictionary:
	var target: float = entry["kph"] / 3.6
	var fraction: float = entry["fraction"]
	var side: float = entry["side"]
	_release_stick()
	_pedals(0.0, 0.0)
	car.recover_to(Vector3(0.0, PAD_HEIGHT + 0.4, 0.0), 0.0)
	# Se coloca el coche YA a la velocidad pedida y se deja asentar la suspensión: la medida
	# es de la curva, no del tiempo que tarda en acelerar.
	car.velocity = Vector3(0.0, 0.0, -minf(target, car.max_forward_speed_ms))
	for i in SETTLE_TICKS:
		await physics_frame
		_speed_control(target)
	var recto := _visual_deg()
	if visual_sign == 0.0:
		# Calibración: la convención del eje de la rueda frente al signo del modelo.
		_push_stick(0.5, 1.0)
		for i in 12:
			await physics_frame
		visual_sign = signf(_visual_deg() - recto) * signf(car.steering_angle)
		# (`recto` está en grados: la diferencia se envuelve en grados, no en radianes)
		_release_stick()
	var approach_speed: float = car.speed_mps
	# Curva: el dedo se queda quieto en su recorrido y el pedal lo lleva el caso.
	var last_yaw := car.rotation.y
	var samples: Array = []
	var walls := 0
	for tick in CORNER_TICKS:
		match String(entry["pedal"]):
			"acelerando":
				_pedals(1.0, 0.0)
			"frenando":
				_pedals(0.0, 1.0)
			_:
				_speed_control(target)
		_push_stick(fraction, side)
		await physics_frame
		var yaw := car.rotation.y
		var yaw_rate := wrapf(yaw - last_yaw, -PI, PI) / TICK
		last_yaw = yaw
		samples.append({"speed": car.speed_mps, "yaw_rate": yaw_rate, "angle": car.steering_angle,
			"visual": wrapf(_visual_deg() - recto, -180.0, 180.0), "visual_raw": _visual_deg(),
			"led": ui._steer_value,
			"input": car.steering_input, "target": car.debug_target_steer,
			"max": car.debug_max_steer, "lean": car.debug_lean_steer, "grip": car.debug_grip_steer,
			"yaw_cap": car.debug_yaw_cap, "limit_g": car.debug_lateral_limit_g,
			"contacts": car.wheel_contacts})
		for i in car.get_slide_collision_count():
			var collision := car.get_slide_collision(i)
			var body := collision.get_collider() as Node
			if _group_of(body) == "WALL" and absf(collision.get_normal().y) < 0.7:
				walls += 1
	var lateral_sum := 0.0
	var yaw_sum := 0.0
	var sustained: Array = []
	var last_sample: Dictionary = samples[samples.size() - 1]
	var peak := 0.0
	for index in samples.size():
		var sample: Dictionary = samples[index]
		var speed: float = sample["speed"]
		var yaw_rate: float = absf(sample["yaw_rate"])
		peak = maxf(peak, speed * yaw_rate / 9.81)
		if index >= SUSTAINED_FROM:
			lateral_sum += speed * yaw_rate / 9.81
			yaw_sum += yaw_rate
			sustained.append(speed)
	var cuenta := maxf(1.0, float(sustained.size()))
	var sustained_g := lateral_sum / cuenta
	var mean_yaw := yaw_sum / cuenta
	var mean_speed := 0.0
	for value in sustained:
		mean_speed += float(value)
	mean_speed /= cuenta
	var radius := 100000.0
	if mean_yaw > 0.0001:
		radius = mean_speed / mean_yaw
	_release_stick()
	_pedals(0.0, 0.0)
	for i in 60:
		await physics_frame
	var label := "%.0f km/h, recorrido %.0f %% a la %s, %s" % [
		float(entry["kph"]), fraction * 100.0, "derecha" if side > 0.0 else "izquierda", String(entry["pedal"])]
	var result := {
		"label": label, "kph": float(entry["kph"]), "fraction": fraction, "side": side,
		"pedal": String(entry["pedal"]), "speed": approach_speed,
		"sustained_g": sustained_g, "peak_g": peak, "radius": radius, "yaw_rate": mean_yaw,
		"walls": walls, "led": float(last_sample["led"]), "input": float(last_sample["input"]),
		"target_deg": rad_to_deg(float(last_sample["target"])),
		"angle_deg": rad_to_deg(float(last_sample["angle"])),
		"visual_deg": float(last_sample["visual"]),
		"visual_raw_deg": float(last_sample["visual_raw"]), "recto_deg": recto,
		"max_deg": rad_to_deg(float(last_sample["max"])),
		"lean_deg": rad_to_deg(float(last_sample["lean"])),
		"grip_deg": rad_to_deg(float(last_sample["grip"])),
		"yaw_cap": float(last_sample["yaw_cap"]), "limit_g": float(last_sample["limit_g"]),
		"contacts": int(last_sample["contacts"]),
		"expected_input": ui._steering_curve(fraction) * side,
	}
	print("DIRECCION_RESULT %s | velocidad=%.0f km/h mando=%.3f demanda=%.3f pedido=%.2f° aplicado=%.2f° visual=%.2f° (crudo %.2f° menos recta %.2f°) topes=[lean %.2f° agarre %.2f° max %.2f°] tope_guiñada=%.3f rad/s agarre_disponible=%.2f g g_sostenida=%.3f g_pico=%.3f radio=%.0f m muros=%d contactos=%d" % [
		label, approach_speed * 3.6, result["led"], result["input"], result["target_deg"],
		result["angle_deg"], result["visual_deg"], result["visual_raw_deg"], result["recto_deg"],
		result["lean_deg"], result["grip_deg"],
		result["max_deg"], result["yaw_cap"], result["limit_g"], sustained_g, peak, radius, walls,
		result["contacts"]])
	return result
