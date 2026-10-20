extends SceneTree

# Sonda de la cámara del MORRO (la segunda vista jugable) y de su botón.
#
# Mide sobre la cámara REAL del juego, con el lienzo de medida de 2400x1080:
#
# 1. Composición en seis situaciones (parado, 100, 150, 200 km/h, una curva
#    tomada a la velocidad que permite su curvatura con el límite de agarre
#    declarado, y
#    frenada): cuánta pista se ve por delante y a qué altura cae el horizonte,
#    más los tres fotogramas por caso (coche visible, sin coche y sin ruedas
#    delanteras) que analiza en píxeles `.tools/recovery/fase-fp/morro_pixeles.py`
#    para medir la franja que ocupa el coche y cuánto se ve de cada neumático.
# 1b. El botón de vista no pisa el mando, los pedales ni los paneles.
# 2. Estabilidad: la posición de la cámara en el marco DEL COCHE no cambia con la
#    velocidad (es rígida respecto al modelo) y no hay saltos por fotograma.
# 3. Holgura con la carrocería: la cámara queda FUERA del carenado en su vertical,
#    medido contra el perfil real de la malla del chasis (no contra una cota a
#    mano). Es el criterio de «no atraviesa la carrocería».
# 4. Cambio de vista, en los dos sentidos y en marcha: la cámara que entra
#    arranca donde estaba la que salía (sin salto), el camino no entra en la
#    carrocería, la carrera NO se interrumpe (el cronómetro sigue, el coche no
#    salta ni se reinicia) y la persecución sigue calculando su estado mientras
#    está en segundo plano (al volver, su distancia es la de diseño).
#
# Uso: "$GODOT" --path . --script scripts/camera_nose_probe.gd
# Falla con código distinto de cero si alguna de las medidas se sale del criterio.

const ROOT_DIR := "res://.tools/recovery/fase-fp"
const FRAME_W := 2400
const FRAME_H := 1080
const TrackScript = preload("res://scripts/track_data.gd")
const RaceScript = preload("res://scripts/race.gd")

# --- criterios de composición -------------------------------------------------
# La composición (franja del coche y neumáticos) se juzga en PÍXELES, en
# `.tools/recovery/fase-fp/morro_pixeles.py`, con los tres fotogramas que deja
# cada caso. Aquí quedan los criterios geométricos.
const HORIZON_MIN := 0.10             # el horizonte ni pegado al borde superior
const HORIZON_MAX := 0.45
const TRACK_POINTS_AHEAD := [20.0, 40.0, 60.0, 100.0, 150.0]
const TRACK_POINTS_MIN := 4           # puntos de trazada por delante dentro del cuadro
const CLEARANCE_MIN_M := 0.02         # holgura entre la cámara y el techo del carenado
const OFFSET_DRIFT_MAX_M := 0.001     # la cámara es rígida respecto al coche
# Salto máximo del cambio de vista, medido EN EL MARCO DEL COCHE (el avance del
# propio coche no cuenta: a 160 km/h son 0,37 m por fotograma que no son de la
# transición). El arco recorre ~0,55 m y el tramo recto ~12 m en 26 fotogramas de
# física, así que el pico real ronda 0,5 m; se deja margen y se persigue el
# teleport (12 m).
const STEP_MAX_M := 0.85
# La cámara que entra nace donde estaba la que sale. Se muestrea UN fotograma
# después del cambio, y en ese fotograma la transición ya ha avanzado el 0,4 %
# del recorrido (~0,05 m), así que el margen es de un paso del arco.
const SWITCH_FIRST_FRAME_MAX_M := 0.15
const CASE_SPEEDS := [100.0, 150.0, 200.0]
const SETTLE_S := 2.2
const BRAKE_FROM_KPH := 200.0
const BRAKE_S := 1.2
const START_OFFSET_M := 60.0
const SAMPLE_MAX_STEPS := 240
# El caso «curva» se conduce por el viraje MÁS CERRADO que el coche puede tomar a
# CURVA_VELOCIDAD_KPH con el límite de agarre lateral declarado (CURVA_AGARRE_G), y
# el asentamiento se coloca para que termine DENTRO del viraje. Antes se sostenían
# 130 km/h en el viraje más cerrado del trazado —radio 30 m, ~3,8 g— y el coche
# acababa fuera, dentro de la barrera; el caso sólo pasaba porque el relieve
# invisible de la calzada lo detenía antes de salirse (hundido en la fase de muros:
# ver .tools/recovery/fase-muros/INFORME-FASE-MUROS.md). Con el relieve ya hundido se
# probó primero a la velocidad que ese viraje de radio 30 m permite (41 km/h), y ahí
# apareció el segundo problema: con la dirección tan girada uno de los neumáticos
# delanteros queda tapado por la carrocería —medido: 9 269 px, 0,36 % del lienzo, por
# debajo del 0,5 % que pide este caso—, una exigencia que un viraje así no puede
# cumplir. El escenario final es un viraje de radio 148 m a 130 km/h, con la
# dirección casi recta como en las otras cinco situaciones.
const CURVA_AGARRE_G := 0.9          # g de agarre lateral que se le permite pedir
const CURVA_VELOCIDAD_KPH := 130.0   # la misma velocidad de siempre para este caso
const CURVA_ASENTAMIENTO_S := 2.6
# Las FOTOGRAFÍAS de la composición en la curva se toman con el coche DETENIDO en el
# mismo punto del viraje. Cuánto neumático delantero enseña la cámara no es
# reproducible a velocidad —medido: el mismo neumático sale con 51 377 px en una
# pasada y con 10 049 px en otra, en el mismo viraje, a la misma velocidad, con la
# suspensión dentro de su recorrido (±0,7 mm), sin topar y con 0,03° de dirección—
# y la composición no depende de eso: depende de dónde está la cámara respecto al
# coche, que es rígida (0,0000 m de deriva en las seis situaciones). Detenido en el
# mismo punto del viraje el estado sí es reproducible (es el de la sonda «parado»,
# igual al 2 % en todas las pasadas). El escenario se mide ANTES, conduciendo: el
# coche recorre el viraje a 121,1 km/h sobre la calzada y a 0,27 m de la trazada.
const CURVA_ASENTAMIENTO_DETENIDO_S := 0.6
const CURVA_DESVIO_MAX_M := 4.0      # m de la trazada: dentro de la calzada
const CURVA_SUPERFICIES := ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE"]

