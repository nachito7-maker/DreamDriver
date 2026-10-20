extends SceneTree

# ¿El coche usa el agarre de la superficie que realmente pisa?
#
# Para cada superficie del circuito (asfalto, bordillo, hierba, grava, arena,
# escapatoria, verde, hormigón...) busca un punto donde las CUATRO ruedas pisen
# el mismo cuerpo de física, coloca allí el coche y compara el agarre que aplica
# la física con el que corresponde a esa superficie.
#
# Fuera del asfalto esto es lo que decide si el coche rueda por hierba con
# agarre de asfalto (y el HUD miente) o con el agarre real de la hierba.
#
# Uso:  Godot --headless --path . --script res://scripts/surface_grip_probe.gd

const TrackScript = preload("res://scripts/track_data.gd")
# La sonda clasifica por su cuenta para poder ejecutarse igual contra la versión
# anterior del controlador, que no expone el clasificador compartido.
const SURFACE_KEYS := ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "CONCRETE", "PITS",
	"GRAVEL", "SAND", "GRASS", "GREEN", "CARPET", "OUT"]
const WHEEL_POINTS := [Vector3(-0.85, 0, -1.5), Vector3(0.85, 0, -1.5), Vector3(-0.85, 0, 1.95), Vector3(0.85, 0, 1.95)]
const TARGETS := ["TRM-BRC", "KERB", "CURB", "RUMBLE", "GRASS", "GRAVEL", "SAND", "OUT", "GREEN", "CONCRETE", "CARPET"]
const REQUIRED := ["TRM-BRC", "KERB", "GRASS", "GRAVEL", "SAND", "OUT", "GREEN"]
const STATION_STEP := 6
const MAX_OFFSET := 45
const TOLERANCE := 0.001
# Colocaciones candidatas por superficie. La búsqueda de sitio se hace con rayos a
# cuatro puntos de rueda, pero eso sólo dice que CABEN ahí, no que el coche se
# quede: asentado sobre el bordillo el cuerpo deriva unos centímetros y en un
# bordillo de un metro (el más estrecho que aparece) la mitad de las ruedas acaba
# en el verde. Se guardan varios sitios y se acepta el primero en el que, DESPUÉS
# de asentar, las CUATRO ruedas reales pisan la superficie pedida.
const CANDIDATES_PER_TARGET := 6
const SETTLE_FRAMES := 40
# Superficies que un monoplaza NO puede pisar con las cuatro ruedas: el bordillo mide
# 1,2-3,5 m y la huella del coche es de 1,7 m de vía y 3,45 m entre ejes. Se validan
# montadas: al menos dos ruedas en la superficie y el resto en otra, con el agarre
# aplicado igual al promedio de las cuatro (cada neumático lleva el suyo).
const STRADDLE := ["KERB", "CURB", "RUMBLE"]
const STRADDLE_MIN_WHEELS := 2
# Maniobra dinámica: salir del asfalto y comparar, fotograma a fotograma, el
# agarre que aplica el coche con la superficie que pisan las cuatro ruedas.
# La estática sola no demuestra nada: el fallo aparecía en marcha, cuando el
# coche deja de figurar apoyado y el agarre se quedaba en el valor anterior.
const DRIVE_STATION := [2760, -1]
const DRIVE_TICKS := 1500
const GRACE_TICKS := 18

var failures := 0
var space: PhysicsDirectSpaceState3D
var line: PackedVector3Array
var race: Node3D
var car: CharacterBody3D

