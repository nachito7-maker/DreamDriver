extends SceneTree

# Sonda de la SUSPENSIÓN del Red Bull (fase 3).
#
# Mide, sobre el árbol real de la escena de carrera y conduciendo con las entradas
# REALES del mapa de acciones, las diez pruebas de la fase 4:
#
#   1. parado sobre superficie plana
#   2. aceleración en recta
#   3. frenada en recta
#   4. curvas a velocidad moderada
#   5. curvas a velocidad elevada
#   6. paso por irregularidades (un resalto de PRUEBA, creado por esta sonda: no
#      existe en el juego ni se toca el circuito)
#   7. compresión y extensión de CADA rueda
#   8. ausencia de vibraciones o saltos artificiales
#   9. ausencia de penetración de las ruedas en el asfalto
#  10. conservación de la posición correcta de los cuatro neumáticos
#
# La sonda TIENE DIENTES: termina con código distinto de cero si la suspensión no
# existe, si el recorrido se sale de sus topes, si una rueda atraviesa el asfalto,
# si el cabeceo o el balanceo van al revés (acelerar debe agachar la cola, frenar
# debe hundir el morro y en curva deben hundirse las ruedas exteriores), si la
# altura del chasis vibra más de lo que permite un amortiguador o si la geometría
# de las ruedas dejó de coincidir con la que verificó la fase 2.
#
# Uso: "$GODOT" --path . --script scripts/suspension_probe.gd

const OUT_DIR := "res://.tools/recovery/fase3-suspension/vistas"
const DATA_PATH := "res://.tools/recovery/fase3-suspension/medidas.json"
const TrackScript = preload("res://scripts/track_data.gd")

# --- umbrales ---------------------------------------------------------------
const REPOSO_RECORRIDO_MAX_MM := 2.0     # parado, cada rueda vuelve a su sitio
const REPOSO_POSE_MAX_GRADOS := 1.0      # el chasis sigue el plano de la calzada
const AIRE_MAX_MM := 12.0                # separación fondo/asfalto admitida
const POSE_MARCHA_MAX_GRADOS := 2.5
const DESCOMPRESION_MAX_MM := 30.0       # tope de extensión del módulo
const COMPRESION_MAX_MM := 35.0          # tope de compresión del módulo
const VIAJE_MIN_ACELERACION_MM := 1.0    # recorrido que debe verse al acelerar
const VIAJE_MIN_FRENADA_MM := 2.0
const LATERAL_MIN_G := 0.30              # exigencia mínima en la curva moderada
const LATERAL_MIN_G_RAPIDA := 0.80       # y en la rápida
# Vibración: la segunda diferencia de la altura del chasis (mm por fotograma²).
# Una rampa del circuito da ~0,05; un salto o un rebote artificial da varios mm.
const VIBRACION_PICO_MAX_MM := 1.0
const VIBRACION_RMS_MAX_MM := 0.25
const GEOMETRIA_TOLERANCIA_M := 0.0005   # x, z de las ruedas respecto a su reposo
const PIVOTE_MAX := 0.0015
const RADIO := Vector2(0.30, 0.45)
const ANCHURA := Vector2(0.25, 0.55)

var race: Node3D
var car: CharacterBody3D
var errores: Array[String] = []
var medidas: Dictionary = {}
var line: PackedVector3Array
var index := 0
var estaciones: Dictionary = {}
var fixture: StaticBody3D
var home_positions: Dictionary = {}

# Acumuladores de todas las pruebas (se vuelcan al JSON y al informe).
var recorrido_min: Dictionary = {}
var recorrido_max: Dictionary = {}
var aire_peor := INF            # separación más negativa vista (penetración)
var aire_mejor := -INF
var altura_min := INF
var altura_max := -INF
var saturacion_max := 0
var contactos_min := 4
var cargadas_min := 4
var cabeceo_max := 0.0
var balanceo_max := 0.0
var cabeceo_rel_max := 0.0
var balanceo_rel_max := 0.0
var muestras_geometria := 0
var muestras_lejanas := 0

# --- arranque ---------------------------------------------------------------

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 120:
		await physics_frame
	car = race.car
	line = TrackScript.get_centerline()
	if car.suspension == null:
		errores.append("el coche no tiene suspensión: car.suspension es null")
		_finish()
		return
	for wheel in car._suspension_wheels:
		home_positions[_wheel_key(wheel)] = wheel.position
	estaciones = _stations()
	print("== estaciones: recta=%d curva=%d (radio medio) largo=%d" % [
		estaciones["recta"], estaciones["curva"], line.size()])
	await _test_reposo()
	await _test_aceleracion()
	await _test_frenada()
	await _test_curva_moderada()
	await _test_curva_rapida()
	await _test_resalto()
	await _test_vibracion()
	await _test_geometria()
	_resumen()
	race.queue_free()
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DATA_PATH).get_base_dir())
	FileAccess.open(DATA_PATH, FileAccess.WRITE).store_string(JSON.stringify(medidas, "  "))
	_finish()

func _finish() -> void:
	var ok: bool = errores.is_empty()
	for error in errores:
		print("  ERROR %s" % error)
	print("SUSPENSION passed=%s errores=%d medidas=%s" % [str(ok), errores.size(), DATA_PATH])
	quit(0 if ok else 1)

func _check(ok: bool, message: String) -> void:
	if not ok:
		errores.append(message)

# --- conducción -------------------------------------------------------------