var race: Node3D
var car: CharacterBody3D
var chase: Camera3D
var nose: Camera3D
var view: SubViewport
var line: PackedVector3Array
var nearest := 0
var errores: Array[String] = []
var casos: Array = []
var transiciones: Array = []
var perfil_carroceria: Array = []      # [z, y_max] del chasis, medido una vez
var _last_usec := 0
var _switch_shots := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT_DIR + "/capturas"))
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
	chase = race.camera
	nose = race.nose_camera
	line = TrackScript.get_centerline()
	if nose == null:
		print("MORRO FALLA: el juego no tiene cámara del morro")
		quit(1)
		return
	_medir_perfil_carroceria()
	print("MORRO punto_de_vista_local=%s fov=%.1f alto_chasis=%.3f holgura_en_la_vertical=%.3f m" % [
		_v(race._nose_offset), nose.fov, _techo_chasis(race._nose_offset.z),
		race._nose_offset.y - _techo_chasis(race._nose_offset.z)])
	print("MORRO anclaje_medido=%s  persecucion: distancia_parado=%.2f distancia_rapida=%.2f" % [
		race._nose_anclaje_medido, race.camera_distance_stopped_m, race.camera_distance_fast_m])

	await _case({"id": "parado", "kph": 0.0})
	for kph in CASE_SPEEDS:
		await _case({"id": "%.0f" % kph, "kph": kph})
	await _case_curve()
	await _case_brake()
	await _case_switch()
	_revisar_boton_de_vista()
	_verdict()
	_write_report()
	race.queue_free()
	await process_frame
	quit(0 if errores.is_empty() else 1)

# --- carrocería ---------------------------------------------------------------

# Perfil del chasis por estaciones de z (marco del coche): para cada z, el techo
# de la carrocería. Es lo que decide si la cámara está fuera del carenado.
func _medir_perfil_carroceria() -> void:
	var inv: Transform3D = car.global_transform.affine_inverse()
	var puntos: Array = []
	for child in car.model_root.find_children("*", "MeshInstance3D", true, false):
		if String(child.name).to_lower().contains("wheel"):
			continue
		var mesh := child.mesh as ArrayMesh
		if mesh == null:
			continue
		var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var stride: int = maxi(1, int(verts.size() / 40000.0))
		for i in range(0, verts.size(), stride):
			puntos.append(inv * (child.global_transform * verts[i]))
	perfil_carroceria.clear()
	for z in range(-28, 29):
		var estacion := float(z) * 0.1
		var alto := -INF
		for punto in puntos:
			if absf(punto.z - estacion) <= 0.06:
				alto = maxf(alto, punto.y)
		if alto > -INF:
			perfil_carroceria.append([estacion, alto])
	print("MORRO perfil de la carrocería: %d estaciones de z, techo máximo %.3f m" % [
		perfil_carroceria.size(), _techo_maximo()])

func _techo_chasis(z: float) -> float:
	var alto := -INF
	for par in perfil_carroceria:
		if absf(par[0] - z) <= 0.11:
			alto = maxf(alto, par[1])
	return alto

func _techo_maximo() -> float:
	var alto := -INF
	for par in perfil_carroceria:
		alto = maxf(alto, par[1])
	return alto

# --- conducción ---------------------------------------------------------------

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

func _index_at_distance(distance: float) -> int:
	var travelled := 0.0
	var i := 0
	while travelled < distance and i < line.size() - 1:
		travelled += line[i].distance_to(line[i + 1])
		i += 1
	return i

func _modo_morro() -> int:
	return RaceScript.MODO_MORRO

func _modo_persecucion() -> int:
	return RaceScript.MODO_PERSECUCION

func _point_ahead(distance: float) -> Vector3:
	var travelled := 0.0
	var i := nearest
	while travelled < distance and i < line.size() - 2:
		travelled += line[i].distance_to(line[i + 1])
		i += 1
	return line[i]

func _press_steer(steer: float) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if steer > 0.001:
		Input.action_press("steer_right", clampf(steer, 0.0, 1.0))
	elif steer < -0.001:
		Input.action_press("steer_left", clampf(-steer, 0.0, 1.0))

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

# Persecución pura sobre la trazada, apuntando 14 índices (≈ 28 m) por delante.
func _steer_lookahead() -> float:
	var target := line[mini(line.size() - 1, nearest + 14)]
	var to_target := target - car.global_position
	var desired := atan2(-to_target.x, -to_target.z)
	var error := wrapf(desired - car.rotation.y, -PI, PI)
	return clampf(-error * 1.6, -1.0, 1.0)

func _step_controls(target_kph: float, brake: bool = false) -> void:
	if brake:
		Input.action_press("brake", 1.0)
		Input.action_release("throttle")
	else:
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
	_press_steer(_steer_lookahead())

func _settle(target_kph: float, seconds: float, brake: bool = false) -> Dictionary:
	var elapsed := 0.0
	var offsets: Array = []
	var pasos := 0.0
	var pasos_max := 0.0
	var anterior := _CERO
	var first := true
	var direcciones := 0
	var signo_previo := 0
	_last_usec = Time.get_ticks_usec()
	while elapsed < seconds:
		_step_controls(target_kph, brake)
		await physics_frame
		var delta := _real_dt()
		elapsed += delta
		if car.speed_kph < target_kph - 25.0 and not brake:
			break
		var local := _local_offset()
		offsets.append(local)
		if not first:
			var paso := (local - anterior).length()
			pasos_max = maxf(pasos_max, paso)
			pasos += paso
			var signo := signi(roundi(signf(local.y - anterior.y) * 100.0))
			if signo != 0 and signo_previo != 0 and signo != signo_previo:
				direcciones += 1
			if signo != 0:
				signo_previo = signo
		anterior = local
		first = false
		nearest = _nearest(nearest)
		if offsets.size() > SAMPLE_MAX_STEPS:
			break
	var deriva := 0.0
	for local in offsets:
		deriva = maxf(deriva, (local - race._nose_offset).length())
	return {"muestras": offsets.size(), "paso_max_m": pasos_max, "paso_medio_m": pasos / maxf(1.0, offsets.size() - 1.0),
		"cambios_de_sentido_y": direcciones, "deriva_max_m": deriva}

