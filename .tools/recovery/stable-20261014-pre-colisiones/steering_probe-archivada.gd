extends SceneTree

# Sonda de dirección analógica medida sobre el coche.
#
# No se conforma con leer el valor del mando: mide cuánto gira el vehículo de
# verdad. El coche se conduce con la cadena de toque real (el mismo dedo
# analógico que en el móvil) sobre una plataforma plana con la misma adherencia
# que el asfalto, así que lo que se mide es el conjunto mando + sensibilidad +
# modelo del coche, sin depender de la forma de la escapatoria.
#
# Para cada velocidad y cada recorrido del mando se registra el ángulo real de
# rueda, la velocidad de giro, el radio de la trazada, la aceleración lateral y
# el deslizamiento, más la simetría izquierda/derecha y la vuelta al centro al
# soltar.

const TICK := 1.0 / 120.0
const PLATFORM_Y := 400.0
const SETTLE_TICKS := 150
const MEASURE_TICKS := 180
const SPEEDS := [8.0, 20.0, 40.0]
const FRACTIONS := [0.25, 0.6, 1.0]

var failures := 0
var space: PhysicsDirectSpaceState3D
var race: Node3D
var car: CharacterBody3D
var ui: CanvasLayer
var steer_center := Vector2.ZERO
var steer_radius := 1.0
var gas_rect := Rect2()
var brake_rect := Rect2()
var gas_point := Vector2.ZERO
var brake_point := Vector2.ZERO

func check(ok: bool, message: String) -> void:
	print("DIRECCION ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func info(message: String) -> void:
	print("DIRECCION INFO ", message)

func _initialize() -> void:
	call_deferred("_run")

func _build_platform() -> void:
	var body := StaticBody3D.new()
	body.name = "Banco de pruebas de direccion"
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6000.0, 8.0, 6000.0)
	shape.shape = box
	shape.position = Vector3(0.0, PLATFORM_Y - 4.0, 0.0)
	body.add_child(shape)
	race.add_child(body)

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
	gas_rect = ui._pedal_rects["throttle"]
	brake_rect = ui._pedal_rects["brake"]
	if gas_rect.size.x <= 0.0 or ui._viewport_size.x <= 0.0:
		push_error("La sonda de dirección necesita una ventana real con viewport medible")
		quit(2)
		return
	gas_point = Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5, gas_rect.position.y + gas_rect.size.y * 0.05)
	brake_point = Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5, brake_rect.end.y - 1.0)
	_build_platform()
	space = race.get_world_3d().direct_space_state
	info("plataforma plana en y=%.0f | sensibilidad del HUD=%.2f | mando centro=%s radio=%.1f | velocidades=%s | recorridos=%s" % [
		PLATFORM_Y, car.steering_sensitivity_multiplier, str(steer_center), steer_radius, str(SPEEDS), str(FRACTIONS)])

	var cases: Array = []
	for speed in SPEEDS:
		for fraction in FRACTIONS:
			for sign in [1.0, -1.0]:
				cases.append(await _measure(float(speed), float(fraction) * float(sign)))
	for case in cases:
		print("DIRECCION_RESULT velocidad_ms=%.1f joystick=%.2f angulo_rueda_deg=%.2f yaw_rad_s=%.4f radio_m=%.2f lateral_g=%.2f contactos=%d suelo=%s desliz=%.3f" % [
			case["speed"], case["fraction"], case["wheel_deg"], case["yaw_rate"], case["radius"],
			case["lateral_g"], case["contacts"], str(case["floor"]), case["slip"]])
	info("vuelta al centro: deriva de rumbo en 1,2 s=%.3f grados, yaw residual=%.4f rad/s" % [rad_to_deg(_center_drift), _center_yaw])
	_evaluate(cases)
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

var _center_drift := 0.0
var _center_yaw := 0.0

