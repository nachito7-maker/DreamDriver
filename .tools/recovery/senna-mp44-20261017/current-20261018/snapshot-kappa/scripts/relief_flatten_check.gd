extends SceneTree

# Cuánto cuesta aplanar el relieve invisible al arrancar: es trabajo que se hace
# una vez, en el primer fotograma de física, así que conviene saber lo que se le
# está añadiendo al arranque del juego (también en Android).
#
# Uso:  Godot --headless --path . --script res://scripts/relief_flatten_check.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var inicio := Time.get_ticks_msec()
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 5:
		await physics_frame
	print("FLATTEN arranque_total_ms=%d cuerpos_de_relieve=%d" % [
		Time.get_ticks_msec() - inicio, race.relief_bodies.size()])
	race.queue_free()
	await process_frame
	quit(0)