func _inputs(throttle: float, brake: float, steer: float) -> void:
	if throttle > 0.001:
		Input.action_press("throttle", clampf(throttle, 0.0, 1.0))
	else:
		Input.action_release("throttle")
	if brake > 0.001:
		Input.action_press("brake", clampf(brake, 0.0, 1.0))
	else:
		Input.action_release("brake")
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if steer > 0.001:
		Input.action_press("steer_right", clampf(steer, 0.0, 1.0))
	elif steer < -0.001:
		Input.action_press("steer_left", clampf(-steer, 0.0, 1.0))

func _release() -> void:
	_inputs(0.0, 0.0, 0.0)

func _pursuit() -> float:
	var target: Vector3 = line[mini(line.size() - 1, index + 14)]
	var to_target: Vector3 = target - car.global_position
	var desired := atan2(-to_target.x, -to_target.z)
	var error := wrapf(desired - car.rotation.y, -PI, PI)
	return clampf(-error * 1.6, -1.0, 1.0)

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

func _yaw(at: int) -> float:
	var tangent: Vector3 = line[(at + 6) % line.size()] - line[(at - 6 + line.size()) % line.size()]
	return atan2(-tangent.x, -tangent.z)

func _place(at: int) -> void:
	index = at
	car.recover_to(line[at], _yaw(at))
	_release()

func _curvature(at: int) -> float:
	var back: Vector3 = line[(at - 25 + line.size()) % line.size()]
	var here: Vector3 = line[at]
	var ahead: Vector3 = line[(at + 25) % line.size()]
	var v1 := Vector2(here.x - back.x, here.z - back.z).normalized()
	var v2 := Vector2(ahead.x - here.x, ahead.z - here.z).normalized()
	return v1.x * v2.y - v1.y * v2.x

# Recta más larga y curva de radio medio del trazado (lejos del cierre de vuelta,
# donde los índices bajos y altos se tocan).
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

# --- muestreo ---------------------------------------------------------------

func _wheel_key(wheel: Node3D) -> String:
	return String(wheel.name).replace("wheel_", "")

func _wheels() -> Array:
	var out := []
	for wheel in car._suspension_wheels:
		out.append(wheel)
	return out

# Cada fotograma: recorrido por rueda, actitud, topes y contactos.
func _sample() -> void:
	var s = car.suspension
	saturacion_max = maxi(saturacion_max, s.saturated)
	contactos_min = mini(contactos_min, s.contacts)
	cargadas_min = mini(cargadas_min, s.loaded_contacts)
	altura_min = minf(altura_min, s.height)
	altura_max = maxf(altura_max, s.height)
	cabeceo_max = maxf(cabeceo_max, absf(s.pitch))
	balanceo_max = maxf(balanceo_max, absf(s.roll))
	cabeceo_rel_max = maxf(cabeceo_rel_max, absf(s.pitch_relative))
	balanceo_rel_max = maxf(balanceo_rel_max, absf(s.roll_relative))
	for i in s.offset.size():
		var key := _wheel_key(car._suspension_wheels[i])
		var mm: float = s.offset[i] * 1000.0
		recorrido_min[key] = minf(float(recorrido_min.get(key, 0.0)), mm)
		recorrido_max[key] = maxf(float(recorrido_max.get(key, 0.0)), mm)

# Separación real entre el fondo de cada neumático y el asfalto bajo su vertical.
# Se mide con la caja del motor (igual que car_wheel_probe) y sirve para la prueba
# de penetración: la caja de una rueda inclinada sobresale unos milímetros por
# debajo del neumático, y eso está dentro de la tolerancia.
func _sample_geometry() -> void:
	for wheel in _wheels():
		var clearance := _clearance(wheel)
		# Fuera de pista el rayo puede dar en el suelo del mundo a metros de
		# distancia: eso no es un contacto ni una penetración, y no se cuenta.
		if absf(clearance) > 0.5:
			muestras_lejanas += 1
			continue
		aire_peor = minf(aire_peor, clearance * 1000.0)
		aire_mejor = maxf(aire_mejor, clearance * 1000.0)
		muestras_geometria += 1

func _clearance(wheel: Node3D) -> float:
	var mesh: Mesh = wheel.mesh
	if mesh == null:
		return 0.0
	var aabb := mesh.get_aabb()
	var axes := _wheel_axes(aabb.size)
	var axle: Vector3 = (wheel.global_basis * axes[2]).normalized()
	var centre: Vector3 = wheel.global_transform * aabb.get_center()
	var bottom := _bottom(centre, axle, aabb.size[axes[1]], aabb.size[axes[0]])
	var ground := _ground_below(Vector3(centre.x, car.global_position.y, centre.z))
	if ground < -900.0:
		return 99.0
	return bottom - ground

func _bottom(centre: Vector3, axle: Vector3, diameter: float, width: float) -> float:
	var r := diameter * 0.5
	var hw := width * 0.5
	return centre.y - (hw * absf(axle.y) + r * sqrt(maxf(0.0, 1.0 - axle.y * axle.y)))

func _ground_below(point: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.5, point - Vector3.UP * 3.0, 1)
	var hit := root.world_3d.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return -999.0
	return (hit["position"] as Vector3).y

