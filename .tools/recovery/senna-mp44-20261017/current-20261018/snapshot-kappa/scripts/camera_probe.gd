extends SceneTree

# ============================================================================
# Sonda de la cámara de persecución (ajuste por velocidad).
#
# Cada caso se prepara colocando el coche al principio de la recta inicial del
# circuito con la velocidad del caso y conduciéndolo con gas, freno y dirección
# REALES durante 2,4 s (14 veces la constante de tiempo más lenta): la cámara
# parte del estado del caso anterior y tiene que asentarse sola. La medida se
# toma cuando la velocidad se ha mantenido dentro de ±2,5 km/h.
#
# Mide, en cada caso:
#   * distancia de la cámara al coche (3D, sobre el plano y de diseño),
#   * parámetro de velocidad, altura de la cámara y FOV,
#   * el tamaño del coche EN PANTALLA, proyectando la caja de su modelo con la
#     cámara real (`unproject_position`), en píxeles y como fracción del alto,
#   * si el coche queda cortado por algún borde y con cuánto margen,
#   * si hay pista visible por delante (trazada a 20, 40 y 60 m),
#   * si algo se interpone entre el coche y la cámara o si la cámara está
#     metida dentro del entorno,
#   * la transición: salto máximo por fotograma, cambios de sentido y rebose.
#
# Deja dos capturas por caso —`<caso>-coche.png` y `<caso>-fondo.png`— que son
# el MISMO fotograma con el coche visible y oculto. Su diferencia es la silueta
# del coche medida en píxeles sin depender de ningún color: eso lo comprueba
# `.tools/recovery/camera_pixels.py` sobre los archivos, no sobre mis cuentas.
#
# La sonda TIENE DIENTES: sale con código distinto de cero si con la cámara
# nueva la distancia no decrece al acelerar, si el coche no crece en pantalla,
# si se sale del encuadre, si la cámara se mete en el entorno o si la transición
# da saltos. Con `-- legacy` mide la fórmula anterior con el mismo instrumento y
# comprueba lo contrario (que la distancia crece con la velocidad), que es la
# confirmación medida de la causa.
#
# Uso:
#   "$GODOT" --path . --script scripts/camera_probe.gd
#   "$GODOT" --path . --script scripts/camera_probe.gd -- legacy
# ============================================================================

const TrackScript = preload("res://scripts/track_data.gd")

const ROOT_DIR := "res://.tools/recovery/fase-camara"
# El lienzo de medida es EXACTAMENTE el del teléfono: la ventana del anfitrión
# no da 1080 px de alto, así que la escena se dibuja en un SubViewport de
# 2400x1080. Así las capturas del anfitrión y las del dispositivo son la misma
# rejilla y el tamaño del coche se puede comparar sin hablar de resoluciones.
const FRAME_W := 2400
const FRAME_H := 1080
const TICKS := 120.0                     # physics_ticks_per_second del proyecto

# Velocidades de los casos, en km/h. 107 y 191 son las dos que el usuario
# fotografió (191 es además el techo real del coche en este circuito).
const CASES := [
	{"id": "50", "kph": 50.0},
	{"id": "100", "kph": 100.0},
	{"id": "107", "kph": 107.0},
	{"id": "150", "kph": 150.0},
	{"id": "191", "kph": 191.0},
	{"id": "200", "kph": 200.0},
]
# Subconjunto con el que se comprueba el orden (el resto es información extra).
const ORDERED := ["parado", "50", "100", "150", "200"]
const BRAKE_STOPS := [150.0, 100.0, 50.0]

# Criterios declarados (los mismos para el antes y el después).
const SPEED_TOLERANCE_KPH := 2.5      # margen para dar la velocidad por alcanzada
const SETTLE_S := 2.4                 # ≥ 4,3·τ (τ máximo 0,55 s): el parámetro converge
const SAMPLE_S := 0.4                 # ventana en la que se exige que no vibre
const STEADY_MAX_M := 0.05            # recorrido de la distancia dentro de esa ventana
const STEP_MIN_M := 0.5               # cuánto tiene que bajar la distancia por escalón
const DESIGN_TOLERANCE_M := 0.25      # distancia aplicada contra la de diseño
const FRAME_MIN_MARGIN_PX := 20.0     # ningún borde debe cortar el coche
const SIZE_GROWTH_MIN := 1.03         # cada caso, al menos 3 % más grande que el anterior
const SIZE_TOTAL_MIN := 1.45          # y a 200 km/h, 45 % más grande que parado
const MIN_HEIGHT_M := 2.30            # altura mínima de la cámara sobre el coche
const MAX_STEP_PER_FRAME_M := 0.10    # el diseño mueve la cámara a 7,6 m/s como mucho
const MAX_TRANSITION_FLIPS := 3       # acercarse/alejarse debe ser monótono
const BRAKE_MAX_STEP_M := 0.10        # ídem al abrirse tras frenar
const BRAKE_MAX_FLIPS := 6
const ABORT_LATERAL_M := 12.0         # fuera de la trazada: el caso no vale
const START_OFFSET_M := 60.0          # dónde se prepara cada caso (recta inicial)

var race: Node3D
var car: CharacterBody3D
var cam: Camera3D
var view: SubViewport
var line: PackedVector3Array
var nearest := 0
var legacy := false
var out_dir := ROOT_DIR
var legacy_node: Node = null

var casos: Array = []                    # medidas por caso
var transiciones: Array = []             # medidas de cada asentamiento
var _brake_series: Array = []            # fotograma a fotograma de la frenada
var _last_usec := 0                      # reloj real, para detectar paradas del motor
var errores: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	legacy = "legacy" in OS.get_cmdline_user_args()
	out_dir = ROOT_DIR + ("/antes" if legacy else "")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir + "/capturas"))
	# Lienzo de medida: SubViewport de 2400x1080, el mismo que el teléfono.
	view = SubViewport.new()
	view.name = "Lienzo de medida 2400x1080"
	view.size = Vector2i(FRAME_W, FRAME_H)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	view.add_child(race)
	Engine.max_fps = 120
	for i in 300:
		await physics_frame
	car = race.car
	cam = race.camera
	line = TrackScript.get_centerline()
	nearest = 0
	if legacy:
		legacy_node = _LegacyCamera.new()
		legacy_node.car = car
		legacy_node.cam = cam
		# Después de race.gd en las DOS fases: race resuelve su cámara en el paso de
		# física y la anterior tiene que quedar por encima antes de dibujar. Cuando
		# el motor recupera tiempo atrasado mete varios pasos de física seguidos sin
		# fase de dibujado entre ellos, y sin esto la captura se hace con la cámara
		# nueva en esos fotogramas.
		legacy_node.set_process(false)
		legacy_node.process_physics_priority = 20
		view.add_child(legacy_node)
	print("CAMARA modo=%s lienzo=%dx%d (viewport %dx%d) camara=%s" % [
		"anterior" if legacy else "nueva", view.size.x, view.size.y,
		root.size.x, root.size.y, str(cam.get_parent().name)])
	# La medida se lee de la textura del SubViewport, así que la ventana del
	# anfitrión tiene que estar dibujando: si queda tapada, macOS puede dejar de
	# pintarla y la textura se queda con el fotograma anterior (las capturas de
	# todos los casos salen idénticas). Se trae al frente una vez al empezar, y
	# `_shot_pair` vuelve a hacerlo si detecta un lienzo congelado.
	DisplayServer.window_move_to_foreground()
	_curvature_profile()

	await _run_case({"id": "parado", "kph": 0.0})
	for caso in CASES:
		await _run_case(caso)
	await _brake_leg()
	await _anticollision_case()

	_verdict()
	_write_report()
	race.queue_free()
	await process_frame
	quit(0 if errores.is_empty() else 1)

