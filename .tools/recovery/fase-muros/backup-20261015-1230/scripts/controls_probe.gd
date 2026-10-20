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
	if not held:
		touch(index, point, true)

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
	var steer_point := center + Vector2(radius * 0.5, 0)
	var brake_travel := Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5, brake.position.y + brake.size.y * 0.8)
	touch(1, tp, true)
	touch(2, steer_point, true)
	for frame in 4:
		await process_frame
		hold(1, tp)
		hold(2, steer_point)
		await physics_frame
	check(car.throttle_input > 0.95 and car.brake_input == 0.0 and car.steering_input > 0.2 and car.steering_input < 0.5, "multitouch throttle plus progressive steering")
	print("VALUES throttle=", car.throttle_input, " steer=",car.steering_input," rect=",throttle, " center=",center)
	var half: float = car.steering_input
	steer_point = center + Vector2(radius, 0)
	drag(2, steer_point)
	for frame in 4:
		await process_frame
		hold(1, tp)
		hold(2, steer_point)
		await physics_frame
	check(car.steering_input > half * 2, "more displacement gives more steering; precise center")
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
	check(car.brake_input > 0.05 and car.brake_input < 0.4, "pedal travel is analog")
	hold(3, brake_travel)
	touch(3, bp, false)
	for frame in 4:
		await process_frame
		await physics_frame
	check(car.brake_input == 0 and car.throttle_input == 0, "pedals release when finger lifts")
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
