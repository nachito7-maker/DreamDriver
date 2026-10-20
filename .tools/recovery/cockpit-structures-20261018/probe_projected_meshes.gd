extends SceneTree

const TrackScript := preload("res://scripts/track_data.gd")
const RaceScene := preload("res://scenes/race.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for vehicle_id in ["mclaren", "rb22_2026"]:
		TrackScript.set_user_selection(TrackScript.BARCELONA, vehicle_id)
		var race: Node3D = RaceScene.instantiate()
		root.add_child(race)
		await process_frame
		if race.car == null or race.car.model_root == null:
			push_error("Model failed to load: " + vehicle_id)
			quit(1)
			return
		race.car.set_physics_process(false)
		race.set_camera_mode(1)
		race._update_nose_camera()
		race._apply_camera_mode(1.0)
		await process_frame
		var camera: Camera3D = race.nose_camera
		var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size
		print("VEHICLE=", vehicle_id, " VIEWPORT=", viewport_size, " CAMERA=", camera.global_position, " FOV=", camera.fov)
		for candidate in race.car.model_root.find_children("*", "MeshInstance3D", true, false):
			var mesh := candidate as MeshInstance3D
			if mesh.mesh == null or not mesh.visible:
				continue
			var box: AABB = mesh.mesh.get_aabb()
			var points: Array[Vector2] = []
			for x in [box.position.x, box.end.x]:
				for y in [box.position.y, box.end.y]:
					for z in [box.position.z, box.end.z]:
						var screen := camera.unproject_position(mesh.global_transform * Vector3(x, y, z))
						points.append(screen)
			var minp := Vector2(INF, INF)
			var maxp := Vector2(-INF, -INF)
			for p in points:
				minp.x = minf(minp.x, p.x); minp.y = minf(minp.y, p.y)
				maxp.x = maxf(maxp.x, p.x); maxp.y = maxf(maxp.y, p.y)
			# Original black protrusions in submitted view: lateral lower foreground
			# beside the nose/front wing, not the camera-local fake halo rails.
			var norm_min := minp / viewport_size
			var norm_max := maxp / viewport_size
			var lower := norm_max.y >= 0.72 and norm_min.y <= 1.02
			var left := norm_max.x >= 0.12 and norm_min.x <= 0.43
			var right := norm_max.x >= 0.57 and norm_min.x <= 0.88
			if lower and (left or right):
				var material := mesh.get_active_material(0)
				print("PROJECTED path=", mesh.get_path(), " mesh=", mesh.mesh.get_class(), " local_aabb=", box,
					" local_pos=", mesh.position, " local_rot=", mesh.rotation, " local_scale=", mesh.scale,
					" screen_norm=", norm_min, "..", norm_max,
					" active_material=", material.resource_name if material else "null",
					" type=", material.get_class() if material else "null")
		race.queue_free()
		await process_frame
	quit()