# --- conducción --------------------------------------------------------------

# Coloca el coche al principio de la recta con la velocidad del caso. Es la
# condición inicial; a partir de ahí conduce el controlador del juego con las
# entradas reales del mapa de acciones.
func _place_at_start(kph: float) -> void:
	await _place_at(_index_at_distance(START_OFFSET_M), kph, 0.0)

func _place_at(index: int, kph: float, offset: float) -> void:
	var tangent := (line[(index + 1) % line.size()] - line[index]).normalized()
	var right := Vector3(-tangent.z, 0.0, tangent.x).normalized()
	car.recover_to(line[index] + right * offset + Vector3.UP * 0.2, atan2(-tangent.x, -tangent.z))
	nearest = index
	car.velocity = tangent * (kph / 3.6)
	car.speed_mps = kph / 3.6
	car.speed_kph = kph
	for i in 8:
		Input.action_release("throttle")
		Input.action_release("brake")
		_press_steer(0.0)
		await physics_frame

# Asentamiento: conduce `seconds` a la velocidad pedida. Devuelve las medidas de
# la transición (salto máximo por fotograma, cambios de sentido, rebose).
func _settle(target_kph: float, seconds: float) -> Dictionary:
	var last := _flat_distance()
	var distances: Array = []
	var flips := 0
	var previous_sign := 0
	var lowest := last
	var highest := last
	var out_of_tolerance := 0
	var blocked_ticks := 0
	var stalled_ticks := 0
	var free_steps: Array = []
	var elapsed := 0.0
	_last_usec = Time.get_ticks_usec()
	while elapsed < seconds:
		_step_controls(target_kph)
		await physics_frame
		var delta := _real_dt()
		var distance := _flat_distance()
		distances.append(distance)
		var step := distance - last
		if _stalled(delta):
			stalled_ticks += 1
		elif _anticollision_blocked():
			blocked_ticks += 1
		else:
			free_steps.append(step)
		lowest = minf(lowest, distance)
		highest = maxf(highest, distance)
		var sign := 0
		if absf(step) > 0.005:
			sign = 1 if step > 0.0 else -1
		if sign != 0:
			if previous_sign != 0 and sign != previous_sign:
				flips += 1
			previous_sign = sign
		if absf(car.speed_kph - target_kph) > SPEED_TOLERANCE_KPH and target_kph > 0.0:
			out_of_tolerance += 1
		last = distance
		elapsed += 1.0 / TICKS
	# Salto mayor entre fotogramas consecutivos: es el criterio de "sin saltos".
	# Los fotogramas en los que el muro obliga a acortar se miden aparte: la
	# anticolisión es una protección y va rápida a propósito.
	var biggest := 0.0
	for i in range(1, distances.size()):
		biggest = maxf(biggest, absf(float(distances[i]) - float(distances[i - 1])))
	var biggest_free := 0.0
	for step in free_steps:
		biggest_free = maxf(biggest_free, absf(float(step)))
	# Cuánto tarda la distancia aplicada en quedarse dentro de 5 cm de su valor
	# final: mide el tiempo de asentamiento real, muro incluido.
	var settle_ticks := distances.size()
	for i in distances.size():
		var stable := true
		for j in range(i, distances.size()):
			if absf(float(distances[j]) - float(distances[distances.size() - 1])) > 0.05:
				stable = false
				break
		if stable:
			settle_ticks = i
			break
	# Ventana final: es donde se exige que la distancia ya esté quieta. El
	# recorrido completo sirve para comprobar que no se sale de los topes.
	var final_min := INF
	var final_max := -INF
	var window := int(SAMPLE_S * TICKS)
	for i in range(maxi(0, distances.size() - window), distances.size()):
		final_min = minf(final_min, float(distances[i]))
		final_max = maxf(final_max, float(distances[i]))
	return {
		"salto_maximo_m": biggest,
		"salto_maximo_sin_muro_m": biggest_free,
		"tics_hasta_estabilizar": settle_ticks,
		"tics_con_muro": blocked_ticks,
		"tics_estancados": stalled_ticks,
		"cambios_de_sentido": flips,
		"distancia_minima_m": lowest,
		"distancia_maxima_m": highest,
		"distancia_final_min_m": final_min,
		"distancia_final_max_m": final_max,
		"fuera_de_tolerancia_tics": out_of_tolerance,
	}

# El mismo rayo que usa la anticolisión de la cámara: si toca, es que hay
# geometría entre el coche y dónde iría la cámara.
func _anticollision_blocked() -> bool:
	var origin: Vector3 = car.global_position + Vector3.UP * race.camera_aim_height_m
	var eye: Vector3 = cam.global_position
	var ray := PhysicsRayQueryParameters3D.create(origin, eye, 1)
	return not car.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

# Perseguidor puro sobre la trazada + control de velocidad con gas y freno.
func _step_controls(target_kph: float) -> void:
	var point := _point_ahead(_steer_lookahead())
	var local := car.to_local(point)
	var alpha := atan2(local.x, -local.z)
	var wheel_angle := atan2(2.0 * car.wheelbase_m * sin(alpha), _steer_lookahead())
	_press_steer(clampf(wheel_angle / maxf(_steering_max(), 0.0001), -1.0, 1.0))
	var error: float = target_kph / 3.6 - car.speed_mps
	# Con un punto de gas fijo mantenido, el mando no se queda sin pedal cuando
	# la velocidad ya es la pedida: sólo corrige alrededor de él.
	Input.action_press("throttle", clampf(0.06 + error * 0.25, 0.0, 1.0))
	Input.action_press("brake", clampf(-error * 0.12, 0.0, 0.9))
	nearest = _nearest(nearest)