func _pedal_point(rect: Rect2, demand: float) -> Vector2:
	var low := 0.0
	var high := 0.8
	for i in 12:
		var mid := (low + high) * 0.5
		if smoothstep(0.0, 0.8, mid) < demand:
			low = mid
		else:
			high = mid
	return rect.position + rect.size * Vector2(0.5, 1.0 - (low + high) * 0.5)

func _hold(point: Vector2, id: int) -> void:
	var needs_press := false
	match id:
		10:
			needs_press = ui._steer_touch_id != id
		11:
			needs_press = ui._throttle_touch_id != id
		12:
			needs_press = ui._brake_touch_id != id
	if needs_press:
		ui._handle_touch_down(id, point)
	else:
		ui._handle_touch_motion(id, point)

func _command(speed_target: float, steer_fraction: float) -> void:
	_hold(steer_center + Vector2(clampf(steer_fraction, -1.0, 1.0) * steer_radius, 0.0), 10)
	var error: float = speed_target - car.speed_mps
	var throttle := clampf(error * 0.35 + 0.12, 0.0, 1.0)
	var brake := clampf(-error * 0.25, 0.0, 0.7)
	var gas := _pedal_point(gas_rect, maxf(0.35, throttle))
	var slow := _pedal_point(brake_rect, brake)
	if throttle <= 0.03:
		gas = Vector2(gas.x, ui._throttle_pedal.position.y + ui._throttle_pedal.size.y + 4.0)
	if brake <= 0.03:
		slow = Vector2(slow.x, ui._brake_pedal.position.y + ui._brake_pedal.size.y + 4.0)
	_hold(gas, 11)
	_hold(slow, 12)
	ui._process(TICK)

func _place() -> void:
	car.recover_to(Vector3(0.0, PLATFORM_Y + 0.6, 0.0), 0.0)
	car.velocity = Vector3.ZERO
	_hold(steer_center, 10)
	_hold(gas_point, 11)
	_hold(brake_point, 12)
	for i in 40:
		await physics_frame
	ui._handle_touch_motion(10, steer_center)

func _measure(speed: float, fraction: float) -> Dictionary:
	await _place()
	# Primero se alcanza la velocidad pedida en línea recta: el mando todavía no
	# se ha tocado, así que el coche no arrastra giro del caso anterior.
	for tick in 600:
		await physics_frame
		_command(speed, 0.0)
		if absf(car.speed_mps - speed) < 1.0 and tick > 60:
			break
	var entry_speed: float = car.speed_mps
	# Se lleva el mando al recorrido pedido y se deja converger el ángulo real de
	# rueda antes de medir.
	for tick in SETTLE_TICKS:
		await physics_frame
		_command(speed, fraction)
	var heading_start := car.rotation.y
	var position_start := car.global_position
	var contacts := 4
	var max_slip := 0.0
	var speed_sum := 0.0
	var speed_samples := 0
	var floor_ok := true

	for tick in MEASURE_TICKS:
		await physics_frame
		_command(speed, fraction)
		contacts = mini(contacts, car.wheel_contacts)
		max_slip = maxf(max_slip, absf(car.lateral_slip))
		speed_sum += car.speed_mps
		speed_samples += 1
		floor_ok = floor_ok and car.is_on_floor()
	var yaw_delta := car.rotation.y - heading_start
	var arc := position_start.distance_to(car.global_position)
	var average_speed := speed_sum / maxf(1.0, float(speed_samples))
	var duration := MEASURE_TICKS * TICK
	var yaw_rate := yaw_delta / duration
	var radius := arc / maxf(absf(yaw_delta), 0.0001)
	var case := {
		"speed": speed, "fraction": fraction, "entry_speed": entry_speed,
		"wheel_deg": rad_to_deg(absf(car.steering_angle)), "yaw_rate": yaw_rate,
		"radius": radius, "lateral_g": average_speed * absf(yaw_rate) / 9.81,
		"contacts": contacts, "floor": floor_ok, "slip": max_slip, "average_speed": average_speed,
	}
	# Suelta y comprueba que el mando vuelve al centro y el coche deja de girar.
	_command(speed, 0.0)
	for tick in 90:
		await physics_frame
		_command(speed, 0.0)
	var heading_release := car.rotation.y
	for tick in 144:
		await physics_frame
		_command(speed, 0.0)
	_center_drift = rad_to_deg(car.rotation.y - heading_release)
	_center_yaw = (car.rotation.y - heading_release) / (144.0 * TICK)
	case["release_drift_deg"] = _center_drift
	return case