func _wheel_axes(size: Vector3) -> Array:
	var values := [size.x, size.y, size.z]
	var axes := [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	var small := 0
	for i in range(1, 3):
		if values[i] < values[small]:
			small = i
	var big := 0
	for i in range(1, 3):
		if i != small and values[i] > values[big]:
			big = i
	if big == small:
		big = 1 if small != 1 else 0
	return [small, big, axes[small]]

# Resumen de una prueba: recorridos por rueda entre dos instantes.
func _viajes() -> Dictionary:
	var out := {}
	for wheel in _wheels():
		var key := _wheel_key(wheel)
		out[key] = {"min_mm": float(recorrido_min.get(key, 0.0)), "max_mm": float(recorrido_max.get(key, 0.0))}
	return out

func _viajes_de(inicio: Dictionary) -> Dictionary:
	var out := {}
	for wheel in _wheels():
		var key := _wheel_key(wheel)
		out[key] = {
			"min_mm": float(recorrido_min.get(key, 0.0)) - float(inicio.get(key, {}).get("min_mm", 0.0)),
			"max_mm": float(recorrido_max.get(key, 0.0)) - float(inicio.get(key, {}).get("max_mm", 0.0)),
		}
	return out

func _snapshot_viajes() -> Dictionary:
	return _viajes()

# --- 1. parado sobre superficie plana ---------------------------------------

func _test_reposo() -> void:
	var at: int = estaciones["recta"]
	_place(at)
	for i in 240:
		await physics_frame
	index = _nearest(index)
	var s = car.suspension
	var pose := _pose_angle()
	var viajes := _viajes()
	var recorrido := 0.0
	for key in viajes:
		recorrido = maxf(recorrido, maxf(absf(viajes[key]["min_mm"]), absf(viajes[key]["max_mm"])))
	var aire := 0.0
	for wheel in _wheels():
		aire = maxf(aire, absf(_clearance(wheel) * 1000.0))
	var cargas := _cargas_por_eje()
	print("\n== 1. REPOSO  velocidad=%.1f km/h contacto=%d cargadas=%d pose=%.2f°" % [
		car.speed_kph, s.contacts, s.loaded_contacts, pose])
	print("   recorrido máx=%.1f mm (tope %.1f)  aire fondo-asfalto máx=%.1f mm (tope %.1f)  carga del.=%.0f N tras.=%.0f N" % [
		recorrido, REPOSO_RECORRIDO_MAX_MM, aire, AIRE_MAX_MM, cargas["delantera"], cargas["trasera"]])
	print("   altura del plano=%.4f m  cabeceo=%+.3f°  balanceo=%+.3f°" % [
		s.height, rad_to_deg(s.pitch), rad_to_deg(s.roll)])
	_check(car.wheel_contacts == 4, "REPOSO: contacto de ruedas=%d y se esperan 4" % car.wheel_contacts)
	_check(pose <= REPOSO_POSE_MAX_GRADOS,
		"REPOSO: el chasis se separa %.2f° del plano de la calzada (máx %.1f)" % [pose, REPOSO_POSE_MAX_GRADOS])
	_check(recorrido <= REPOSO_RECORRIDO_MAX_MM,
		"REPOSO: el recorrido de alguna rueda es %.1f mm y el máximo admitido es %.1f" % [recorrido, REPOSO_RECORRIDO_MAX_MM])
	_check(aire <= AIRE_MAX_MM,
		"REPOSO: una rueda queda a %.1f mm del asfalto (máx %.1f)" % [aire, AIRE_MAX_MM])
	# El reparto estático entre ejes debe respetar el 46 % delantero del coche.
	var total: float = cargas["delantera"] + cargas["trasera"]
	_check(absf(cargas["delantera"] / maxf(total, 1.0) - 0.46) <= 0.04,
		"REPOSO: el reparto delantero es %.3f y el coche declara 0.460" % [cargas["delantera"] / maxf(total, 1.0)])
	medidas["reposo"] = {
		"pose_grados": pose, "recorrido_max_mm": recorrido, "aire_max_mm": aire,
		"altura_m": s.height, "cabeceo_grados": rad_to_deg(s.pitch), "balanceo_grados": rad_to_deg(s.roll),
		"carga_delantera_n": cargas["delantera"], "carga_trasera_n": cargas["trasera"], "viajes": viajes,
	}
	await _shots("reposo")

# --- 2. aceleración en recta ------------------------------------------------

func _test_aceleracion() -> void:
	var at: int = estaciones["recta"]
	_place(at)
	for i in 60:
		await physics_frame
	# Primero se llega a velocidad de crucero y desde ahí se pisa a fondo: lo que
	# se mide es la respuesta a la aceleración, no el arranque desde parado.
	for i in 300:
		_inputs(0.5, 0.0, _pursuit())
		index = _nearest(index)
		await physics_frame
	var inicio := _snapshot_viajes()
	var v0: float = car.speed_kph
	var pitch0: float = car.suspension.pitch_relative
	var aceleracion := 0.0
	for i in 210:
		_inputs(1.0, 0.0, _pursuit())
		index = _nearest(index)
		_sample()
		if i % 5 == 0:
			_sample_geometry()
		await physics_frame
		aceleracion = maxf(aceleracion, car.acceleration_longitudinal)
	_release()
	var s = car.suspension
	var delta := _viajes_de(inicio)
	print("\n== 2. ACELERACIÓN  %.1f → %.1f km/h a fondo (3,5 s)  a máx=%.2f m/s2" % [v0, car.speed_kph, aceleracion])
	print("   cabeceo de suspensión: %+.3f° → %+.3f° (positivo = morro arriba)  altura del plano=%.4f m" % [
		rad_to_deg(pitch0), rad_to_deg(s.pitch_relative), s.height])
	for key in delta:
		print("   %-3s recorrido %.1f … %+.1f mm" % [key, delta[key]["min_mm"], delta[key]["max_mm"]])
	# Al acelerar: la cola se agacha (cabeceo positivo) y las ruedas traseras se
	# comprimen más que las delanteras, que se descargan.
	var delantera := _eje(delta, true)
	var trasera := _eje(delta, false)
	_check(s.pitch_relative >= 0.03,
		"ACELERACIÓN: el cabeceo de suspensión es %+.3f° y al acelerar debe ser positivo (morro arriba, mínimo 0.03°)" % rad_to_deg(s.pitch_relative))
	_check(trasera["max_mm"] >= VIAJE_MIN_ACELERACION_MM,
		"ACELERACIÓN: las ruedas traseras no se comprimen (%.2f mm)" % trasera["max_mm"])
	_check(delantera["min_mm"] <= -VIAJE_MIN_ACELERACION_MM,
		"ACELERACIÓN: las ruedas delanteras no se extienden (%.2f mm)" % delantera["min_mm"])
	_check(trasera["max_mm"] > delantera["max_mm"],
		"ACELERACIÓN: la compresión trasera (%.2f mm) no supera a la delantera (%.2f mm)" % [
			trasera["max_mm"], delantera["max_mm"]])
	_check(car.speed_kph > 150.0, "ACELERACIÓN: no pasó de %.1f km/h en la recta" % car.speed_kph)
	medidas["aceleracion"] = {
		"velocidad_inicial_kph": v0, "velocidad_final_kph": car.speed_kph,
		"aceleracion_max_m_s2": aceleracion,
		"cabeceo_suspension_grados": rad_to_deg(s.pitch_relative), "viajes": delta,
	}
	await _shots("aceleracion")

# --- 3. frenada en recta ----------------------------------------------------

func _test_frenada() -> void:
	var inicio := _snapshot_viajes()
	var v0: float = car.speed_kph
	var pitch0: float = rad_to_deg(car.suspension.pitch_relative)
	var frenada_max := 0.0
	for i in 180:
		_inputs(0.0, 1.0, _pursuit())
		index = _nearest(index)
		_sample()
		if i % 5 == 0:
			_sample_geometry()
		await physics_frame
		frenada_max = maxf(frenada_max, -car.acceleration_longitudinal)
	_release()
	var s = car.suspension
	var delta := _viajes_de(inicio)
	print("\n== 3. FRENADA  %.1f → %.1f km/h  desaceleración máx=%.2f m/s2" % [v0, car.speed_kph, frenada_max])
	print("   cabeceo de suspensión: %+.3f° → %+.3f° (negativo = morro abajo)  altura del plano=%.4f m" % [
		pitch0, rad_to_deg(s.pitch_relative), s.height])
	for key in delta:
		print("   %-3s recorrido %.1f … %+.1f mm" % [key, delta[key]["min_mm"], delta[key]["max_mm"]])
	var delantera := _eje(delta, true)
	var trasera := _eje(delta, false)
	_check(frenada_max >= 6.0, "FRENADA: la desaceleración sólo llegó a %.2f m/s2" % frenada_max)
	_check(s.pitch_relative <= -0.03,
		"FRENADA: el cabeceo de suspensión es %+.3f° y al frenar debe ser negativo (morro abajo, máximo -0.03°)" % rad_to_deg(s.pitch_relative))
	_check(delantera["max_mm"] >= VIAJE_MIN_FRENADA_MM,
		"FRENADA: las ruedas delanteras no se comprimen (%.2f mm)" % delantera["max_mm"])
	_check(trasera["min_mm"] <= -VIAJE_MIN_FRENADA_MM,
		"FRENADA: las ruedas traseras no se extienden (%.2f mm)" % trasera["min_mm"])
	_check(delantera["max_mm"] > trasera["max_mm"],
		"FRENADA: la compresión delantera (%.2f mm) no supera a la trasera (%.2f mm)" % [
			delantera["max_mm"], trasera["max_mm"]])
	for key in delta:
		_check(delta[key]["min_mm"] >= -DESCOMPRESION_MAX_MM - 0.01 and delta[key]["max_mm"] <= COMPRESION_MAX_MM + 0.01,
			"FRENADA %s: recorrido fuera de los topes (%.2f … %+.2f mm)" % [key, delta[key]["min_mm"], delta[key]["max_mm"]])
	medidas["frenada"] = {
		"velocidad_inicial_kph": v0, "velocidad_final_kph": car.speed_kph,
		"desaceleracion_max_m_s2": frenada_max,
		"cabeceo_suspension_grados": rad_to_deg(s.pitch_relative), "viajes": delta,
	}
	await _shots("frenada")

# --- 4 y 5. curvas ----------------------------------------------------------

func _test_curva_moderada() -> void:
	# Se entra desde 150 índices antes (unos 220 m) para llegar rodando a la curva.
	await _curva("4. CURVA MODERADA", 0.34, 900, LATERAL_MIN_G, false, 150)

func _test_curva_rapida() -> void:
	# Se entra desde antes: a esta curva hay que llegar con velocidad, no desde
	# parado en el vértice.
	await _curva("5. CURVA RÁPIDA", 0.80, 1400, LATERAL_MIN_G_RAPIDA, true, 260)

func _curva(titulo: String, throttle: float, frames: int, lateral_min: float, rapida: bool, back := 0) -> void:
	var at: int = wrapi(int(estaciones["curva"]) - back, 0, line.size())
	_place(at)
	for i in 60:
		await physics_frame
	var inicio := _snapshot_viajes()
	var lateral := 0.0
	var lateral_muestras := 0
	var roll := 0.0
	var velocidades: Array[float] = []
	# El recorrido puede pasar por zonas muy distintas; se guarda la muestra con
	# más aceleración lateral, que es la situación que la prueba quiere medir.
	var mejor := {"lateral": 0.0, "firmado": 0.0, "viajes": {}, "roll": 0.0, "velocidad": 0.0, "altura": 0.0}
	for i in frames:
		_inputs(throttle, 0.0, _pursuit())
		index = _nearest(index)
		_sample()
		if i % 5 == 0:
			_sample_geometry()
		await physics_frame
		var g := absf(car.acceleration_lateral) / 9.81
		if g >= 0.10 and absf(car.steering_angle) > 0.02:
			lateral = maxf(lateral, g)
			lateral_muestras += 1
			velocidades.append(car.speed_kph)
			roll = maxf(roll, absf(car.suspension.roll))
			if g > float(mejor["lateral"]):
				mejor["lateral"] = g
				mejor["firmado"] = car.acceleration_lateral
				mejor["roll"] = rad_to_deg(car.suspension.roll_relative)
				mejor["velocidad"] = car.speed_kph
				mejor["altura"] = car.suspension.height
				mejor["viajes"] = _viajes_de(inicio)
	_release()
	var viajes: Dictionary = mejor["viajes"]
	var velocidad := 0.0
	if not velocidades.is_empty():
		velocidad = velocidades[velocidades.size() / 2]
	print("\n== %s  curva en %d  velocidad mediana=%.1f km/h  lateral máx=%.2f g (%.0f muestras)" % [
		titulo, estaciones["curva"], velocidad, lateral, lateral_muestras])
	print("   en el vértice: %.1f km/h, %.2f g, balanceo de suspensión=%+.3f°, altura=%.4f m" % [
		mejor["velocidad"], mejor["lateral"], mejor["roll"], mejor["altura"]])
	for key in viajes:
		print("   %-3s recorrido %.1f … %+.1f mm" % [key, viajes[key]["min_mm"], viajes[key]["max_mm"]])
	_check(lateral >= lateral_min,
		"%s: la curva sólo llegó a %.2f g (mínimo %.2f); no se puede juzgar la suspensión" % [titulo, lateral, lateral_min])
	# Sentido físico del balanceo: en una curva a la izquierda (aceleración lateral
	# positiva) el chasis se apoya en las ruedas derechas, que son las exteriores.
	var firmado: float = mejor["firmado"]
	_check(absf(float(mejor["roll"])) >= 0.01 and firmado * float(mejor["roll"]) < 0.0,
		"%s: el balanceo de suspensión (%+.3f°) no se opone al lado exterior (a_lat=%+.2f m/s2)" % [titulo, mejor["roll"], firmado])
	# Diferencia de recorrido entre el lado izquierdo y el derecho en el vértice:
	# es la transferencia de carga, y debe existir y ser razonable.
	var izq := _lado(viajes, false)
	var der := _lado(viajes, true)
	print("   transferencia: izquierda %.2f mm / derecha %.2f mm (diferencia %.2f mm, a_lat=%+.2f m/s2)" % [
		izq, der, absf(izq - der), firmado])
	_check(absf(izq - der) >= 0.5,
		"%s: los dos lados se mueven casi igual (%.2f mm); no hay transferencia de carga" % [titulo, absf(izq - der)])
	_check((der - izq) * firmado > 0.0,
		"%s: el lado cargado no es el exterior (izq %.2f, der %.2f, a_lat %+.2f)" % [titulo, izq, der, firmado])
	medidas[titulo] = {
		"lateral_max_g": lateral, "lateral_firmado_m_s2": firmado,
		"balanceo_suspension_grados": mejor["roll"], "velocidad_kph": mejor["velocidad"],
		"altura_m": mejor["altura"], "viajes_vertice": viajes, "lado_izquierdo_mm": izq, "lado_derecho_mm": der,
	}
	await _shots("curva_%s" % ("rapida" if rapida else "moderada"))

# Media del recorrido (el punto medio entre su mínimo y su máximo) de un lado.
func _lado(viajes: Dictionary, derecha: bool) -> float:
	var total := 0.0
	var cuenta := 0
	for key in viajes:
		if _es_derecha(key) == derecha:
			total += (float(viajes[key]["min_mm"]) + float(viajes[key]["max_mm"])) * 0.5
			cuenta += 1
	return total / maxf(1.0, float(cuenta))

func _es_derecha(key: String) -> bool:
	return key.ends_with("r")

# --- 6. paso por irregularidades --------------------------------------------

# Resalto de PRUEBA. Lo crea esta sonda en el mundo de la física: no existe en el
# juego, no se toca el circuito y no colisiona con la caja del coche (0,30 m de
# ancho, colocados justo bajo las dos ruedas izquierdas, fuera de los 1,20 m de la
# caja central). Sirve para medir el recorrido de suspensión ante un escalón real
# de 30 mm, que es lo que un badén del circuito provoca.
func _make_bump() -> void:
	var left: Vector3 = car.global_transform * Vector3(-0.93, 0.0, 0.0)
	var ground := _ground_below(left)
	var forward: Vector3 = -car.global_basis.z
	var body := StaticBody3D.new()
	body.name = "Resalto de prueba 30 mm"
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("ac_surface", "ASPHALT")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.30, 0.06, 3.0)
	shape.shape = box
	body.add_child(shape)
	# Primero al árbol y después la posición global: Godot no admite fijar
	# `global_position` a un nodo que todavía no está dentro del árbol.
	race.add_child(body)
	body.global_position = Vector3(left.x, ground, left.z) + forward * 14.0
	fixture = body
	print("\n== 6. RESALTO de prueba: 30 mm de alto × 0,30 m de ancho × 3,00 m de largo")
	print("   colocado bajo las ruedas izquierdas a 14 m, asfalto medido en %.4f m" % ground)

