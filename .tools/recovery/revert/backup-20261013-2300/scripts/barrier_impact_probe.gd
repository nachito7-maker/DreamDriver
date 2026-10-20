extends SceneTree

# Sonda de impacto REAL contra una barrera.
#
# Elige barreras de verdad con rayos desde la trazada, coloca el coche en el
# asfalto mirando al muro, lo acelera hasta una velocidad objetivo con los
# mandos reales y mide el choque: contacto detectado, pérdida de velocidad,
# desplazamiento tras el golpe y penetración respecto a la superficie que el
# rayo midió. Distingue una colisión válida (la malla que toca es la que el rayo
# ve) de un bloqueo artificial (el coche se para contra algo que no está donde
# la geometría dice).

const TrackScript = preload("res://scripts/track_data.gd")
const TICK := 1.0 / 120.0
const STATION_STEP := 40
const MAX_SCAN := 70.0
const SCAN_HEIGHTS := [0.4, 0.9, 1.6]
const SURFACE_KEYS := ["TRM-BRC", "ROAD", "CURB", "KERB", "RUMBLE", "GRAVEL", "SAND", "GRASS", "GREEN", "OUT", "CONCRETE", "PITS", "CARPET", "WALL"]
const VERTICAL_NORMAL := 0.7
const CAR_FRONT_HALF := 1.7
const RUNS := 4
const CONTACT_OBSERVATION_TICKS := 240

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
	print("IMPACTO ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func info(message: String) -> void:
	print("IMPACTO INFO ", message)

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

func _is_vertical(normal: Vector3) -> bool:
	return absf(normal.y) < VERTICAL_NORMAL

func _obstacle_ahead(position: Vector3, direction: Vector3) -> Dictionary:
	var ground := _ground_height(position)
	if ground == INF:
		return {"gap": INF, "body": "", "group": "NONE", "point": Vector3.ZERO}
	var best := {"gap": INF, "body": "", "group": "NONE", "point": Vector3.ZERO}
	for height_value in SCAN_HEIGHTS:
		var origin := Vector3(position.x, ground + float(height_value), position.z)
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * MAX_SCAN, 1)
		var hit := space.intersect_ray(query)
		if hit.is_empty() or not _is_vertical(hit.normal):
			continue
		var gap := origin.distance_to(hit.position)
		if gap < float(best["gap"]):
			best = {"gap": gap, "body": String((hit.collider as Node).name), "group": _group_of(hit.collider as Node), "point": hit.position}
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
		push_error("La sonda de impacto necesita una ventana real con viewport medible")
		quit(2)
		return
	gas_point = Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5, gas_rect.position.y + gas_rect.size.y * 0.05)
	brake_point = Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5, brake_rect.end.y - 1.0)
	line = TrackScript.get_centerline()
	space = race.get_world_3d().direct_space_state

	var targets := _pick_barriers()
	info("barreras elegidas: %s" % _summary(targets))
	if targets.is_empty():
		check(false, "había barreras reales que probar")
		race.queue_free()
		await process_frame
		quit(1)
		return

	var speeds := [10.0, 22.0]
	var results: Array = []
	for i in mini(targets.size(), RUNS / 2 * 2):
		for speed in speeds:
			results.append(await _impact(targets[i], speed))
	for result in results:
		print("IMPACTO_RESULT idx=%d side=%d objetivo_kph=%.0f barrera_rayo=%s(%s) a=%.2f contacto=%s(%s) misma_malla=%s velocidad_choque_kph=%.1f velocidad_min_kph=%.1f velocidad_tras_0s5_kph=%.1f avance_tras_golpe=%.2f holgura_min=%.2f holgura_final=%.2f normalidad=%s" % [
			result["index"], int(result["side"]), result["target_kph"], result["obstacle_body"], result["obstacle_group"],
			result["obstacle_gap"], result["contact_body"], result["contact_group"], str(result["same_body"]),
			result["approach_kph"], result["min_kph"], result["speed_after_kph"], result["progress_after_impact"],
			result["min_clearance"], result["final_clearance"], result["contact_normal"]])
	_evaluate(results)
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _pick_barriers() -> Array:
	var candidates: Array = []
	for i in range(0, line.size(), STATION_STEP):
		var tangent := (line[(i + 3) % line.size()] - line[(i - 3 + line.size()) % line.size()]).normalized()
		var lateral := Vector3(tangent.z, 0.0, -tangent.x).normalized()
		var ground := _ground_height(line[i])
		if ground == INF:
			continue
		for side in [1.0, -1.0]:
			var direction: Vector3 = lateral * side
			var obstacle := _obstacle_ahead(Vector3(line[i].x, ground, line[i].z), direction)
			# Una barrera con recorrido suficiente para acelerar de frente, pero
			# lo bastante cerca para medir el golpe sin recorrer medio circuito.
			if obstacle["group"] != "WALL" or float(obstacle["gap"]) < 15.0 or float(obstacle["gap"]) > 45.0:
				continue
			candidates.append({"index": i, "side": float(side), "lateral": lateral, "ground": ground,
				"gap": obstacle["gap"], "body": obstacle["body"], "group": obstacle["group"], "point": obstacle["point"]})
	candidates.sort_custom(func(a, b): return float(a["gap"]) < float(b["gap"]))
	var picked: Array = []
	for entry in candidates:
		var clashes := false
		for other in picked:
			if absi(int(other["index"]) - int(entry["index"])) < STATION_STEP * 4:
				clashes = true
				break
		if clashes:
			continue
		picked.append(entry)
		if picked.size() >= RUNS / 2:
			break
	return picked

