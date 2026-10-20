extends SceneTree

# ============================================================================
# Etiqueta de los casos de captura por la GEOMETRÍA y la VELOCIDAD IDEAL.
#
# Los cuatro casos de `.tools/recovery/linea/capturar.gd` se eligen por el patrón de la
# recomendación (verde/amarillo/rojo) a una velocidad de referencia de 300 km/h, no por el
# tipo de curva. Para poder decir con números qué situación del encargo cubre cada uno
# —"curva lenta", "curva rápida"— esta sonda imprime, en el índice exacto de cada caso:
#
#   * el radio de la trazada (circunradio de tres puntos separados ±2 anillos),
#   * la velocidad ideal de la línea en ese punto,
#   * el mínimo de la velocidad ideal en los 260 m visibles por delante (lo que el
#     conductor vería venir) y con él una etiqueta: lenta < 120, media < 200, rápida.
#
# Uso:
#   "$GODOT" --headless --path . --script .tools/recovery/linea-visual/curvatura_casos.gd
# ============================================================================

const TrackScript = preload("res://scripts/track_data.gd")
const LineScript = preload("res://scripts/driving_line.gd")

const CASOS := {"recta": 0, "aproximacion": 310, "frenada": 420, "salida": 2910}
const VENTANA_M := 260.0
const LENTA_KPH := 120.0
const MEDIA_KPH := 200.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var points := TrackScript.get_centerline()
	var linea := MeshInstance3D.new()
	linea.set_script(LineScript)
	linea.construir(points)
	var count := points.size()
	print("CURVA casos=%d puntos=%d referencia=300 km/h ventana=%.0f m" % [CASOS.size(), count, VENTANA_M])
	for id in CASOS:
		var i: int = CASOS[id]
		var radio := _radio(points, i)
		var ideal := float(linea.speed_ideal[i]) * 3.6
		var minimo := ideal
		var ds := 0.0
		while ds <= VENTANA_M:
			var j := _indice_de_arco(linea.arc, float(linea.arc[i]) + ds, count)
			minimo = minf(minimo, float(linea.speed_ideal[j]) * 3.6)
			ds += 5.0
		var tipo := "lenta" if minimo < LENTA_KPH else ("media" if minimo < MEDIA_KPH else "rápida")
		print("CURVA caso=%-13s indice=%-5d radio=%7.1f m ideal=%5.0f km/h ideal_min_ventana=%5.0f km/h tipo=%s"
			% [id, i, radio, ideal, minimo, tipo])
	quit()

func _radio(points: PackedVector3Array, i: int) -> float:
	var count := points.size()
	var a := points[(i - 2 + count) % count]
	var b := points[i]
	var c := points[(i + 2) % count]
	var ab := (b - a).length()
	var bc := (c - b).length()
	var ca := (a - c).length()
	var area := 0.5 * (b - a).cross(c - a).length()
	if area < 0.0001:
		return INF
	return (ab * bc * ca) / (4.0 * area)

func _indice_de_arco(arc: PackedFloat32Array, s: float, count: int) -> int:
	var low := 0
	var high := count - 1
	var objetivo := fposmod(s, arc[count - 1])
	while low < high:
		var mid := int((low + high + 1) / 2)
		if arc[mid] <= objetivo:
			low = mid
		else:
			high = mid - 1
	return low