func _test_resalto() -> void:
	# Sobre la recta, asentado y mirando recto: desde ahí el coche avanza sin tocar
	# la dirección y pasa por encima del resalto con las dos ruedas izquierdas.
	_place(int(estaciones["recta"]))
	for i in 90:
		await physics_frame
	_make_bump()
	var inicio := _snapshot_viajes()
	var aire_antes := aire_peor
	var alcanzado := false
	var pico_izq := 0.0
	var pico_der := 0.0
	var altura_antes: float = car.suspension.height
	var altura_pico := 0.0
	for i in 300:
		# Sin dirección: el coche va recto por la recta de meta y pasa por encima
		# del resalto con las dos ruedas izquierdas.
		_inputs(0.35 if not alcanzado else 0.25, 0.0, 0.0)
		index = _nearest(index)
		_sample()
		_sample_geometry()
		await physics_frame
		var viajes := _viajes_de(inicio)
		var izq := _lado(viajes, false)
		var der := _lado(viajes, true)
		pico_izq = maxf(pico_izq, izq)
		pico_der = minf(pico_der, der)
		altura_pico = maxf(altura_pico, absf(car.suspension.height - altura_antes))
		if absf(izq) > 3.0 and not alcanzado:
			alcanzado = true
			print("   contacto con el resalto en el fotograma %d a %.1f km/h" % [i, car.speed_kph])
	_release()
	var viajes := _viajes_de(inicio)
	print("   pico de recorrido: izquierda %+.1f mm / derecha %+.1f mm  (altura del chasis %+.1f mm)" % [
		pico_izq, pico_der, altura_pico * 1000.0])
	for key in viajes:
		print("   %-3s recorrido %.1f … %+.1f mm" % [key, viajes[key]["min_mm"], viajes[key]["max_mm"]])
	print("   separación fondo-asfalto: peor %.1f mm (antes del resalto %.1f mm)" % [aire_peor, aire_antes])
	_check(alcanzado, "RESALTO: el coche no llegó a pisar el resalto de prueba")
	_check(pico_izq >= 5.0,
		"RESALTO: la rueda izquierda sólo se comprimió %.2f mm sobre un escalón de 30 mm" % pico_izq)
	_check(pico_der <= -5.0,
		"RESALTO: la rueda derecha sólo se extendió %.2f mm al subir el lado izquierdo" % pico_der)
	_check(absf(pico_izq + pico_der) <= 12.0,
		"RESALTO: el recorrido no reparte la altura del escalón (izq %+.1f, der %+.1f)" % [pico_izq, pico_der])
	_check(aire_peor >= -AIRE_MAX_MM,
		"RESALTO: una rueda atravesó el asfalto %.1f mm" % -aire_peor)
	medidas["resalto"] = {
		"alcanzado": alcanzado, "izquierda_mm": pico_izq, "derecha_mm": pico_der,
		"altura_chasis_mm": altura_pico * 1000.0, "viajes": viajes, "aire_peor_mm": aire_peor,
	}
	await _shots("resalto")
	if fixture != null:
		fixture.queue_free()

