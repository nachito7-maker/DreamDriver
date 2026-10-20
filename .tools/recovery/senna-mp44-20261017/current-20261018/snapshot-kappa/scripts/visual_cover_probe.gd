extends SceneTree

# ¿La geometría de física que sobresale está DIBUJADA en algún sitio?
#
# Es la pregunta que decide si algo es un muro (se ve, debe parar al coche) o una
# barrera invisible (no se ve, es un fallo del port). Se responde con geometría, no
# con una impresión: se construyen colisiones TEMPORALES con las mallas VISIBLES
# (las que el jugador ve) y se raya contra ellas alrededor de cada cara de física
# que sobresale del suelo. Si en 0,25 m a la redonda no hay nada dibujado, esa
# cara es invisible.
#
# La medida se hace sobre el relieve A SU ALTURA ORIGINAL —la que entrega AC—, y a
# propósito: la pregunta de esta sonda es si la geometría que el circuito trae de
# fábrica está dibujada. Como el juego la hunde 1,50 m (y lo deja anotado en
# `ac_relief_sunk_m`), la sonda le devuelve esa altura sólo para medir, sin tocar el
# mundo de física: los rayos siguen midiéndose contra la calzada de verdad.
#
# Uso:  Godot --headless --path . --script res://scripts/visual_cover_probe.gd

const GROUND := ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "GRAVEL", "SAND",
	"GRASS", "GREEN", "OUT", "CONCRETE", "PITS", "CARPET"]
const RELIEVE := ["MARBLES", "BUMP", "GRILL", "CNCPTS", "TRAV"]
const VIENTO_VISUAL := 0.25       # m: a esta distancia se considera dibujado
const ALTURA_MINIMA := 0.05       # m: por debajo no molesta al coche

var space: PhysicsDirectSpaceState3D
var visuales: Array = []          # RIDs de las colisiones temporales de las mallas visibles

func _initialize() -> void:
	call_deferred("_run")

func _group_of(body: Node) -> String:
	if body == null:
		return "NONE"
	var label := (String(body.name) + " " + String(body.get_meta("ac_surface", ""))).to_upper()
	for key in (GROUND + ["GRILL", "WALL", "BUMP", "MARBLES", "CNCPTS", "TRAV"]):
		if key in label:
			return key
	return "OTHER"

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	await physics_frame
	space = race.get_world_3d().direct_space_state
	Engine.max_fps = 0

	# 1. Las colisiones temporales de las mallas VISIBLES, en una capa aparte (4)
	#    que el coche no usa.
	var contenedor := Node3D.new()
	race.add_child(contenedor)
	var mallas := 0
	for nodo in race.track_mesh.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		if not malla.visible or malla.mesh == null:
			continue
		var cuerpo := StaticBody3D.new()
		cuerpo.collision_layer = 4
		cuerpo.collision_mask = 0
		contenedor.add_child(cuerpo)
		cuerpo.global_transform = malla.global_transform
		var forma := CollisionShape3D.new()
		forma.shape = malla.mesh.create_trimesh_shape()
		cuerpo.add_child(forma)
		visuales.append(cuerpo.get_rid())
		mallas += 1
	print("VISIBLE mallas_dibujadas=%d" % mallas)
	await physics_frame

	# 2. Cada cara de física que sobresale, contra la geometría dibujada.
	# Punto concreto (opcional): se informa qué cuerpo de física tiene caras ahí y si
	# hay algo dibujado. Se usa para juzgar paradas fuera de la calzada.
	var puntos: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--punto="):
			var partes := arg.substr(8).split(",")
			if partes.size() == 3:
				puntos.append(Vector3(float(partes[0]), float(partes[1]), float(partes[2])))
	for punto in puntos:
		var en_el_punto: Array = []
		for nodo in race.track_mesh.find_children("*", "StaticBody3D", true, false):
			var cuerpo := nodo as StaticBody3D
			if cuerpo.collision_layer == 0:
				continue
			var caras := _caras_en_el_mundo(cuerpo)
			var indice := 0
			var verticales := 0
			var total := 0
			while indice * 3 + 2 < caras.size():
				var a := caras[indice * 3]
				var b := caras[indice * 3 + 1]
				var c := caras[indice * 3 + 2]
				indice += 1
				if not _cubre(a, b, c, punto, 0.5):
					continue
				total += 1
				var normal := (b - a).cross(c - a)
				if normal.length_squared() > 1e-9 and absf(normal.normalized().y) < 0.5:
					verticales += 1
			if total > 0:
				en_el_punto.append("%s(%d caras, %d verticales)" % [_group_of(cuerpo), total, verticales])
		print("VISIBLE PUNTO %s → fisica: %s | dibujado a menos de %.2f m: %s" % [
			str(punto), str(en_el_punto), VIENTO_VISUAL, "si" if _hay_dibujo(punto) else "NO"])
	for nodo in race.track_mesh.find_children("*", "StaticBody3D", true, false):
		var cuerpo := nodo as StaticBody3D
		if cuerpo.collision_layer == 0:
			continue
		var grupo := _group_of(cuerpo)
		if not RELIEVE.has(grupo):
			continue
		var caras := PackedVector3Array()
		var exclusion: Array = [cuerpo.get_rid()]
		# Lo que el juego le ha restado, tal como lo dejó anotado al hundirla: se le
		# devuelve sólo en la medida, no en el mundo de física.
		var hundido := float(cuerpo.get_meta("ac_relief_sunk_m", 0.0))
		for hijo in cuerpo.get_children():
			var forma := hijo as CollisionShape3D
			if forma != null and forma.shape is ConcavePolygonShape3D:
				caras = _en_el_mundo((forma.shape as ConcavePolygonShape3D).get_faces(),
					forma.global_transform)
				for i in caras.size():
					caras[i].y += hundido
		if caras.is_empty():
			continue
		var con_dibujo := 0
		var sin_dibujo := 0
		var alturas_sin_dibujo := {}
		var indice := 0
		while indice * 3 + 2 < caras.size():
			var a := caras[indice * 3]
			var b := caras[indice * 3 + 1]
			var c := caras[indice * 3 + 2]
			var centro := (a + b + c) / 3.0
			var debajo := _suelo(centro, exclusion)
			indice += 1
			if float(debajo["altura"]) == INF:
				continue
			var relieve := centro.y - float(debajo["altura"])
			if relieve <= ALTURA_MINIMA:
				continue
			if _hay_dibujo(centro):
				con_dibujo += 1
			else:
				sin_dibujo += 1
				var banda := int(floor(relieve * 2.0)) / 2.0
				alturas_sin_dibujo[banda] = int(alturas_sin_dibujo.get(banda, 0)) + 1
		print("VISIBLE grupo=%s caras_que_sobresalen=%d con_geometria_dibujada=%d SIN_geometria_dibujada=%d por_altura=%s" % [
			grupo, con_dibujo + sin_dibujo, con_dibujo, sin_dibujo, str(alturas_sin_dibujo)])
	contenedor.queue_free()
	await process_frame
	quit(0)

