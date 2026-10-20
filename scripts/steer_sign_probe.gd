extends SceneTree

# ¿El joystick gira el coche hacia donde se mueve el dedo?
#
# Mide la cadena completa: posición del dedo -> demanda -> ángulo de dirección ->
# sentido de giro real del coche sobre el asfalto. Se prueba a la derecha, a la
# izquierda y con el mando centrado.

const TICK := 1.0 / 120.0

var failures := 0

func check(ok: bool, message: String) -> void:
	print("SENTIDO ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 120:
		await physics_frame
	var car: CharacterBody3D = race.car
	var ui: CanvasLayer = race.controls
	var radius := maxf(1.0, ui._steering_ring.size.x * 0.46)
	for entry in [{"x": 1.0, "label": "derecha", "expect": -1.0}, {"x": -1.0, "label": "izquierda", "expect": 1.0}]:
		var line: PackedVector3Array = load("res://scripts/track_data.gd").get_centerline()
		car.recover_to(line[600] + Vector3.UP * 0.3, 0.0)
		car.rotation.y = 0.0
		car.velocity = Vector3.ZERO
		ui._handle_touch_up(10)
		for i in 40:
			await physics_frame
		var start_yaw: float = car.rotation.y
		ui._handle_touch_down(10, ui._steer_center + Vector2(radius * float(entry["x"]), 0.0))
		ui._handle_touch_down(11, Vector2(ui._throttle_pedal.position.x + 20.0, ui._pedal_rects["throttle"].position.y + 3.0))
		for i in 240:
			await physics_frame
			ui._process(TICK)
		var delta_yaw := wrapf(car.rotation.y - start_yaw, -PI, PI)
		print("SENTIDO mando=%s valor_mando=%.3f entrada=%.3f angulo=%.3f giro=%.1f° velocidad=%.0f km/h" % [
			entry["label"], ui._steer_value, car.steering_input, car.steering_angle, rad_to_deg(delta_yaw), car.speed_kph])
		check(signf(delta_yaw) == float(entry["expect"]) and absf(delta_yaw) > 0.05,
			"el mando a %s gira el coche a %s (giro %.1f°)" % [entry["label"], entry["label"], rad_to_deg(delta_yaw)])
		ui._handle_touch_up(10)
		ui._handle_touch_up(11)
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
