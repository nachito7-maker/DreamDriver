extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 120:
		await physics_frame
	var car: CharacterBody3D = race.car
	var start := car.global_position
	print("RUNTIME floor=", car.is_on_floor(), " contacts=", car.wheel_contacts, " position=", start, " wheels=", car._front_wheels.size() + car._rear_wheels.size())
	var grounded: bool = car.is_on_floor() and car.wheel_contacts == 4
	var wheel_before: Basis = car._front_wheels[0].basis if not car._front_wheels.is_empty() else Basis.IDENTITY
	Input.action_press("throttle")
	for i in 480:
		await physics_frame
		if i < 4 or i == 120:
			print("CONTACT throttle=",car.throttle_input," velocity=",car.velocity," collisions=",car.get_slide_collision_count())
			for c in car.get_slide_collision_count():
				var hit := car.get_slide_collision(c)
				print("HIT ",hit.get_collider().name," normal=",hit.get_normal()," position=",hit.get_position())
	var speed: float = car.speed_kph
	var displacement := car.global_position.distance_to(start)
	var rotating: bool = not car._front_wheels.is_empty() and not car._front_wheels[0].basis.is_equal_approx(wheel_before)
	print("RUNTIME acceleration_kph=", speed, " displacement_m=", displacement, " position=", car.global_position, " floor=", car.is_on_floor(), " rotating=", rotating)
	Input.action_release("throttle")
	Input.action_press("brake")
	for i in 240:
		await physics_frame
	print("RUNTIME braking_kph=", car.speed_kph)
	var passed: bool = grounded and speed > 65.0 and displacement > 30.0 and rotating and car.speed_kph < 2.0
	Input.action_release("brake")
	race.queue_free()
	await process_frame
	quit(0 if passed else 1)
