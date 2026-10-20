extends SceneTree

# Renderiza la escena de carrera real en el host (no headless), guarda un PNG y
# mide el color del asfalto. El tinte azul de las capturas anteriores no venia
# del traductor OpenGL del emulador: aparece igual en la GPU nativa del host, asi
# que se mide aqui de forma objetiva: el asfalto de AC es de albedo neutro
# (asph_updt (80,80,80), road-concrete-ext (100,96,90)) y debe salir gris.

const BANDS := {
	"izquierda": Rect2(0.35, 0.70, 0.07, 0.15),
	"derecha": Rect2(0.58, 0.70, 0.07, 0.15),
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 120:
		await process_frame
	var image: Image = root.get_texture().get_image()
	var path := "res://.tools/recovery/host-render.png"
	var error := image.save_png(path)
	print("RENDER saved=", error == OK, " path=", path, " size=", image.get_width(), "x", image.get_height())
	var worst := 0.0
	for band in BANDS:
		var stats := _measure(image, BANDS[band])
		worst = maxf(worst, float(stats["spread"]))
		print("ASFALTO %s=%.1f%% medio=(%s) recorte=%d%%" % [band, float(stats["spread"]) * 100.0, stats["mean"], roundi(float(stats["clipped"]) * 100.0)])
	var neutral: bool = worst < 0.08
	print("RENDER asfalto_neutro=", neutral, " peor_desviacion=%.1f%%" % (worst * 100.0))
	race.queue_free()
	await process_frame
	quit(0 if error == OK and neutral else 1)

func _measure(image: Image, band: Rect2) -> Dictionary:
	# Devuelve la fraccion de pixeles casi saturados, la desviacion de tono y el
	# color medio legible de la banda de asfalto.
	var x0 := int(image.get_width() * band.position.x)
	var y0 := int(image.get_height() * band.position.y)
	var w := int(image.get_width() * band.size.x)
	var h := int(image.get_height() * band.size.y)
	var r := 0.0
	var g := 0.0
	var b := 0.0
	var n := 0
	var clipped := 0
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			var c := image.get_pixel(x, y)
			r += c.r
			g += c.g
			b += c.b
			n += 1
			if maxf(c.r, maxf(c.g, c.b)) > 0.995 and minf(c.r, minf(c.g, c.b)) < 0.85:
				clipped += 1
	r /= n
	g /= n
	b /= n
	var top := maxf(r, maxf(g, b))
	return {
		"clipped": float(clipped) / float(n),
		"spread": (top - minf(r, minf(g, b))) / maxf(top, 0.0001),
		"mean": "%d,%d,%d" % [roundi(r * 255.0), roundi(g * 255.0), roundi(b * 255.0)],
	}
