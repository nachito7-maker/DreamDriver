extends SceneTree

# ¿El coche queda bloqueado por una "barrera invisible" al salir del asfalto?
#
# Para cada escapatoria conocida de la vuelta prueba dos maniobras:
#
#   lento  — desde la trazada, mirando hacia fuera, acelerador a fondo: es el
#            caso en el que un borde bajo de 15-20 cm se nota, porque el coche
#            llega despacio y no lo supera.
#   rápido — 30 m de recta sobre el asfalto y después se apunta hacia fuera
#            manteniendo el rumbo: es el caso de salirse de verdad en curva.
#
# Cuando el coche se para mide, en ese mismo punto y en ese mismo instante:
#   * qué cuerpos ha tocado desde que dejó el asfalto (nombre y grupo real),
#   * qué cara vertical hay delante a 0.25, 0.60, 1.20 y 2.00 m de altura,
#   * y el perfil de altura del suelo hacia delante cada 25 cm.
#
# Un muro de verdad levanta cara vertical a 0.60 m o más. Un escalón invisible
# de 20 cm sólo la levanta a 0.25 m y desaparece a 0.60 m. Esa es la diferencia
# que decide si el coche está bloqueado por una barrera real o por un borde
# bajo que no se ve.
#
# Uso:  Godot --path . --script res://scripts/offtrack_mobility_probe.gd

const TrackScript = preload("res://scripts/track_data.gd")
const TICK := 1.0 / 120.0
const RUNUP_M := 30.0
const RUNUP_STATIONS := 20
const MAX_SCAN := 30.0
const FACE_HEIGHTS := [0.25, 0.6, 1.2, 2.0]
const GROUPS := ["TRM-BRC", "ROAD", "CURB", "KERB", "RUMBLE", "GRAVEL", "SAND", "GRASS", "GREEN",
	"OUT", "CONCRETE", "PITS", "CARPET", "GRILL", "WALL"]
const ASPHALT := ["TRM-BRC", "ROAD"]
const MAX_TICKS := 1900           # ~16 s por maniobra
const STALL_SPEED := 1.0          # m/s
const STALL_TICKS := 60           # 0.5 s parado = bloqueado
const LOW_LEDGE_M := 0.35         # por debajo de esta altura un borde no debería parar
const MIN_OPEN_TRAVEL := 15.0      # metros fuera del asfalto que se exigen a una escapatoria
const LONG_OPEN_TRAVEL := 50.0     # metros que prueban que fuera del asfalto se circula de verdad
const AUTO_OPEN := 3              # escapatorias abiertas elegidas por barrido

# (estación de la trazada, lado). +1 = izquierda según el sentido de marcha.
# Las tres primeras son las que el informe previo señaló como sospechosas; las
# demás cubren los extremos del barrido: el muro más cercano y las escapatorias
# más abiertas.
const STATIONS := [
	[2760, -1], [2440, 1], [2360, -1],
	[2360, 1], [480, 1], [2240, 1], [1200, 1], [1540, 1],
]

var failures := 0
var space: PhysicsDirectSpaceState3D
var line: PackedVector3Array
var race: Node3D
var car: CharacterBody3D
var ui: CanvasLayer
var steer_center := Vector2.ZERO
var steer_radius := 1.0
var gas_rect := Rect2()
var gas_point := Vector2.ZERO
var brake_point := Vector2.ZERO

