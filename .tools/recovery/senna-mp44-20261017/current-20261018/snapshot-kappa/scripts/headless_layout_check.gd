extends SceneTree

# Comprobación corta: ¿el diseño de los controles de toque tiene medidas reales
# cuando Godot arranca sin ventana? Si las tiene, las sondas de conducción pueden
# usar el joystick analógico real en modo headless (mucho más rápido).

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 90:
		await physics_frame
	var ui = race.controls
	var size: Vector2 = ui._viewport_size
	print("LAYOUT viewport=%s centro=%s radio=%s pedales=%s" % [str(size), str(ui._steer_center),
		str(ui._steering_ring.size), str(ui._pedal_rects)])
	if size.x > 0.0:
		ui._handle_touch_down(10, ui._steer_center + Vector2(ui._steering_ring.size.x * 0.23, 0.0))
		ui._handle_touch_down(11, Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5, ui._pedal_rects["throttle"].position.y + 2.0))
		ui._process(1.0 / 120.0)
		print("LAYOUT direccion_a_medio_recorrido=%.4f acelerador=%.4f" % [ui._steer_value, ui._throttle_value])
	race.queue_free()
	await process_frame
	quit(0)