func _evaluate(cases: Array) -> void:
	if cases.is_empty():
		check(false, "hubo casos de dirección que medir")
		return
	var best_low := INF
	var best_low_fraction := 0.0
	var moderate_low := INF
	var monotonic := true
	var symmetry := true
	var high_stable := true
	var high_bounded := true
	var wheel_low := 0.0
	for case in cases:
		if absf(float(case["fraction"])) == 0.25 and is_equal_approx(float(case["speed"]), 8.0):
			moderate_low = minf(moderate_low, float(case["radius"]))
		if absf(float(case["fraction"])) == 1.0 and is_equal_approx(float(case["speed"]), 8.0):
			if float(case["radius"]) < best_low:
				best_low = float(case["radius"])
				best_low_fraction = float(case["fraction"])
			wheel_low = maxf(wheel_low, float(case["wheel_deg"]))
		if is_equal_approx(float(case["speed"]), 40.0):
			if int(case["contacts"]) < 4 or not bool(case["floor"]) or float(case["slip"]) > 1.2:
				high_stable = false
			if absf(float(case["yaw_rate"])) > 0.35:
				high_bounded = false
	for speed in SPEEDS:
		var responses: Array = []
		for case in cases:
			if is_equal_approx(float(case["speed"]), float(speed)) and float(case["fraction"]) > 0.0:
				responses.append(absf(float(case["yaw_rate"])))
		for case in cases:
			if not is_equal_approx(float(case["speed"]), float(speed)):
				continue
			for other in cases:
				if is_equal_approx(float(other["speed"]), float(speed)) and is_equal_approx(float(other["fraction"]), -float(case["fraction"])):
					var a := absf(float(case["yaw_rate"]))
					var b := absf(float(other["yaw_rate"]))
					if maxf(a, b) > 0.02 and absf(a - b) > maxf(a, b) * 0.3:
						symmetry = false
	for speed in SPEEDS:
		var previous := -1.0
		for fraction in FRACTIONS:
			var found := -1.0
			for case in cases:
				if is_equal_approx(float(case["speed"]), float(speed)) and is_equal_approx(float(case["fraction"]), float(fraction)):
					found = absf(float(case["yaw_rate"]))
			if found >= 0.0:
				if previous >= 0.0 and found <= previous + 0.005:
					monotonic = false
				previous = found
	check(moderate_low < 45.0, "un recorrido moderado del mando (25%%) gira el coche a baja velocidad: radio %.2f m" % moderate_low)
	check(best_low < 12.0, "el mando a fondo a baja velocidad da un radio corto: %.2f m (recorrido %.0f%%)" % [best_low, best_low_fraction * 100.0])
	check(wheel_low >= 25.0, "hay ángulo real de rueda a baja velocidad: %.2f grados" % wheel_low)
	check(monotonic, "la respuesta es progresiva: más recorrido de mando da más giro en todas las velocidades")
	check(symmetry, "el coche gira igual a izquierda y a derecha para el mismo recorrido")
	check(high_stable, "a alta velocidad mantiene las cuatro ruedas y no desliza en exceso")
	check(high_bounded, "a alta velocidad el giro queda acotado (sin trompo): yaw <= 0.35 rad/s")
	check(absf(_center_drift) < 2.0 and absf(_center_yaw) < 0.03, "al soltar el mando el coche deja de girar: deriva %.2f grados" % _center_drift)
