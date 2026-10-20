extends SceneTree
func _initialize():
	var scene = load("res://assets/BarcelonaMoto-Tutorial.glb").instantiate()
	root.add_child(scene)
	print("IMPORTED SCENE children=",scene.get_child_count())
	for node in scene.get_children():
		print(node.name," type=",node.get_class()," meta=",node.get_meta_list(), " transform=",node.transform)
		for c in node.get_children():
			print("  ",c.name," type=",c.get_class()," meta=",c.get_meta_list())
	quit()
