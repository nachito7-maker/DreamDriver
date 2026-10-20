extends SceneTree

# ¿Cuánto gira el coche de verdad? Respuesta de dirección medida.
#
# Cada caso coloca el coche al principio de la recta principal, regula la
# velocidad pedida y después aplica una demanda de dirección fija durante 1,2 s,
# muestreando el régimen alcanzado:
#
#   * aceleración lateral sostenida en g y pico,
#   * régimen de guiñada (rad/s),
#   * radio de giro equivalente (m),
#   * regularidad del régimen (si oscila o se mantiene),
#   * contactos con muro durante la maniobra (invalidan la medida si los hay).
#
# Se ejecuta sin ventana: la demanda de dirección se inyecta por el mismo canal
# que usa el joystick (touch_steer) con el proceso de la capa de controles
# detenido, así que la física es la real y la medida es repetible.
#
# Uso:  Godot --headless --path . --script res://scripts/steering_probe.gd

const TrackScript = preload("res://scripts/track_data.gd")
const TICK := 1.0 / 120.0
# La medida se hace sobre una losa de asfalto plana y sin obstáculos: en la
# recta real, 1,2 s a 1,2 g llevan al coche 8 m de lado y acaba tocando las
# barreras, con lo que la medida del modelo se contaminaba.
const PAD_HEIGHT := 1500.0
const PAD_HALF := 4000.0
const CORNER_TICKS := 144          # 1,2 s de curva
const SUSTAINED_FROM := 96         # media desde aquí: régimen establecido
const APPROACH_TICKS := 700
const SPEED_TOLERANCE := 0.6       # m/s
const MIN_SUSTAINED_G := 0.75
const MIN_STEER_WHILE_ACCEL_G := 0.45
const MIN_STEER_WHILE_BRAKE_G := 0.45
const MAX_OSCILLATION := 0.35
const MAX_LEFT_RIGHT_DIFFERENCE := 0.15

const CASES := [
	{"label": "curva 60 km/h a fondo de dirección", "speed": 60.0 / 3.6, "steer": 1.0, "demand": "hold"},
	{"label": "curva 120 km/h a fondo de dirección", "speed": 120.0 / 3.6, "steer": 1.0, "demand": "hold"},
	{"label": "curva 180 km/h a fondo de dirección", "speed": 180.0 / 3.6, "steer": 1.0, "demand": "hold"},
	{"label": "curva 120 km/h a media dirección", "speed": 120.0 / 3.6, "steer": 0.5, "demand": "hold"},
	{"label": "curva 120 km/h a un cuarto del recorrido", "speed": 120.0 / 3.6, "steer": 0.25, "demand": "hold"},
	{"label": "curva 180 km/h a un cuarto del recorrido", "speed": 180.0 / 3.6, "steer": 0.25, "demand": "hold"},
	{"label": "curva 120 km/h a la izquierda", "speed": 120.0 / 3.6, "steer": -1.0, "demand": "hold"},
	{"label": "acelerando y girando a 60 km/h", "speed": 60.0 / 3.6, "steer": 1.0, "demand": "accelerate"},
	{"label": "frenando y girando a 180 km/h", "speed": 180.0 / 3.6, "steer": 1.0, "demand": "brake"},
]

var failures := 0
var race: Node3D
var car: CharacterBody3D
var ui: CanvasLayer
var spawn_yaw := 0.0

func check(ok: bool, message: String) -> void:
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

# Demandas de pedal al canal real de entrada (metadatos leídos por el coche).
func _demand(throttle: float, brake: float, steer: float) -> void:
	car.set_meta("touch_throttle", throttle)
	car.set_meta("touch_brake", brake)
	car.set_meta("touch_steer", steer)

func _speed_control(target: float) -> void:
	var error: float = target - car.speed_mps
	var throttle := clampf(error * 0.4 + 0.1, 0.0, 1.0)
	var brake := clampf(-error * 0.3, 0.0, 1.0)
	if throttle < 0.05:
		throttle = 0.0
	if brake < 0.05:
		brake = 0.0
	_demand(throttle, brake, 0.0)

