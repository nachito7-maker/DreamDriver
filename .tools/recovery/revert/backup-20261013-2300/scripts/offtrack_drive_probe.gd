extends SceneTree

# Sonda de salida de pista REAL.
#
# No empuja el coche a mano ni se conforma con ver mallas: coloca el coche en el
# asfalto, lo conduce con la cadena de toque real (los mismos mandos que usa un
# dedo) hacia fuera de la trazada y mide lo que ocurre por el camino.
#
# La referencia de "dónde hay algo de verdad" no se escribe a mano: en cada
# estación se lanzan rayos desde la posición del coche hacia fuera y se anota el
# primer obstáculo con cara vertical (muro, bordillo, talud). Así, cualquier
# colisión del coche se puede contrastar con lo que la geometría visible tiene
# delante: si el coche se detiene donde los rayos no ven nada, el bloqueo es una
# malla invisible y la sonda dice cuál.

const TrackScript = preload("res://scripts/track_data.gd")
const TICK := 1.0 / 120.0
const STATION_STEP := 40
const MAX_SCAN := 70.0
const SCAN_HEIGHTS := [0.4, 0.9, 1.6]
const SURFACE_KEYS := ["TRM-BRC", "ROAD", "CURB", "KERB", "RUMBLE", "GRAVEL", "SAND", "GRASS", "GREEN", "OUT", "CONCRETE", "PITS", "CARPET", "WALL"]
const ASPHALT_KEYS := ["TRM-BRC", "ROAD"]
const VERTICAL_NORMAL := 0.7
const CAR_FRONT_HALF := 1.7
const DRIVE_SPEED := 8.0
const RETURN_SPEED := 6.0
const STATIONS_TO_DRIVE := 4

var failures := 0
var space: PhysicsDirectSpaceState3D
var line: PackedVector3Array
var race: Node3D
var car: CharacterBody3D
var ui: CanvasLayer
var steer_center := Vector2.ZERO
var steer_radius := 1.0
var gas_rect := Rect2()
var brake_rect := Rect2()
var gas_point := Vector2.ZERO
var brake_point := Vector2.ZERO