# --- 7. compresión y extensión de cada rueda --------------------------------

func _test_vibracion() -> void:
	var at: int = estaciones["recta"]
	_place(at)
	# Se acelera hasta una velocidad de crucero y se mantiene: en la recta, con la
	# dirección quieta, lo único que puede mover al chasis son el perfil del
	# asfalto y el amortiguador.
	for i in 240:
		_inputs(0.35, 0.0, _pursuit())
		index = _nearest(index)
		await physics_frame
	var alturas: Array[float] = []
	var velocidades: Array[float] = []
	for i in 180:
		_inputs(0.28, 0.0, _pursuit())
		index = _nearest(index)
		_sample()
		alturas.append(car.suspension.height)
		velocidades.append(car.speed_mps)
		await physics_frame
	_release()
	# La altura del chasis sigue el perfil del circuito, que es una rampa suave: la
	# vibración no está en la PRIMERA diferencia (que es la pendiente del asfalto ×
	# la velocidad) sino en la SEGUNDA. Un salto o un rebote aparece ahí como un
	# pico; una rampa, no.
	var pico := 0.0
	var suma := 0.0
	var cuenta := 0
	for i in range(2, alturas.size()):
		var segunda := (alturas[i] - 2.0 * alturas[i - 1] + alturas[i - 2]) * 1000.0
		pico = maxf(pico, absf(segunda))
		suma += segunda * segunda
		cuenta += 1
	var rms := sqrt(suma / maxf(1.0, float(cuenta)))
	var segundos := alturas.size() / 60.0
	var velocidad := 0.0
	for value in velocidades:
		velocidad += value
	velocidad = velocidad / maxf(1.0, float(velocidades.size())) * 3.6
	print("\n== 8. VIBRACIÓN  crucero a %.1f km/h durante %.1f s (60 Hz)" % [velocidad, segundos])
	print("   aceleración de la altura del chasis: pico=%.3f mm/fotograma² (tope %.1f)  RMS=%.3f mm (tope %.2f)" % [
		pico, VIBRACION_PICO_MAX_MM, rms, VIBRACION_RMS_MAX_MM])
	_check(pico <= VIBRACION_PICO_MAX_MM,
		"VIBRACIÓN: la altura del chasis pega un salto de %.2f mm/fotograma² (máx %.1f)" % [pico, VIBRACION_PICO_MAX_MM])
	_check(rms <= VIBRACION_RMS_MAX_MM,
		"VIBRACIÓN: la altura del chasis vibra con un RMS de %.3f mm (máx %.2f)" % [rms, VIBRACION_RMS_MAX_MM])
	medidas["vibracion"] = {
		"velocidad_kph": velocidad, "pico_mm_fotograma2": pico, "rms_mm": rms, "segundos": segundos,
	}