func _steer_lookahead() -> float:
	return 10.0 + car.speed_mps * 0.9

func _steering_max() -> float:
	return lerpf(car.steering_at_low_speed_rad, car.steering_at_high_speed_rad,
		pow(clampf(car.speed_mps / 100.0, 0.0, 1.0), 0.68))

func _press_steer(steer: float) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if steer > 0.001:
		Input.action_press("steer_right", clampf(steer, 0.0, 1.0))
	elif steer < -0.001:
		Input.action_press("steer_left", clampf(-steer, 0.0, 1.0))

func _point_ahead(distance: float) -> Vector3:
	var walked := 0.0
	var index := nearest
	for i in 500:
		var next := (index + 1) % line.size()
		walked += line[index].distance_to(line[next])
		index = next
		if walked >= distance:
			break
	return line[index]

func _index_at_distance(distance: float) -> int:
	var walked := 0.0
	var index := 0
	for i in line.size():
		var next := (index + 1) % line.size()
		walked += line[index].distance_to(line[next])
		index = next
		if walked >= distance:
			break
	return index

func _nearest(from: int) -> int:
	var best := from
	var best_distance := INF
	for offset in range(-25, 26):
		var at := wrapi(from + offset, 0, line.size())
		var d := Vector2(line[at].x - car.global_position.x, line[at].z - car.global_position.z).length_squared()
		if d < best_distance:
			best_distance = d
			best = at
	return best

# --- casos y medidas ---------------------------------------------------------

func _run_case(caso: Dictionary) -> void:
	var target: float = caso["kph"]
	await _place_at_start(target)
	var transition := await _settle(target, SETTLE_S)
	var steady: bool = await _sample_case(target, SAMPLE_S)
	var entry: Dictionary = _measure()
	entry["id"] = caso["id"]
	entry["objetivo_kph"] = target
	entry["alcanzado"] = absf(car.speed_kph - target) <= SPEED_TOLERANCE_KPH
	entry["estable"] = steady
	_copy_transition(entry, transition)
	entry["asentado"] = float(transition["distancia_final_max_m"]) - float(transition["distancia_final_min_m"]) <= STEADY_MAX_M
	casos.append(entry)
	transiciones.append({"id": caso["id"], "velocidad_kph": car.speed_kph, "transicion": transition})
	await _shot_pair("%s/capturas/%s" % [out_dir, caso["id"]])
	print("CAMARA caso=%-6s objetivo=%3.0f real=%6.1f dist=%6.3f m (diseno %6.3f) altura=%.3f m pantalla=%.3f del alto (%.0f x %.0f px) margen=%.0f px salto=%.4f m vueltas=%d" % [
		caso["id"], target, car.speed_kph, entry["distancia_plano_m"], entry["distancia_diseno_m"],
		entry["altura_m"], entry["alto_fraccion"], entry["ancho_px"], entry["alto_px"],
		entry["margen_min_px"], entry["transicion_salto_maximo_m"], entry["transicion_cambios_de_sentido"]])

# Ventana corta en la que se exige que la distancia aplicada no vibre.
func _sample_case(target: float, seconds: float) -> bool:
	var distances: Array = []
	var elapsed := 0.0
	while elapsed < seconds:
		_step_controls(target)
		await physics_frame
		distances.append(_flat_distance())
		elapsed += 1.0 / TICKS
	if distances.is_empty():
		return false
	var lowest: float = distances[0]
	var highest: float = distances[0]
	for value in distances:
		lowest = minf(lowest, value)
		highest = maxf(highest, value)
	return (highest - lowest) <= STEADY_MAX_M

func _measure() -> Dictionary:
	var base := car.global_position
	var corners := _car_box_corners()
	var box := AABB(corners[0], Vector3.ZERO)
	for i in 8:
		box = box.expand(corners[i])
	var rect := Rect2()
	var first := true
	var behind := 0
	for i in 8:
		var corner: Vector3 = corners[i]
		if cam.is_position_behind(corner):
			behind += 1
			continue
		var projected := cam.unproject_position(corner)
		if first:
			rect = Rect2(projected, Vector2.ZERO)
			first = false
		else:
			rect = rect.expand(projected)
	var margins := [rect.position.x, rect.position.y, FRAME_W - rect.end.x, FRAME_H - rect.end.y]
	var worst := INF
	for margin in margins:
		worst = minf(worst, float(margin))
	var outside := 0
	if not first and (rect.position.x < 0.0 or rect.position.y < 0.0
			or rect.end.x > FRAME_W or rect.end.y > FRAME_H):
		outside = 1
	return {
		"velocidad_kph": car.speed_kph,
		"velocidad_m_s": car.speed_mps,
		"distancia_3d_m": cam.global_position.distance_to(base),
		"distancia_plano_m": _flat_distance(),
		"distancia_diseno_m": _design_distance(),
		"distancia_minima_m": race.camera_min_distance_m,
		"distancia_aplicada_m": race._camera_distance,
		"altura_m": cam.global_position.y - base.y,
		"blend": race._camera_blend,
		"fov": cam.fov,
		"ancho_px": rect.size.x,
		"alto_px": rect.size.y,
		"alto_fraccion": rect.size.y / float(FRAME_H),
		"ancho_fraccion": rect.size.x / float(FRAME_W),
		"margen_min_px": worst,
		"fuera_del_cuadro": outside,
		"esquinas_detras": behind,
		"caja_altura_m": box.size.y,
		"caja_largo_m": box.size.z,
		"caja_ancho_m": box.size.x,
		"adelante": _ahead_visibility(),
		"bloqueos": _occlusion(),
		"lateral_m": _lateral_error(),
	}

# Distancia que DEBE tener la cámara: la de la fórmula nueva (del parámetro
# filtrado) o, en modo anterior, el offset más v/λ —la causa que se midió—.
func _design_distance() -> float:
	if legacy:
		return 9.0 + car.speed_mps / 6.0
	return lerpf(race.camera_distance_stopped_m, race.camera_distance_fast_m, race._camera_blend)

func _copy_transition(entry: Dictionary, transition: Dictionary) -> void:
	for key in transition:
		entry["transicion_" + key] = transition[key]

func _flat_distance() -> float:
	var offset := cam.global_position - car.global_position
	return Vector2(offset.x, offset.z).length()

