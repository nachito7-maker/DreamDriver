extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	await process_frame
	race.set_camera_mode(1)
	for i in 45: await process_frame
	var body := race.car.model_root.find_child("Body", true, false) as MeshInstance3D
	if body:
		body.visible = false
		for i in 3: await process_frame
		root.get_texture().get_image().save_png("res://.tools/recovery/visual-20261017/helmet-iteration/wheels-without-body.png")
		body.visible = true
		for i in 3: await process_frame
		root.get_texture().get_image().save_png("res://.tools/recovery/visual-20261017/helmet-iteration/wheels-with-body.png")
	quit()