# --- 10. geometría de los neumáticos ----------------------------------------

func _test_geometria() -> void:
	print("\n== 10. GEOMETRÍA DE LOS NEUMÁTICOS tras las pruebas")
	var peor_desplazamiento := 0.0
	var peor_orbita := 0.0
	var peor_pivote := 0.0
	for wheel in _wheels():
		var key := _wheel_key(wheel)
		var home: Vector3 = home_positions.get(key, wheel.position)
		var desvio := Vector2(wheel.position.x - home.x, wheel.position.z - home.z).length()
		peor_desplazamiento = maxf(peor_desplazamiento, desvio)
		var mesh: Mesh = wheel.mesh
		var aabb := mesh.get_aabb()
		var centre_local := aabb.get_center()
		peor_pivote = maxf(peor_pivote, centre_local.length())
		var axes := _wheel_axes(aabb.size)
		var axle_car: Vector3 = (car.global_basis.inverse() * (wheel.global_basis * axes[2]).normalized()).normalized()
		var radio: float = aabb.size[axes[1]] * 0.5
		var anchura: float = aabb.size[axes[0]]
		# Radio de órbita: con la MISMA transformación que usa _update_visuals, el
		# centro de la rueda no debe moverse (el pivote está en el eje).
		var parent_g: Transform3D = wheel.get_parent().global_transform
		var hub: Vector3 = wheel.global_transform * centre_local
		var orbita := 0.0
		for combo in [[0.3, 0.0], [0.0, 1.5708], [0.3, 3.0]]:
			var basis_nueva: Basis = Basis(Vector3.UP, -combo[0]) * Basis(Vector3.RIGHT, -combo[1]) * (car._wheel_rest[wheel] as Basis)
			var hub_nuevo: Vector3 = parent_g * (basis_nueva * centre_local + wheel.position)
			orbita = maxf(orbita, (hub_nuevo - hub).length())
		peor_orbita = maxf(peor_orbita, orbita)
		print("   %-3s x=%.4f z=%.4f (reposo x=%.4f z=%.4f)  desvío=%.4f mm  pivote=%.4f mm  órbita=%.4f mm  radio=%.4f  ancho=%.4f" % [
			key, wheel.position.x, wheel.position.z, home.x, home.z, desvio * 1000.0,
			centre_local.length() * 1000.0, orbita * 1000.0, radio, anchura])
		_check(desvio <= GEOMETRIA_TOLERANCIA_M,
			"GEOMETRÍA %s: la rueda se movió %.2f mm en planta (máx %.2f)" % [key, desvio * 1000.0, GEOMETRIA_TOLERANCIA_M * 1000.0])
		_check(centre_local.length() <= PIVOTE_MAX,
			"GEOMETRÍA %s: el pivote está descentrado %.2f mm (máx %.2f)" % [key, centre_local.length() * 1000.0, PIVOTE_MAX * 1000.0])
		_check(absf(axle_car.x) > 0.98, "GEOMETRÍA %s: el eje de giro no es el lateral" % key)
		_check(orbita <= 0.0010, "GEOMETRÍA %s: al girar, el centro orbita %.2f mm" % [key, orbita * 1000.0])
		_check(radio >= RADIO.x and radio <= RADIO.y, "GEOMETRÍA %s: radio %.4f fuera de rango" % [key, radio])
		_check(anchura >= ANCHURA.x and anchura <= ANCHURA.y, "GEOMETRÍA %s: anchura %.4f fuera de rango" % [key, anchura])
		medidas["geometria_%s" % key] = {
			"desvio_planta_mm": desvio * 1000.0, "pivote_mm": centre_local.length() * 1000.0,
			"orbita_mm": orbita * 1000.0, "radio_m": radio, "anchura_m": anchura,
		}
	_check(peor_desplazamiento <= GEOMETRIA_TOLERANCIA_M,
		"GEOMETRÍA: alguna rueda se movió %.2f mm en planta" % (peor_desplazamiento * 1000.0))
	_check(peor_orbita <= 0.0010, "GEOMETRÍA: la rueda orbita %.2f mm al girar" % (peor_orbita * 1000.0))