func _lateral_error() -> float:
	var point := line[nearest]
	return Vector2(point.x - car.global_position.x, point.z - car.global_position.z).length()

# Las ocho esquinas, en el mundo, de la caja envolvente del coche EN SU PROPIO
# sistema. Se calcula en el sistema del coche a propósito: una caja alineada con
# los ejes del MUNDO, con el coche girado, mide hasta 5,8 m de ancho en lugar de
# 2,15 — la caja del mundo no es el coche, es el coche visto por una caja.
func _car_box_corners() -> Array:
	var box := AABB()
	var first := true
	var to_car := car.global_transform.affine_inverse()
	for node in car.model_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh == null or mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var local := mesh.get_aabb()
		var relative := to_car * mesh.global_transform
		for i in 8:
			var corner: Vector3 = relative * local.get_endpoint(i)
			if first:
				box = AABB(corner, Vector3.ZERO)
				first = false
			else:
				box = box.expand(corner)
	var corners := []
	for i in 8:
		corners.append(car.global_transform * box.get_endpoint(i))
	return corners

# Pista visible por delante: la trazada a 20, 40 y 60 m tiene que caer dentro.
func _ahead_visibility() -> Dictionary:
	var out := {}
	for distance in [20.0, 40.0, 60.0]:
		var point := _point_ahead(distance)
		var behind := cam.is_position_behind(point)
		var projected := cam.unproject_position(point)
		out[str(int(distance))] = {
			"detras": behind,
			"dentro": (not behind) and projected.x >= 0.0 and projected.x <= FRAME_W
				and projected.y >= 0.0 and projected.y <= FRAME_H,
			"x": projected.x,
			"y": projected.y,
		}
	return out

# ¿Hay algo entre el coche y la cámara? ¿Está la cámara enterrada en un muro?
func _occlusion() -> Dictionary:
	var space := car.get_world_3d().direct_space_state
	var reference: Vector3 = car.global_position + Vector3.UP * race.camera_aim_height_m
	var ray := PhysicsRayQueryParameters3D.create(reference, cam.global_position, 1)
	var hit := space.intersect_ray(ray)
	var buried := 0
	var directions := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]
	for direction in directions:
		var short_ray := PhysicsRayQueryParameters3D.create(cam.global_position,
			cam.global_position + direction * 0.6, 1)
		if not space.intersect_ray(short_ray).is_empty():
			buried += 1
	return {
		"interpuesto": not hit.is_empty(),
		"paredes_alrededor": buried,
	}

# --- capturas ---------------------------------------------------------------

# El mismo fotograma dos veces: con el coche y sin él. Congelando la simulación
# (delta cero) lo único que cambia entre las dos imágenes es el modelo, así que
# la diferencia ES la silueta del coche en píxeles.
# El fotograma se congela PARANDO los dos nodos que se mueven (el coche y la
# carrera), no bajando `time_scale`: al devolver `time_scale` a 1, el motor
# entrega un delta enorme y la cámara da un salto de dos o tres décimas en un
# fotograma que no es del juego, es de la prueba.
func _set_frozen(frozen: bool) -> void:
	race.set_physics_process(not frozen)
	car.set_physics_process(not frozen)
	# En modo anterior la cámara tiene su propio nodo: si siguiera resolviéndose
	# mientras el coche está congelado, se movería entre las dos capturas y la
	# diferencia saldría en toda la imagen.
	if legacy_node != null:
		legacy_node.set_physics_process(not frozen)

# Fotograma estancado: escribir cada PNG de 2400x1080 bloquea el hilo principal
# unas décimas y, al volver, el motor recupera el tiempo atrasado dando varios
# pasos de física de golpe. La distancia recorre en ese hueco lo que habría
# recorrido en los fotogramas que no existieron: no es un salto del juego, es
# del cronómetro de la prueba, y por eso se mide y se excluye.
func _real_dt() -> float:
	var now := Time.get_ticks_usec()
	var delta := float(now - _last_usec) / 1000000.0
	_last_usec = now
	return delta

func _stalled(delta: float) -> bool:
	return delta > 2.0 / TICKS

func _shot_pair(stem: String) -> void:
	_set_frozen(true)
	# Entre las dos capturas lo único que cambia es el modelo: si la rejilla no
	# nota nada, no se está fotografiando el coche y la silueta no se puede medir.
	# Se cuenta en muestras (una de cada 36 píxeles), no en fracción: a 200 km/h
	# con la cámara anterior el coche ocupa muy poco y una fracción lo dejaría
	# fuera. La silueta exacta la mide `camera_pixels.py` sobre el PNG entero.
	var changed := 0
	for intento in 2:
		await _render()
		await _grab(stem + "-coche.png")
		car.model_root.visible = false
		await _render()
		changed = await _grab(stem + "-fondo.png")
		car.model_root.visible = true
		if changed >= 20:
			break
		# Las dos capturas salen IDÉNTICAS: no es que el coche sea pequeño, es
		# que el lienzo no se ha vuelto a dibujar entre una y otra. En macOS una
		# ventana tapada puede dejar de pintarse y la textura del SubViewport se
		# queda con el fotograma anterior (comprobado: cuatro PNG con el mismo
		# SHA-256, de casos distintos). Se trae la ventana al frente y se repite
		# la pareja antes de dar el caso por perdido.
		print("CAMARA lienzo congelado en %s (%d muestras): se trae la ventana al frente y se repite" % [stem, changed])
		DisplayServer.window_move_to_foreground()
		await _render()
	_set_frozen(false)
	await _render()
	if changed < 20:
		errores.append("las capturas de %s no distinguen el coche del fondo (%d muestras): el lienzo no se está volviendo a dibujar" % [stem, changed])

# Fracción de la rejilla muestreada que cambia respecto al fotograma anterior:
# comprobación barata de que se está capturando algo y de que ocultar el coche
# cambia la imagen.
var _previous_luma: PackedFloat32Array = PackedFloat32Array()

func _grab(path: String) -> int:
	for i in 3:
		await process_frame
	var image: Image = view.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		errores.append("no se pudo guardar %s (error %d)" % [path, error])
		return 0
	var luma := PackedFloat32Array()
	for y in range(0, image.get_height(), 6):
		for x in range(0, image.get_width(), 6):
			luma.append(image.get_pixel(x, y).get_luminance())
	var changed := 0
	if _previous_luma.size() == luma.size():
		for i in luma.size():
			if absf(luma[i] - _previous_luma[i]) > 0.05:
				changed += 1
	_previous_luma = luma
	return changed

func _render() -> void:
	for i in 3:
		await process_frame

# --- desaceleración ----------------------------------------------------------

