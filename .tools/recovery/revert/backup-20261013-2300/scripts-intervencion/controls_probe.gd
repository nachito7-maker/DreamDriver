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
	var tp := Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5, throttle.position.y + throttle.size.y * 0.05)
	var bp := Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5, brake.position.y + brake.size.y * 0.05)
	var center: Vector2 = ui._steer_center
	var radius: float = ui._steering_ring.size.x * 0.46
	touch(1, tp, true)
	touch(2, center + Vector2(radius * 0.5, 0), true)
	for frame in 4:
		await process_frame
		await physics_frame
	check(car.throttle_input > 0.95 and car.brake_input == 0.0 and car.steering_input > 0.45 and car.steering_input < 0.75, "multitouch throttle plus useful progressive steering at half travel")
	print("STEERING_CONFIG default=", car.steering_sensitivity_multiplier, " low_speed_max_deg=", rad_to_deg(car.steering_at_low_speed_rad), " high_speed_max_deg=", rad_to_deg(car.steering_at_high_speed_rad))
	var sensitivity_values: Array[float] = []
	for i in 4:
		ui._cycle_steering_sensitivity()
		sensitivity_values.append(ui._steering_sensitivity)
		check(is_equal_approx(float(car.get("steering_sensitivity_multiplier")), ui._steering_sensitivity), "HUD sensitivity applies %.2f× to the vehicle steering" % ui._steering_sensitivity)
	check(sensitivity_values.size() == 4 and is_equal_approx(sensitivity_values[0], 1.25) and is_equal_approx(sensitivity_values[1], 1.4) and is_equal_approx(sensitivity_values[2], 0.85) and is_equal_approx(sensitivity_values[3], 1.1), "HUD sensitivity cycles through safe settings and wraps to default")
	ui._process(1.0 / 60.0)
	print("VALUES throttle=", car.throttle_input, " steer=",car.steering_input," rect=",throttle, " center=",center)
	var half: float = car.steering_input
	drag(2, center + Vector2(radius, 0))
	for frame in 4:
		await process_frame
		await physics_frame
	check(car.steering_input > half * 1.35, "near-full joystick travel adds steering beyond the half-travel response")
	drag(2, center + Vector2(radius * 0.25, 0))
	for frame in 3:
		await process_frame
		await physics_frame
	check(car.steering_input > 0.15 and car.steering_input < half, "quarter travel produces a distinct small analog correction")
	drag(2, center + Vector2(radius, 0))
	for frame in 3:
		await process_frame
		await physics_frame
	touch(2, center, false)
	await process_frame
	check(car.steering_input > 0, "release does not abruptly snap physical steering")
	for i in 70:
		await create_timer(0.01).timeout
	check(absf(float(car.get_meta("touch_steer"))) < 0.001 and (ui._steering_knob.position + ui._steering_knob.size * 0.5).distance_to(center) < 0.3, "physical input and visual joystick return to center")
	touch(1, tp, false)
	touch(3, bp, true)
	for frame in 4:
		await process_frame
		await physics_frame
	check(car.throttle_input == 0 and car.brake_input > 0.95, "brake applies brake only")
	drag(3, Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5, brake.position.y + brake.size.y * 0.8))
	for frame in 4:
		await process_frame
		await physics_frame
	check(car.brake_input > 0.05 and car.brake_input < 0.4, "pedal travel is analog")
	touch(3, bp, false)
	for frame in 4:
		await process_frame
		await physics_frame
	check(car.brake_input == 0 and car.throttle_input == 0, "pedals release when finger lifts")
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