func check(ok: bool, message: String) -> void:
	print("MOVILIDAD ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func info(message: String) -> void:
	print("MOVILIDAD INFO ", message)

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
		return {"height": INF, "group": "NONE", "body": "NONE"}
	return {"height": float(hit.position.y), "group": _group_of(hit.collider as Node),
		"body": String((hit.collider as Node).name)}

# Cara vertical delante, a cada altura sobre el suelo local.
func _faces_ahead(position: Vector3, direction: Vector3) -> Dictionary:
	var ground := _ground(position)
	if float(ground["height"]) == INF:
		return {}
	var out := {}
	for height_value in FACE_HEIGHTS:
		var origin := Vector3(position.x, float(ground["height"]) + float(height_value), position.z)
		out[height_value] = INF
		for offset in [-0.6, 0.0, 0.6]:
			var side: Vector3 = direction.cross(Vector3.UP).normalized() * float(offset)
			var query := PhysicsRayQueryParameters3D.create(origin + side, origin + side + direction * MAX_SCAN, 1)
			var hit := space.intersect_ray(query)
			if hit.is_empty() or absf((hit.normal as Vector3).y) >= 0.7:
				continue
			out[height_value] = minf(float(out[height_value]), Vector3(origin.x, origin.y, origin.z).distance_to(hit.position))
	return out

func _profile_ahead(position: Vector3, direction: Vector3) -> Array:
	var base := _ground(position)
	if float(base["height"]) == INF:
		return []
	var out: Array = []
	for step in range(1, 17):
		var ground := _ground(position + direction * (float(step) * 0.25))
		if float(ground["height"]) == INF:
			out.append("sin_suelo")
			continue
		out.append("%+.2f" % (float(ground["height"]) - float(base["height"])))
	return out

# Barrido radial alrededor del coche parado: mide qué hay de verdad a su
# alrededor, en las 24 direcciones y a 0,25 y 0,60 m de altura sobre el suelo
# local. Un muro real aparece como cara vertical del grupo WALL; una barrera
# invisible aparecería como otro grupo, o como una cara vertical pegada al
# coche. Las caras horizontales se descartan porque son suelo, no obstáculo.
# Es la prueba que decide si la parada la produjo la barrera del circuito o un
# borde que no se ve.
func _radial(position: Vector3) -> Dictionary:
	var out := {"suelo": "sin_suelo", "mas_cercano": "nada", "muro_mas_cercano": INF, "otros": []}
	var ground := _ground(position)
	if float(ground["height"]) == INF:
		return out
	out["suelo"] = ground["group"]
	var base := Vector3(position.x, float(ground["height"]), position.z)
	var nearest := INF
	for step in 24:
		var bearing := TAU * float(step) / 24.0
		var direction := Vector3.FORWARD.rotated(Vector3.UP, bearing)
		for height_value in [0.25, 0.6]:
			var origin := base + Vector3.UP * float(height_value)
			var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * MAX_SCAN, 1)
			var hit := space.intersect_ray(query)
			if hit.is_empty() or absf((hit.normal as Vector3).y) >= 0.7:
				continue
			var distance := origin.distance_to(hit.position)
			var group := _group_of(hit.collider as Node)
			var label := "%s@%.2f m (%.0f°, %.2f m)" % [group, distance, rad_to_deg(bearing), float(height_value)]
			if distance < nearest:
				nearest = distance
				out["mas_cercano"] = label
			if group == "WALL":
				out["muro_mas_cercano"] = minf(float(out["muro_mas_cercano"]), distance)
			elif distance < 2.0:
				out["otros"].append(label)
	return out

func _contacts() -> Array:
	var out: Array = []
	for i in car.get_slide_collision_count():
		var collision := car.get_slide_collision(i)
		var body := collision.get_collider() as Node
		var entry := "%s(%s)" % [String(body.name), _group_of(body)]
		if not out.has(entry):
			out.append(entry)
	return out

func _pedal_point(rect: Rect2, demand: float) -> Vector2:
	var low := 0.0
	var high := 0.8
	for i in 12:
		var mid := (low + high) * 0.5
		if smoothstep(0.0, 0.8, mid) < demand:
			low = mid
		else:
			high = mid
	return rect.position + rect.size * Vector2(0.5, 1.0 - (low + high) * 0.5)

func _hold(point: Vector2, id: int) -> void:
	var needs_press := false
	match id:
		10:
			needs_press = ui._steer_touch_id != id
		11:
			needs_press = ui._throttle_touch_id != id
		12:
			needs_press = ui._brake_touch_id != id
	if needs_press:
		ui._handle_touch_down(id, point)
	else:
		ui._handle_touch_motion(id, point)