# --- 7 y 9. resumen de recorridos, topes y penetración ----------------------

func _resumen() -> void:
	print("\n== 7. COMPRESIÓN Y EXTENSIÓN DE CADA RUEDA (todas las pruebas)")
	var recorridos := _viajes()
	for key in recorridos:
		var comp := float(recorridos[key]["max_mm"])
		var ext := float(recorridos[key]["min_mm"])
		print("   %-3s compresión %+.1f mm (tope %.1f)  extensión %+.1f mm (tope -%.1f)" % [
			key, comp, COMPRESION_MAX_MM, ext, DESCOMPRESION_MAX_MM])
		_check(comp <= COMPRESION_MAX_MM + 0.01 and ext >= -DESCOMPRESION_MAX_MM - 0.01,
			"RECORRIDO %s: %.2f … %+.2f mm fuera de los topes" % [key, ext, comp])
		_check(comp >= VIAJE_MIN_ACELERACION_MM and ext <= -VIAJE_MIN_ACELERACION_MM,
			"RECORRIDO %s: la rueda no llegó a comprimirse y extenderse (%.2f … %+.2f mm)" % [key, ext, comp])
	print("\n== 9. PENETRACIÓN  muestras geométricas=%d (descartadas %d por suelo lejano)" % [muestras_geometria, muestras_lejanas])
	print("   separación fondo-asfalto: peor %+.1f mm / mayor %+.1f mm (tope ±%.1f)" % [
		aire_peor, aire_mejor, AIRE_MAX_MM])
	print("   contactos mínimos=%d  ruedas cargadas mínimas=%d  topes alcanzados máx=%d" % [
		contactos_min, cargadas_min, saturacion_max])
	print("   altura del plano entre %.4f y %.4f m (variación %.1f mm)" % [
		altura_min, altura_max, (altura_max - altura_min) * 1000.0])
	print("   actitud total: cabeceo máx=%.2f°  balanceo máx=%.2f°" % [rad_to_deg(cabeceo_max), rad_to_deg(balanceo_max)])
	print("   actitud de SUSPENSIÓN (respecto a la calzada): cabeceo máx=%.3f°  balanceo máx=%.3f°" % [
		rad_to_deg(cabeceo_rel_max), rad_to_deg(balanceo_rel_max)])
	_check(aire_peor >= -AIRE_MAX_MM,
		"PENETRACIÓN: una rueda atravesó el asfalto %.1f mm" % -aire_peor)
	_check(contactos_min >= 2, "CONTACTO: en algún momento hubo %d contactos de rueda" % contactos_min)
	_check(muestras_geometria > 0, "PENETRACIÓN: no se tomaron muestras de separación")
	medidas["recorridos"] = recorridos
	medidas["penetracion"] = {
		"aire_peor_mm": aire_peor, "aire_mayor_mm": aire_mejor, "muestras": muestras_geometria,
		"muestras_suelo_lejano": muestras_lejanas,
		"contactos_min": contactos_min, "cargadas_min": cargadas_min, "saturacion_max": saturacion_max,
		"altura_min_m": altura_min, "altura_max_m": altura_max,
		"cabeceo_max_grados": rad_to_deg(cabeceo_max), "balanceo_max_grados": rad_to_deg(balanceo_max),
		"cabeceo_suspension_max_grados": rad_to_deg(cabeceo_rel_max),
		"balanceo_suspension_max_grados": rad_to_deg(balanceo_rel_max),
	}