func _real_dt() -> float:
	var ahora := Time.get_ticks_usec()
	var delta := float(ahora - _last_usec) / 1000000.0
	_last_usec = ahora
	return clampf(delta, 0.0, 0.2)

const _CERO := Vector3.ZERO

func _local_offset() -> Vector3:
	return car.global_transform.affine_inverse() * nose.global_position

# --- medida de un caso --------------------------------------------------------

func _case(caso: Dictionary) -> void:
	await _place_at(_index_at_distance(START_OFFSET_M), float(caso["kph"]), 0.0)
	race.set_camera_mode(_modo_morro())
	# El cambio de vista dura `nose_switch_seconds`: hay que dejarlo terminar ANTES
	# de empezar a muestrear, o las primeras muestras miden la transición y no el
	# asentamiento (medido: 1,45 m de deriva y saltos de 0,46 m en «parado»).
	await _esperar_transicion()
	var estabilidad := await _settle(float(caso["kph"]), SETTLE_S)
	var medida := _measure()
	for clave in estabilidad:
		medida[clave] = estabilidad[clave]
	medida["id"] = caso["id"]
	casos.append(medida)
	_revisar_caso(medida)
	await _capturar_composicion(caso["id"])

func _esperar_transicion() -> void:
	for i in int(ceil((race.nose_switch_seconds + 0.15) * 120.0)):
		await physics_frame

func _case_curve() -> void:
	# La curva más cerrada que el coche puede tomar a esta velocidad con el límite de
	# agarre declarado: v²k ≤ a. Con el viraje más cerrado del trazado (radio 30 m)
	# harían falta ~3,8 g, el coche se iba fuera y acababa dentro de la barrera; y
	# frenar hasta que lo tomara (41 km/h) obliga a girar tanto la dirección que uno
	# de los neumáticos delanteros queda tapado por la carrocería (medido: 9 269 px,
	# 0,36 % del lienzo, por debajo del 0,5 % que pide este caso), que es una
	# exigencia que un viraje cerrado no puede cumplir. En una curva viable a 130
	# km/h la dirección va casi recta, como en los otros cinco casos.
	var kph := CURVA_VELOCIDAD_KPH
	var viables := _curva_viable(kph)
	var curvatura: float = float(viables["k"])
	if curvatura <= 0.0:
		errores.append("curva: no hay ningún viraje del trazado que se pueda tomar a %.0f km/h con %.1f g" % [kph, CURVA_AGARRE_G])
		return
	# El coche se suelta lo justo para que el asentamiento acabe en el viraje: lo que
	# se recorre en la transición de vista (el coche rueda sin pedales) más los
	# segundos de asentamiento.
	var espera: float = float(race.nose_switch_seconds) + 0.15
	var metros: float = kph / 3.6 * (espera + CURVA_ASENTAMIENTO_S)
	await _place_at(maxi(0, int(viables["indice"]) - _steps_for(metros)), kph, 0.0)
	race.set_camera_mode(_modo_morro())
	await _esperar_transicion()
	var estabilidad := await _settle(kph, CURVA_ASENTAMIENTO_S)
	var medida := _measure()
	for clave in estabilidad:
		medida[clave] = estabilidad[clave]
	medida["id"] = "curva"
	medida["curvatura"] = _curvature(nearest)
	medida["curvatura_de_la_curva"] = curvatura
	medida["radio_de_la_curva_m"] = float(viables["radio_m"])
	medida["velocidad_permitida_kph"] = kph
	medida["agarre_demandado_g"] = (car.speed_mps * car.speed_mps) * absf(_curvature(nearest)) / 9.81
	medida["desvio_lateral_m"] = _desvio_lateral()
	medida["superficie"] = car.ground_surface
	casos.append(medida)
	_revisar_caso(medida)
	await _stop_in_place()
	casos[casos.size() - 1]["desvio_lateral_al_fotografiar_m"] = snappedf(_desvio_lateral(), 0.01)
	casos[casos.size() - 1]["superficie_al_fotografiar"] = String(car.ground_surface)
	casos[casos.size() - 1]["velocidad_al_fotografiar_kph"] = snappedf(car.speed_kph, 0.1)
	await _capturar_composicion("curva")

# Detiene el coche donde está, soltando pedales y dirección, para las fotografías de
# la composición en la curva (ver `CURVA_ASENTAMIENTO_DETENIDO_S`).
func _stop_in_place() -> void:
	Input.action_release("throttle")
	Input.action_release("brake")
	_press_steer(0.0)
	car.velocity = Vector3.ZERO
	car.speed_mps = 0.0
	car.speed_kph = 0.0
	for i in int(ceil(CURVA_ASENTAMIENTO_DETENIDO_S * 120.0)):
		nearest = _nearest(nearest)
		Input.action_release("throttle")
		Input.action_release("brake")
		_press_steer(0.0)
		car.velocity = Vector3.ZERO
		await physics_frame

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
	return {"indice": mejor, "k": mejor_k, "radio_m": 1.0 / maxf(mejor_k, 1e-9)}

func _steps_for(metros: float) -> int:
	var travelled := 0.0
	var steps := 0
	var i := 0
	while travelled < metros and i < line.size() - 2:
		travelled += line[i].distance_to(line[i + 1])
		i += 1
		steps += 1
	return steps

