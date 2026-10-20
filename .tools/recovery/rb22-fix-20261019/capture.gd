extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 180: await physics_frame
	race.controls.set_process(false)
	race.set_process(false)
	race.car.set_physics_process(false)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.cull_mask = 1
	camera.fov = 48
	camera.position = race.car.to_global(Vector3(4, 1.5, -5))
	camera.look_at(race.car.to_global(Vector3(0, 0.3, -0.2)))
	camera.make_current()
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://.tools/recovery/rb22-fix-20261019/rb22-contact.png")
	print("CAPTURE error=", error)
	race.queue_free()
	camera.queue_free()
	await process_frame
	quit(0 if error == OK else 1)