func _command(steer: float) -> void:
	_hold(steer_center + Vector2(clampf(steer, -1.0, 1.0) * steer_radius, 0.0), 10)
	_hold(gas_point, 11)             # a fondo todo el tiempo
	_hold(Vector2(brake_point.x, ui._brake_pedal.position.y + ui._brake_pedal.size.y + 6.0), 12)
	ui._process(TICK)

func _frame(index: int) -> Dictionary:
	var tangent := (line[(index + 4) % line.size()] - line[(index - 4 + line.size()) % line.size()]).normalized()
	return {"tangent": tangent, "lateral": Vector3(tangent.z, 0.0, -tangent.x).normalized()}

func _release() -> void:
	for id in [10, 11, 12]:
		ui._handle_touch_up(id)

func _run() -> void:
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 120:
		await physics_frame
	car = race.car
	ui = race.controls
	steer_center = ui._steer_center
	steer_radius = maxf(1.0, ui._steering_ring.size.x * 0.46)
	gas_rect = ui._pedal_rects["throttle"]
	if gas_rect.size.x <= 0.0:
		push_error("La sonda de movilidad necesita una ventana real con viewport medible")
		quit(2)
		return
	gas_point = Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5, gas_rect.position.y + gas_rect.size.y * 0.05)
	brake_point = Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5, gas_rect.end.y - 1.0)
	line = TrackScript.get_centerline()
	space = race.get_world_3d().direct_space_state

	var blocked_by_ledge := 0
	var blocked_by_wall := 0
	var blocked_unknown := 0
	var open_escapes := 0
	var open_proven := 0
	var open_bounded := 0
	var long_escapes := 0
	var runs := 0
	var planned: Array = []
	for station in STATIONS:
		planned.append({"index": station[0], "side": station[1], "modes": [false, true], "open": false})
	for station in _open_stations(AUTO_OPEN):
		planned.append({"index": station[0], "side": station[1], "modes": [false], "open": true})
	info("escapatorias abiertas elegidas por barrido: %s" % str(planned.filter(func(e): return e["open"]).map(
		func(e): return "idx=%d side=%d" % [e["index"], e["side"]])))
	for entry in planned:
		var index: int = entry["index"]
		var side: int = entry["side"]
		for fast in entry["modes"]:
			runs += 1
			var result: Dictionary = await _escape(index, side, fast)
			var mode := "rápido" if fast else "lento "
			if not bool(result["left_asphalt"]):
				check(false, "idx=%d side=%d %s abandona el asfalto" % [index, side, mode])
				continue
			var blocked := float(result["stall"]) >= STALL_TICKS / 120.0
			var wall_face := float(result["wall_face"])
			var low_face := float(result["low_face"])
			# Si el coche está parado, lo primero que decide el veredicto es contra
			# qué está apoyado en ese instante: es la medida directa, no una
			# estimación por rayos. El barrido de caras sólo desempata cuando el
			# cuerpo no es un muro (ahí sí importa si lo que bloquea es un borde bajo).
			var wall_contact := false
			for entry_contact in result["stop_contacts"]:
				if "(WALL)" in String(entry_contact):
					wall_contact = true
			var verdict := "libre"
			if blocked:
				if wall_contact or wall_face <= MAX_SCAN:
					verdict = "bloqueado_por_muro"
					blocked_by_wall += 1
				elif low_face < INF and low_face <= 3.0:
					verdict = "bloqueado_por_borde_bajo"
					blocked_by_ledge += 1
				else:
					verdict = "bloqueado_por_cuerpo_desconocido"
					blocked_unknown += 1
			else:
				open_escapes += 1
			if float(result["travel"]) >= LONG_OPEN_TRAVEL:
				long_escapes += 1
			print("MOVILIDAD RESULT idx=%d side=%d modo=%s veredicto=%s velocidad_al_dejar=%.1f km/h recorrido_fuera=%.1f m parada=%.2f s toca=%s cara_baja=%.2f m cara_muro=%.2f m superficies=%s" % [
				index, side, mode, verdict, float(result["speed_at_edge"]) * 3.6, float(result["travel"]),
				float(result["stall"]), str(result["contacted"]), low_face, wall_face, str(result["surfaces"])])
			if blocked:
				print("MOVILIDAD PARADA idx=%d side=%d modo=%s pos=%s contacto=%s" % [index, side, mode,
					str(result["stop_position"]), str(result["stop_contacts"])])
				print("MOVILIDAD PARADA idx=%d side=%d modo=%s caras_verticales=%s" % [index, side, mode, str(result["faces"])])
				print("MOVILIDAD PARADA idx=%d side=%d modo=%s radial=%s" % [index, side, mode, str(result["radial"])])
				print("MOVILIDAD PARADA idx=%d side=%d modo=%s perfil_suelo_cada_25cm=%s" % [index, side, mode, str(result["profile"])])
			if verdict == "bloqueado_por_borde_bajo":
				check(false, "idx=%d side=%d %s no se detiene contra un borde bajo invisible" % [index, side, mode])
			if verdict == "libre" and float(result["travel"]) < MIN_OPEN_TRAVEL and wall_face > MAX_SCAN:
				check(false, "idx=%d side=%d %s recorre al menos %.0f m en escapatoria abierta" % [index, side, mode, MIN_OPEN_TRAVEL])
			if bool(entry["open"]):
				# Lo que se exige a una escapatoria abierta es que el coche salga y
				# recorra metros fuera del asfalto. Si acaba parado, tiene que ser
				# contra una barrera real del circuito: una barrera invisible al
				# borde del asfalto suspende la maniobra.
				if float(result["travel"]) >= MIN_OPEN_TRAVEL:
					open_proven += 1
				elif verdict == "bloqueado_por_muro":
					open_bounded += 1
				else:
					check(false, "idx=%d side=%d escapatoria abierta: %.1f m fuera del asfalto y el bloqueo no es un muro (%s)" % [index, side, float(result["travel"]), verdict])
			_release()
			for i in 60:
				await physics_frame
	info("maniobras=%d sin parar=%d bloqueadas_por_muro=%d bloqueadas_por_borde_bajo=%d bloqueadas_por_cuerpo_desconocido=%d" % [
		runs, open_escapes, blocked_by_wall, blocked_by_ledge, blocked_unknown])
	info("maniobras que recorren al menos %.0f m fuera del asfalto antes de la barrera: %d de %d" % [
		LONG_OPEN_TRAVEL, long_escapes, runs])
	info("escapatorias abiertas: %d recorren al menos %.0f m, %d acaban en muro real, %d de %d" % [
		open_proven, MIN_OPEN_TRAVEL, open_bounded, open_proven + open_bounded, AUTO_OPEN])
	check(blocked_by_ledge == 0, "ninguna maniobra se detiene contra un borde bajo invisible (%d de %d)" % [blocked_by_ledge, runs])
	check(blocked_unknown == 0, "ninguna maniobra se detiene contra un cuerpo sin cara vertical ni contacto de muro (%d de %d)" % [blocked_unknown, runs])
	check(long_escapes >= 2, "fuera del asfalto se circula de verdad: al menos 2 maniobras recorren %.0f m antes de la barrera (%d de %d)" % [LONG_OPEN_TRAVEL, long_escapes, runs])
	check(open_proven >= 1, "alguna escapatoria abierta deja recorrer al menos %.0f m fuera del asfalto (%d de %d)" % [MIN_OPEN_TRAVEL, open_proven, AUTO_OPEN])
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