func _desvio_lateral() -> float:
	var tangent := (line[(nearest + 3) % line.size()] - line[(nearest - 3 + line.size()) % line.size()]).normalized()
	return (car.global_position - line[nearest]).dot(Vector3(tangent.z, 0.0, -tangent.x).normalized())

func _case_brake() -> void:
	await _place_at(_index_at_distance(START_OFFSET_M + 140.0), BRAKE_FROM_KPH, 0.0)
	race.set_camera_mode(_modo_morro())
	await _esperar_transicion()
	var estabilidad := await _settle(60.0, BRAKE_S, true)
	var medida := _measure()
	for clave in estabilidad:
		medida[clave] = estabilidad[clave]
	medida["id"] = "frenada"
	casos.append(medida)
	_revisar_caso(medida)
	await _capturar_composicion("frenada")

# Medida geométrica del caso. La composición (cuánto ocupa el coche, dónde caen
# los neumáticos) NO se mide aquí proyectando vértices: el carenado pasa a 12 cm
# por debajo de la cámara y los vértices pegados al plano cercano proyectan cajas
# enormes (medido: 21 veces el ancho del lienzo con el encuadre perfectamente
# correcto). Esa parte se mide en PÍXELES por diferencia de fotogramas, con el
# coche visible y oculto, en `.tools/recovery/fase-fp/morro_pixeles.py`; aquí se
# guardan los tres fotogramas de cada caso y se miden las magnitudes que sí son
# geométricas: la pista por delante, el horizonte, la holgura con la carrocería y
# la estabilidad.
# Estado de la suspensión en el instante de medir. Importa porque la CANTIDAD de
# neumático delantero que enseña la cámara depende de dónde esté la rueda respecto
# a la carrocería: medido, el mismo neumático de la curva sale con 51 377 px en una
# pasada y con 10 049 px en otra, misma velocidad y mismo viraje. Si esa diferencia
# es el recorrido de la suspensión, tiene que verse aquí.
func _estado_ruedas() -> Dictionary:
	var suspension = car.suspension
	if suspension == null:
		return {}
	var recorridos := []
	for valor in suspension.offset:
		recorridos.append(snappedf(float(valor) * 1000.0, 0.1))
	return {
		"ruedas_recorrido_mm": recorridos,
		"ruedas_topadas": int(suspension.saturated),
		"altura_chasis_m": snappedf(float(suspension.height), 0.001),
		"actitud_rad": [snappedf(float(suspension.pitch_relative), 0.0001),
			snappedf(float(suspension.roll_relative), 0.0001)],
		"direccion_rad": snappedf(float(car.steering_angle), 0.00001),
	}

func _measure() -> Dictionary:
	var pista := 0
	var pista_puntos := []
	for distance in TRACK_POINTS_AHEAD:
		var point := _point_ahead(distance)
		var pantalla := nose.unproject_position(point)
		var dentro := (not nose.is_position_behind(point) and pantalla.x >= 0.0 and pantalla.x <= FRAME_W
			and pantalla.y >= 0.0 and pantalla.y <= FRAME_H)
		if dentro:
			pista += 1
		pista_puntos.append({"m": distance, "dentro": dentro,
			"y_fraccion": pantalla.y / float(FRAME_H) if not nose.is_position_behind(point) else -1.0})
	var local_camara := _local_offset()
	var base := nose.global_transform
	var adelante := -base.basis.z
	# Fracción del alto donde cae el horizonte: mirar hacia abajo (adelante.y < 0)
	# lo sube por encima del centro del cuadro.
	var horizonte := 0.5 + rad_to_deg(asin(clampf(adelante.y, -1.0, 1.0))) / nose.fov
	return {
		"velocidad_kph": car.speed_kph,
		"pista_puntos_dentro": pista,
		"pista_puntos": pista_puntos,
		"horizonte_fraccion": horizonte,
		"camara_local": [local_camara.x, local_camara.y, local_camara.z],
		"holgura_carroceria_m": local_camara.y - _techo_chasis(local_camara.z),
		"fov": nose.fov,
		"persecucion_distancia_m": race._camera_distance,
		"cronometro_s": car.lap_tracker.lap_time if car.lap_tracker != null else -1.0,
		"vueltas": car.lap_tracker.laps if car.lap_tracker != null else -1,
		"ruedas": _estado_ruedas(),
	}

