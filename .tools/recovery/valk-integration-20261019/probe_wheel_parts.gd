extends SceneTree

const MODEL := "res://assets/Valkyrie-LMHypercar.glb"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := load(MODEL) as PackedScene
	var root := scene.instantiate() as Node3D
	get_root().add_child(root)
	await process_frame
	print("[root] basis=", root.global_basis, " origin=", root.global_position)
	var hub := root.find_child("HUB_LF", true, false) as Node3D
	print("[hub] basis=", hub.global_basis)
	for child in hub.find_children("*", "", true, false):
		print("[hub-child] ", child.get_path(), " (", child.get_class(), ")")
	var wheel := root.find_child("WHEEL_LF", true, false) as Node3D
	print("[wheel] basis=", wheel.global_basis)
	for child in wheel.find_children("*", "", true, false):
		var mi := child as MeshInstance3D
		print("[wheel-child] ", child.get_path(), " (", child.get_class(), ") aabb=", (mi.global_transform * mi.mesh.get_aabb()) if mi != null and mi.mesh != null else "n/a")
	for wanted in ["STEER", "COCKPIT", "DRIVER", "BODY", "BODY_LF", "BODY_RF"]:
		for node in root.find_children(wanted, "", true, false):
			print("[part] ", node.get_path(), " (", node.get_class(), ")")
	quit()
