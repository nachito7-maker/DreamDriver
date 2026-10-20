extends SceneTree

const HudScript = preload("res://scripts/race_hud.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var hud := CanvasLayer.new()
	hud.set_script(HudScript)
	root.add_child(hud)
	await process_frame
	hud._on_pause_pressed()
	await process_frame
	var menu_button: Button = hud.get_node("Telemetry layout/Main menu")
	var overlay: ColorRect = hud.get_node("Telemetry layout/Pause overlay")
	var pause_menu: Control = overlay.get_node("Pause menu")
	var pause_buttons: Array[String] = []
	for child in pause_menu.get_children():
		if child is Button:
			pause_buttons.append((child as Button).text)
	var pause_menu_button := pause_menu.get_node_or_null("Pause main menu") as Button
	var passed := overlay.visible and pause_menu_button != null and pause_menu_button.visible and pause_menu_button.text == "MENÚ PRINCIPAL" and pause_menu_button.position.y > 0.0 and pause_menu_button.position.y + pause_menu_button.size.y <= pause_menu.size.y and pause_buttons.size() == 3
	print("PAUSE_MENU visible=", overlay.visible, " overlay_mouse_filter=", overlay.mouse_filter,
		" main_menu_parent=", menu_button.get_parent().name, " main_menu_under_overlay=", menu_button.get_index() < overlay.get_index(),
		" pause_buttons=", pause_buttons, " pause_menu_main_button_visible=", pause_menu_button != null and pause_menu_button.visible,
		" panel_size=", pause_menu.size, " passed=", passed)
	hud.queue_free()
	await process_frame
	quit(0 if passed else 1)