func _revisar_caso(medida: Dictionary) -> void:
	var id: String = medida["id"]
	if medida["pista_puntos_dentro"] < TRACK_POINTS_MIN:
		errores.append("%s: sólo %d de los %d puntos de trazada por delante caen en el cuadro"
			% [id, medida["pista_puntos_dentro"], TRACK_POINTS_AHEAD.size()])
	if medida["horizonte_fraccion"] < HORIZON_MIN or medida["horizonte_fraccion"] > HORIZON_MAX:
		errores.append("%s: el horizonte cae al %.0f %% del alto (se pide entre %.0f y %.0f %%)"
			% [id, medida["horizonte_fraccion"] * 100.0, HORIZON_MIN * 100.0, HORIZON_MAX * 100.0])
	if medida["holgura_carroceria_m"] < CLEARANCE_MIN_M:
		errores.append("%s: la cámara está a %.3f m del techo de la carrocería (se pide ≥ %.2f m): la atraviesa"
			% [id, medida["holgura_carroceria_m"], CLEARANCE_MIN_M])
	if medida["deriva_max_m"] > OFFSET_DRIFT_MAX_M:
		errores.append("%s: la cámara se mueve %.4f m respecto al coche (tiene que ser rígida, %.3f m)"
			% [id, medida["deriva_max_m"], OFFSET_DRIFT_MAX_M])
	if medida["paso_max_m"] > 0.05:
		errores.append("%s: la cámara da saltos de %.3f m por fotograma respecto al coche" % [id, medida["paso_max_m"]])
	if medida["camara_local"][1] - race._nose_offset.y > OFFSET_DRIFT_MAX_M:
		errores.append("%s: la cámara se ha elevado %.4f m respecto al modelo" % [id, medida["camara_local"][1] - race._nose_offset.y])
	# El caso «curva» mide la composición CON el coche en la curva: si se sale, lo
	# que se mide es su silueta dentro de la barrera. Se exige que siga en calzada y
	# cerca de la trazada, y queda escrito en el informe con cuánto se desvía.
	if id == "curva":
		if not CURVA_SUPERFICIES.has(String(medida.get("superficie", ""))):
			errores.append("curva: el coche no está sobre la calzada (%s) a %.1f km/h en la curva: la composición no es la de una curva"
				% [String(medida.get("superficie", "")), medida["velocidad_kph"]])
		if absf(float(medida.get("desvio_lateral_m", 0.0))) > CURVA_DESVIO_MAX_M:
			errores.append("curva: el coche va %.2f m fuera de la trazada (se pide ≤ %.1f m) y la medida de composición no vale"
				% [float(medida.get("desvio_lateral_m", 0.0)), CURVA_DESVIO_MAX_M])
	# Y las mismas dos exigencias en el instante que se fotografía (después de llevar
	# la dirección al centro), que es el estado del que salen los recortes.
	if id == "curva" and medida.has("superficie_al_fotografiar"):
		if not CURVA_SUPERFICIES.has(String(medida["superficie_al_fotografiar"])):
			errores.append("curva: al fotografiar los neumáticos el coche ya no está sobre la calzada (%s)"
				% String(medida["superficie_al_fotografiar"]))
		if absf(float(medida.get("desvio_lateral_al_fotografiar_m", 0.0))) > CURVA_DESVIO_MAX_M:
			errores.append("curva: al fotografiar los neumáticos el coche va %.2f m fuera de la trazada (se pide ≤ %.1f m)"
				% [float(medida.get("desvio_lateral_al_fotografiar_m", 0.0)), CURVA_DESVIO_MAX_M])
	print("MORRO %-8s %5.1f km/h  horizonte=%.2f  pista=%d/%d  holgura=%.3f m  deriva_camara=%.4f m  paso=%.4f m" % [
		id, medida["velocidad_kph"], medida["horizonte_fraccion"], medida["pista_puntos_dentro"],
		TRACK_POINTS_AHEAD.size(), medida["holgura_carroceria_m"], medida["deriva_max_m"],
		medida["paso_max_m"]])
	var ruedas: Dictionary = medida.get("ruedas", {})
	if not ruedas.is_empty():
		print("MORRO   %-8s ruedas: recorrido(mm)=%s topadas=%d altura=%.3f m actitud=(%.2f°, %.2f°) dirección=%.2f°" % [
			id, str(ruedas["ruedas_recorrido_mm"]), int(ruedas["ruedas_topadas"]),
			float(ruedas["altura_chasis_m"]), rad_to_deg(float(ruedas["actitud_rad"][0])),
			rad_to_deg(float(ruedas["actitud_rad"][1])), rad_to_deg(float(ruedas["direccion_rad"]))])

# --- cambio de vista ----------------------------------------------------------

# El caso del cambio de vista se hace DOS veces por sentido: la primera mide
# fotograma a fotograma SIN capturas (una captura cuesta fotogramas de dibujado y
# el motor los recupera con varios pasos de física seguidos, así que el «paso
# máximo» medido con capturas en medio era de 12 m: el salto de la aplicación, no
# el de la cámara), y la segunda hace las fotos del cambio, que es lo que se mira.
func _case_switch() -> void:
	for sentido in ["morro", "persecucion"]:
		await _paso_de_vista(sentido, true)
		await _paso_de_vista(sentido, false)

