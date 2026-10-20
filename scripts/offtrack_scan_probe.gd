extends SceneTree

# Barrido de la escapatoria, estación por estación y lado por lado.
#
# Qué responde: al salir del asfalto, ¿el primer obstáculo vertical es un muro de
# verdad (grupo WALL) o el borde de una superficie (KERB, CURB, SAND, GRASS...)?
# El segundo caso es el que se siente como barrera invisible: el coche se para
# contra un escalón que a simple vista no se ve.
#
# Sólo mide geometría con rayos: no conduce nada, así que sirve igual antes y
# después de cualquier cambio de física y tarda poco.
#
# Uso:  Godot --headless --path . --script res://scripts/offtrack_scan_probe.gd

const TrackScript = preload("res://scripts/track_data.gd")
const STATION_STEP := 20
const MAX_SCAN := 30.0
# Alturas sobre el suelo de la trazada a las que se busca cara vertical. La más
# baja es la que decide: un escalón de menos de 0.25 m no debería parar el coche.
const FACE_HEIGHTS := [0.25, 0.6, 1.2, 2.0]
const GROUPS := ["TRM-BRC", "ROAD", "CURB", "KERB", "RUMBLE", "GRAVEL", "SAND", "GRASS", "GREEN",
	"OUT", "CONCRETE", "PITS", "CARPET", "GRILL", "WALL"]
const LOW_FACE_LIMIT := 0.6
const SUSPECT_RANGE := 15.0

var failures := 0
var space: PhysicsDirectSpaceState3D
var line: PackedVector3Array

func check(condition: bool, message: String) -> void:
	print("SCAN ", "PASS " if condition else "FAIL ", message)
	if not condition:
		failures += 1

func info(message: String) -> void:
	print("SCAN INFO ", message)

func _initialize() -> void:
	call_deferred("_run")

func _group_of(body: Node) -> String:
	if body == null:
		return "NONE"
	var label := (String(body.name) + " " + String(body.get_meta("ac_surface", ""))).to_upper()
	for key in GROUPS:
		if key in label:
			return key
	return "OTHER"

func _ground(point: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 4.0, point - Vector3.UP * 6.0, 1)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return {"height": INF, "group": "NONE"}
	return {"height": float(hit.position.y), "group": _group_of(hit.collider as Node)}

# Cara vertical más cercana desde una altura concreta sobre el suelo local.
func _vertical_ahead(origin: Vector3, direction: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * MAX_SCAN, 1)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return {"distance": INF, "group": "NONE", "body": ""}
	if absf((hit.normal as Vector3).y) >= 0.7:
		return {"distance": INF, "group": "NONE", "body": ""}
	var body := hit.collider as Node
	return {"distance": origin.distance_to(hit.position), "group": _group_of(body), "body": String(body.name)}

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	await physics_frame
	space = race.get_world_3d().direct_space_state
	line = TrackScript.get_centerline()
	Engine.max_fps = 0

	var columns := 0
	var open_columns := 0
	var wall_columns := 0
	var surface_columns := 0
	var suspects: Array = []
	var wall_distances: Array = []
	var blocker_counts := {}
	for i in range(0, line.size(), STATION_STEP):
		var tangent := (line[(i + 3) % line.size()] - line[(i - 3 + line.size()) % line.size()]).normalized()
		var lateral := Vector3(tangent.z, 0.0, -tangent.x).normalized()
		var center_ground := _ground(line[i])
		if float(center_ground["height"]) == INF:
			continue
		var base := float(center_ground["height"])
		for side in [1.0, -1.0]:
			columns += 1
			var direction: Vector3 = lateral * side
			# Perfil de la escapatoria: qué superficie hay a cada metro.
			var sequence: Array = []
			for distance in range(1, int(MAX_SCAN) + 1):
				var ground := _ground(line[i] + direction * float(distance))
				if float(ground["height"]) == INF:
					break
				var group: String = ground["group"]
				if sequence.is_empty() or sequence[-1] != group:
					sequence.append(group)
			# Primera cara vertical de muro y de superficie, por separado.
			var wall_face := INF
			var wall_body := ""
			var surface_face := INF
			var surface_group := "NONE"
			var surface_body := ""
			var surface_face_height := 0.0
			var lowest_face := INF
			var lowest_group := "NONE"
			var lowest_body := ""
			for height_value in FACE_HEIGHTS:
				var face := _vertical_ahead(Vector3(line[i].x, base + float(height_value), line[i].z), direction)
				if String(face["group"]) == "NONE":
					continue
				if float(face["distance"]) < lowest_face:
					lowest_face = float(face["distance"])
					lowest_group = String(face["group"])
					lowest_body = String(face["body"])
				if String(face["group"]) == "WALL":
					if float(face["distance"]) < wall_face:
						wall_face = float(face["distance"])
						wall_body = String(face["body"])
				elif float(face["distance"]) < surface_face:
					surface_face = float(face["distance"])
					surface_group = String(face["group"])
					surface_body = String(face["body"])
					surface_face_height = float(height_value)
			if lowest_face == INF:
				open_columns += 1
				blocker_counts["NONE"] = int(blocker_counts.get("NONE", 0)) + 1
				continue
			blocker_counts[lowest_group] = int(blocker_counts.get(lowest_group, 0)) + 1
			if lowest_group == "WALL":
				wall_columns += 1
				wall_distances.append(lowest_face)
			else:
				surface_columns += 1
			# Sospechoso: un borde de superficie a la altura del morro (o más bajo)
			# que aparece antes que cualquier muro.
			if surface_face < INF and surface_face <= SUSPECT_RANGE and surface_face < wall_face and surface_face_height <= LOW_FACE_LIMIT:
				suspects.append({"i": i, "side": side, "group": surface_group, "body": surface_body,
					"distance": surface_face, "height": surface_face_height, "wall": wall_face,
					"wall_body": wall_body, "sequence": str(sequence)})
	print("SCAN_STATIONS columnas=%d | primer_obstaculo=%s | abiertas=%d muro=%d superficie=%d" % [
		columns, str(blocker_counts), open_columns, wall_columns, surface_columns])
	if not wall_distances.is_empty():
		var minimum := INF
		var maximum := 0.0
		var total := 0.0
		for value in wall_distances:
			minimum = minf(minimum, float(value))
			maximum = maxf(maximum, float(value))
			total += float(value)
		info("muro más cercano a la trazada=%.1f m, más lejano=%.1f m, media=%.1f m (%d columnas)" % [
			minimum, maximum, total / wall_distances.size(), wall_distances.size()])
	info("columnas donde una superficie cierra antes que el muro: %d" % suspects.size())
	for entry in suspects.slice(0, 25):
		print("SCAN_SUSPECT idx=%d side=%d grupo=%s a=%.2f m altura_cara=%.2f m muro_a=%.1f m cuerpo=%s muro=%s superficies=%s" % [
			entry["i"], int(entry["side"]), entry["group"], entry["distance"], entry["height"],
			entry["wall"], entry["body"], entry["wall_body"], entry["sequence"]])
	print("SCAN_SUMMARY columnas=%d abiertas=%d muro=%d superficie=%d sospechosas=%d" % [
		columns, open_columns, wall_columns, surface_columns, suspects.size()])
	check(open_columns + wall_columns + surface_columns == columns, "todas las columnas quedan clasificadas (%d)" % columns)
	check(suspects.is_empty(), "ningún borde de superficie cierra la escapatoria antes que un muro real: %d columnas" % suspects.size())
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