# Escapatorias sin cara vertical en 30 m: son las que el circuito ofrece para
# salirse sin barrera, y las que deben dejar circular al coche.
func _open_stations(count: int) -> Array:
	var out: Array = []
	for index in range(0, line.size(), 20):
		var frame := _frame(index)
		var center := _ground(line[index])
		if float(center["height"]) == INF:
			continue
		for side in [1, -1]:
			if out.size() >= count:
				break
			var direction: Vector3 = (frame["lateral"] as Vector3) * float(side)
			var origin := Vector3(line[index].x, float(center["height"]) + 0.4, line[index].z)
			var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * MAX_SCAN, 1)
			var hit := space.intersect_ray(query)
			if not hit.is_empty() and absf((hit.normal as Vector3).y) < 0.7:
				continue
			var clash := false
			for entry in out:
				if absi(int(entry[0]) - index) < 60:
					clash = true
					break
			if clash:
				continue
			out.append([index, side])
	return out

func _escape(index: int, side: int, fast: bool) -> Dictionary:
	var frame := _frame(index)
	var outward: Vector3 = (frame["lateral"] as Vector3) * float(side)
	var start_index := index
	if fast:
		start_index = posmod(index - RUNUP_STATIONS, line.size())
	var start_frame := _frame(start_index)
	var start := line[start_index] + Vector3.UP * 0.6
	var yaw := atan2(-(start_frame["tangent"] as Vector3).x, -(start_frame["tangent"] as Vector3).z)
	car.recover_to(start, yaw)
	car.velocity = Vector3.ZERO
	_hold(steer_center, 10)
	_hold(gas_point, 11)
	_hold(brake_point, 12)
	for i in 30:
		await physics_frame

	var travelled := 0.0
	var left_asphalt := false
	var speed_at_edge := 0.0
	var edge_travel := 0.0
	var min_speed_after := INF
	var last_speed := 0.0
	var stall_ticks := 0
	var worst_stall := 0
	var stop_position := Vector3.ZERO
	var stop_faces := {}
	var stop_profile: Array = []
	var stop_contacts: Array = []
	var stop_radial := {}
	var contacted: Array = []
	var surfaces: Array = []
	for tick in MAX_TICKS:
		await physics_frame
		var position: Vector3 = car.global_position
		travelled = (position - line[start_index]).length()
		var steer := 0.0
		if not fast or travelled > RUNUP_M:
			# Se apunta hacia fuera y se mantiene el rumbo: la salida es una
			# recta, no una curva que vuelve a cruzar la pista.
			var forward := -car.global_basis.z
			forward.y = 0.0
			forward = forward.normalized()
			steer = -clampf(forward.cross(outward).y * 2.2, -1.0, 1.0)
		_command(steer)
		if left_asphalt:
			for entry in _contacts():
				if not contacted.has(entry):
					contacted.append(entry)
		var ground := _ground(position)
		var group: String = ground["group"]
		if surfaces.is_empty() or surfaces[-1] != group:
			surfaces.append(group)
		if not left_asphalt:
			if not ASPHALT.has(group) and group != "NONE":
				left_asphalt = true
				speed_at_edge = car.speed_mps
				edge_travel = travelled
		else:
			min_speed_after = minf(min_speed_after, car.speed_mps)
			if car.speed_mps < STALL_SPEED:
				stall_ticks += 1
				if stall_ticks > worst_stall:
					worst_stall = stall_ticks
					stop_position = position
					stop_contacts = _contacts()
					for entry in stop_contacts:
						if not contacted.has(entry):
							contacted.append(entry)
					stop_faces = _faces_ahead(position, outward)
					stop_profile = _profile_ahead(position, outward)
					stop_radial = _radial(position)
			else:
				stall_ticks = 0
		last_speed = car.speed_mps
	var displacement := (car.global_position - line[start_index]).length()
	var wall_face := 1000000.0
	var low_face := 1000000.0
	if not stop_faces.is_empty():
		low_face = float(stop_faces.get(0.25, 1000000.0))
		wall_face = minf(float(stop_faces.get(0.6, 1000000.0)), minf(float(stop_faces.get(1.2, 1000000.0)), float(stop_faces.get(2.0, 1000000.0))))
	return {"left_asphalt": left_asphalt, "speed_at_edge": speed_at_edge, "travel": displacement - edge_travel,
		"stall": worst_stall / 120.0, "contacted": contacted, "low_face": low_face, "wall_face": wall_face,
		"surfaces": surfaces, "stop_position": stop_position, "stop_contacts": stop_contacts,
		"faces": stop_faces, "profile": stop_profile, "radial": stop_radial,
		"min_speed_after": min_speed_after, "last_speed": last_speed}
