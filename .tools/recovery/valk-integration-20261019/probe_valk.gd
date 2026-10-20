extends SceneTree

const MODEL := "res://assets/Valkyrie-LMHypercar.glb"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := load(MODEL) as PackedScene
	if scene == null:
		push_error("No se pudo cargar " + MODEL)
		quit(1)
		return
	var root := scene.instantiate() as Node3D
	get_root().add_child(root)
	await process_frame
	print("[valk] root=", root.name, " children=", root.get_child_count())
	var meshes: Array[MeshInstance3D] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node as MeshInstance3D)
	var aabb := AABB()
	var first := true
	var tris := 0
	for mesh in meshes:
		if mesh.mesh == null:
			continue
		var box: AABB = mesh.global_transform * mesh.mesh.get_aabb()
		aabb = box if first else aabb.merge(box)
		first = false
		for s in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(s)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.size() > 0:
				tris += indices.size() / 3
			else:
				var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				tris += verts.size() / 3
	print("[valk] meshes=", meshes.size(), " triangles=", tris)
	print("[valk] bounds position=", aabb.position, " size=", aabb.size)
	for wheel_name in ["wheel_fl", "wheel_fr", "wheel_rl", "wheel_rr", "wheel_lf", "wheel_rf", "wheel_lr", "wheel_rr"]:
		var found := root.find_children(wheel_name, "", true, false)
		if not found.is_empty():
			for node in found:
				var n3 := node as Node3D
				print("[valk] wheel-name ", wheel_name, " -> ", node.name, " (", node.get_class(), ") global=", n3.global_position if n3 != null else "n/a")
	print("[valk] --- nodos con 'wheel' en el nombre ---")
	for node in root.find_children("*", "", true, false):
		if "wheel" in String(node.name).to_lower():
			var n3 := node as Node3D
			var extra := ""
			if n3 is MeshInstance3D:
				var m := n3 as MeshInstance3D
				extra = " aabb=" + str(m.mesh.get_aabb()) if m.mesh != null else ""
			print("[valk] ", node.get_path(), " (", node.get_class(), ") pos=", n3.position if n3 != null else "n/a", extra)
	print("[valk] --- hijos directos ---")
	for child in root.get_children():
		print("[valk] direct ", child.name, " (", child.get_class(), ")")
	print("[valk] --- materiales ---")
	var seen := {}
	for mesh in meshes:
		for s in mesh.mesh.get_surface_count() if mesh.mesh != null else 0:
			var mat := mesh.get_active_material(s)
			if mat == null:
				continue
			var key := String(mat.resource_name) + "|" + mat.resource_path
			if not seen.has(key):
				seen[key] = true
				var st := mat as StandardMaterial3D
				var tex := ""
				if st != null and st.albedo_texture != null:
					tex = st.albedo_texture.resource_path
				print("[valk] mat ", mat.resource_name, " path=", mat.resource_path, " albedo=", tex)
	quit()
