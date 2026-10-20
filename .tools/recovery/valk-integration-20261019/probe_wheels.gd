extends SceneTree

const MODEL := "res://assets/Valkyrie-LMHypercar.glb"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := load(MODEL) as PackedScene
	var root := scene.instantiate() as Node3D
	get_root().add_child(root)
	await process_frame
	for name in ["WHEEL_LF", "WHEEL_RF", "WHEEL_LR", "WHEEL_RR"]:
		var wheels := root.find_children(name, "", true, false)
		if wheels.is_empty():
			print("[wheel] MISSING ", name)
			continue
		var w := wheels[0] as Node3D
		var box := AABB()
		var first := true
		var meshes := 0
		for node in w.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			if mi.mesh == null:
				continue
			meshes += 1
			var b: AABB = mi.global_transform * mi.mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		print("[wheel] %s global=%s parent=%s meshes=%d aabb_pos=%s aabb_size=%s" % [
			name, str(w.global_position), str(w.get_parent().name), meshes, str(box.position), str(box.size)])
	for name in ["HUB_LF", "HUB_RF", "HUB_LR", "HUB_RR", "SUSP_LF", "SUSP_RF", "SUSP_LR", "SUSP_RR", "BODY", "COCKPIT", "STEER", "DRIVER"]:
		var found := root.find_children(name, "", true, false)
		if found.is_empty():
			continue
		for node in found:
			var n3 := node as Node3D
			print("[node] %s path=%s global=%s" % [name, str(node.get_path()), str(n3.global_position) if n3 != null else "n/a"])
	var body := root.find_children("BODY", "MeshInstance3D", true, false)
	for node in body.slice(0, 3):
		var mi := node as MeshInstance3D
		print("[body] %s global=%s aabb=%s" % [str(mi.get_path()), str(mi.global_position), str(mi.global_transform * mi.mesh.get_aabb())])
	print("[root] transform=", root.transform)
	quit()
