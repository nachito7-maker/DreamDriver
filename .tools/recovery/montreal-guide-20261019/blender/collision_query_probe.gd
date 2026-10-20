extends SceneTree

const TrackScript = preload("res://scripts/track_data.gd")

func _initialize() -> void:
	var packed := load("res://montreal-guide.fbx") as PackedScene
	var root_node := packed.instantiate()
	root.add_child(root_node)
	var point := Vector3(79.66756, -2.056788, 407.07095)
	for body in root_node.find_children("*", "StaticBody3D", true, false):
		var b := body as StaticBody3D
		if not b.name in ["Asphalt", "Kerbs", "Grass", "Runoff", "Barriers", "Fences"]: continue
		var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 100.0, point - Vector3.UP * 100.0, 1)
		query.collide_with_areas = false
		query.exclude = []
		var result := get_root().get_world_3d().direct_space_state.intersect_ray(query) if get_root().get_world_3d() else {}
		print("BODYQUERY name=", b.name, " layer=", b.collision_layer, " direct=", result.get("collider", null).name if result.get("collider") else "none")
	quit()
