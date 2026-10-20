extends SceneTree

# ¿El muro que detiene al coche está dibujado?
#
# Busca las columnas (estación de la trazada + lado) donde el primer obstáculo
# vertical del grupo WALL está más cerca, y en cada una renderiza dos vistas:
#   * `salida`  — cámara a 1,6 m del borde de pista mirando hacia fuera, que es
#     lo que ve quien se sale;
#   * `aerea`   — cámara 45 m por encima mirando en oblicuo, que muestra de un
#     vistazo si hay barrera dibujada donde el coche se para.
#
# Uso:  Godot --path . --script res://scripts/wall_visibility_probe.gd
# (necesita ventana: sin ella no hay render que guardar)

const TrackScript = preload("res://scripts/track_data.gd")
const STATION_STEP := 20
const MAX_SCAN := 30.0
const FACE_HEIGHTS := [0.25, 0.6, 1.2, 2.0]
const GROUPS := ["TRM-BRC", "ROAD", "CURB", "KERB", "RUMBLE", "GRAVEL", "SAND", "GRASS", "GREEN",
	"OUT", "CONCRETE", "PITS", "CARPET", "GRILL", "WALL"]
const SHOTS := 6
const OUTPUT_DIR := "res://.tools/recovery/fase1-colisiones/shots"

var space: PhysicsDirectSpaceState3D
var line: PackedVector3Array
var race: Node3D
var camera: Camera3D

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

func _wall_distance(origin: Vector3, direction: Vector3) -> float:
	var best := INF
	for height_value in FACE_HEIGHTS:
		var from := Vector3(origin.x, origin.y + float(height_value), origin.z)
		var query := PhysicsRayQueryParameters3D.create(from, from + direction * MAX_SCAN, 1)
		var hit := space.intersect_ray(query)
		if hit.is_empty() or absf((hit.normal as Vector3).y) >= 0.7:
			continue
		if _group_of(hit.collider as Node) != "WALL":
			continue
		best = minf(best, from.distance_to(hit.position))
	return best

func _run() -> void:
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	await physics_frame
	space = race.get_world_3d().direct_space_state
	line = TrackScript.get_centerline()
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)

	var columns: Array = []
	for i in range(0, line.size(), STATION_STEP):
		var tangent := (line[(i + 3) % line.size()] - line[(i - 3 + line.size()) % line.size()]).normalized()
		var lateral := Vector3(tangent.z, 0.0, -tangent.x).normalized()
		var center := _ground(line[i])
		if float(center["height"]) == INF:
			continue
		for side in [1.0, -1.0]:
			var direction: Vector3 = lateral * side
			var distance := _wall_distance(Vector3(line[i].x, float(center["height"]), line[i].z), direction)
			if distance == INF:
				continue
			columns.append({"i": i, "side": side, "distance": distance, "lateral": lateral,
				"tangent": tangent, "ground": float(center["height"]), "direction": direction})
	columns.sort_custom(func(a, b): return float(a["distance"]) < float(b["distance"]))
	var picked: Array = []
	for entry in columns:
		var clash := false
		for other in picked:
			if absi(int(other["i"]) - int(entry["i"])) < STATION_STEP * 4:
				clash = true
				break
		if clash:
			continue
		picked.append(entry)
		if picked.size() >= SHOTS:
			break
	print("VISIBILIDAD muro más cercano por columna: %s" % str(picked.map(func(e): return "idx=%d side=%d a=%.1f m" % [e["i"], int(e["side"]), e["distance"]])))

	camera = Camera3D.new()
	camera.name = "Sonda de visibilidad"
	camera.fov = 70.0
	camera.far = 3000.0
	race.add_child(camera)
	var grounded: CharacterBody3D = race.car
	grounded.set_physics_process(false)
	grounded.visible = false
	for entry in picked:
		var index: int = entry["i"]
		var direction: Vector3 = entry["direction"]
		var point: Vector3 = line[index] + direction * 3.0
		var ground := _ground(point)
		var base: float = float(ground["height"]) if float(ground["height"]) != INF else float(entry["ground"])
		# Vista a la altura del morro, mirando hacia fuera.
		camera.look_at_from_position(Vector3(point.x, base + 1.6, point.z) - direction * 6.0,
			Vector3(point.x, base + 1.2, point.z) + direction * 12.0, Vector3.UP)
		camera.current = true
		await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		shot.save_png("%s/idx%04d_side%d_salida.png" % [OUTPUT_DIR, index, int(entry["side"])])
		# Vista oblicua desde arriba: muestra barrera y escapatoria a la vez.
		camera.look_at_from_position(Vector3(line[index].x - direction.x * 22.0, base + 42.0, line[index].z - direction.z * 22.0),
			Vector3(line[index].x + direction.x * 14.0, base, line[index].z + direction.z * 14.0), Vector3.UP)
		camera.current = true
		await process_frame
		await RenderingServer.frame_post_draw
		shot = root.get_texture().get_image()
		shot.save_png("%s/idx%04d_side%d_aerea.png" % [OUTPUT_DIR, index, int(entry["side"])])
		print("VISIBILIDAD guardado idx=%d side=%d muro_a=%.1f m punto=%s superficies_alrededor=%s" % [
			index, int(entry["side"]), entry["distance"], str(point),
			str(_sequence(point, direction))])
	race.queue_free()
	await process_frame
	quit(0)

func _sequence(point: Vector3, direction: Vector3) -> Array:
	var out: Array = []
	for distance in range(0, 31, 3):
		var ground := _ground(point + direction * float(distance))
		if float(ground["height"]) == INF:
			break
		var group: String = ground["group"]
		if out.is_empty() or out[-1] != group:
			out.append(group)
	return out