func _summary(entries: Array) -> String:
	var parts: Array = []
	for entry in entries:
		parts.append("idx=%d side=%d barrera a %.1f m %s(%s)" % [entry["index"], int(entry["side"]), entry["gap"], entry["body"], entry["group"]])
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

func _impact(station: Dictionary, target_speed: float) -> Dictionary:
	var index: int = station["index"]
	var side: float = station["side"]
	var lateral: Vector3 = (station["lateral"] as Vector3) * side
	var ground: float = station["ground"]
	var start := Vector3(line[index].x, ground + 0.5, line[index].z)
	var yaw := atan2(-lateral.x, -lateral.z)
	car.recover_to(start, yaw)
	car.velocity = Vector3.ZERO
	_hold(steer_center, 10)
	_hold(gas_point, 11)
	_hold(brake_point, 12)
	for i in 30:
		await physics_frame
	ui._handle_touch_motion(10, steer_center)
	# Medición independiente de dónde está la barrera, hecha con el coche ya
	# colocado en su sitio de salida.
	var measured := _obstacle_ahead(car.global_position, lateral)
	var wall_point: Vector3 = measured["point"]
	var approach_kph := 0.0
	var min_kph := INF
	var speed_after_kph := 0.0
	var contact_body := ""
	var contact_group := ""
	var contact_normal := Vector3.ZERO
	var contact_tick := -1
	var min_clearance := INF
	var progress_at_contact := 0.0
	var travel := 0.0
	var progress_after_impact := 0.0
	var outward_before := 0.0
	var outward_after := 0.0
	var seen_vertical := false
	for tick in 1800:
		var speed_before: float = car.speed_mps
		await physics_frame
		travel = (car.global_position - start).dot(lateral)
		var clearance := (wall_point - car.global_position).dot(lateral) - CAR_FRONT_HALF
		min_clearance = minf(min_clearance, clearance)
		if contact_tick < 0:
			for c in car.get_slide_collision_count():
				var hit := car.get_slide_collision(c)
				if not _is_vertical(hit.get_normal()):
					continue
				var body := hit.get_collider() as Node
				seen_vertical = true
				contact_body = String(body.name)
				contact_group = _group_of(body)
				contact_normal = hit.get_normal()
				contact_tick = tick
				approach_kph = speed_before * 3.6
				outward_before = car.velocity.dot(lateral)
				progress_at_contact = travel
				break
		if contact_tick >= 0:
			min_kph = minf(min_kph, car.speed_kph)
			if tick == contact_tick + 60:
				speed_after_kph = car.speed_kph
				outward_after = car.velocity.dot(lateral)
			if tick >= contact_tick + CONTACT_OBSERVATION_TICKS:
				progress_after_impact = travel - progress_at_contact
				break
		_command(target_speed, 0.0)
	if contact_tick < 0:
		# Sin contacto: se informa de hasta dónde llegó y de lo que había delante.
		progress_after_impact = travel
		min_kph = car.speed_kph
	var final_clearance := (wall_point - car.global_position).dot(lateral) - CAR_FRONT_HALF
	return {
		"index": index, "side": side, "target_kph": target_speed * 3.6,
		"obstacle_body": measured["body"], "obstacle_group": measured["group"], "obstacle_gap": measured["gap"],
		"contact_body": contact_body, "contact_group": contact_group,
		"same_body": contact_body != "" and contact_body == String(measured["body"]),
		"approach_kph": approach_kph, "min_kph": min_kph, "speed_after_kph": speed_after_kph,
		"outward_before": outward_before, "outward_after": outward_after,
		"progress_after_impact": progress_after_impact, "min_clearance": min_clearance,
		"final_clearance": final_clearance, "contact_normal": str(contact_normal.snapped(Vector3(0.01, 0.01, 0.01))),
		"contacted": contact_tick >= 0, "seen_vertical": seen_vertical,
	}