func check(ok: bool, message: String) -> void:
	print("ESCAPE ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func info(message: String) -> void:
	print("ESCAPE INFO ", message)

func _initialize() -> void:
	call_deferred("_run")

func _group_of(body: Node) -> String:
	if body == null:
		return "NONE"
	var names := String(body.get_meta("ac_surface", body.name)).to_upper()
	for key in SURFACE_KEYS:
		if key in names:
			return key
	return "OTHER"

func _ground_height(point: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 30.0, point - Vector3.UP * 30.0, 1)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return INF
	return float(hit.position.y)

func _surface_under(point: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.2, point - Vector3.UP * 3.0, 1)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return {"group": "NONE", "body": ""}
	var body := hit.collider as Node
	return {"group": _group_of(body), "body": String(body.name)}

func _is_vertical(normal: Vector3) -> bool:
	return absf(normal.y) < VERTICAL_NORMAL

# Primer obstáculo con cara vertical delante del coche, medido en la dirección de
# salida. Es la geometría que el jugador ve, no una suposición.
func _obstacle_ahead(position: Vector3, direction: Vector3) -> Dictionary:
	var ground := _ground_height(position)
	if ground == INF:
		return {"gap": INF, "body": "", "group": "NONE"}
	var best := {"gap": INF, "body": "", "group": "NONE"}
	for height_value in SCAN_HEIGHTS:
		var origin := Vector3(position.x, ground + float(height_value), position.z)
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * MAX_SCAN, 1)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		if not _is_vertical(hit.normal):
			continue
		var gap := origin.distance_to(hit.position)
		if gap < float(best["gap"]):
			best = {"gap": gap, "body": String((hit.collider as Node).name), "group": _group_of(hit.collider as Node)}
	return best

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
	brake_rect = ui._pedal_rects["brake"]
	if gas_rect.size.x <= 0.0 or brake_rect.size.x <= 0.0 or ui._viewport_size.x <= 0.0:
		push_error("La sonda de salida de pista necesita una ventana real con viewport medible")
		quit(2)
		return
	gas_point = Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5, gas_rect.position.y + gas_rect.size.y * 0.05)
	brake_point = Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5, brake_rect.end.y - 1.0)
	line = TrackScript.get_centerline()
	space = race.get_world_3d().direct_space_state

	var stations := _scan_stations()
	var widest: Array = stations.duplicate()
	widest.sort_custom(func(a, b): return float(a["gap"]) > float(b["gap"]))
	info("estaciones exploradas=%d | las mas abiertas: %s" % [stations.size(), _summary(widest.slice(0, 8))])
	var chosen := _choose_stations(stations)
	info("escapatorias elegidas para conducir: %s" % _summary(chosen))

	var results: Array = []
	for station in chosen:
		results.append(await _drive_escape(station))
	for result in results:
		print("ESCAPE_RESULT idx=%d side=%d gaps_escaneados=%.1f rumbo=%s left_asphalt=%s runoff=%s travel=%.2f obstaculo_rayo=%s(%s) a=%.1f contacto=%s(%s,a=%.1f,min_kph=%.1f) parada=%s superficies=%s" % [
			result["index"], int(result["side"]), result["scanned_gap"], result["heading_group"], str(result["left_asphalt"]),
			result["runoff_group"], result["travel"], result["path_obstacle_body"], result["path_obstacle_group"],
			result["path_obstacle_gap"], result["contact_body"], result["contact_group"], result["contact_progress"],
			result["contact_min_kph"], result["stop_reason"], result["surface_sequence"]])
		for contact in result["contacts"]:
			print("ESCAPE_CONTACT idx=%d side=%d vertical=%s body=%s group=%s a=%.2f min_kph=%.1f ticks=%d normal=%s" % [
				result["index"], int(result["side"]), str(contact["vertical"]), contact["body"], contact["group"],
				contact["progress"], contact["min_speed_kph"], contact["ticks"], contact["normal"]])
		if result["blocker_body"] != "":
			print("ESCAPE_BLOCKER idx=%d side=%d body=%s group=%s a=%.2f rayos_delante=%s" % [
				result["index"], int(result["side"]), result["blocker_body"], result["blocker_group"],
				result["blocker_progress"], result["rest_obstacle"]])
		print("ESCAPE_RETURN idx=%d recorre=%.2f surface=%s body=%s reached=%s" % [
			result["index"], result["return"]["travel"], result["return"]["group"], result["return"]["body"],
			str(result["return"]["reached"])])
	_evaluate(results)
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _scan_stations() -> Array:
	var out: Array = []
	for i in range(0, line.size(), STATION_STEP):
		var tangent := (line[(i + 3) % line.size()] - line[(i - 3 + line.size()) % line.size()]).normalized()
		var lateral := Vector3(tangent.z, 0.0, -tangent.x).normalized()
		var ground := _ground_height(line[i])
		if ground == INF:
			continue
		for side in [1.0, -1.0]:
			var direction: Vector3 = lateral * side
			var obstacle := _obstacle_ahead(Vector3(line[i].x, ground, line[i].z), direction)
			out.append({"index": i, "side": float(side), "lateral": lateral, "ground": ground,
				"gap": obstacle["gap"], "body": obstacle["body"], "group": obstacle["group"]})
	return out