func _brake_leg() -> void:
	await _place_at_start(CASES[CASES.size() - 1]["kph"])
	var index := 0
	var last := _flat_distance()
	var max_step := 0.0
	var flips := 0
	var previous_sign := 0
	var opening := 0.0
	var first_distance := last
	var max_step_at := {"velocidad_kph": 0.0, "distancia_m": 0.0}
	var blocked_ticks := 0
	var stalled_ticks := 0
	var series: Array = []
	var elapsed := 0.0
	_last_usec = Time.get_ticks_usec()
	while elapsed < 30.0:
		Input.action_press("throttle", 0.0)
		Input.action_press("brake", 1.0)
		nearest = _nearest(nearest)
		_press_steer(_brake_steer())
		await physics_frame
		var distance := _flat_distance()
		opening = distance - first_distance
		var step := distance - last
		var delta := _real_dt()
		var blocked := _anticollision_blocked()
		if _stalled(delta):
			stalled_ticks += 1
		elif blocked:
			blocked_ticks += 1
		if absf(step) > max_step and not blocked and not _stalled(delta):
			max_step = absf(step)
			max_step_at = {"velocidad_kph": car.speed_kph, "distancia_m": distance}
		var sign := 0
		if absf(step) > 0.005:
			sign = 1 if step > 0.0 else -1
		if sign != 0:
			if previous_sign != 0 and sign != previous_sign:
				flips += 1
			previous_sign = sign
		last = distance
		series.append({
			"t": snappedf(elapsed, 0.001), "kph": snappedf(car.speed_kph, 0.01),
			"plano_m": snappedf(distance, 0.0001), "aplicada_m": snappedf(race._camera_distance, 0.0001),
			"diseno_m": snappedf(_design_distance(), 0.0001), "blend": snappedf(race._camera_blend, 0.0001),
			"muro": blocked, "dt_real": snappedf(delta, 0.0001),
		})
		elapsed += 1.0 / TICKS
		while index < BRAKE_STOPS.size() and car.speed_kph <= BRAKE_STOPS[index]:
			var entry: Dictionary = _measure()
			entry["id"] = "frenada-%d" % int(BRAKE_STOPS[index])
			entry["objetivo_kph"] = BRAKE_STOPS[index]
			entry["alcanzado"] = true
			entry["estable"] = true
			entry["desacelerando"] = true
			# En los casos de frenada la captura es un instante de una rampa, no un
			# asentamiento: la distancia del momento vale como su propio mínimo y
			# máximo, y el salto y las vueltas los mide el tramo completo.
			_copy_transition(entry, {
				"salto_maximo_m": max_step, "cambios_de_sentido": flips,
				"distancia_minima_m": entry["distancia_plano_m"],
				"distancia_maxima_m": entry["distancia_plano_m"],
				"distancia_final_min_m": entry["distancia_plano_m"],
				"distancia_final_max_m": entry["distancia_plano_m"],
				"fuera_de_tolerancia_tics": 0,
			})
			entry["asentado"] = true
			casos.append(entry)
			await _shot_pair("%s/capturas/frenada-%d" % [out_dir, int(BRAKE_STOPS[index])])
			print("CAMARA frenada a %6.1f km/h: dist=%6.3f m pantalla=%.3f del alto [%s]" % [
				car.speed_kph, entry["distancia_plano_m"], entry["alto_fraccion"], entry["id"]])
			index += 1
		if car.speed_kph < 1.0:
			break
	# Tras parar, la cámara tiene que volver sola a la distancia de parado.
	var at_rest := await _settle(0.0, 5.0)
	var final: Dictionary = _measure()
	final["id"] = "frenado-final"
	final["objetivo_kph"] = 0.0
	final["alcanzado"] = true
	final["estable"] = true
	final["desacelerando"] = true
	_copy_transition(final, at_rest)
	final["asentado"] = float(at_rest["distancia_final_max_m"]) - float(at_rest["distancia_final_min_m"]) <= STEADY_MAX_M
	final["estable"] = final["asentado"]
	casos.append(final)
	await _shot_pair(out_dir + "/capturas/frenado-final")
	print("CAMARA frenada: apertura=%6.3f m salto_maximo=%.4f m por fotograma (a %.1f km/h, %.3f m) cambios_de_sentido=%d tics_con_muro=%d tics_estancados=%d reposo=%6.3f m" % [
		opening, max_step, float(max_step_at["velocidad_kph"]), float(max_step_at["distancia_m"]), flips,
		blocked_ticks, stalled_ticks, final["distancia_plano_m"]])
	transiciones.append({"id": "frenada", "velocidad_kph": 0.0, "transicion": {
		"salto_maximo_m": max_step, "cambios_de_sentido": flips,
		"distancia_minima_m": first_distance, "distancia_maxima_m": last,
		"fuera_de_tolerancia_tics": 0, "tics_estancados": stalled_ticks,
	}})
	_brake_series = series
	if max_step > BRAKE_MAX_STEP_M and blocked_ticks == 0 and stalled_ticks == 0:
		errores.append("la distancia cambia a saltos durante la frenada (%.4f m en un fotograma)" % max_step)
	if flips > BRAKE_MAX_FLIPS:
		errores.append("la distancia oscila durante la frenada (%d cambios de sentido)" % flips)

func _brake_steer() -> float:
	var point := _point_ahead(_steer_lookahead())
	var local := car.to_local(point)
	var alpha := atan2(local.x, -local.z)
	var wheel_angle := atan2(2.0 * car.wheelbase_m * sin(alpha), _steer_lookahead())
	return clampf(wheel_angle / maxf(_steering_max(), 0.0001), -1.0, 1.0)

# --- anticolisión ------------------------------------------------------------

# La cámara se trae por delante del muro cuando el muro queda entre ella y el
# coche. Se pega el coche al muro exterior del primer tramo con curva y se
# comprueba que NADA se interpone y que la cámara no queda enterrada.
# Barrido por TODO el circuito: en qué puntos hay algo detrás del coche a la
# altura y a la distancia donde se pondría la cámara. Sin el barrido, la
# anticolisión sólo se probaría donde uno cree que hay muro.
func _wall_sweep() -> Array:
	var space := car.get_world_3d().direct_space_state
	var found := []
	var index := 0
	var stride := 8
	while index < line.size():
		var tangent := (line[(index + 1) % line.size()] - line[index]).normalized()
		var right := Vector3(-tangent.z, 0.0, tangent.x).normalized()
		for offset in [-3.0, 0.0, 3.0]:
			var point: Vector3 = line[index] + right * offset
			var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.8,
				point + Vector3.UP * race.camera_height_fast_m - tangent * race.camera_distance_stopped_m, 1)
			var hit := space.intersect_ray(ray)
			if not hit.is_empty():
				found.append({
					"index": index, "offset": offset,
					"muro_m": point.distance_to(hit["position"]),
				})
		index += stride
	return found

