extends SceneTree

# Curvatura de la trazada: grados de giro por metro en cada índice. Sirve para
# distinguir una curva real de una irregularidad de la línea de IA (por ejemplo
# en la línea de meta, donde la variante de motos quitó la chicane final).

const TrackScript = preload("res://scripts/track_data.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var line := TrackScript.get_centerline()
	var count := line.size()
	var turn := PackedFloat32Array()
	turn.resize(count)
	for i in count:
		var previous := line[(i - 1 + count) % count]
		var current := line[i]
		var following := line[(i + 1) % count]
		var a := (current - previous).normalized()
		var b := (following - current).normalized()
		var length := current.distance_to(following)
		turn[i] = rad_to_deg(acos(clampf(a.dot(b), -1.0, 1.0))) / maxf(length, 0.001)
	var ordered: Array = []
	for i in count:
		ordered.append([i, turn[i]])
	ordered.sort_custom(func(x, y): return float(x[1]) > float(y[1]))
	print("CURVATURA puntos=%d | giro medio=%.2f °/m" % [count, _mean(turn)])
	for entry in ordered.slice(0, 12):
		print("CURVATURA índice=%d giro=%.2f °/m punto=%s" % [entry[0], entry[1], str(line[entry[0]].snapped(Vector3(0.1, 0.1, 0.1)))])
	# La línea de meta es el índice 0: ¿hay ahí un codo artificial?
	for i in range(count - 6, count):
		print("CURVATURA meta_antes índice=%d giro=%.2f °/m" % [i, turn[i]])
	for i in range(0, 7):
		print("CURVATURA meta_despues índice=%d giro=%.2f °/m" % [i, turn[i]])
	# Longitud del salto entre el último punto y el primero.
	print("CURVATURA cierre distancia=%.2f m (media=%.2f m)" % [line[count - 1].distance_to(line[0]), _mean_length(line)])
	quit(0)

func _mean(values: PackedFloat32Array) -> float:
	var total := 0.0
	for value in values:
		total += value
	return total / maxf(1.0, values.size())

func _mean_length(line: PackedVector3Array) -> float:
	var total := 0.0
	for i in line.size():
		total += line[i].distance_to(line[(i + 1) % line.size()])
	return total / maxf(1.0, line.size())
