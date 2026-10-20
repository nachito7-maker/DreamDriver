extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	var model: Node3D = race.car.model_root
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		print("MESH ", mesh.name, " AABB ", mesh.mesh.get_aabb())
		for s in mesh.mesh.get_surface_count():
			var mat := mesh.get_active_material(s)
			print(" SURFACE ",s," material=",mat.resource_name," albedo=",mat.albedo_color," albedo_tex=",mat.albedo_texture," normal=",mat.normal_texture," rough=",mat.roughness," metallic=",mat.metallic)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	doc.append_from_file("res://assets/RedBull.glb", state)
	var alt := doc.generate_scene(state)
	root.add_child(alt)
	for node in alt.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		print("ALT MESH ",mesh.name," AABB ",mesh.mesh.get_aabb()," surfaces=",mesh.mesh.get_surface_count())
	quit()
