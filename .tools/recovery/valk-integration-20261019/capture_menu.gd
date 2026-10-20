extends SceneTree

# Captura el menú principal con el LM Hypercar Valkyrie seleccionado, tanto la
# ventana completa como el recuadro 3D del coche.
# Uso: Godot --path . --script .tools/recovery/valk-integration-20261019/capture_menu.gd

const OUT := "res://.tools/recovery/valk-integration-20261019"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	for i in 30:
		await process_frame
	var button := menu.find_child("Vehicle valkyrie", true, false) as Button
	print("boton_valkyrie=", button != null)
	if button != null:
		button.emit_signal("pressed")
	for i in 180:
		await process_frame
	await RenderingServer.frame_post_draw
	var viewport: SubViewport = menu._vehicle_viewport
	var preview: Image = viewport.get_texture().get_image()
	print("recuadro %dx%d -> %s" % [preview.get_width(), preview.get_height(),
		preview.save_png(OUT + "/menu-valkyrie-coche.png")])
	await RenderingServer.frame_post_draw
	var full: Image = root.get_texture().get_image()
	print("ventana %dx%d -> %s" % [full.get_width(), full.get_height(),
		full.save_png(OUT + "/menu-valkyrie.png")])
	quit()