# La cámara se trae por delante del muro cuando el muro queda entre ella y el
# coche. Se eligen TRES sitios del circuito donde el barrido encontró muro
# detrás, y se comprueba que nada se interpone y que la cámara no queda
# enterrada; se dice además en cuántos hubo que acortar la distancia.
func _anticollision_case() -> void:
	if legacy:
		print("CAMARA anticolision: la camara anterior no tenia guardia de muro; no se prueba")
		return
	var found := _wall_sweep()
	print("CAMARA muros: %d posiciones del circuito con algo detrás del coche (barrido cada 8 puntos, tres desplazamientos laterales)" % found.size())
	var chosen := []
	for entry in found:
		var distinct := true
		for other in chosen:
			if absi(int(entry["index"]) - int(other["index"])) < 400:
				distinct = false
		if distinct:
			chosen.append(entry)
		if chosen.size() >= 3:
			break
	await _test_wall_case()
	if chosen.is_empty():
		print("CAMARA anticolision: el circuito no tiene ninguna posición con muro a la altura y a la distancia de la cámara; el guardia se prueba con el muro de prueba")
		return
	var shortenings := 0
	var worst := 99.0
	for step in chosen.size():
		var site: Dictionary = chosen[step]
		await _place_at(int(site["index"]), 100.0, float(site["offset"]))
		var transition := await _settle(100.0, 1.6)
		var entry: Dictionary = _measure()
		entry["id"] = "muro-%d" % step
		entry["objetivo_kph"] = 100.0
		entry["alcanzado"] = true
		entry["estable"] = true
		entry["asentado"] = true
		_copy_transition(entry, transition)
		casos.append(entry)
		await _shot_pair("%s/capturas/muro-%d" % [out_dir, step])
		var shortened := float(entry["distancia_plano_m"]) < float(entry["distancia_diseno_m"]) - 0.05
		if shortened:
			shortenings += 1
		worst = minf(worst, float(entry["margen_min_px"]))
		print("CAMARA muro-%d idx=%d lateral=%.0f m muro_detras=%.2f m dist=%6.3f m (diseno %6.3f, acortada=%s) interpuesto=%s paredes=%d margen=%.0f px" % [
			step, int(site["index"]), float(site["offset"]), float(site["muro_m"]),
			entry["distancia_plano_m"], entry["distancia_diseno_m"], str(shortened),
			str(entry["bloqueos"]["interpuesto"]), int(entry["bloqueos"]["paredes_alrededor"]),
			entry["margen_min_px"]])
		if bool(entry["bloqueos"]["interpuesto"]):
			errores.append("con el coche junto al muro hay geometría entre el coche y la cámara (puesto %d)" % step)
		if int(entry["bloqueos"]["paredes_alrededor"]) >= 4:
			errores.append("con el coche junto al muro la cámara queda enterrada (puesto %d)" % step)
		if int(entry["fuera_del_cuadro"]) != 0:
			errores.append("con el coche junto al muro el encuadre se rompe (puesto %d)" % step)
	print("CAMARA anticolision: acortó la distancia en %d de %d posiciones con muro, margen_minimo=%.0f px" % [
		shortenings, chosen.size(), worst])

# Prueba del guardia anticolisión: se levanta un muro de prueba de 2,6 m por
# detrás del coche (el proyecto ya usa un resalto de prueba para la suspensión)
# y se comprueba que la cámara se trae POR DELANTE del muro en vez de quedarse
# dentro de él. El barrido del circuito no encuentra ninguna posición que lo
# necesite, así que sin esta prueba el mecanismo viajaría sin ejercitar.
func _test_wall_case() -> void:
	await _place_at_start(100.0)
	var wall := StaticBody3D.new()
	wall.name = "Muro de prueba de la camara"
	wall.collision_layer = 1
	wall.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(14.0, 2.6, 0.4)
	shape.shape = box
	shape.position = Vector3(0.0, 1.3, 0.0)
	wall.add_child(shape)
	# Va montado en el coche a propósito: el muro tiene que quedarse SIEMPRE a la
	# misma distancia por detrás, o el coche se aleja de él a 100 km/h y la
	# prueba mediría el viaje en vez de la anticolisión.
	car.add_child(wall)
	wall.position = Vector3(0.0, 0.0, 6.0)
	var transition := await _settle(100.0, 2.0)
	var entry: Dictionary = _measure()
	entry["id"] = "muro-prueba"
	entry["objetivo_kph"] = 100.0
	entry["alcanzado"] = true
	entry["estable"] = true
	entry["asentado"] = float(transition["distancia_final_max_m"]) - float(transition["distancia_final_min_m"]) <= STEADY_MAX_M
	_copy_transition(entry, transition)
	casos.append(entry)
	await _shot_pair(out_dir + "/capturas/muro-prueba")
	var shortened := float(entry["distancia_plano_m"]) < float(entry["distancia_diseno_m"]) - 0.05
	print("CAMARA muro de prueba (2,6 m a 6,0 m del coche): dist=%6.3f m (diseno %6.3f, acortada=%s) interpuesto=%s paredes=%d salto=%.4f m" % [
		entry["distancia_plano_m"], entry["distancia_diseno_m"], str(shortened),
		str(entry["bloqueos"]["interpuesto"]), int(entry["bloqueos"]["paredes_alrededor"]),
		entry["transicion_salto_maximo_m"]])
	if not shortened:
		errores.append("con un muro de prueba detrás, la cámara no acortó la distancia")
	if bool(entry["bloqueos"]["interpuesto"]):
		errores.append("con un muro de prueba detrás, hay geometría entre el coche y la cámara")
	if int(entry["bloqueos"]["paredes_alrededor"]) >= 4:
		errores.append("con un muro de prueba detrás, la cámara queda enterrada")
	# La anticolisión es una protección y se mueve deprisa a propósito: lo que se
	# le exige no es un salto pequeño, sino que acabe pronto y sin oscilar.
	if int(entry["transicion_tics_hasta_estabilizar"]) > int(0.6 * TICKS):
		errores.append("la anticolisión tarda %.2f s en estabilizarse" % (float(entry["transicion_tics_hasta_estabilizar"]) / TICKS))
	if int(entry["transicion_cambios_de_sentido"]) > MAX_TRANSITION_FLIPS:
		errores.append("la anticolisión oscila al acortar (%d cambios de sentido)" % entry["transicion_cambios_de_sentido"])
	if float(entry["margen_min_px"]) < FRAME_MIN_MARGIN_PX:
		errores.append("con el muro de prueba el coche queda a %.0f px del borde" % entry["margen_min_px"])
	wall.queue_free()
	await physics_frame

