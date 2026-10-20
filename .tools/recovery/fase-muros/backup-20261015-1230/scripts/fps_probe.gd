extends SceneTree

# Mide fotogramas por segundo reales de la escena de carrera en la GPU del
# host. Es la unica medida de rendimiento util como referencia de juego: el
# emulador disponible usa traduccion OpenGL es->Metal y esta saturado de CPU,
# asi que su cifra no representa a un telefono.

const WARMUP := 180
const SAMPLES := 600

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	for i in WARMUP:
		await process_frame
	var start := Time.get_ticks_usec()
	for i in SAMPLES:
		await process_frame
	var elapsed := float(Time.get_ticks_usec() - start) / 1000000.0
	var fps := float(SAMPLES) / elapsed
	print("FPS host fps=%.1f frames=%d tiempo=%.3fs viewport=%s" % [fps, SAMPLES, elapsed, root.get_visible_rect().size])
	race.queue_free()
	await process_frame
	quit(0 if fps > 30.0 else 1)
