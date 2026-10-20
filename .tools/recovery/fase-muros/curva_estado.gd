extends SceneTree

# ¿Qué hace el coche en el caso «curva» de la sonda del morro?
#
# Reproduce esa situación fuera de la sonda —mismo viraje (el más cerrado que el
# coche puede tomar a 130 km/h con el límite de agarre declarado), misma colocación
# del asentamiento, misma persecución pura de 14 índices— y va publicando, cada 0,2 s,
# dónde está el coche respecto a la trazada, qué superficie pisa, cuántas ruedas tocan
# y con qué choca. Sirve para separar dos cosas que la medida en píxeles no distingue:
# que la composición de la cámara haya cambiado, o que el coche se haya ido fuera.
#
# Los dos números tienen que coincidir con los de `scripts/camera_nose_probe.gd`
# (`CURVA_AGARRE_G`, `CURVA_VELOCIDAD_KPH`, `CURVA_ASENTAMIENTO_S`); si se cambian
# allí, se cambian aquí.
#
# Uso:  Godot --headless --path . --script res://.tools/recovery/fase-muros/curva_estado.gd

const TrackScript = preload("res://scripts/track_data.gd")

const CURVA_AGARRE_G := 0.9
const CURVA_VELOCIDAD_KPH := 130.0
const CURVA_ASENTAMIENTO_S := 2.6

var line: PackedVector3Array
var car: CharacterBody3D

func _initialize() -> void:
	call_deferred("_run")

func _nearest(from: int) -> int:
	var best := from
	var best_distance := INF
	for offset in range(-25, 26):
		var at := wrapi(from + offset, 0, line.size())
		var distance := Vector2(line[at].x - car.global_position.x, line[at].z - car.global_position.z).length()
		if distance < best_distance:
			best_distance = distance
			best = at
	return best

func _curvature(at: int) -> float:
	var back := line[(at - 25 + line.size()) % line.size()]
	var here := line[at]
	var ahead := line[(at + 25) % line.size()]
	var v1 := Vector2(here.x - back.x, here.z - back.z).normalized()
	var v2 := Vector2(ahead.x - here.x, ahead.z - here.z).normalized()
	return v1.cross(v2) / 25.0

func _curva_viable(kph: float) -> Dictionary:
	var v := kph / 3.6
	var k_max := CURVA_AGARRE_G * 9.81 / (v * v)
	var mejor := 0
	var mejor_k := 0.0
	for at in range(200, line.size() - 200, 5):
		var k := absf(_curvature(at))
		if k <= k_max and k > mejor_k and _curvature(at) * _curvature(at + 100) > 0.0:
			mejor_k = k
			mejor = at
	return {"indice": mejor, "k": mejor_k}

func _press_steer(steer: float) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if steer > 0.001:
		Input.action_press("steer_right", clampf(steer, 0.0, 1.0))
	elif steer < -0.001:
		Input.action_press("steer_left", clampf(-steer, 0.0, 1.0))

func _step(target_kph: float, nearest: int) -> void:
	var error: float = target_kph - car.speed_kph
	if error > 1.0:
		Input.action_press("throttle", clampf(error / 40.0, 0.15, 1.0))
		Input.action_release("brake")
	elif error < -1.0:
		Input.action_press("brake", clampf(-error / 40.0, 0.1, 1.0))
		Input.action_release("throttle")
	else:
		Input.action_release("throttle")
		Input.action_release("brake")
	var target := line[mini(line.size() - 1, nearest + 14)]
	var to_target := target - car.global_position
	var desired := atan2(-to_target.x, -to_target.z)
	var heading := wrapf(desired - car.rotation.y, -PI, PI)
	_press_steer(clampf(-heading * 1.6, -1.0, 1.0))

func _choques() -> String:
	var texto := ""
	for c in car.get_slide_collision_count():
		var cuerpo := car.get_slide_collision(c).get_collider() as Node
		texto += "%s " % String(cuerpo.name).replace("barcelona_remastered_physics_obj__", "")
	if texto == "":
		return "(ninguno)"
	return texto

func _steps_for(metros: float) -> int:
	var travelled := 0.0
	var steps := 0
	var i := 0
	while travelled < metros and i < line.size() - 2:
		travelled += line[i].distance_to(line[i + 1])
		i += 1
		steps += 1
	return steps

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	for i in 60:
		await physics_frame
	car = race.car
	line = TrackScript.get_centerline()
	var kph := CURVA_VELOCIDAD_KPH
	var viables := _curva_viable(kph)
	var k: float = float(viables["k"])
	if k <= 0.0:
		print("ESTADO FALLA no hay ningún viraje del trazado que se pueda tomar a %.0f km/h con %.1f g"
			% [kph, CURVA_AGARRE_G])
		quit(1)
		return
	# Igual que la sonda: se suelta el coche lo que se recorre durante la transición
	# de vista más el asentamiento, para que éste termine DENTRO del viraje.
	var espera: float = float(race.nose_switch_seconds) + 0.15
	var metros: float = kph / 3.6 * (espera + CURVA_ASENTAMIENTO_S)
	var index: int = maxi(0, int(viables["indice"]) - _steps_for(metros))
	var tangent := (line[(index + 1) % line.size()] - line[index]).normalized()
	car.recover_to(line[index] + Vector3.UP * 0.2, atan2(-tangent.x, -tangent.z))
	car.velocity = tangent * (kph / 3.6)
	car.speed_mps = kph / 3.6
	car.speed_kph = kph
	print("ESTADO curva: estación del viraje=%d curvatura=%.5f (radio %.0f m) se suelta en la estación %d (%.0f m antes)" % [
		int(viables["indice"]), k, 1.0 / maxf(k, 1e-9), index, metros])
	print("ESTADO a %.0f km/h en ese viraje el coche necesita %.2f g de agarre lateral" % [
		kph, (kph / 3.6) * (kph / 3.6) * k / 9.81])
	var nearest := index
	for tick in 624:
		await physics_frame
		nearest = _nearest(nearest)
		_step(kph, nearest)
		if tick % 24 == 0:
			var t := (line[(nearest + 3) % line.size()] - line[(nearest - 3 + line.size()) % line.size()]).normalized()
			var lateral := (car.global_position - line[nearest]).dot(Vector3(t.z, 0.0, -t.x).normalized())
			print("ESTADO t=%.1f estacion=%d desvio=%+.2f m %.1f km/h superficie=%s ruedas=%d suelo=%s choques=%s" % [
				tick / 120.0, nearest, lateral, car.speed_kph, car.ground_surface,
				car.wheel_contacts, str(car.is_on_floor()), _choques()])
	race.queue_free()
	await process_frame
	quit(0)
