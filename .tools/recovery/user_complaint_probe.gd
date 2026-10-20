extends SceneTree
const TD = preload("res://scripts/track_data.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.max_fps = 60
	for track_id in [TD.BARCELONA, TD.SUZUKA]:
		for vehicle_id in ["rb22_2026", "mclaren"]:
			TD.reset_selection()
			TD.set_user_selection(track_id, vehicle_id)
			var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
			root.add_child(race)
			for i in 120:
				await physics_frame
			var car: CharacterBody3D = race.car
			print("DIAG START track=", track_id, " car=", vehicle_id, " spawn=", race.spawn_position, " carpos=", car.global_position, " contacts=", car.wheel_contacts, " model=", car.model_root, " wheels=", car._suspension_wheels.size(), " suspension=", car.suspension)
			if car.suspension != null:
				print("DIAG RIDE height=", car.suspension.height, " road=", car.suspension.road, " pitch=", rad_to_deg(car.suspension.pitch), " roll=", rad_to_deg(car.suspension.roll))
			for i in car._suspension_wheels.size():
				var wheel: Node3D = car._suspension_wheels[i]
				var hub_car: Vector3 = car.global_transform.affine_inverse() * wheel.global_position
				var world: Vector3 = car.global_transform * Vector3(hub_car.x, 0.0, hub_car.z)
				var query := PhysicsRayQueryParameters3D.create(world + Vector3.UP * 0.8, world - Vector3.UP * 0.9, 1)
				var hit := car.get_world_3d().direct_space_state.intersect_ray(query)
				if hit.is_empty():
					print("WHEEL ", i, " name=", wheel.name, " hub=", hub_car, " ray=MISS")
				else:
					print("WHEEL ", i, " name=", wheel.name, " hub=", hub_car, " hit=", hit.collider.name, " hit_y=", hit.position.y, " car_y=", car.global_position.y, " gap=", hit.position.y-car.global_position.y, " normal=", hit.normal)
			var start_yaw: float = car.rotation.y
			Input.action_press("throttle", 0.65)
			Input.action_press("steer_right", 0.6)
			for i in 360:
				await physics_frame
			var yaw_change := wrapf(car.rotation.y-start_yaw, -PI, PI)
			print("DIAG DRIVE track=", track_id, " car=", vehicle_id, " speed=", car.speed_kph, " pos=", car.global_position, " contacts=", car.wheel_contacts, " yaw_deg=", rad_to_deg(yaw_change), " steer_deg=", rad_to_deg(car.steering_angle), " pitch_deg=", rad_to_deg(car.suspension.pitch) if car.suspension != null else NAN, " roll_deg=", rad_to_deg(car.suspension.roll) if car.suspension != null else NAN)
			Input.action_release("throttle")
			Input.action_release("steer_right")
			race.queue_free()
			await process_frame
	print("DIAG DONE")
	quit(0)
