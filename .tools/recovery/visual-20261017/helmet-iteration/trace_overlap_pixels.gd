extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	await process_frame
	race.set_camera_mode(1)
	for i in 45:
		await process_frame
	var cam: Camera3D = race.nose_camera
	var body := race.car.model_root.find_child("Body", true, false) as MeshInstance3D
	var vertices: PackedVector3Array = body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = body.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	var viewport := root.get_viewport().get_visible_rect().size
	for nx in [0.02, 0.08, 0.14, 0.20, 0.26, 0.32, 0.38, 0.62, 0.68, 0.74, 0.80, 0.86, 0.92, 0.98]:
		for ny in [0.62, 0.70, 0.78, 0.86, 0.94]:
			var screen := Vector2(viewport.x * nx, viewport.y * ny)
			var origin := cam.project_ray_origin(screen)
			var direction := cam.project_ray_normal(screen)
			var closest := INF
			var found := Vector3.ZERO
			var face := -1
			for i in range(0, indices.size(), 3):
				var a: Vector3 = body.global_transform * vertices[indices[i]]
				var b: Vector3 = body.global_transform * vertices[indices[i + 1]]
				var c: Vector3 = body.global_transform * vertices[indices[i + 2]]
				var hit: Variant = Geometry3D.ray_intersects_triangle(origin, direction, a, b, c)
				if hit == null:
					continue
				var distance := origin.distance_to(hit)
				if distance >= closest:
					continue
				closest = distance
				found = hit
				face = i / 3
			if face >= 0:
				print("PIX %.2f %.2f face=%d local=%s" % [nx, ny, face, body.to_local(found)])
	quit()