func _choose_stations(stations: Array) -> Array:
	var ranked: Array = []
	for entry in stations:
		if float(entry["gap"]) == INF:
			continue
		ranked.append(entry)
	ranked.sort_custom(func(a, b): return float(a["gap"]) < float(b["gap"]))
	# Se prueban escapatorias estrechas (poco margen: cualquier muro invisible
	# apareceria enseguida) y anchas (recorrido largo de salida), repartidas por
	# toda la vuelta y sin repetir la misma zona.
	var chosen: Array = []
	var positions: Array = [0, ranked.size() / 3, ranked.size() * 2 / 3, ranked.size() - 1]
	for position in positions:
		var entry: Dictionary = ranked[clampi(int(position), 0, ranked.size() - 1)]
		var clashes := false
		for picked in chosen:
			if absi(int(picked["index"]) - int(entry["index"])) < STATION_STEP * 3:
				clashes = true
				break
		if clashes:
			continue
		chosen.append(entry)
		if chosen.size() >= STATIONS_TO_DRIVE:
			break
	return chosen

func _summary(entries: Array) -> String:
	var parts: Array = []
	for entry in entries:
		parts.append("idx=%d side=%d gap=%.1f %s(%s)" % [entry["index"], int(entry["side"]), entry["gap"], entry["body"], entry["group"]])
	return " | ".join(parts)

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

func _command(speed_target: float, steer_fraction: float) -> void:
	_hold(steer_center + Vector2(clampf(steer_fraction, -1.0, 1.0) * steer_radius, 0.0), 10)
	var error: float = speed_target - car.speed_mps
	var throttle := clampf(error * 0.35 + 0.12, 0.0, 1.0)
	var brake := clampf(-error * 0.25, 0.0, 0.7)
	var gas := _pedal_point(gas_rect, maxf(0.35, throttle))
	var slow := _pedal_point(brake_rect, brake)
	if throttle <= 0.03:
		gas = Vector2(gas.x, ui._throttle_pedal.position.y + ui._throttle_pedal.size.y + 4.0)
	if brake <= 0.03:
		slow = Vector2(slow.x, ui._brake_pedal.position.y + ui._brake_pedal.size.y + 4.0)
	_hold(gas, 11)
	_hold(slow, 12)
	ui._process(TICK)