# --- criterios ---------------------------------------------------------------

func _verdict() -> void:
	var by_id := {}
	for entry in casos:
		by_id[String(entry["id"])] = entry
	var ordered := []
	for id in ORDERED:
		if by_id.has(id):
			ordered.append(by_id[id])
	if ordered.size() < ORDERED.size():
		errores.append("faltan casos medidos: %s" % str(ordered.size()))
		return
	# 1. Distancia contra la velocidad: con la cámara nueva tiene que bajar y con
	#    la anterior subir. El sentido lo fija el modo, y es lo que se comprueba.
	for i in range(1, ordered.size()):
		var previous: float = ordered[i - 1]["distancia_plano_m"]
		var current: float = ordered[i]["distancia_plano_m"]
		if legacy:
			if current - previous < STEP_MIN_M:
				errores.append("anterior: de %s a %s km/h la distancia no creció: %.3f → %.3f m" % [
					ordered[i - 1]["id"], ordered[i]["id"], previous, current])
		elif previous - current < STEP_MIN_M:
			errores.append("de %s a %s km/h la cámara no se acerca: %.3f → %.3f m" % [
				ordered[i - 1]["id"], ordered[i]["id"], previous, current])
	# 2. Cada caso conduce de verdad a su velocidad, con la distancia de diseño.
	for entry in casos:
		if not bool(entry["alcanzado"]) and not bool(entry.get("desacelerando", false)):
			errores.append("%s: no se mantuvo la velocidad (%.1f km/h de %.0f)" % [
				entry["id"], entry["velocidad_kph"], entry["objetivo_kph"]])
		# En modo anterior la distancia NO se queda quieta a alta velocidad: la
		# cámara arrastra un retardo de v/λ que cambia con cada corrección de
		# dirección. Eso es el defecto que se está midiendo, no un fallo de la
		# medida, así que ahí se informa y no se exige.
		if not bool(entry["estable"]) and not legacy:
			if float(entry["transicion_fuera_de_tolerancia_tics"]) == 0.0:
				errores.append("%s: la distancia no se queda quieta dentro de la ventana" % entry["id"])
		# Con la cámara anterior la distancia de diseño es la predicción v/λ sobre un
		# filtro que todavía se está asentando, así que se le da más margen; en las
		# frenadas la predicción no vale (es un transitorio) y sólo se informa.
		var tolerance := DESIGN_TOLERANCE_M * (2.0 if legacy else 1.0)
		if not String(entry["id"]).begins_with("muro") and not (legacy and bool(entry.get("desacelerando", false))) and absf(float(entry["distancia_plano_m"]) - float(entry["distancia_diseno_m"])) > tolerance:
			errores.append("%s: la distancia aplicada (%.3f m) no es la de diseño (%.3f m)" % [
				entry["id"], entry["distancia_plano_m"], entry["distancia_diseno_m"]])
		if not legacy and float(entry["distancia_plano_m"]) < float(entry["distancia_minima_m"]) - 0.05:
			errores.append("%s: la cámara se acercó más que su mínimo" % entry["id"])
		if float(entry["altura_m"]) < MIN_HEIGHT_M and not String(entry["id"]).begins_with("muro") and not bool(entry.get("desacelerando", false)):
			errores.append("%s: la cámara bajó demasiado (%.2f m sobre el coche)" % [entry["id"], entry["altura_m"]])
		# 3. El coche no queda cortado y hay pista por delante.
		if int(entry["fuera_del_cuadro"]) != 0 or int(entry["esquinas_detras"]) != 0:
			errores.append("%s: el coche se sale del encuadre" % entry["id"])
		if float(entry["margen_min_px"]) < FRAME_MIN_MARGIN_PX:
			errores.append("%s: el coche queda a %.0f px del borde" % [entry["id"], entry["margen_min_px"]])
		for distance in ["20", "40", "60"]:
			if not bool(entry["adelante"][distance]["dentro"]):
				errores.append("%s: la trazada a %s m no está en el cuadro" % [entry["id"], distance])
		# 4. La transición no da saltos ni oscila.
		# Los criterios de transición no se aplican a la cámara anterior: como su
		# posición es un filtro con memoria, cada colocación del coche en la recta
		# (que es parte del montaje de la prueba) le deja un hueco de decenas de
		# metros que tarda en recorrer. Lo que se compara del "antes" son las
		# distancias y los tamaños ya asentados.
		if not legacy and not bool(entry.get("desacelerando", false)) and not String(entry["id"]).begins_with("muro") and float(entry["transicion_salto_maximo_sin_muro_m"]) > MAX_STEP_PER_FRAME_M:
			errores.append("%s: la distancia salta %.4f m en un fotograma" % [entry["id"], entry["transicion_salto_maximo_sin_muro_m"]])
		if not legacy and not bool(entry.get("desacelerando", false)) and int(entry["transicion_cambios_de_sentido"]) > MAX_TRANSITION_FLIPS:
			errores.append("%s: la distancia cambia de sentido %d veces al asentarse" % [entry["id"], entry["transicion_cambios_de_sentido"]])
		if not legacy and not String(entry["id"]).begins_with("muro") and not bool(entry.get("desacelerando", false)):
			var lowest: float = minf(float(race.camera_distance_fast_m), float(race.camera_distance_stopped_m))
			var highest: float = maxf(float(race.camera_distance_fast_m), float(race.camera_distance_stopped_m))
			if float(entry["transicion_distancia_minima_m"]) < lowest - 0.25 or float(entry["transicion_distancia_maxima_m"]) > highest + 0.25:
				errores.append("%s: la transición se sale de los topes (%.3f..%.3f m)" % [
					entry["id"], entry["transicion_distancia_minima_m"], entry["transicion_distancia_maxima_m"]])
		if not legacy and bool(entry["bloqueos"]["interpuesto"]):
			errores.append("%s: hay geometría entre el coche y la cámara" % entry["id"])
	# 5. El coche crece en pantalla con la velocidad (y encoge con la anterior).
	var total: float = ordered[ordered.size() - 1]["alto_fraccion"] / maxf(ordered[0]["alto_fraccion"], 0.0001)
	for i in range(1, ordered.size()):
		var previous: float = ordered[i - 1]["alto_fraccion"]
		var current: float = ordered[i]["alto_fraccion"]
		if legacy:
			if current > previous / SIZE_GROWTH_MIN:
				errores.append("anterior: de %s a %s km/h el coche no encogió: %.3f → %.3f del alto" % [
					ordered[i - 1]["id"], ordered[i]["id"], previous, current])
		elif current < previous * SIZE_GROWTH_MIN:
			errores.append("de %s a %s km/h el coche no crece en pantalla: %.3f → %.3f del alto" % [
				ordered[i - 1]["id"], ordered[i]["id"], previous, current])
	if not legacy and total < SIZE_TOTAL_MIN:
		errores.append("de parado a 200 km/h el coche sólo crece un %.0f %%" % ((total - 1.0) * 100.0))
	if legacy and total > 1.0 / SIZE_TOTAL_MIN:
		errores.append("anterior: de parado a 200 km/h el coche sólo encoge un %.0f %%" % ((1.0 - total) * 100.0))
	# 6. Al frenar del todo, la cámara vuelve sola a la distancia de parado.
	var final_brake: Dictionary = by_id.get("frenado-final", {})
	if not final_brake.is_empty():
		var stopped: float = ordered[0]["distancia_plano_m"]
		if legacy:
			if float(final_brake["distancia_plano_m"]) > stopped + 0.30:
				errores.append("anterior: tras frenar la cámara no volvió a %.3f m (quedó en %.3f m)" % [
					stopped, final_brake["distancia_plano_m"]])
		elif float(final_brake["distancia_plano_m"]) < stopped - 0.30:
			errores.append("tras frenar la cámara no volvió a la distancia de parado: %.3f m frente a %.3f m" % [
				final_brake["distancia_plano_m"], stopped])
	if legacy:
		print("CAMARA modo anterior: la distancia crece %.2f m de parado a 200 km/h y el coche encoge a %.0f %% del tamaño; criterios de transición no aplicables (la cámara anterior arrastra estado)" % [
			ordered[ordered.size() - 1]["distancia_plano_m"] - ordered[0]["distancia_plano_m"], total * 100.0])
	for error in errores:
		print("  ERROR %s" % error)
	print("CAMARA distancia parado=%.2f m 200=%.2f m | alto parado=%.3f 200=%.3f del lienzo | factor=%.2f | errores=%d" % [
		ordered[0]["distancia_plano_m"], ordered[ordered.size() - 1]["distancia_plano_m"],
		ordered[0]["alto_fraccion"], ordered[ordered.size() - 1]["alto_fraccion"], total, errores.size()])