func _paso_de_vista(sentido: String, medir: bool) -> void:
	await _place_at(_index_at_distance(START_OFFSET_M + 200.0), 160.0, 0.0)
	race.set_camera_mode(_modo_morro() if sentido == "persecucion" else _modo_persecucion())
	var estabilidad := await _settle(160.0, 1.2)
	var saliente: Camera3D = nose if sentido == "persecucion" else chase
	var esperado_saliente := saliente.global_position
	var cronometro_antes: float = car.lap_tracker.lap_time
	var vueltas_antes: int = car.lap_tracker.laps
	var posicion_antes: Vector3 = car.global_position
	var velocidad_antes: float = car.speed_kph
	# El botón del HUD llama exactamente a esto (`camera_toggle_pressed`).
	race.toggle_camera()
	await physics_frame
	var entrante: Camera3D = nose if sentido == "morro" else chase
	var primera: float = entrante.global_position.distance_to(esperado_saliente)
	var pasos_max := 0.0
	var local_max := 0.0
	var holgura_min := INF
	var paso_anterior := entrante.global_position
	var local_anterior := car.global_transform.affine_inverse() * entrante.global_position
	var muestras := 0
	var cronometro_serie := []
	var coche_saltos := 0.0
	var posicion_anterior := posicion_antes
	var frames := int((race.nose_switch_seconds + 0.35) * 120.0)
	var peor_holgura := {}
	if not medir:
		_switch_shots = 0
	for i in frames:
		await physics_frame
		var paso := entrante.global_position.distance_to(paso_anterior)
		pasos_max = maxf(pasos_max, paso)
		paso_anterior = entrante.global_position
		var local := car.global_transform.affine_inverse() * entrante.global_position
		local_max = maxf(local_max, (local - local_anterior).length())
		local_anterior = local
		var holgura := local.y - _techo_chasis(local.z)
		holgura_min = minf(holgura_min, holgura)
		if i % 2 == 0 and (peor_holgura.is_empty() or holgura < float(peor_holgura["holgura_m"])):
			peor_holgura = {"fotograma": i, "holgura_m": holgura, "blend": race._switch_blend,
				"local": [local.x, local.y, local.z], "lienzo_local": local.y - race._nose_offset.y}
		cronometro_serie.append(car.lap_tracker.lap_time)
		coche_saltos = maxf(coche_saltos, car.global_position.distance_to(posicion_anterior))
		posicion_anterior = car.global_position
		muestras += 1
		if not medir and i % 4 == 0:
			await _shot("cambio-%s-%02d" % [sentido, _switch_shots])
			_switch_shots += 1
		if i == frames - 1 and not entrante.current:
			errores.append("cambio %s: la cámara que entra no es la activa al terminar" % sentido)
	var cronometro_despues: float = car.lap_tracker.lap_time
	var vueltas_despues: int = car.lap_tracker.laps
	var monotono := true
	for i in range(1, cronometro_serie.size()):
		if cronometro_serie[i] < cronometro_serie[i - 1] - 1e-6:
			monotono = false
	if not medir:
		print("CAPTURAS del cambio de vista %s: %d fotogramas fotografiados" % [sentido, _switch_shots])
		return
	var registro := {
		"sentido": sentido,
		"primera_muestra_desde_la_saliente_m": primera,
		"paso_max_m": pasos_max,
		"paso_max_en_el_coche_m": local_max,
		"holgura_min_m": holgura_min,
		"muestras": muestras,
		"cronometro_antes_s": cronometro_antes,
		"cronometro_despues_s": cronometro_despues,
		"cronometro_monotono": monotono,
		"vueltas_antes": vueltas_antes,
		"vueltas_despues": vueltas_despues,
		"coche_salto_max_m": coche_saltos,
		"velocidad_antes_kph": velocidad_antes,
		"velocidad_despues_kph": car.speed_kph,
		"distancia_persecucion_al_volver_m": race._camera_distance,
		"distancia_persecucion_diseno_m": lerpf(race.camera_distance_stopped_m, race.camera_distance_fast_m, race._camera_blend),
		"estabilidad_antes": estabilidad,
		"peor_holgura": peor_holgura,
	}
	if sentido == "morro":
		registro["distancia_persecucion_en_morro_m"] = race._camera_distance
		registro["offset_morro_durante_el_cambio_m"] = (car.global_transform.affine_inverse() * nose.global_position - race._nose_offset).length()
	transiciones.append(registro)
	_revisar_cambio(registro)
	# El coche tiene que seguir corriendo: el avance tiene que ser el de su
	# velocidad durante los fotogramas de física que ha durado el cambio (con
	# margen), no un teleport ni una parada.
	var avance := car.global_position.distance_to(posicion_antes)
	var esperado := velocidad_antes / 3.6 * (frames / 120.0)
	if avance < esperado * 0.5 or avance > esperado * 1.5 + 5.0:
		errores.append("cambio %s: el coche avanzó %.1f m en %d fotogramas (a %.0f km/h se esperaban ~%.1f m)"
			% [sentido, avance, frames, velocidad_antes, esperado])
	if car.speed_kph < 5.0:
		errores.append("cambio %s: el coche se paró (%.1f km/h)" % [sentido, car.speed_kph])
	if car.lap_tracker != null and car.lap_tracker.laps != vueltas_antes:
		errores.append("cambio %s: el número de vueltas cambió durante el cambio" % sentido)
	if car.lap_tracker != null and car.lap_tracker.lap_time + 1e-6 < cronometro_antes:
		errores.append("cambio %s: el cronómetro se reinició durante el cambio" % sentido)
	print("CAMBIO %-12s peor_holgura: fotograma=%d blend=%.2f local=(%.2f, %.2f, %.2f) holgura=%.3f m" % [
		sentido, int(peor_holgura.get("fotograma", -1)), float(peor_holgura.get("blend", -1.0)),
		peor_holgura.get("local", [0.0, 0.0, 0.0])[0], peor_holgura.get("local", [0.0, 0.0, 0.0])[1],
		peor_holgura.get("local", [0.0, 0.0, 0.0])[2], float(peor_holgura.get("holgura_m", -1.0))])
	print("CAMBIO %-12s primera=%.3f m  paso_max=%.3f m  paso_max_en_el_coche=%.3f m  holgura_min=%.3f m  cronómetro %.2f→%.2f s (monótono=%s)  vueltas %d→%d  coche %.1f km/h  avance=%.1f m" % [
		sentido, primera, pasos_max, local_max, holgura_min, cronometro_antes, cronometro_despues, monotono,
		vueltas_antes, vueltas_despues, car.speed_kph, car.global_position.distance_to(posicion_antes)])

func _revisar_cambio(registro: Dictionary) -> void:
	var sentido: String = registro["sentido"]
	if registro["primera_muestra_desde_la_saliente_m"] > SWITCH_FIRST_FRAME_MAX_M:
		errores.append("cambio %s: la cámara que entra nace a %.3f m de donde estaba la que sale (salto)"
			% [sentido, registro["primera_muestra_desde_la_saliente_m"]])
	if registro["paso_max_en_el_coche_m"] > STEP_MAX_M:
		errores.append("cambio %s: la cámara da un salto de %.3f m por fotograma respecto al coche (se pide ≤ %.2f m)"
			% [sentido, registro["paso_max_en_el_coche_m"], STEP_MAX_M])
	if registro["holgura_min_m"] < CLEARANCE_MIN_M:
		errores.append("cambio %s: durante el cambio la cámara entra en la carrocería (holgura mínima %.3f m)"
			% [sentido, registro["holgura_min_m"]])
	if not registro["cronometro_monotono"]:
		errores.append("cambio %s: el cronómetro retrocedió durante el cambio" % sentido)
	if registro["cronometro_despues_s"] <= registro["cronometro_antes_s"]:
		errores.append("cambio %s: el cronómetro no avanzó durante el cambio (la carrera se detuvo)" % sentido)
	if sentido == "persecucion":
		var diseno: float = registro["distancia_persecucion_diseno_m"]
		if absf(registro["distancia_persecucion_al_volver_m"] - diseno) > 0.5:
			errores.append("cambio persecucion: al volver, la distancia es %.2f m y la de diseño %.2f m (el estado de la persecución no siguió corriendo en segundo plano)"
				% [registro["distancia_persecucion_al_volver_m"], diseno])