func _run() -> void:
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 120:
		await physics_frame
	car = race.car
	ui = race.controls
	ui.set_process(false)              # la inyección manda; el joystick no sobrescribe
	_build_pad()
	spawn_yaw = 0.0

	var results: Array = []
	for entry in CASES:
		var result: Dictionary = await _measure(entry)
		results.append(result)
		print("DIRECCION RESULT %s | velocidad=%.0f km/h direccion=%.2f g_sostenida=%.3f g_pico=%.3f radio=%.0f m guiñada=%.3f rad/s oscilacion=%.2f muros=%d" % [
			entry["label"], float(result["speed"]) * 3.6, float(entry["steer"]), result["sustained_g"],
			result["peak_g"], result["radius"], result["yaw_rate"], result["oscillation"], result["walls"]])
	for entry in results:
		check(int(entry["walls"]) == 0, "sin contacto con muro durante la medida: %s" % entry["label"])

	var by_label := {}
	for entry in results:
		by_label[entry["label"]] = entry
	var right_120: float = float(by_label["curva 120 km/h a fondo de dirección"]["sustained_g"])
	var left_120: float = float(by_label["curva 120 km/h a la izquierda"]["sustained_g"])
	var moderate: float = float(by_label["curva 60 km/h a fondo de dirección"]["sustained_g"])
	var half_120: float = float(by_label["curva 120 km/h a media dirección"]["sustained_g"])
	check(right_120 >= half_120 * 0.98, "a la misma velocidad el manillar a fondo gira al menos como el medio (%.2f g frente a %.2f g)" % [right_120, half_120])
	check(right_120 >= MIN_SUSTAINED_G, "a 120 km/h mantiene al menos %.2f g de curva (%.2f g)" % [MIN_SUSTAINED_G, right_120])
	check(moderate >= MIN_SUSTAINED_G, "a 60 km/h mantiene al menos %.2f g de curva (%.2f g)" % [MIN_SUSTAINED_G, moderate])
	var difference := absf(right_120 - left_120) / maxf(right_120, left_120)
	check(difference <= MAX_LEFT_RIGHT_DIFFERENCE, "gira igual a izquierda y derecha (diferencia %.0f%%)" % (difference * 100.0))
	var quarter_120: float = float(by_label["curva 120 km/h a un cuarto del recorrido"]["sustained_g"])
	var quarter_180: float = float(by_label["curva 180 km/h a un cuarto del recorrido"]["sustained_g"])
	# Progresividad: el primer cuarto del recorrido no debe saturar el agarre; el
	# manillar tiene que repartir el mando por todo su recorrido.
	check(quarter_120 <= right_120 * 0.8, "a 120 km/h el primer cuarto del manillar no satura (%.2f g de %.2f g)" % [quarter_120, right_120])
	check(quarter_180 <= float(by_label["curva 180 km/h a fondo de dirección"]["sustained_g"]) * 0.8,
		"a 180 km/h el primer cuarto del manillar no satura (%.2f g)" % quarter_180)
	var accelerating: float = float(by_label["acelerando y girando a 60 km/h"]["sustained_g"])
	var braking: float = float(by_label["frenando y girando a 180 km/h"]["sustained_g"])
	check(accelerating >= MIN_STEER_WHILE_ACCEL_G, "gira mientras acelera (%.2f g)" % accelerating)
	check(braking >= MIN_STEER_WHILE_BRAKE_G, "gira mientras frena (%.2f g)" % braking)
	for entry in results:
		check(int(entry["sign_changes"]) == 0, "la guiñada no cambia de sentido en %s (%d cambios)" % [entry["label"], entry["sign_changes"]])
		if String(entry["demand"]) == "hold":
			check(float(entry["oscillation"]) <= MAX_OSCILLATION, "régimen regular sin oscilar en %s (%.2f)" % [entry["label"], entry["oscillation"]])
	for text in ui_surface_texts():
		info(text)
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