# --- informes ----------------------------------------------------------------

func _write_report() -> void:
	var report := {
		"modo": "anterior" if legacy else "nueva",
		"lienzo": [FRAME_W, FRAME_H],
		"tics_por_segundo": TICKS,
		"criterios": {
			"tolerancia_velocidad_kph": SPEED_TOLERANCE_KPH,
			"asentamiento_s": SETTLE_S,
			"ventana_estable_s": SAMPLE_S,
			"estable_max_m": STEADY_MAX_M,
			"escalon_min_m": STEP_MIN_M,
			"diseno_tolerancia_m": DESIGN_TOLERANCE_M,
			"margen_minimo_px": FRAME_MIN_MARGIN_PX,
			"crecimiento_min": SIZE_GROWTH_MIN,
			"crecimiento_total_min": SIZE_TOTAL_MIN,
			"altura_minima_m": MIN_HEIGHT_M,
			"salto_maximo_por_fotograma_m": MAX_STEP_PER_FRAME_M,
			"cambios_de_sentido_max": MAX_TRANSITION_FLIPS,
			"frenada_salto_maximo_m": BRAKE_MAX_STEP_M,
			"frenada_cambios_de_sentido_max": BRAKE_MAX_FLIPS,
		},
		"casos": casos,
		"transiciones": transiciones,
		"serie_frenada": _brake_series,
		"errores": errores,
		"passed": errores.is_empty(),
	}
	var path := out_dir + "/medidas.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("CAMARA informe=%s" % path)

# Perfil de curvatura desde la salida: deja dicho por qué la medida se puede
# hacer a 200 km/h en la recta inicial (κ admite v = √(12/κ) con 1,2 g).
func _curvature_profile() -> void:
	var bins := PackedFloat32Array()
	bins.resize(16)
	var walked := 0.0
	var index := 0
	for i in 1200:
		var at := (index + i) % line.size()
		var next := (at + 1) % line.size()
		var a := (line[at] - line[(at - 1 + line.size()) % line.size()]).normalized()
		var b := (line[next] - line[at]).normalized()
		var length := line[at].distance_to(line[next])
		walked += length
		var turn := rad_to_deg(acos(clampf(a.dot(b), -1.0, 1.0))) / maxf(length, 0.001)
		var bin := clampi(int(walked / 50.0), 0, bins.size() - 1)
		bins[bin] = maxf(bins[bin], turn)
	var text := "CAMARA perfil desde la salida:"
	for bin in bins.size():
		var curvature := deg_to_rad(bins[bin]) / 50.0
		text += " %dm:%.2f°/m(%.0f km/h)" % [bin * 50, bins[bin], sqrt(12.0 / maxf(curvature, 0.000001)) * 3.6]
	print(text)

# Cámara anterior, transcrita tal cual del código que se retiró: suavizado
# exponencial de la POSICIÓN en coordenadas del mundo (λ = 6 s⁻¹) más el punto
# de mira adelantado 12 m + 0,15 m por m/s. En régimen ese filtro se queda
# v/λ metros por detrás del objetivo: es la causa que se mide aquí.
class _LegacyCamera extends Node:
	var car: CharacterBody3D
	var cam: Camera3D
	var eye := Vector3.ZERO
	var primed := false

	# SÓLO en el paso de física, y después de race.gd: es la misma fase en la que
	# se mueve el coche, así que el filtro avanza con el reloj que le toca. En
	# las dos fases avanzaría el doble por fotograma y el retardo v/λ medido sería
	# la mitad del real.
	func _physics_process(delta: float) -> void:
		place(delta)

	func place(delta: float) -> void:
		if car == null or cam == null:
			return
		var forward := -car.global_basis.z
		var target := car.global_position + Vector3.UP * 3.4 - forward * 9.0
		if not primed:
			eye = target
			primed = true
		eye = eye.lerp(target, 1.0 - exp(-delta * 6.0))
		cam.global_position = eye
		cam.look_at(car.global_position + forward * (12.0 + car.speed_mps * 0.15) + Vector3.UP * 0.8, Vector3.UP)