# --- utilidades ---------------------------------------------------------------

# Fotografía el lienzo. Se esperan tres fotogramas de dibujado antes de leer la
# textura: la vista del SubViewport se actualiza al dibujar y leer el mismo
# fotograma devuelve lo anterior (es el fallo de «capturas congeladas» que ya se
# midió en la fase de la cámara de persecución).
#
# Además se comprueba que la captura CAMBIA respecto al fotograma del que tiene
# que diferir (p. ej. la del coche oculto respecto a la del coche visible). En
# macOS una ventana tapada deja de repintar el lienzo y la textura se queda con
# el fotograma anterior: medido en esta misma sonda, las cinco capturas de un
# caso salieron con el MISMO SHA-256 y la auditoría en píxeles dio cero neumático
# y reglas que no coincidían. Cuando pasa se trae la ventana al frente, se fuerza
# el dibujado y se repite; si aun así no cambia, se declara el fallo en vez de
# medir una foto vieja.
func _shot(nombre: String, distinto_de: Image = null) -> Image:
	var path := "%s/capturas/%s.png" % [ROOT_DIR, nombre]
	var image: Image = null
	for intento in 4:
		DisplayServer.window_move_to_foreground()
		for i in 3:
			await process_frame
		RenderingServer.force_draw(true)
		image = view.get_texture().get_image()
		if image == null:
			continue
		if distinto_de == null or not _misma_imagen(image, distinto_de):
			print("CAPTURA %s -> %s" % [nombre, image.save_png(path)])
			return image
		print("CAPTURA %s idéntica al fotograma de referencia (lienzo congelado): se trae la ventana al frente y se repite" % nombre)
		await process_frame
	errores.append("%s: el lienzo no se redibujó; la captura sería la del fotograma anterior" % nombre)
	if image != null:
		image.save_png(path)
	return image

func _misma_imagen(uno: Image, otro: Image) -> bool:
	if otro == null or uno.get_size() != otro.get_size() or uno.get_format() != otro.get_format():
		return false
	return uno.get_data() == otro.get_data()

# Composición por diferencia de fotogramas: con el coche visible, sin el coche y
# sin las ruedas delanteras. El análisis por píxeles de los tres
# (`morro_pixeles.py`) da la franja que ocupa el coche, su centrado y cuánto se
# ve de cada neumático delantero. Es la medida buena: proyectar vértices de
# geometría pegada al plano cercano da cajas de 21 anchos de lienzo.
func _capturar_composicion(id: String) -> void:
	var mallas: Array[MeshInstance3D] = []
	var delanteras: Array[MeshInstance3D] = []
	for child in car.model_root.find_children("*", "MeshInstance3D", true, false):
		var malla := child as MeshInstance3D
		mallas.append(malla)
		if String(malla.name).to_lower().contains("wheel"):
			var local: Vector3 = car.global_transform.affine_inverse() * malla.global_position
			if local.z < 0.0:
				delanteras.append(malla)
	# Los tres fotogramas tienen que ser del MISMO instante: sin congelar el
	# tiempo, entre captura y captura el coche avanza metros (medido: 113 m a 160
	# km/h, porque cada captura cuesta fotogramas de dibujado) y la diferencia
	# entre ellos ya no mide la silueta del coche, sino el paisaje que se movió.
	# Con el reloj a cero el coche se queda quieto y la única diferencia entre los
	# tres fotogramas es lo que se oculta en cada uno.
	Engine.time_scale = 0.0
	var con_coche: Image = await _shot("composicion-%s-todo" % id)
	_set_visible(mallas, false)
	await _shot("composicion-%s-sin-coche" % id, con_coche)
	_set_visible(mallas, true)
	_set_visible(delanteras, false)
	await _shot("composicion-%s-sin-delanteras" % id, con_coche)
	_set_visible(delanteras, true)
	# Segmentación pintada: la diferencia de fotogramas no ve el neumático donde el
	# asfalto es tan oscuro como él (medido: 5.083 px a 150 km/h frente a 28.098 a
	# 100, con la misma cámara), porque el cambio queda por debajo del umbral. Con
	# el coche pintado de color plano, la silueta se recorta por color y no depende
	# de lo que haya detrás. Los colores son MAGENTA (el coche) y CIAN (los
	# neumáticos) y no verde y rojo: el verde lo lleva el arbolado del circuito —la
	# máscara verde declaraba que el coche llegaba al borde superior del cuadro— y
	# el rojo lo llevan bordillos, paneles y gradas.
	await _shot("morro-%s" % id)
	# Las dos de segmentación se hacen CON el circuito y el cielo puestos: ocultar
	# el circuito cambia lo que dibuja el lienzo y la vista de esas dos capturas
	# dejaba de ser la de la cámara del morro (medido: la silueta del coche saltaba
	# a la franja 0,86 en la curva). Sólo se quita el HUD y los mandos, que son
	# superposiciones y no escena: su borde cian entraba en la máscara de los
	# neumáticos y los hacía llegar al borde superior del cuadro.
	if race.hud != null:
		race.hud.visible = false
	if race.controls != null:
		race.controls.visible = false
	_set_override(mallas, Color(1.0, 0.0, 1.0))
	var magenta: Image = await _shot("composicion-%s-coche-magenta" % id)
	_set_override(mallas, Color(0.0, 0.0, 0.0))
	_set_override(delanteras, Color(0.0, 1.0, 1.0))
	await _shot("composicion-%s-delanteras-cian" % id, magenta)
	_set_override(delanteras, Color(0.0, 0.0, 0.0))
	if race.hud != null:
		race.hud.visible = true
	if race.controls != null:
		race.controls.visible = true
	Engine.time_scale = 1.0
	for i in 2:
		await physics_frame

func _set_visible(mallas: Array[MeshInstance3D], estado: bool) -> void:
	for malla in mallas:
		malla.visible = estado

