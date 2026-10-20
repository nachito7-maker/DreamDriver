extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var packed := load("res://scenes/race.tscn") as PackedScene
	var race := packed.instantiate()
	root.add_child(race)
	await process_frame
	await process_frame
	race.set_camera_mode(1)
	for i in 45:
		await process_frame
	var image := root.get_texture().get_image()
	image.save_png("res://.tools/recovery/visual-20261017/helmet-iteration/helmet-nose.png")
	var body := race.car.model_root.find_child("Body", true, false) as MeshInstance3D
	body.visible = false
	await process_frame
	var wheels_only := root.get_texture().get_image()
	wheels_only.save_png("res://.tools/recovery/visual-20261017/helmet-iteration/wheels-only-nose.png")
	for node in race.car.model_root.find_children("*", "MeshInstance3D", true, false):
		var wheel := node as MeshInstance3D
		if not String(wheel.name).to_lower().contains("wheel"):
			continue
		for surface in wheel.mesh.get_surface_count():
			var diagnostic := StandardMaterial3D.new()
			diagnostic.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			diagnostic.albedo_color = Color(0.9, 0.05, 0.05) if surface == 0 else Color(0.05, 0.2, 0.95)
			wheel.set_surface_override_material(surface, diagnostic)
	await process_frame
	await process_frame
	var split := root.get_texture().get_image()
	split.save_png("res://.tools/recovery/visual-20261017/helmet-iteration/wheels-surfaces-nose.png")
	quit()
