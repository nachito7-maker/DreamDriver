extends SceneTree

# Qué geometría hay exactamente en un punto de contacto.
#
# Los rayos tienen un punto ciego: si el rayo arranca dentro de un cuerpo macizo
# no ve nada. Aquí no se lanzan rayos a ciegas: se recorren las CARAS de la malla
# de cada cuerpo y se listan las que caen dentro del radio pedido, con su rango de
# altura y la inclinación de su normal. Es la verdad cruda del fichero.
#
# Uso:  Godot --headless --path . --script res://scripts/contact_face_probe.gd

const GROUND := ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "GRAVEL", "SAND",
	"GRASS", "GREEN", "OUT", "CONCRETE", "PITS", "CARPET"]
# Punto de contacto medido en la reproducción (estación 549, 4,84 m a la derecha),
# y el punto donde quedó el coche.
const CONTACTO := Vector3(95.44251, -26.96474, -517.3502)
const COCHE := Vector3(95.16936, -27.00436, -515.6842)
const RADIO := 3.0

func _initialize() -> void:
	call_deferred("_run")

func _group_of(body: Node) -> String:
	if body == null:
		return "NONE"
	var label := (String(body.name) + " " + String(body.get_meta("ac_surface", ""))).to_upper()
	for key in ["TRM-BRC", "ROAD", "CURB", "KERB", "RUMBLE", "GRAVEL", "SAND", "GRASS",
			"GREEN", "OUT", "CONCRETE", "PITS", "CARPET", "GRILL", "WALL", "BUMP",
			"MARBLES", "CNCPTS", "TRAV"]:
		if key in label:
			return key
	return "OTHER"

func _en_el_mundo(caras: PackedVector3Array, transformacion: Transform3D) -> PackedVector3Array:
	# Las caras vienen en coordenadas LOCALES y el circuito va rotado (π sobre Y):
	# sin aplicar la transformación del cuerpo, comparar con un punto del mundo da
	# resultados sin sentido.
	var salida := PackedVector3Array()
	salida.resize(caras.size())
	for i in caras.size():
		salida[i] = transformacion * caras[i]
	return salida


func _cubre(a: Vector3, b: Vector3, c: Vector3, punto: Vector3, margen: float) -> bool:
	var x0 := minf(a.x, minf(b.x, c.x)) - margen
	var x1 := maxf(a.x, maxf(b.x, c.x)) + margen
	var z0 := minf(a.z, minf(b.z, c.z)) - margen
	var z1 := maxf(a.z, maxf(b.z, c.z)) + margen
	return punto.x >= x0 and punto.x <= x1 and punto.z >= z0 and punto.z <= z1


func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	await physics_frame
	Engine.max_fps = 0

	print("CARAS radio=%.1f m contacto=%s coche=%s" % [RADIO, str(CONTACTO), str(COCHE)])
	for nodo in race.track_mesh.find_children("*", "StaticBody3D", true, false):
		var cuerpo := nodo as StaticBody3D
		if cuerpo.collision_layer == 0:
			continue
		var grupo := _group_of(cuerpo)
		var caras := PackedVector3Array()
		for hijo in cuerpo.get_children():
			var forma := hijo as CollisionShape3D
			if forma != null and forma.shape is ConcavePolygonShape3D:
				caras = _en_el_mundo((forma.shape as ConcavePolygonShape3D).get_faces(),
					cuerpo.global_transform)
		if caras.is_empty():
			continue
		var cerca := 0
		var y_min := INF
		var y_max := -INF
		var horizontales := 0
		var verticales := 0
		var ejemplos: Array = []
		var indice := 0
		while indice * 3 + 2 < caras.size():
			var a := caras[indice * 3]
			var b := caras[indice * 3 + 1]
			var c := caras[indice * 3 + 2]
			var centro := (a + b + c) / 3.0
			if _cubre(a, b, c, CONTACTO, RADIO):
				cerca += 1
				y_min = minf(y_min, minf(a.y, minf(b.y, c.y)))
				y_max = maxf(y_max, maxf(a.y, maxf(b.y, c.y)))
				var normal := (b - a).cross(c - a)
				var vertical := false
				if normal.length_squared() > 1e-9:
					vertical = absf(normal.normalized().y) < 0.5
				if vertical:
					verticales += 1
				else:
					horizontales += 1
				if ejemplos.size() < 4:
					ejemplos.append("centro=%s normal=(%.2f, %.2f, %.2f)" % [
						str(centro.snapped(Vector3(0.001, 0.001, 0.001))),
						normal.normalized().x, normal.normalized().y, normal.normalized().z])
			indice += 1
		if cerca == 0:
			continue
		print("CARAS grupo=%s nombre=%s caras_en_el_radio=%d altura=%.3f..%.3f m verticales=%d horizontales=%d" % [
			grupo, String(cuerpo.name), cerca, y_min, y_max, verticales, horizontales])
		for ejemplo in ejemplos:
			print("CARAS   ejemplo %s" % ejemplo)
	# Altura del asfalto justo debajo del punto de contacto, para saber cuánto
	# sobresale lo que paró al coche.
	for nodo in race.track_mesh.find_children("*", "StaticBody3D", true, false):
		var cuerpo := nodo as StaticBody3D
		if cuerpo.collision_layer == 0 or not GROUND.has(_group_of(cuerpo)):
			continue
		var caras := PackedVector3Array()
		for hijo in cuerpo.get_children():
			var forma := hijo as CollisionShape3D
			if forma != null and forma.shape is ConcavePolygonShape3D:
				caras = _en_el_mundo((forma.shape as ConcavePolygonShape3D).get_faces(),
					cuerpo.global_transform)
		var techo := -INF
		var indice := 0
		while indice * 3 + 2 < caras.size():
			var centro := (caras[indice * 3] + caras[indice * 3 + 1] + caras[indice * 3 + 2]) / 3.0
			if _cubre(caras[indice * 3], caras[indice * 3 + 1], caras[indice * 3 + 2], CONTACTO, 1.0):
				techo = maxf(techo, maxf(caras[indice * 3].y, maxf(caras[indice * 3 + 1].y, caras[indice * 3 + 2].y)))
			indice += 1
		if techo > -INF:
			print("CARAS suelo grupo=%s altura_maxima_bajo_el_contacto=%.3f m" % [_group_of(cuerpo), techo])
	race.queue_free()
	await process_frame
	quit(0)
