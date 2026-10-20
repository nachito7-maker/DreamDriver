extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	await process_frame
	race.set_camera_mode(1)
	for i in 45: await process_frame
	var cam: Camera3D = race.nose_camera
	var body := race.car.model_root.find_child("Body", true, false) as MeshInstance3D
	var arrays := body.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var size := root.get_viewport().get_visible_rect().size
	print("VIEWPORT ",size)
	var tests: Array[Vector2] = []
	for nx in [0.44,0.47,0.50,0.53,0.56]:
		for ny in [0.72,0.78,0.84,0.90,0.96]:
			tests.append(Vector2(size.x*nx,size.y*ny))
	for screen in tests:
		var origin := cam.project_ray_origin(screen)
		var direction := cam.project_ray_normal(screen)
		var closest := INF
		var found_uv := Vector2.ZERO
		var found_pos := Vector3.ZERO
		var found_face := -1
		for i in range(0, indices.size(), 3):
			var ia: int = indices[i]
			var ib: int = indices[i+1]
			var ic: int = indices[i+2]
			var a := body.global_transform * verts[ia]
			var b := body.global_transform * verts[ib]
			var c := body.global_transform * verts[ic]
			var hit: Variant = Geometry3D.ray_intersects_triangle(origin, direction, a, b, c)
			if hit == null: continue
			var dist := origin.distance_to(hit)
			if dist >= closest: continue
			closest = dist
			found_pos = hit
			found_face = i / 3
			var v0 := b-a
			var v1 := c-a
			var v2: Vector3 = hit-a
			var d00 := v0.dot(v0); var d01 := v0.dot(v1); var d11 := v1.dot(v1)
			var d20 := v2.dot(v0); var d21 := v2.dot(v1)
			var denom := d00*d11-d01*d01
			var vb := (d11*d20-d01*d21)/denom
			var vc := (d00*d21-d01*d20)/denom
			var va := 1.0-vb-vc
			found_uv = uvs[ia]*va + uvs[ib]*vb + uvs[ic]*vc
		print("SCREEN ",screen," hit=",closest," local=",body.to_local(found_pos)," face=",found_face," uv=",found_uv)
	var adjacency := {}
	for face in range(indices.size() / 3):
		for corner in 3:
			var vertex_index: int = indices[face * 3 + corner]
			if not adjacency.has(vertex_index): adjacency[vertex_index] = []
			adjacency[vertex_index].append(face)
	for seed in [55253, 57665]:
		var visited := {}
		var stack: Array[int] = [seed]
		while not stack.is_empty() and visited.size() < 500000:
			var face: int = stack.pop_back()
			if visited.has(face): continue
			visited[face] = true
			for corner in 3:
				var vertex_index: int = indices[face * 3 + corner]
				for neighbor in adjacency[vertex_index]:
					if not visited.has(neighbor): stack.append(neighbor)
		var low := Vector3(INF,INF,INF); var high := Vector3(-INF,-INF,-INF)
		for face in visited:
			for corner in 3:
				var point: Vector3 = verts[indices[int(face) * 3 + corner]]
				low = low.min(point); high = high.max(point)
		print("COMPONENT seed=",seed," faces=",visited.size()," bounds=",low," .. ",high)
	quit()