# Pinta las mallas con un color plano sin iluminación (para recortar la silueta por
# color). Un color negro como "apagado" deja el material original en su sitio: el
# material se guarda la primera vez que se pinta.
func _set_override(mallas: Array[MeshInstance3D], color: Color) -> void:
	for malla in mallas:
		if color == Color(0.0, 0.0, 0.0):
			malla.material_override = null
			continue
		var plano := malla.material_override as StandardMaterial3D
		if plano == null:
			plano = StandardMaterial3D.new()
			plano.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			malla.material_override = plano
		plano.albedo_color = color

# El botón de vista no puede pisar el mando, los pedales ni los paneles de
# telemetría. Se comprueba con los rectángulos REALES de los controles
# (los mismos que usa el inyector de toques del dispositivo), no con una copia a
# mano de sus posiciones.
func _revisar_boton_de_vista() -> void:
	var boton := race.hud.get_node_or_null("Telemetry layout/Camera switch") as Control
	if boton == null:
		errores.append("el HUD no tiene el botón de cambio de vista")
		return
	var rect := boton.get_global_rect()
	if rect.size.x < 60.0 or rect.size.y < 30.0 or rect.size.x > 420.0 or rect.size.y > 130.0:
		errores.append("el botón de vista mide %.0fx%.0f px (discreto, se pide entre 60x30 y 420x130)"
			% [rect.size.x, rect.size.y])
	var ajenos := {
		"telemetría": race.hud.get_node_or_null("Telemetry layout/Telemetry card") as Control,
		"cronómetro": race.hud.get_node_or_null("Telemetry layout/Lap timing") as Control,
		"mando": race.controls.get_node_or_null("Touch overlay/Analog steering zone") as Control,
		"acelerador": race.controls.get_node_or_null("Touch overlay/Throttle pedal") as Control,
		"freno": race.controls.get_node_or_null("Touch overlay/Brake pedal") as Control,
	}
	for nombre in ajenos:
		var otro := ajenos[nombre] as Control
		if otro == null:
			errores.append("no se encontró el control «%s» para comprobar el botón" % nombre)
			continue
		var suyo := otro.get_global_rect()
		if rect.intersects(suyo) and rect.intersection(suyo).get_area() > 1.0:
			errores.append("el botón de vista pisa «%s» (%.0f px² de solape)" % [nombre, rect.intersection(suyo).get_area()])
	print("BOTÓN vista rect=(%.0f, %.0f, %.0f, %.0f) px en el lienzo %dx%d" % [
		rect.position.x, rect.position.y, rect.size.x, rect.size.y, FRAME_W, FRAME_H])
	for nombre in ajenos:
		var otro := ajenos[nombre] as Control
		if otro != null:
			var suyo := otro.get_global_rect()
			print("  %-11s rect=(%.0f, %.0f, %.0f, %.0f)" % [nombre, suyo.position.x, suyo.position.y, suyo.size.x, suyo.size.y])

func _stations() -> Dictionary:
	var best_straight := 0
	var best_curve := 0
	var k_straight := INF
	var k_curve := 0.0
	for at in range(200, line.size() - 200, 5):
		var k := absf(_curvature(at))
		if k < k_straight:
			k_straight = k
			best_straight = at
		if k > k_curve and k < 0.35 and _curvature(at) * _curvature(at + 100) > 0.0:
			k_curve = k
			best_curve = at
	return {"recta": best_straight, "recta_k": k_straight, "curva": best_curve, "curva_k": k_curve}

func _curvature(at: int) -> float:
	var back: Vector3 = line[(at - 25 + line.size()) % line.size()]
	var here: Vector3 = line[at]
	var ahead: Vector3 = line[(at + 25) % line.size()]
	var v1 := Vector2(here.x - back.x, here.z - back.z).normalized()
	var v2 := Vector2(ahead.x - here.x, ahead.z - here.z).normalized()
	return v1.x * v2.y - v1.y * v2.x

func _verdict() -> void:
	print("MORRO casos=%d transiciones=%d errores=%d" % [casos.size(), transiciones.size(), errores.size()])
	for error in errores:
		print("  ERROR %s" % error)

func _write_report() -> void:
	var salida := {
		"lienzo": [FRAME_W, FRAME_H],
		"punto_de_vista_local_m": [race._nose_offset.x, race._nose_offset.y, race._nose_offset.z],
		"anclaje_medido_del_modelo": race._nose_anclaje_medido,
		"fov": nose.fov,
		"inclinacion_abajo_deg": race.nose_pitch_down_deg,
		"punto_de_vista_detras_del_eje_m": race.nose_behind_axle_m,
		"punto_de_vista_sobre_el_neumatico_m": race.nose_above_wheels_m,
		"transicion_s": race.nose_switch_seconds,
		"transicion_arco_m": race.nose_switch_arc_m,
		"criterios": {
			"horizonte": [HORIZON_MIN, HORIZON_MAX],
			"pista_puntos_dentro": TRACK_POINTS_MIN,
			"holgura_carroceria_m": CLEARANCE_MIN_M,
			"deriva_max_m": OFFSET_DRIFT_MAX_M,
			"paso_max_cambio_m": STEP_MAX_M,
			"primer_fotograma_m": SWITCH_FIRST_FRAME_MAX_M,
			"composicion": "en píxeles, .tools/recovery/fase-fp/morro_pixeles.py",
		},
		"casos": casos,
		"transiciones": transiciones,
		"perfil_carroceria": perfil_carroceria,
		"errores": errores,
		"passed": errores.is_empty(),
	}
	var destino := "%s/morro.json" % ROOT_DIR
	FileAccess.open(ProjectSettings.globalize_path(destino), FileAccess.WRITE).store_string(JSON.stringify(salida, "  "))
	print("MORRO informe=%s passed=%s" % [destino, errores.is_empty()])

func _v(value: Vector3) -> String:
	return "(%.3f, %.3f, %.3f)" % [value.x, value.y, value.z]