func _drive_escape(station: Dictionary) -> Dictionary:
	var index: int = station["index"]
	var side: float = station["side"]
	var lateral: Vector3 = (station["lateral"] as Vector3) * side
	var ground: float = station["ground"]
	var start := Vector3(line[index].x, ground + 0.5, line[index].z) - lateral * 5.0
	var yaw := atan2(-lateral.x, -lateral.z)
	var spawn_ground := _ground_height(start)
	var spawn_surface := _surface_under(start)
	car.recover_to(start, yaw)
	car.velocity = Vector3.ZERO
	_hold(steer_center, 10)
	_hold(gas_point, 11)
	_hold(brake_point, 12)
	for i in 30:
		await physics_frame
	ui._handle_touch_motion(10, steer_center)
	info("SPAWN idx=%d side=%d start=%s suelo=%.2f superficie=%s tras 30 ticks pos=%s velocidad=%.2f suelo_on=%s contactos=%d gas=%.2f freno=%.2f ids=%d/%d/%d" % [
		index, int(side), str(start), spawn_ground, spawn_surface["group"], str(car.global_position),
		car.speed_mps, str(car.is_on_floor()), car.wheel_contacts, car.throttle_input, car.brake_input,
		ui._steer_touch_id, ui._throttle_touch_id, ui._brake_touch_id])

	var contacts := {}
	var contact_order: Array = []
	var surfaces: Array = []
	var travel := 0.0
	var stop_reason := "timeout"
	var low_speed_ticks := 0
	var contact_progress := 0.0
	var contact_min_kph := 0.0
	var contact_body := ""
	var contact_group := ""
	var path_obstacle := {"gap": INF, "body": "", "group": "NONE"}
	var rest_obstacle := INF
	var rest_body := ""
	var stalled := 0
	var stall_reference := 0.0
	for tick in 2400:
		var speed_before: float = car.speed_mps
		await physics_frame
		var speed_now: float = car.speed_mps
		travel = (car.global_position - start).dot(lateral)
		if tick % 12 == 0:
			var sample := _surface_under(car.global_position)
			if surfaces.is_empty() or surfaces[-1] != sample["group"]:
				surfaces.append(sample["group"])
		if tick % 4 == 0:
			var ahead := _obstacle_ahead(car.global_position, lateral)
			if float(ahead["gap"]) < float(path_obstacle["gap"]):
				path_obstacle = ahead
		for c in car.get_slide_collision_count():
			var hit := car.get_slide_collision(c)
			var body := hit.get_collider() as Node
			var name := String(body.name)
			var vertical := _is_vertical(hit.get_normal())
			if not contacts.has(name):
				contacts[name] = {"body": name, "group": _group_of(body), "vertical": vertical,
					"progress": travel, "min_speed_kph": car.speed_kph, "ticks": 0,
					"normal": str(hit.get_normal().snapped(Vector3(0.01, 0.01, 0.01)))}
				contact_order.append(name)
				if vertical and contact_body == "":
					contact_body = name
					contact_group = _group_of(body)
					contact_progress = travel
					contact_min_kph = car.speed_kph
			if vertical and contact_body == name:
				contact_min_kph = minf(contact_min_kph, car.speed_kph)
			contacts[name]["ticks"] = int(contacts[name]["ticks"]) + 1
			contacts[name]["min_speed_kph"] = minf(float(contacts[name]["min_speed_kph"]), car.speed_kph)
		if car.speed_mps < 0.5 and tick > 120:
			low_speed_ticks += 1
		else:
			low_speed_ticks = 0
		if low_speed_ticks > 60:
			stop_reason = "blocked"
			break
		# Varias toneladas contra una barrera no cambian de velocidad en un solo
		# fotograma, pero el avance se acaba: si el coche lleva dos segundos con
		# un obstáculo vertical delante y sin ganar terreno, el muro lo ha parado.
		if contact_body != "" and car.speed_mps < speed_before * 0.55 and speed_before > 3.0:
			stop_reason = "impacto_contra_barrera"
			break
		if contact_body != "" and absf(travel - stall_reference) < 0.05:
			stalled += 1
			if stalled > 150:
				stop_reason = "bloqueado_por_obstaculo"
				break
		else:
			stalled = 0
			stall_reference = travel
		if travel > MAX_SCAN:
			stop_reason = "max_distance"
			break
		_command(DRIVE_SPEED, 0.0)
		if tick % 400 == 0:
			info("TRACE idx=%d tick=%d pos=%s travel=%.2f velocidad=%.2f gas=%.2f suelo=%s contactos=%d" % [
				index, tick, str(car.global_position), travel, car.speed_mps, car.throttle_input,
				str(car.is_on_floor()), car.wheel_contacts])
	if stop_reason == "timeout":
		stop_reason = "timeout_sin_parada"
	var final_obstacle := _obstacle_ahead(car.global_position, lateral)
	rest_obstacle = float(final_obstacle["gap"])
	rest_body = String(final_obstacle["body"])
	var blocker := {"body": "", "group": "", "progress": 0.0}
	if stop_reason != "frontal_contact" and stop_reason != "max_distance" and contact_order.size() > 0:
		for name in contact_order:
			var entry: Dictionary = contacts[name]
			if bool(entry["vertical"]) and float(entry["min_speed_kph"]) < 8.0:
				blocker = {"body": name, "group": entry["group"], "progress": entry["progress"]}
				break
	var left_asphalt := false
	var runoff_group := ""
	for group_name in surfaces:
		if not ASPHALT_KEYS.has(group_name) and group_name != "NONE":
			left_asphalt = true
			runoff_group = group_name
			break
	var contact_list: Array = []
	for name in contact_order:
		contact_list.append(contacts[name])
	return {
		"index": index, "side": side, "scanned_gap": station["gap"], "heading_group": station["group"],
		"travel": travel, "left_asphalt": left_asphalt, "runoff_group": runoff_group,
		"surface_sequence": str(surfaces), "path_obstacle_body": path_obstacle["body"],
		"path_obstacle_group": path_obstacle["group"], "path_obstacle_gap": path_obstacle["gap"],
		"contact_body": contact_body, "contact_group": contact_group, "contact_progress": contact_progress,
		"contact_min_kph": contact_min_kph, "stop_reason": stop_reason, "contacts": contact_list,
		"blocker_body": blocker["body"], "blocker_group": blocker["group"], "blocker_progress": blocker["progress"],
		"rest_obstacle": rest_obstacle, "rest_body": rest_body,
		"return": await _return_to_track(lateral),
	}

