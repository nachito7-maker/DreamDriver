extends SceneTree

const OUTPUT := "res://.tools/recovery/cockpit-black-20261018"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 240:
		await process_frame
	race.set_camera_mode(1)
	for i in 45:
		await process_frame
	var details: Node = race.nose_camera.get_node_or_null("Onboard cockpit details")
	var bar: MeshInstance3D = details.get_node_or_null("Halo front crossbar") as MeshInstance3D if details != null else null
	print("SUSPECT_PATH=", bar.get_path() if bar else "ABSENT_AFTER_FIX")
	if bar != null:
		var material := bar.material_override as StandardMaterial3D
		print("SUSPECT_TYPE=", bar.get_class(), " mesh=", bar.mesh.get_class(), " size=", (bar.mesh as BoxMesh).size,
			" local_pos=", bar.position, " layer=", bar.layers, " albedo=", material.albedo_color if material else Color.TRANSPARENT)
	var nose := root.get_texture().get_image()
	print("NOSE_SAVE=", nose.save_png(OUTPUT + "/after/morro-sin-barra.png"))
	if bar != null:
		bar.visible = false
		for i in 4:
			await process_frame
		RenderingServer.force_draw(true)
		var no_bar := root.get_texture().get_image()
		print("NOSE_ISOLATION_SAVE=", no_bar.save_png(OUTPUT + "/after/morro-isolated-no-barra.png"))
		print("NOSE_IDENTICAL=", nose.get_data() == no_bar.get_data())
	race.set_camera_mode(0)
	for i in 45:
		await process_frame
	var chase := root.get_texture().get_image()
	print("EXTERIOR_SAVE=", chase.save_png(OUTPUT + "/after/exterior-sin-barra.png"))
	print("PRODUCTION_HAS_SUSPECT=", race.nose_camera.find_child("Halo front crossbar", true, false) != null)
	quit()

func _different_pixels(a: Image, b: Image) -> int:
	if a.get_size() != b.get_size():
		return -1
	var count := 0
	for y in range(0, a.get_height(), 4):
		for x in range(0, a.get_width(), 4):
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				count += 1
	return count
