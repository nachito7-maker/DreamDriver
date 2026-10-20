extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var car := CharacterBody3D.new()
	car.set_script(load("res://scripts/car_controller.gd"))
	root.add_child(car)
	await process_frame
	car.surface_grip = 1.0
	car.throttle_input = 1.0
	for i in 600:
		var forward := -car.global_basis.z
		var right := car.global_basis.x
		car.speed_mps = maxf(0.0, car.velocity.dot(forward))
		car.speed_kph = car.speed_mps * 3.6
		car._update_engine_and_forces(1.0 / 120.0, forward, right, car.velocity.dot(forward), car.velocity.dot(right))
		car.velocity.y = 0.0
		car.move_and_slide()
		car.velocity.y = 0.0
	var accelerated: float = car.speed_kph
	print("AFTER_ACCEL speed=", accelerated, " velocity=", car.velocity, " forward=", -car.global_basis.z)
	car.throttle_input = 0.0
	car.brake_input = 1.0
	for i in 240:
		var forward := -car.global_basis.z
		var right := car.global_basis.x
		car.speed_mps = maxf(0.0, car.velocity.dot(forward))
		car.speed_kph = car.speed_mps * 3.6
		car._update_engine_and_forces(1.0 / 120.0, forward, right, car.velocity.dot(forward), car.velocity.dot(right))
		car.velocity.y = 0.0
		car.move_and_slide()
		car.velocity.y = 0.0
	var braked: float = car.speed_kph
	print("AFTER_BRAKE speed=", braked, " velocity=", car.velocity, " forward=", -car.global_basis.z)
	car.brake_input = 0.0
	car.throttle_input = 1.0
	car.steering_input = 0.0
	car.speed_mps = 2.0
	car.speed_kph = 7.2
	car.steering_sensitivity_multiplier = 1.1
	var steer_angles := PackedFloat32Array()
	var yaw_start: float = car.rotation.y
	for demand in [0.18, 0.42, 0.78]:
		car.steering_input = demand
		for i in 100:
			var forward := -car.global_basis.z
			var right := car.global_basis.x
			car.speed_mps = maxf(0.0, car.velocity.dot(forward))
			car.speed_kph = car.speed_mps * 3.6
			car._update_engine_and_forces(1.0 / 120.0, forward, right, car.velocity.dot(forward), car.velocity.dot(right))
			car.velocity.y = 0.0
			car.move_and_slide()
			car.velocity.y = 0.0
		steer_angles.append(absf(car.steering_angle))
		print("STEERING_DEMAND input=", demand, " wheel_angle_deg=", rad_to_deg(absf(car.steering_angle)), " yaw_delta=", snappedf(car.rotation.y - yaw_start, 0.001))
	var yaw: float = car.rotation.y
	print("DYNAMICS acceleration_kph=", snappedf(accelerated, 0.1), " braking_kph=", snappedf(braked, 0.1), " yaw_rad=", snappedf(yaw - yaw_start, 0.001), " downforce_N=", snappedf(car.downforce_n, 1.0), " velocity=", car.velocity)
	var progressive: bool = steer_angles.size() == 3 and steer_angles[0] < steer_angles[1] and steer_angles[1] < steer_angles[2]
	var passed: bool = accelerated > 120.0 and braked < accelerated and absf(yaw - yaw_start) > 0.02 and car.downforce_n > 0.0 and progressive
	car.queue_free()
	await process_frame
	quit(0 if passed else 1)