func _return_to_track(lateral: Vector3) -> Dictionary:
	var start := car.global_position
	car.recover_to(start, car.rotation.y + PI)
	for i in 20:
		await physics_frame
	var travel := 0.0
	var surface := _surface_under(car.global_position)
	var reached := false
	for tick in 1800:
		await physics_frame
		travel = (car.global_position - start).dot(-lateral)
		surface = _surface_under(car.global_position)
		if tick % 12 == 0 and ASPHALT_KEYS.has(surface["group"]) and travel > 3.0:
			reached = true
			break
		_command(RETURN_SPEED, 0.0)
	return {"travel": travel, "group": surface["group"], "body": surface["body"], "reached": reached}

func _evaluate(results: Array) -> void:
	if results.is_empty():
		check(false, "hubo escapatorias que probar")
		return
	var travelled := 0.0
	var left := false
	var runoff_group := ""
	var returned := false
	for result in results:
		travelled = maxf(travelled, result["travel"])
		if result["left_asphalt"]:
			left = true
			runoff_group = result["runoff_group"]
		if bool(result["return"]["reached"]):
			returned = true
	check(left, "el coche abandona el asfalto y rueda por la escapatoria (superficie %s)" % runoff_group)
	check(travelled > 5.0, "el coche recorre la escapatoria con su propia física: %.2f m desde la trazada" % travelled)
	var line_barrier := false
	for result in results:
		for contact in result["contacts"]:
			var name := String(contact["body"]).to_lower()
			if ("line" in name or "fast_lane" in name) and "wall" not in name:
				line_barrier = true
	check(not line_barrier, "la trazada no actúa como barrera: ningún contacto procede de la línea de IA")
	var invisible := []
	var explained := []
	for result in results:
		for contact in result["contacts"]:
			if not bool(contact["vertical"]):
				continue
			var scanned := float(result["path_obstacle_gap"])
			if scanned == INF or float(contact["progress"]) > scanned - CAR_FRONT_HALF + 6.0:
				explained.append("%s (%s) a %.1f m con obstáculo visible a %.1f m" % [contact["body"], contact["group"], contact["progress"], scanned])
			else:
				invisible.append("%s (%s) a %.1f m sin nada visible delante (rayos a %.1f m)" % [contact["body"], contact["group"], contact["progress"], scanned])
		if result["stop_reason"] in ["blocked", "bloqueado_por_obstaculo", "impacto_contra_barrera"]:
			if float(result["rest_obstacle"]) <= 4.0:
				explained.append("parada ante %s a %.1f m del coche" % [result["rest_body"], result["rest_obstacle"]])
			else:
				invisible.append("el coche se detiene con %s a %.1f m y nada visible delante (%s)" % [result["blocker_body"], result["rest_obstacle"], result["blocker_group"]])
			if result["blocker_body"] == "":
				invisible.append("el coche se detiene sin contacto vertical identificable en la escapatoria %d" % result["index"])
	check(invisible.is_empty(), "ninguna colisión sale de una malla invisible: %s" % (str(invisible) if not invisible.is_empty() else "todas coinciden con geometría medida por rayos"))
	info("colisiones atribuidas a geometría visible: %s" % (str(explained) if not explained.is_empty() else "ninguna"))
	check(returned, "el coche puede volver a la pista desde la escapatoria")