func check(ok: bool, message: String) -> void:
	print("AGARRE ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func info(message: String) -> void:
	print("AGARRE INFO ", message)

func _initialize() -> void:
	call_deferred("_run")

func _group_of(body: Node) -> String:
	if body == null:
		return "NONE"
	var label := (String(body.name) + " " + String(body.get_meta("ac_surface", ""))).to_upper()
	for key in SURFACE_KEYS:
		if key in label:
			return key
	return "OTHER"

func _ground(point: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 4.0, point - Vector3.UP * 6.0, 1)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return {"height": INF, "group": "NONE"}
	return {"height": float(hit.position.y), "group": _group_of(hit.collider as Node)}

# Superficie común a las cuatro ruedas si el coche se coloca en ese punto con
# ese rumbo; vacío si las ruedas no coinciden.
func _uniform_surface(point: Vector3, yaw: float) -> String:
	var basis := Basis(Vector3.UP, yaw)
	var found := ""
	for offset in WHEEL_POINTS:
		var ground := _ground(point + basis * offset)
		var group: String = ground["group"]
		if group == "NONE":
			return ""
		if found == "":
			found = group
		elif found != group:
			return ""
	return found

# Superficie dominante bajo las cuatro ruedas del coche, igual que la mide el
# propio controlador (mismos cuatro puntos de rueda).
# Superficie que pisa cada rueda AHORA, con los mismos cuatro puntos de rueda que usa
# el controlador. Es la única medida que vale para decidir si la colocación se sostiene.
func _wheel_groups() -> Array:
	var groups := []
	for offset in WHEEL_POINTS:
		var world: Vector3 = car.global_transform * offset
		var query := PhysicsRayQueryParameters3D.create(world + Vector3.UP, world - Vector3.UP * 1.2, 1)
		var hit := space.intersect_ray(query)
		groups.append(_group_of(hit.collider as Node) if not hit.is_empty() else "NONE")
	return groups

func _wheel_surface() -> String:
	return _dominant_of(_wheel_groups())

# Superficie mayoritaria y agarre medio de una lista de grupos de rueda. `NONE` (rayo sin
# suelo) y `OTHER` (malla sin grupo) no cuentan, igual que en el controlador.
func _dominant_of(groups: Array) -> String:
	var votes := {}
	for group in groups:
		if group == "OTHER" or group == "NONE":
			continue
		votes[group] = int(votes.get(group, 0)) + 1
	var best := ""
	var best_votes := 0
	for key in votes:
		if int(votes[key]) > best_votes:
			best_votes = int(votes[key])
			best = String(key)
	return best

func _mean_grip(groups: Array) -> float:
	var total := 0.0
	var counted := 0
	for group in groups:
		if group == "OTHER" or group == "NONE":
			continue
		total += TrackScript.get_surface_grip(String(group))
		counted += 1
	return total / float(counted) if counted > 0 else -1.0

func _drive_out_and_compare() -> void:
	var index: int = DRIVE_STATION[0]
	var side: int = DRIVE_STATION[1]
	var tangent := (line[(index + 4) % line.size()] - line[(index - 4 + line.size()) % line.size()]).normalized()
	var outward := Vector3(tangent.z, 0.0, -tangent.x).normalized() * float(side)
	var start := line[index] + Vector3.UP * 0.5
	car.recover_to(start, atan2(-outward.x, -outward.z))
	for i in 40:
		await physics_frame
	Input.action_press("throttle")
	var last_surface := ""
	var since_change := 0
	var off_ticks := 0
	var mismatches := 0
	var mismatch_run := 0
	var examples: Array = []
	var left_asphalt := false
	for tick in DRIVE_TICKS:
		await physics_frame
		var groups := _wheel_groups()
		var group := _dominant_of(groups)
		if group == "":
			continue
		if group != last_surface:
			last_surface = group
			since_change = 0
		else:
			since_change += 1
		if group != "TRM-BRC" and group != "ROAD":
			left_asphalt = true
		if not left_asphalt:
			continue
		off_ticks += 1
		# Lo que corresponde en marcha es el promedio de las ruedas, no el de la
		# superficie mayoritaria: montando el bordillo o rozando la hierba con una
		# rueda el coche ya pierde parte del agarre.
		var expected := _mean_grip(groups)
		var applied: float = car.surface_grip
		if expected < 0.0 or absf(applied - expected) <= TOLERANCE:
			mismatch_run = 0
			continue
		mismatch_run += 1
		# El controlador muestrea la superficie cada 0,08 s (unos 5 fotogramas) y la
		# rueda que cae justo en el borde del cuerpo puede discrepar un fotograma; sólo
		# cuenta como desajuste lo que se sostiene en el tiempo.
		if mismatch_run < GRACE_TICKS:
			continue
		if mismatch_run > GRACE_TICKS:
			continue
		mismatches += 1
		if examples.size() < 6:
			examples.append("%s: aplica %.2f, corresponde %.2f" % [str(groups), applied, expected])
		if mismatches == 1:
			info("primer desajuste en el fotograma %d, posición %s" % [tick, str(car.global_position.snapped(Vector3(0.1, 0.1, 0.1)))])
	Input.action_release("throttle")
	info("marcha fuera del asfalto: fotogramas=%d, desajustes de agarre=%d %s" % [off_ticks, mismatches, str(examples)])
	check(off_ticks > 240, "la maniobra recorre superficie fuera del asfalto durante al menos 2 s (%d fotogramas)" % off_ticks)
	check(mismatches == 0, "en marcha el agarre coincide con la superficie pisada (%d desajustes de %d fotogramas)" % [mismatches, off_ticks])

func _run() -> void:
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 120:
		await physics_frame
	car = race.car
	line = TrackScript.get_centerline()
	space = race.get_world_3d().direct_space_state

	var placements := {}
	var index := 0
	while index < line.size() and placements.size() < TARGETS.size() * CANDIDATES_PER_TARGET:
		var tangent := (line[(index + 4) % line.size()] - line[(index - 4 + line.size()) % line.size()]).normalized()
		var lateral := Vector3(tangent.z, 0.0, -tangent.x).normalized()
		var yaw := atan2(-tangent.x, -tangent.z)
		for offset in range(-MAX_OFFSET, MAX_OFFSET + 1, 2):
			if placements.size() >= TARGETS.size() * CANDIDATES_PER_TARGET:
				break
			var point: Vector3 = line[index] + lateral * float(offset)
			var center := _ground(point)
			if float(center["height"]) == INF:
				continue
			var group: String = center["group"]
			if not TARGETS.has(group) or int(placements.get(group, []).size()) >= CANDIDATES_PER_TARGET:
				continue
			var ground_point := Vector3(point.x, float(center["height"]) + 0.25, point.z)
			if _uniform_surface(ground_point, yaw) != group:
				continue
			if not placements.has(group):
				placements[group] = []
			placements[group].append({"point": ground_point, "yaw": yaw, "index": index, "offset": offset})
		index += STATION_STEP
	info("superficies localizadas: %s" % str(placements.keys()))

	var measured := {}
	for group in TARGETS:
		if not placements.has(group):
			continue
		# Se prueban las colocaciones candidatas hasta dar con una en la que el coche
		# asentado tenga las cuatro ruedas sobre la superficie. Si ninguna se sostiene
		# se mide la última, para que el fallo salga en el registro con sus datos.
		var entry: Dictionary = placements[group][0]
		var settled := []
		for candidate in placements[group]:
			car.recover_to(candidate["point"], candidate["yaw"])
			for i in SETTLE_FRAMES:
				await physics_frame
			settled = _wheel_groups()
			entry = candidate
			var sostiene := true
			var hitting := 0
			for wheel_group in settled:
				if String(wheel_group) == group:
					hitting += 1
				elif not STRADDLE.has(group):
					sostiene = false
					break
			if STRADDLE.has(group) and hitting < STRADDLE_MIN_WHEELS:
				sostiene = false
			if sostiene:
				break
			info("%s no se sostiene en idx=%d offset=%d (ruedas %s), se prueba otro sitio" % [
				group, int(candidate["index"]), int(candidate["offset"]), str(settled)])
		var reported := String(car.get("ground_surface")) if car.get("ground_surface") != null else ""
		var grip: float = car.surface_grip
		# Lo que corresponde: el promedio de lo que pisa cada rueda, que es la regla
		# del controlador. Con las cuatro iguales coincide con el agarre de la
		# superficie; montadas en el bordillo queda entre el bordillo y el verde.
		var expected := 0.0
		var counted := 0
		var counting := {}
		for wheel_group in settled:
			var key := String(wheel_group)
			if key == "OTHER" or key == "NONE":
				continue
			expected += TrackScript.get_surface_grip(key)
			counted += 1
			counting[key] = int(counting.get(key, 0)) + 1
		if counted > 0:
			expected /= float(counted)
		var dominant := ""
		var best_votes := 0
		for key in counting:
			if int(counting[key]) > best_votes:
				best_votes = int(counting[key])
				dominant = String(key)
		measured[group] = grip
		print("AGARRE MUESTRA grupo=%s idx=%d offset=%d informado=%s agarre=%.3f esperado=%.3f ruedas=%s" % [
			group, entry["index"], entry["offset"], reported if reported != "" else "(sin dato)", grip, expected, str(settled)])
		check(reported == dominant, "%s: la superficie informada es la mayoritaria bajo las ruedas (%s, ruedas %s)" % [group, dominant if dominant != "" else "(sin dato)", str(settled)])
		check(absf(grip - expected) < TOLERANCE, "%s aplica el agarre que pisan sus ruedas (%.3f)" % [group, expected])
		if STRADDLE.has(group):
			check(grip < 1.0 - TOLERANCE, "%s montado ya no se circula con el agarre del asfalto (%.3f)" % [group, grip])
	for group in REQUIRED:
		check(placements.has(group), "%s tiene al menos un punto alcanzable" % group)
	var off_track := ["GRASS", "GRAVEL", "SAND", "OUT", "GREEN"]
	for group in off_track:
		if measured.has(group):
			check(absf(float(measured[group]) - 1.0) > TOLERANCE, "fuera del asfalto (%s) no se circula con agarre de asfalto" % group)
	await _drive_out_and_compare()
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
