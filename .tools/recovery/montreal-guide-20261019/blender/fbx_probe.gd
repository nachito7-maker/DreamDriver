extends SceneTree

func _initialize() -> void:
	var packed := load("res://montreal-guide.fbx") as PackedScene
	if packed == null:
		push_error("FBX importer did not return a PackedScene")
		quit(2)
		return
	var scene := packed.instantiate()
	var meshes := scene.find_children("*", "MeshInstance3D", true, false)
	var bodies := scene.find_children("*", "StaticBody3D", true, false)
	print("FBX_IMPORTED root=", scene.name, " meshes=", meshes.size(), " bodies=", bodies.size())
	for node in scene.get_children():
		print("FBX_ROOT_CHILD type=", node.get_class(), " name=", node.name)
	for body in bodies:
		var shapes := 0
		for child in body.get_children():
			if child is CollisionShape3D and child.shape != null:
				shapes += 1
		print("FBX_BODY name=", body.name, " shapes=", shapes)
	if meshes.size() < 800:
		push_error("Imported FBX mesh count is unexpectedly low")
		quit(3)
		return
	quit(0)