func _cubre(a: Vector3, b: Vector3, c: Vector3, punto: Vector3, margen: float) -> bool:
	return (punto.x >= minf(a.x, minf(b.x, c.x)) - margen and punto.x <= maxf(a.x, maxf(b.x, c.x)) + margen
		and punto.z >= minf(a.z, minf(b.z, c.z)) - margen and punto.z <= maxf(a.z, maxf(b.z, c.z)) + margen)


func _caras_en_el_mundo(body: StaticBody3D) -> PackedVector3Array:
	for hijo in body.get_children():
		var forma := hijo as CollisionShape3D
		if forma != null and forma.shape is ConcavePolygonShape3D:
			return _en_el_mundo((forma.shape as ConcavePolygonShape3D).get_faces(), body.global_transform)
	return PackedVector3Array()


func _en_el_mundo(caras: PackedVector3Array, transformacion: Transform3D) -> PackedVector3Array:
	var salida := PackedVector3Array()
	salida.resize(caras.size())
	for i in caras.size():
		salida[i] = transformacion * caras[i]
	return salida

func _suelo(point: Vector3, exclude: Array) -> Dictionary:
	var consulta := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 12.0, point - Vector3.UP * 8.0, 1)
	consulta.exclude = exclude
	var golpe := space.intersect_ray(consulta)
	if golpe.is_empty():
		return {"altura": INF}
	return {"altura": float(golpe.position.y)}

func _hay_dibujo(point: Vector3) -> bool:
	# Ocho direcciones horizontales, a la altura de la cara: basta con que una
	# encuentre una superficie dibujada a menos de `VIENTO_VISUAL` metros.
	for direccion in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK,
			(Vector3.RIGHT + Vector3.FORWARD).normalized(), (Vector3.RIGHT + Vector3.BACK).normalized(),
			(Vector3.LEFT + Vector3.FORWARD).normalized(), (Vector3.LEFT + Vector3.BACK).normalized()]:
		var consulta := PhysicsRayQueryParameters3D.create(point,
			point + Vector3(direccion.x, 0.0, direccion.z).normalized() * VIENTO_VISUAL, 4)
		if not space.intersect_ray(consulta).is_empty():
			return true
	return false
