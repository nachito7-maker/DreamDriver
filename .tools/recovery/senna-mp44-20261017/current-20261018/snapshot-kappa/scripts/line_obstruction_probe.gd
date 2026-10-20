extends SceneTree

# Barrido de la TRAZADA contra obstáculos que no son suelo.
#
# Qué responde: circulando por el asfalto, ¿hay algún cuerpo de física delante del
# coche que no sea la propia carretera? Un muro real a los lados no aparece aquí
# —está fuera de la anchura de la vía—, pero cualquier barrera, caja o malla de
# física que cruce la calzada sale en la primera estación donde se cruza.
#
# Se barren las estaciones de la línea de IA metro a metro y, en cada una, varios
# carriles laterales y varias alturas: es lo que hace falta para no dejar pasar
# un obstáculo por caer entre dos muestras. Cada cuerpo que bloquea se informa con
# su nombre, su grupo, sus metadatos de origen y si su malla se dibuja o no, que
# es la diferencia entre un muro y una barrera invisible.
#
# Uso:  Godot --headless --path . --script res://scripts/line_obstruction_probe.gd

const TrackScript = preload("res://scripts/track_data.gd")

const STATION_STEP := 1                  # 1.51 m de media: la vía entera, sin huecos
const LANES := [-7.0, -5.0, -3.0, -1.5, 0.0, 1.5, 3.0, 5.0, 7.0]
# Alturas sobre el suelo local a las que se busca el obstáculo. La más baja (0.15)
# es la que ve el morro; las altas cazan vigas, paneles y cajas que cuelgan.
const HEIGHTS := [0.15, 0.35, 0.8, 1.5, 2.5]
const AHEAD := 5.0                       # m que mira el rayo delante de cada muestra
const GROUND := ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "GRAVEL", "SAND",
	"GRASS", "GREEN", "OUT", "CONCRETE", "PITS", "CARPET", "GRILL"]

var failures := 0
var space: PhysicsDirectSpaceState3D
var line: PackedVector3Array

func check(condition: bool, message: String) -> void:
	print("TRAZADA ", "PASS " if condition else "FAIL ", message)
	if not condition:
		failures += 1

func info(message: String) -> void:
	print("TRAZADA INFO ", message)

func _initialize() -> void:
	call_deferred("_run")

func _group_of(body: Node) -> String:
	if body == null:
		return "NONE"
	var label := (String(body.name) + " " + String(body.get_meta("ac_surface", ""))
		+ " " + String(body.get_meta("ac_source", ""))).to_upper()
	for key in (GROUND + ["WALL", "BARRIER", "RAIL", "FENCE", "BUMP", "MARBLES", "CNCPTS", "TRAV"]):
		if key in label:
			return key
	return "OTHER"

func _drawn(body: Node) -> bool:
	"""¿Se dibuja el cuerpo que bloquea? Si no, el obstáculo es invisible.

	Los cuerpos creados por `race.gd` para las mallas de física de AC son hijos de
	la malla, que se oculta (`visible = false`) precisamente porque la física de
	AC no se dibuja. Un cuerpo del propio glTF puede estar visible o no.
	"""
	var mesh := body.get_parent() as MeshInstance3D
	if mesh == null:
		return true
	return mesh.visible

func _ground(point: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 6.0, point - Vector3.UP * 8.0, 1)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return {"height": INF, "group": "NONE"}
	return {"height": float(hit.position.y), "group": _group_of(hit.collider as Node)}

