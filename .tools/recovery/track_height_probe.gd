extends SceneTree
const TD = preload("res://scripts/track_data.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	TD.reset_selection()
	TD.set_user_selection(TD.SUZUKA, "rb22_2026")
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 120:
		await physics_frame
	var car: CharacterBody3D = race.car
	var line: PackedVector3Array = TD.get_centerline()
	print("HEIGHT spawn=", car.global_position, " line0=", line[0], " line1=", line[1], " spawn_api=", TD.get_spawn_position())
	for idx in [0, 100, 500, 1000, 1500, 2000, 2500, 3000, 3500]:
		var point: Vector3 = line[idx % line.size()]
		var world: Vector3 = point
		var query := PhysicsRayQueryParameters3D.create(world + Vector3.UP * 100.0, world - Vector3.UP * 100.0, 1)
		var hit: Dictionary = race.get_world_3d().direct_space_state.intersect_ray(query)
		print("CENTER idx=", idx, " line=", world, " hit=", hit.collider.name if not hit.is_empty() else "MISS", " y=", hit.position.y if not hit.is_empty() else NAN, " delta=", hit.position.y-world.y if not hit.is_empty() else NAN)
	var spawn_xz := Vector3(car.global_position.x, 0.0, car.global_position.z)
	var spawn_hit: Dictionary = race.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(spawn_xz + Vector3.UP * 100.0, spawn_xz - Vector3.UP * 100.0, 1))
	print("SPAWN_RAY hit=", spawn_hit.collider.name if not spawn_hit.is_empty() else "MISS", " pos=", spawn_hit.position if not spawn_hit.is_empty() else Vector3.ZERO)
	for body in race.track_mesh.find_children("*", "StaticBody3D", true, false):
		if body.name in ["1ROAD", "1PITLANE", "1KERB", "1WALL"]:
			print("BODY ", body.name, " layer=", body.collision_layer, " pos=", body.global_position, " childs=", body.get_child_count())
	var model: Node3D = car.model_root
	for node in model.find_children("*", "Node3D", true, false):
		var nm := String(node.name).to_lower()
		if "wheel" in nm or nm in ["susp_lf", "susp_rf", "susp_lr", "susp_rr"]:
			print("RB_NODE name=", node.name, " type=", node.get_class(), " pos=", node.position, " global=", node.global_position, " mesh=", (node as MeshInstance3D).mesh if node is MeshInstance3D else "")
	quit(0)
