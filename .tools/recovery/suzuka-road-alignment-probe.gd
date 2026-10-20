extends SceneTree
const TD = preload("res://scripts/track_data.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	TD.reset_selection()
	TD.select_track(TD.SUZUKA)
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 10:
		await physics_frame
	var track: Node3D = race.track_mesh
	var line := TD.get_centerline()
	var idx := 1300
	var p := line[idx]
	print("ALIGN line=", p, " track_transform=", track.global_transform, " race_children=", race.get_children().map(func(n): return n.name))
	for node in track.find_children("*", "StaticBody3D", true, false):
		var body := node as StaticBody3D
		if body.name.to_upper().contains("ROAD"):
			print("ROAD body=", body.name, " layer=", body.collision_layer, " transform=", body.global_transform, " childinfo=", body.get_children().map(func(n): return [n.name, n.get_class(), (n as CollisionShape3D).shape.get_class() if n is CollisionShape3D and n.shape else "", (n as CollisionShape3D).shape.get_faces().size() if n is CollisionShape3D and n.shape is ConcavePolygonShape3D else 0]))
	var candidates := [p, track.global_transform * p, Vector3(-p.x,p.y,-p.z), track.global_transform * Vector3(-p.x,p.y,-p.z)]
	for j in candidates.size():
		var q: Vector3 = candidates[j]
		for layer in [1, 2, 3]:
			var ray := PhysicsRayQueryParameters3D.create(q + Vector3.UP * 100.0, q - Vector3.UP * 100.0, 1 << (layer - 1))
			var hit: Dictionary = race.get_world_3d().direct_space_state.intersect_ray(ray)
			print("RAY j=",j," layer=",layer," at=",q," hit=",hit.is_empty() if hit.is_empty() else [hit.position, hit.collider.name, hit.normal])
	for lane_index in range(idx - 2, idx + 3):
		var point: Vector3 = line[lane_index]
		var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 100.0, point - Vector3.UP * 100.0, 1)
		var hit: Dictionary = race.get_world_3d().direct_space_state.intersect_ray(query)
		print("LANE index=", lane_index, " xyz=", point, " hit=", hit.is_empty() if hit.is_empty() else [hit.position, hit.collider.name])
	race.queue_free()
	await process_frame
	quit()