func _ahead(origin: Vector3, direction: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * AHEAD, 1)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return {"grupo": "NONE"}
	var body := hit.collider as Node
	var normal: Vector3 = hit.normal
	return {
		"grupo": _group_of(body),
		"cuerpo": String(body.name),
		"capa": body.collision_layer,
		"superficie": String(body.get_meta("ac_surface", "")),
		"origen": String(body.get_meta("ac_source", "")),
		"dibujado": _drawn(body),
		"distancia": origin.distance_to(hit.position),
		"vertical": absf(normal.y) < 0.7,
		"normal_y": normal.y,
		"punto": hit.position,
	}

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	await physics_frame
	space = race.get_world_3d().direct_space_state
	line = TrackScript.get_centerline()
	Engine.max_fps = 0

	var muestras := 0
	var suelo := 0
	var bloqueos: Array = []
	var por_cuerpo := {}
	var sin_suelo := 0
	for i in range(0, line.size(), STATION_STEP):
		var anterior := line[(i - 3 + line.size()) % line.size()]
		var siguiente := line[(i + 3) % line.size()]
		var tangent := (siguiente - anterior).normalized()
		var lateral := Vector3(tangent.z, 0.0, -tangent.x).normalized()
		var centro := _ground(line[i])
		if float(centro["height"]) == INF:
			sin_suelo += 1
			continue
		for carril in LANES:
			var punto: Vector3 = line[i] + lateral * carril
			var suelo_carril := _ground(punto)
			if float(suelo_carril["height"]) == INF:
				continue
			for altura in HEIGHTS:
				muestras += 1
				var origen := Vector3(punto.x, float(suelo_carril["height"]) + float(altura), punto.z)
				var delante := _ahead(origen, tangent)
				if String(delante["grupo"]) == "NONE":
					continue
				if GROUND.has(String(delante["grupo"])):
					# La propia carretera: el rayo roza el asfalto en un badén.
					suelo += 1
					continue
				if not bool(delante["vertical"]):
					# Superficie horizontal por encima del suelo: un escalón.
					if float(altura) < 0.3:
						continue
				bloqueos.append({
					"i": i, "carril": carril, "altura": altura,
					"grupo": delante["grupo"], "cuerpo": delante["cuerpo"],
					"capa": delante["capa"], "superficie": delante["superficie"],
					"origen": delante["origen"], "dibujado": delante["dibujado"],
					"distancia": delante["distancia"], "punto": delante["punto"],
				})
				var clave := "%s|%s|%s" % [delante["cuerpo"], delante["grupo"], delante["origen"]]
				if not por_cuerpo.has(clave):
					por_cuerpo[clave] = {"n": 0, "min": i, "max": i, "carriles": [],
						"alturas": [], "dibujado": delante["dibujado"]}
				var registro: Dictionary = por_cuerpo[clave]
				registro["n"] = int(registro["n"]) + 1
				registro["min"] = mini(int(registro["min"]), i)
				registro["max"] = maxi(int(registro["max"]), i)
				if not registro["carriles"].has(carril):
					registro["carriles"].append(carril)
				if not registro["alturas"].has(altura):
					registro["alturas"].append(altura)

	info("estaciones=%d carriles=%d alturas=%d muestras=%d suelo=%d bloqueos=%d sin_suelo=%d" % [
		line.size(), LANES.size(), HEIGHTS.size(), muestras, suelo, bloqueos.size(), sin_suelo])
	info("cuerpos distintos que cruzan la trazada: %d" % por_cuerpo.size())
	var claves: Array = por_cuerpo.keys()
	claves.sort()
	for clave in claves:
		var registro: Dictionary = por_cuerpo[clave]
		print("TRAZADA BLOQUEO cuerpo=%s estaciones=%d..%d muestras=%d carriles=%s alturas=%s dibujado=%s" % [
			clave, int(registro["min"]), int(registro["max"]), int(registro["n"]),
			str(registro["carriles"]), str(registro["alturas"]), str(registro["dibujado"])])
	# Los diez primeros puntos exactos, con coordenada, para poder ir a verlos.
	for entrada in bloqueos.slice(0, 10):
		print("TRAZADA PUNTO idx=%d carril=%+.1f altura=%.2f grupo=%s cuerpo=%s punto=%s" % [
			int(entrada["i"]), float(entrada["carril"]), float(entrada["altura"]),
			String(entrada["grupo"]), String(entrada["cuerpo"]), str(entrada["punto"])])

	var invisibles := bloqueos.filter(func(e): return not bool(e["dibujado"]))
	check(bloqueos.is_empty(),
		"ningún cuerpo que no sea suelo cruza la trazada (%d muestras bloqueadas)" % bloqueos.size())
	if not invisibles.is_empty():
		info("de esos bloqueos, %d son de mallas de física que no se dibujan" % invisibles.size())
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