func _evaluate(results: Array) -> void:
	var contacted := 0
	var valid := 0
	var same_mesh := 0
	var penetrated := []
	var passed_through := []
	var speed_responded := 0
	var displacement_responded := 0
	var outside_wall := 0
	for result in results:
		if not bool(result["contacted"]):
			continue
		contacted += 1
		if result["contact_group"] == "WALL":
			valid += 1
		if bool(result["same_body"]):
			same_mesh += 1
		if float(result["min_clearance"]) < -0.5:
			penetrated.append("idx=%d holgura mínima %.2f m" % [result["index"], result["min_clearance"]])
		# La holgura es la distancia del paragolpes al plano del muro medido por el
		# rayo: unos centímetros negativos son el margen de contacto del motor
		# físico, no un atravesamiento.
		if float(result["final_clearance"]) < -0.25:
			passed_through.append("idx=%d holgura final %.2f m" % [result["index"], result["final_clearance"]])
		if float(result["approach_kph"]) > 15.0 and float(result["speed_after_kph"]) < float(result["approach_kph"]) * 0.6:
			speed_responded += 1
		# Tras el golpe el coche sigue pisando el acelerador contra el muro: lo que
		# mide si el impacto le paró es el avance lateral, no la velocidad final.
		if absf(float(result["progress_after_impact"])) < 3.0:
			displacement_responded += 1
		if float(result["outward_after"]) < float(result["outward_before"]) * 0.5:
			outside_wall += 1
	check(contacted == results.size() and contacted > 0, "todos los lanzamientos contra barrera terminan en contacto físico (%d/%d)" % [contacted, results.size()])
	check(valid == contacted and contacted > 0, "el contacto lo produce la barrera del circuito (grupo WALL) en %d/%d golpes" % [valid, contacted])
	check(same_mesh == contacted and contacted > 0, "la malla que golpea el coche es la misma que midió el rayo en %d/%d golpes" % [same_mesh, contacted])
	check(speed_responded == contacted and contacted > 0, "la velocidad responde al impacto (cae por debajo del 60%% en %d/%d)" % [speed_responded, contacted])
	check(displacement_responded == contacted and contacted > 0, "el avance se detiene tras el golpe (%d/%d)" % [displacement_responded, contacted])
	check(penetrated.is_empty(), "el coche no atraviesa la barrera: %s" % (str(penetrated) if not penetrated.is_empty() else "penetración por debajo de 0,5 m"))
	check(passed_through.is_empty(), "el coche queda del lado de la pista: %s" % (str(passed_through) if not passed_through.is_empty() else "el paragolpes no pasa del plano del muro"))
	info("impactos válidos=%d/%d, contactos=%d/%d" % [valid, contacted, contacted, results.size()])