# Traducción del recorrido del joystick a demanda, para dejar constancia de la
# respuesta del mando analógico (función pura de la capa de controles).
func ui_surface_texts() -> Array:
	var out: Array = []
	for fraction in [0.25, 0.5, 0.75, 1.0]:
		out.append("joystick al %d%% del recorrido -> demanda %.3f" % [roundi(fraction * 100.0), ui._steering_curve(fraction)])
	return out

# Losa de asfalto de pruebas: cuerpo estático llamado TRM-BRC para que el
# controlador la reconozca como asfalto, plana y sin nada alrededor.
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

func _measure(entry: Dictionary) -> Dictionary:
	var target: float = entry["speed"]
	var steer: float = entry["steer"]
	car.recover_to(Vector3(0.0, PAD_HEIGHT + 0.4, -float(APPROACH_TICKS) * 0.02), spawn_yaw)
	car.velocity = Vector3.ZERO
	_demand(0.0, 0.0, 0.0)
	for i in 30:
		await physics_frame
	# Aproximación: se alcanza la velocidad pedida en la recta principal.
	var settled := 0
	for tick in APPROACH_TICKS:
		await physics_frame
		_speed_control(target)
		if absf(car.speed_mps - target) <= SPEED_TOLERANCE:
			settled += 1
			if settled > 90:
				break
		else:
			settled = 0
	var approach_speed: float = car.speed_mps
	# Curva: demanda fija, pedal según el caso.
	var last_yaw := car.rotation.y
	var samples: Array = []
	var walls := 0
	for tick in CORNER_TICKS:
		match String(entry["demand"]):
			"accelerate":
				_demand(1.0, 0.0, steer)
			"brake":
				_demand(0.0, 1.0, steer)
			_:
				_speed_control(target)
				car.set_meta("touch_steer", steer)
		await physics_frame
		var yaw := car.rotation.y
		var yaw_rate := wrapf(yaw - last_yaw, -PI, PI) / TICK
		last_yaw = yaw
		samples.append({"speed": car.speed_mps, "yaw_rate": yaw_rate})
		for i in car.get_slide_collision_count():
			var collision := car.get_slide_collision(i)
			if _group_of(collision.get_collider() as Node) == "WALL" and absf(collision.get_normal().y) < 0.7:
				walls += 1
	var sustained := []
	var sign_changes := 0
	var last_sign := 0
	var lateral_sum := 0.0
	var peak := 0.0
	var yaw_sum := 0.0
	var yaw_values: Array = []
	for index in samples.size():
		var sample: Dictionary = samples[index]
		var speed: float = sample["speed"]
		var yaw_rate: float = absf(sample["yaw_rate"])
		var lateral_g := speed * yaw_rate / 9.81
		peak = maxf(peak, lateral_g)
		if index >= SUSTAINED_FROM:
			var sign := signi(1 if sample["yaw_rate"] > 0.01 else (-1 if sample["yaw_rate"] < -0.01 else 0))
			if sign != 0 and last_sign != 0 and sign != last_sign:
				sign_changes += 1
			if sign != 0:
				last_sign = sign
			lateral_sum += lateral_g
			yaw_sum += yaw_rate
			yaw_values.append(yaw_rate)
			sustained.append(speed)
	var sustained_g := lateral_sum / maxf(1.0, sustained.size())
	var mean_yaw := yaw_sum / maxf(1.0, yaw_values.size())
	var oscillation := 0.0
	if mean_yaw > 0.0001:
		var spread := 0.0
		for value in yaw_values:
			spread = maxf(spread, absf(float(value) - mean_yaw))
		oscillation = spread / mean_yaw
	var mean_speed := 0.0
	for value in sustained:
		mean_speed += float(value)
	mean_speed /= maxf(1.0, sustained.size())
	var radius := 100000.0
	if mean_yaw > 0.0001:
		radius = mean_speed / mean_yaw
	_demand(0.0, 0.0, 0.0)
	for i in 60:
		await physics_frame
	return {"label": entry["label"], "demand": entry["demand"], "speed": approach_speed,
		"sustained_g": sustained_g, "peak_g": peak, "radius": radius, "yaw_rate": mean_yaw,
		"oscillation": oscillation, "walls": walls, "sign_changes": sign_changes}