# --- auxiliares -------------------------------------------------------------

func _eje(viajes: Dictionary, delantera: bool) -> Dictionary:
	var comp := -INF
	var ext := INF
	for key in viajes:
		var es_delantera: bool = key.begins_with("f")
		if es_delantera != delantera:
			continue
		comp = maxf(comp, float(viajes[key]["max_mm"]))
		ext = minf(ext, float(viajes[key]["min_mm"]))
	if comp == -INF:
		return {"min_mm": 0.0, "max_mm": 0.0}
	return {"min_mm": ext, "max_mm": comp}

func _cargas_por_eje() -> Dictionary:
	var delantera := 0.0
	var trasera := 0.0
	for i in car.suspension.load.size():
		var key := _wheel_key(car._suspension_wheels[i])
		if key.begins_with("f"):
			delantera += car.suspension.load[i]
		else:
			trasera += car.suspension.load[i]
	return {"delantera": delantera, "trasera": trasera}

# Desvío del "arriba" del chasis respecto a la normal del suelo medida por el
# juego: la prueba de que la pose no va invertida.
func _pose_angle() -> float:
	var up: Vector3 = car.model_root.global_basis.y.normalized()
	var normal: Vector3 = car.ground_normal.normalized()
	return rad_to_deg(acos(clampf(up.dot(normal), -1.0, 1.0)))

# --- vistas -----------------------------------------------------------------

func _shots(tag: String) -> void:
	# La vista real del juego, sin tocar la cámara: comparable con el emulador.
	await _save(tag, "camara_del_juego")
	# Para las vistas de medida hay que parar el controlador de cámara de race.gd.
	# Los puntos de vista van en el sistema DEL COCHE y se rehacen cada fotograma:
	# a velocidad alta el coche recorre casi un metro por fotograma.
	race.set_process(false)
	var views := [
		["trasera_baja", Vector3(0.0, 0.45, 6.0), Vector3(0.0, 0.4, 0.0)],
		["lateral", Vector3(6.5, 1.0, 0.2), Vector3(0.0, 0.4, 0.0)],
		["frontal", Vector3(0.0, 1.1, -6.0), Vector3(0.0, 0.4, 0.0)],
		["rueda_trasera_izq", Vector3(-2.9, 0.75, 1.95), Vector3(-0.89, 0.38, 1.95)],
		["rueda_delantera_izq", Vector3(-2.93, 0.75, -1.51), Vector3(-0.93, 0.38, -1.51)],
		["rueda_delantera_der", Vector3(2.93, 0.75, -1.51), Vector3(0.93, 0.38, -1.51)],
	]
	for view in views:
		race.camera.global_position = car.global_transform * view[1]
		race.camera.look_at(car.global_transform * view[2], Vector3.UP)
		await _save(tag, view[0])
	race.set_process(true)
	for i in 3:
		await physics_frame

func _save(tag: String, name: String) -> void:
	for i in 3:
		await process_frame
	var image: Image = root.get_texture().get_image()
	var path := "%s/%s-%s.png" % [OUT_DIR, tag, name]
	var error := image.save_png(path)
	print("VISTA %s -> %s error=%d" % [name, path, error])
