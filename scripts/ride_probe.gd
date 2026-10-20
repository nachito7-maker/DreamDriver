extends SceneTree

# ============================================================================
# CALIDAD DE MARCHA Y CADENA DE ACELERACIÓN
#
# El encargo trae dos defectos: el monoplaza SALTA sobre asfalto aparentemente normal
# y la velocidad sube y baja sin que el pedal cambie. Los dos se miden aquí, por
# separado y con números, y la medida distingue lo FÍSICO de lo que sólo se ve.
#
# PARTE A — LA RECTA DEL CIRCUITO, acelerador a fondo y sin tocar la dirección (la
#   maniobra del encargo). Fotograma a fotograma se registra lo que el coche PIDE y lo
#   que el coche GANA:
#     * la aceleración que el modelo declara (`debug_longitudinal_accel`) frente al
#       cambio de velocidad medido, y la DIFERENCIA entre las dos: la pérdida que no
#       está en NINGÚN término del balance de fuerzas (si el modelo pide 4 m/s² y el
#       coche gana 1, aquí aparecen los 3 que faltan);
#     * el desplazamiento vertical del CUERPO y el del MODELO respecto al cuerpo, con
#       el número de ruedas en contacto y la inclinación de la calzada en ese punto:
#       así se separa un salto físico de un salto del modelo o de la cámara;
#     * la cadena completa del pedal (demanda, límite de agarre, par de motor,
#       resistencia, tope de punta) para descartar —o no— cada eslabón.
#
# PARTE B — BANCO DE PENDIENTES. Cuatro losas planas a 0°, 1°, 2° y 3°, y en cada una
#   la misma prueba: recta y acelerador a fondo a velocidad sostenida. Sobre una
#   pendiente CONOCIDA la pérdida medida se puede comparar con la que pide la física
#   (g·sen θ), que es lo único que subir una cuesta debe costar.
#
# PARTE C — GEOMETRÍA DEL ASFALTO BAJO EL COCHE. Un barrido por la trazada mide, en
#   cada estación, la altura del asfalto bajo las cuatro ruedas y el desnivel entre la
#   rueda más alta y la más baja dentro de la huella de 3,4 m del coche: un desnivel
#   grande es un escalón que la caja de colisión va a embestir.
#
# Uso:  Godot --headless --path . --script res://scripts/ride_probe.gd
# ============================================================================

const TrackScript = preload("res://scripts/track_data.gd")

const TICK := 1.0 / 120.0
const G := 9.81

# --- parte A ------------------------------------------------------------------
const A_SEGUNDOS := 30.0
# Un "salto" es un desplazamiento vertical del cuerpo mayor que esto en un solo
# fotograma de física. A 120 Hz, 5 mm por fotograma son 0,6 m/s de velocidad vertical:
# una rueda que se despega, no el ruido de la malla.
const SALTO_MM := 5.0
# Y un salto que se VE: el modelo respecto al cuerpo. El modelo se coloca en el plano
# del asfalto medido, así que su desplazamiento relativo es lo que salta en pantalla.
const SALTO_VISUAL_MM := 8.0
# Tolerancia de la pérdida no modelada en recta. En asfalto llano el cambio de
# velocidad tiene que ser el que declara el balance de fuerzas; 0,35 m/s² es el margen
# que deja el propio integrador (el fotograma de retardo entre fijar la fuerza y medir
# la velocidad) y no una concesión: en recta plana la pérdida medida es 0,00.
const PERDIDA_MAX_M_S2 := 0.35
# Un salto de más de 20 mm por fotograma sólo puede salir de una embestida contra la
# malla: 2,4 m/s de velocidad vertical en 8,3 ms. Sobre asfalto llano no debe haber
# ninguno, y por eso el criterio es cero, no un promedio.
const SALTOS_GRAVES_MAX := 0

# --- parte B ------------------------------------------------------------------
const PAD_Y := 1500.0
const PAD_MEDIO_LADO := 2000.0
const PENDIENTES_DEG := [0.0, 1.0, 2.0, 3.0]
const B_VELOCIDAD := 60.0          # m/s de la prueba en el banco (216 km/h)
const B_ASENTAR := 30              # fotogramas de asentamiento antes de medir
const B_MEDIR := 180               # 1,5 s de medida
# Lo que subir una pendiente puede costar, como mucho, es g·sen θ. Se admite un 60 %
# de más para no confundir el criterio con el redondeo del integrador; el defecto que
# se busca paga entre seis y veinte veces la cuenta física.
const B_TOLERANCIA := 1.6

# --- parte C ------------------------------------------------------------------
const C_PASO_PUNTOS := 4           # cada 4 puntos de la trazada (~6 m)
# Las superficies que el juego considera ASFALTO (`track_data.get_surface_grip`: 1,0 de
# agarre). La pérdida no modelada sólo se mide sobre ellas: en hierba o grava el balance
# cambia de superficie a media recta y la comparación dejaría de ser limpia.
const ASFALTO := ["TRM-BRC", "ROAD", "TARMAC", "ASPHALT"]

var failures := 0
var race: Node3D
var car: CharacterBody3D
var ui: CanvasLayer
var puntos := PackedVector3Array()
var saltos: Array = []
var perdidas: Array = []
var banco: Array = []
var colocado: Array = []   # altura del modelo respecto al asfalto, fotograma a fotograma


func check(ok: bool, message: String) -> void:
	print("MARCHA ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1


func info(message: String) -> void:
	print("MARCHA INFO ", message)


func _initialize() -> void:
	call_deferred("_run")


# La demanda entra por el canal REAL del juego (los mismos metadatos que lee el
# controlador), con la capa de controles detenida para que nadie la sobrescriba.
func _demand(throttle: float, brake: float, steer: float) -> void:
	car.set_meta("touch_throttle", throttle)
	car.set_meta("touch_brake", brake)
	car.set_meta("touch_steer", steer)


func _run() -> void:
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	for i in 120:
		await physics_frame
	car = race.car
	ui = race.controls
	ui.set_process(false)
	puntos = TrackScript.get_centerline()
	var solo_a: bool = OS.get_cmdline_user_args().has("--solo-a")
	var solo_b: bool = OS.get_cmdline_user_args().has("--solo-b")
	if not solo_b:
		await _parte_a()
	if solo_b:
		await _parte_b()
	elif not solo_a:
		# El orden importa: la vuelta guiada (D) tiene que correr con el coche que trae
		# la escena, asentado sobre el asfalto. Las partes B y C recolocan el coche en un
		# banco de pruebas y lo dejan flotando (recolocar lo sube por encima del suelo y,
		# mientras los rayos vean asfalto, no vuelve a caer), así que van al final.
		await _parte_d()
		await _parte_b()
		await _parte_c()
	_resumen()
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


# ------------------------------------------------------------------ parte A: recta

func _visual_y() -> float:
	if car.model_root == null:
		return car.global_position.y
	return car.model_root.global_position.y


func _nearest_station(position: Vector3, desde: int) -> int:
	var mejor := desde
	var mejor_distancia := INF
	for offset in range(-40, 60):
		var indice := posmod(desde + offset, puntos.size())
		var distancia := Vector2(position.x - puntos[indice].x, position.z - puntos[indice].z).length_squared()
		if distancia < mejor_distancia:
			mejor_distancia = distancia
			mejor = indice
	return mejor


# Índice de la rueda que más se ha movido en el fotograma (0-3) y su salto en mm.
func _rueda_mayor(saltos: PackedFloat32Array) -> int:
	var mejor := 0
	for k in 4:
		if absf(saltos[k]) > absf(saltos[mejor]):
			mejor = k
	return mejor


func _desvio(station: int) -> float:
	var tangente := (puntos[(station + 3) % puntos.size()] - puntos[(station - 3 + puntos.size()) % puntos.size()]).normalized()
	var lateral := Vector3(tangente.z, 0.0, -tangente.x).normalized()
	return (car.global_position - puntos[station]).dot(lateral)


func _parte_a() -> void:
	# La maniobra del encargo: se sale de la posición de salida y se mantiene el
	# acelerador a fondo. El coche se va a salir de la pista solo (no gira), así que la
	# medida termina cuando sale del asfalto o al cabo de `A_SEGUNDOS`: lo que se mide
	# es la recta, no la escapatoria. NO se recoloca el coche: se deja el que trae la
	# escena y se le da tiempo a asentarse, porque recolocarlo lo dejaría flotando por
	# encima del asfalto y la medida de la colocación dejaría de ser la del juego.
	_demand(0.0, 0.0, 0.0)
	for i in 240:
		await physics_frame
	info("recta: colocación de partida cuerpo_sobre_asfalto=%+.1f mm modelo_crudo=%+.1f mm aplicado=%+.1f mm ruedas=%d pie=%s" % [
		(car.global_position.y - car.suspension.road[0]) * 1000.0,
		(car.suspension.height - car.global_position.y) * 1000.0, car.model_root.position.y * 1000.0,
		car.wheel_contacts, str(car.is_on_floor())])
	var station := 0
	var prev_y := car.global_position.y
	var prev_speed: float = car.speed_mps
	var prev_visual_relative := _visual_y() - car.global_position.y
	var prev_camera_y: float = race.camera.global_position.y
	var max_kph := 0.0
	var aire := 0
	var ticks := int(A_SEGUNDOS * 120.0)
	var perdida_suma := 0.0
	var perdida_peor := 0.0
	var perdida_muestra := 0
	var fuera_de_pista := -1
	var camera_max := 0.0
	print("MARCHA INFO recta: %.0f s de acelerador a fondo por la trazada, sin tocar la dirección" % A_SEGUNDOS)
	print("MARCHA INFO %-7s %-7s %-7s %-8s %-8s %-8s %-8s %-7s %-6s %-6s %-8s %s" % [
		"t(s)", "km/h", "gas", "acel_m", "pide_m", "perd_m", "dy_mm", "dy_vis", "ruedas", "incl", "sup"])
	for tick in ticks:
		_demand(1.0, 0.0, 0.0)
		await physics_frame
		station = _nearest_station(car.global_position, station)
		var speed: float = car.speed_mps
		var y := car.global_position.y
		var visual_relative := _visual_y() - y
		var camera_y: float = race.camera.global_position.y
		var dy_mm := (y - prev_y) * 1000.0
		var dy_visual_mm := (visual_relative - prev_visual_relative) * 1000.0
		var dy_camera_mm := (camera_y - prev_camera_y) * 1000.0
		# Altura de colocación del modelo: la que sale del plano del asfalto medido menos la
		# del cuerpo físico. Es el número que el juego RECORTA a ±0,25 m antes de colocar el
		# modelo, así que hace falta la cruda (la que se recorta) y la aplicada.
		var cruda: float = car.suspension.height - y
		var aplicada: float = car.model_root.position.y
		colocado.append({"t": tick / 120.0, "cruda_mm": cruda * 1000.0, "aplicada_mm": aplicada * 1000.0,
			"recortada": absf(cruda) > 0.25, "tilt_deg": car.debug_ground_tilt_deg,
			"contacts": car.wheel_contacts, "kph": speed * 3.6, "station": station,
			"saturated": int(car.suspension.saturated), "loaded": int(car.suspension.loaded_contacts),
			"camara_a_coche_m": race.camera.global_position.distance_to(car.global_position)})
		var ganada: float = (speed - prev_speed) / TICK
		var perdida: float = ganada - car.debug_longitudinal_accel
		max_kph = maxf(max_kph, car.speed_kph)
		if car.wheel_contacts == 0:
			aire += 1
		# La pérdida no modelada se mide sólo sobre asfalto y con el coche apoyado: en
		# el aire el balance de fuerzas no manda y fuera de pista hay hierba y grava.
		if car.wheel_contacts > 0 and ASFALTO.has(car.ground_surface):
			perdida_suma += perdida
			perdida_peor = maxf(perdida_peor, absf(perdida))
			perdida_muestra += 1
		if absf(dy_mm) >= SALTO_MM or absf(dy_visual_mm) >= SALTO_VISUAL_MM:
			saltos.append({
				"t": tick / 120.0, "station": station, "kph": speed * 3.6,
				"dy_mm": dy_mm, "dy_visual_mm": dy_visual_mm, "dy_camera_mm": dy_camera_mm,
				"contacts": car.wheel_contacts, "tilt_deg": car.debug_ground_tilt_deg,
				"surface": car.ground_surface, "desvio_m": _desvio(station),
				"off_center": car.is_on_floor(),
			})
		perdidas.append(ganada)
		camera_max = maxf(camera_max, absf(dy_camera_mm))
		if tick % 60 == 0:
			print("MARCHA RECTA %6.2f %7.1f %6.2f %+8.2f %+8.2f %+8.2f %+8.2f %+7.1f %4d %5.1f° %-8s est=%d desvio=%+.2f cruda=%+7.1f cuerpo_sobre_asfalto=%+.1f ruedas_aire=%+.1f/%.1f/%.1f/%.1f" % [
				tick / 120.0, speed * 3.6, car.throttle_input, ganada, car.debug_longitudinal_accel,
				perdida, dy_mm, dy_visual_mm, car.wheel_contacts, car.debug_ground_tilt_deg,
				car.ground_surface, station, _desvio(station), cruda * 1000.0,
				(car.global_position.y - car.suspension.road[0]) * 1000.0,
				(car.global_position.y - car.suspension.road[0]) * 1000.0,
				(car.global_position.y - car.suspension.road[1]) * 1000.0,
				(car.global_position.y - car.suspension.road[2]) * 1000.0,
				(car.global_position.y - car.suspension.road[3]) * 1000.0])
		prev_y = y
		prev_speed = speed
		prev_visual_relative = visual_relative
		prev_camera_y = camera_y
		if fuera_de_pista < 0 and not ASFALTO.has(car.ground_surface) and tick > 240:
			fuera_de_pista = tick
			break
	var media := perdida_suma / maxf(1.0, float(perdida_muestra))
	info("cadena al final: gas=%.2f gas_real=%.2f par=%.0f N freno=%.0f N aire=%.0f N rodadura=%.0f N total=%.0f N pide=%+.2f m/s² tope=%.1f m/s limitado=%s" % [
		car.throttle_input, car.debug_actual_throttle, car.debug_engine_force_n, car.debug_brake_force_n,
		car.debug_drag_force_n, car.debug_roll_force_n, car.debug_longitudinal_force_n,
		car.debug_longitudinal_accel, car.debug_safe_speed_ms, str(car.debug_top_speed_limited)])
	info("recta: máximo %.1f km/h, %d fotogramas sin ninguna rueda en el suelo de %d, %d saltos de más de %.0f mm" % [
		max_kph, aire, ticks, saltos.size(), SALTO_MM])
	info("recta: pérdida NO modelada media %+.3f m/s² (peor %.3f) sobre %d fotogramas de asfalto; salto vertical máximo de la cámara %.1f mm/fotograma" % [
		media, perdida_peor, perdida_muestra, camera_max])
	_colocacion()
	check(perdida_muestra > 600, "la recta tiene asfalto suficiente para medir la pérdida no modelada (%d fotogramas)" % perdida_muestra)
	check(absf(media) <= PERDIDA_MAX_M_S2,
		"en la recta el coche gana la velocidad que declara su balance de fuerzas (pérdida no modelada %.3f m/s², tope %.2f)" % [
			media, PERDIDA_MAX_M_S2])


# Altura del modelo: la cruda (la que el juego recorta) y la aplicada. Si la cruda vive
# pegada al recorte, cualquier cambio de rasante mueve el modelo a tirones.
func _colocacion() -> void:
	if colocado.is_empty():
		return
	var crudas: Array = []
	var aplicadas: Array = []
	var recortadas := 0
	var saltos_modelo := 0
	var peor := 0.0
	var previa := float(colocado[0]["aplicada_mm"])
	var distancia_min := INF
	var distancia_max := 0.0
	for fila in colocado:
		crudas.append(float(fila["cruda_mm"]))
		aplicadas.append(float(fila["aplicada_mm"]))
		if bool(fila["recortada"]):
			recortadas += 1
		var salto: float = absf(float(fila["aplicada_mm"]) - previa)
		if salto > 20.0:
			saltos_modelo += 1
		peor = maxf(peor, salto)
		previa = float(fila["aplicada_mm"])
		distancia_min = minf(distancia_min, float(fila["camara_a_coche_m"]))
		distancia_max = maxf(distancia_max, float(fila["camara_a_coche_m"]))
	crudas.sort()
	aplicadas.sort()
	info("colocación: altura del modelo cruda (la que el juego recorta) mín %.1f mm, mediana %.1f mm, máx %.1f mm; aplicada mín %.1f mm, máx %.1f mm" % [
		crudas[0], crudas[crudas.size() / 2], crudas[crudas.size() - 1],
		aplicadas[0], aplicadas[aplicadas.size() - 1]])
	info("colocación: %d fotogramas de %d con la altura RECORTADA por el tope de ±250 mm; %d tirones del modelo de más de 20 mm (peor %.1f mm); distancia de la cámara al coche entre %.2f y %.2f m" % [
		recortadas, colocado.size(), saltos_modelo, peor, distancia_min, distancia_max])
	colocado.sort_custom(func(a, b): return absf(float(a["cruda_mm"])) > absf(float(b["cruda_mm"])))
	for j in mini(6, colocado.size()):
		var fila: Dictionary = colocado[j]
		info("  colocación peor %d: t=%.2f estación=%d %.1f km/h cruda=%+.1f mm aplicada=%+.1f mm inclinación=%.2f° ruedas=%d cargadas=%d saturadas=%d desvío=%+.2f m" % [
			j + 1, float(fila["t"]), int(fila["station"]), float(fila["kph"]), float(fila["cruda_mm"]),
			float(fila["aplicada_mm"]), float(fila["tilt_deg"]), int(fila["contacts"]),
			int(fila["loaded"]), int(fila["saturated"]),
			_desvio(int(fila["station"]))])


# ------------------------------------------------------------ parte B: pendientes

func _losas(grados: float) -> StaticBody3D:
	var pad := StaticBody3D.new()
	pad.name = "TRM-BRC banco de pendiente %.1f°" % grados
	pad.collision_layer = 1
	pad.collision_mask = 0
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(PAD_MEDIO_LADO * 2.0, 40.0, PAD_MEDIO_LADO * 2.0)
	collision.shape = box
	pad.add_child(collision)
	race.add_child(pad)
	# La losa se inclina sobre el eje X y se desplaza para que su cara SUPERIOR pase
	# por el origen del banco: así la carretera sube en el sentido de la marcha (-Z) y
	# la pendiente que pisa el coche es exactamente la declarada.
	pad.rotation.x = deg_to_rad(grados)
	pad.global_position = Vector3(0.0, PAD_Y, 0.0) - pad.global_transform.basis.y * 20.0
	return pad


func _suelo_en(x: float, z: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, PAD_Y + 60.0, z), Vector3(x, PAD_Y - 60.0, z), 1)
	var hit := car.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return NAN
	return hit["position"].y


func _parte_b() -> void:
	print("MARCHA INFO banco de pendientes: recta a %.0f m/s con el acelerador a fondo; lo que cuesta subir tiene que ser g·sen θ" % B_VELOCIDAD)
	for grados in PENDIENTES_DEG:
		var pad := _losas(float(grados))
		for i in 4:
			await physics_frame
		# El desnivel MEDIDO de la losa, no el declarado: si la inclinación no fuese la
		# que dice el nombre, la comparación con g·sen θ sería contra un número falso.
		var bajo := _suelo_en(0.0, 20.0)
		var alto := _suelo_en(0.0, -20.0)
		var grados_medidos := rad_to_deg(atan2(alto - bajo, 40.0))
		var suelo := _suelo_en(0.0, 0.0)
		car.recover_to(Vector3(0.0, suelo + 0.4, 0.0), 0.0)
		car.velocity = Vector3.ZERO
		_demand(0.0, 0.0, 0.0)
		for i in 30:
			await physics_frame
		car.velocity = -car.global_transform.basis.z * B_VELOCIDAD
		for i in B_ASENTAR:
			_demand(1.0, 0.0, 0.0)
			await physics_frame
		var velocidad_entrada: float = car.speed_mps
		var ganada_suma := 0.0
		var pide_suma := 0.0
		var inclinacion_suma := 0.0
		var aire := 0
		var ruedas_min := 4
		for i in B_MEDIR:
			_demand(1.0, 0.0, 0.0)
			var antes: float = car.speed_mps
			await physics_frame
			ganada_suma += (car.speed_mps - antes) / TICK
			pide_suma += car.debug_longitudinal_accel
			inclinacion_suma += car.debug_ground_tilt_deg
			if car.wheel_contacts == 0:
				aire += 1
			ruedas_min = mini(ruedas_min, car.wheel_contacts)
		var ganada := ganada_suma / float(B_MEDIR)
		var pide := pide_suma / float(B_MEDIR)
		var inclinacion := inclinacion_suma / float(B_MEDIR)
		# Lo que la física cobra por subir: la componente del peso en la rasante. Con el
		# coche sin inclinación lateral es g·sen θ, y el signo negativo es que cuesta.
		var fisica := -G * sin(deg_to_rad(grados_medidos))
		var perdida := ganada - pide
		banco.append({
			"grados": grados, "grados_medidos": grados_medidos, "ganada": ganada, "pide": pide,
			"perdida": perdida, "fisica": fisica, "inclinacion": inclinacion,
			"velocidad": car.speed_mps, "entrada": velocidad_entrada, "aire": aire, "ruedas_min": ruedas_min,
		})
		print("MARCHA BANCO %4.1f° (medido %5.2f°, inclinación del suelo %5.2f°) v=%5.1f m/s el modelo pide %+7.3f m/s² y el coche gana %+7.3f m/s²: pérdida no modelada %+7.3f m/s², %.1f× lo que cuesta subir (%.3f m/s²); ruedas_min=%d aire=%d" % [
			float(grados), grados_medidos, inclinacion, car.speed_mps, pide, ganada, perdida,
			absf(perdida) / maxf(absf(fisica), 1e-4), absf(fisica), ruedas_min, aire])
		pad.queue_free()
		await process_frame
		for i in 30:
			await physics_frame
	var peor := 0.0
	info("banco: pérdida no modelada por pendiente: %s" % [
		", ".join(PackedStringArray(banco.map(func(f): return "%.1f°→%+.3f m/s² (%.1f×)" % [
			float(f["grados"]), float(f["perdida"]),
			absf(float(f["perdida"])) / maxf(absf(float(f["fisica"])), 1e-4)])))])
	# El criterio se mide sobre la pendiente más suave que no es llana: a 1° la física
	# sólo cobra 0,171 m/s² y cualquier error de proyección se ve multiplicado.
	for fila in banco:
		if float(fila["grados"]) <= 0.0:
			continue
		peor = maxf(peor, absf(float(fila["perdida"])) / maxf(absf(float(fila["fisica"])), 1e-4))
	check(peor <= B_TOLERANCIA,
		"subir una pendiente cuesta lo que dice la física y no más (peor caso %.1f× g·sen θ, tope %.1f×)" % [
			peor, B_TOLERANCIA])


# ------------------------------------------------------ parte C: geometría del suelo

func _parte_c() -> void:
	# Se vuelve al circuito: se quitan los bancos y se barre la trazada midiendo el
	# asfalto bajo las cuatro ruedas del coche, en la orientación real del coche sobre
	# la línea. El desnivel dentro de la huella es lo que la caja de 3,4 m va a embestir.
	car.recover_to(TrackScript.get_spawn_position() + Vector3.UP * 0.3, TrackScript.get_spawn_yaw())
	car.velocity = Vector3.ZERO
	_demand(0.0, 0.0, 0.0)
	for i in 30:
		await physics_frame
	var offs := [Vector3(-0.85, 0.0, -1.5), Vector3(0.85, 0.0, -1.5), Vector3(-0.85, 0.0, 1.95), Vector3(0.85, 0.0, 1.95)]
	var peores: Array = []
	var estaciones := 0
	var desnivel_max := 0.0
	var escalon_max := 0.0
	var escalon_en := -1
	var anterior := NAN
	for i in range(0, puntos.size(), C_PASO_PUNTOS):
		var tangente := (puntos[(i + 2) % puntos.size()] - puntos[(i - 2 + puntos.size()) % puntos.size()]).normalized()
		var yaw := atan2(-tangente.x, -tangente.z)
		var base := puntos[i] + Vector3.UP * 12.0
		var basis := Basis(Vector3.UP, yaw)
		var alturas := PackedFloat32Array()
		var valido := true
		for offset in offs:
			var mundo: Vector3 = base + basis * offset
			var query := PhysicsRayQueryParameters3D.create(mundo, mundo - Vector3.UP * 30.0, 1)
			var hit := car.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty():
				valido = false
				break
			alturas.append(hit["position"].y)
		if not valido:
			anterior = NAN
			continue
		estaciones += 1
		var alto := alturas[0]
		var bajo := alturas[0]
		for altura in alturas:
			alto = maxf(alto, altura)
			bajo = minf(bajo, altura)
		var desnivel := alto - bajo
		desnivel_max = maxf(desnivel_max, desnivel)
		peores.append({"station": i, "desnivel_mm": desnivel * 1000.0, "alturas": alturas})
		# Escalón a lo largo de la marcha: cuánto sube o baja el asfalto de una estación
		# a la siguiente (paso ~6 m). Un salto grande aquí es un badén de verdad.
		if not is_nan(anterior):
			var escalon := absf(alturas[1] - anterior)
			if escalon > escalon_max:
				escalon_max = escalon
				escalon_en = i
		anterior = alturas[1]
	peores.sort_custom(func(a, b): return float(a["desnivel_mm"]) > float(b["desnivel_mm"]))
	info("geometría: %d estaciones medidas sobre la trazada; desnivel máximo DENTRO de la huella del coche %.1f mm; escalón máximo entre estaciones consecutivas %.1f mm (en la estación %d)" % [
		estaciones, desnivel_max * 1000.0, escalon_max * 1000.0, escalon_en])
	for j in mini(8, peores.size()):
		var fila: Dictionary = peores[j]
		info("  peor %d: estación %d desnivel %.1f mm (alturas %.3f / %.3f / %.3f / %.3f m)" % [
			j + 1, int(fila["station"]), float(fila["desnivel_mm"]),
			fila["alturas"][0], fila["alturas"][1], fila["alturas"][2], fila["alturas"][3]])


# ------------------------------------------------ parte D: conducción de verdad
#
# Censo de saltos sobre la pista REAL: se conduce el coche por la trazada a
# velocidades de conducción (una fracción de la velocidad ideal de la línea), con el
# mando y los pedales por el canal REAL del juego, y se registra lo que salta el
# MODELO y lo que salta el cuerpo, con el estado de la suspensión en ese instante. La
# recta de la parte A es un caso de laboratorio (siempre el mismo asfalto); aquí se
# pasa por curvas, bordillos, rasantes y frenadas, que es donde el coche salta en los
# vídeos del encargo.
#
# Y se registra además la MEDIDA de la que sale la colocación: las alturas del asfalto
# bajo cada rueda y el salto del plano del asfalto de un fotograma a otro. Un salto de
# la MEDIDA es un salto del coche en pantalla aunque la física no se mueva, y separa
# «el asfalto tiene un escalón» de «la medida se ha ido».
const D_SEGUNDOS := 60.0
const D_FACTOR_LINEA := 0.5        # fracción de la velocidad ideal que se pide
const D_VELOCIDAD_MAX := 30.0      # m/s (108 km/h): se conduce, no se corre
# Un salto del MODELO que se ve en pantalla: 50 mm a la distancia de la cámara son
# unos 3 píxeles, el umbral por debajo del cual no se distingue del ruido de dibujo.
const D_POP_MM := 50.0
const D_SALTO_PLANO_MM := 60.0     # salto del plano del asfalto que ya es un tirón

func _parte_d() -> void:
	var linea = race.assistance_line
	if linea == null or linea.speed_ideal.size() != puntos.size():
		info("vuelta guiada: la línea de asistencia no está lista (%s puntos frente a %d de la trazada)" % [
			str(linea.speed_ideal.size()) if linea != null else "sin línea", puntos.size()])
		return
	info("vuelta guiada: %.0f s siguiendo la trazada al %.0f %% de su velocidad ideal (tope %.0f m/s)" % [
		D_SEGUNDOS, D_FACTOR_LINEA * 100.0, D_VELOCIDAD_MAX])
	_demand(0.0, 0.0, 0.0)
	for i in 120:
		await physics_frame
	var station := _nearest_station(car.global_position, 0)
	var arco := 0.0
	var pops: Array = []
	var saltos_cuerpo := 0
	var aire := 0
	var recortadas := 0
	var velocidad_max := 0.0
	var perdida_suma := 0.0
	var perdida_peor := 0.0
	var perdida_muestra := 0
	var prev_aplicada: float = car.model_root.position.y
	var prev_cruda: float = car.suspension.height - car.global_position.y
	var prev_y := car.global_position.y
	var prev_speed: float = car.speed_mps
	var previo := station
	var ruedas_bajo := 4
	var salidas := 0
	var prev_plano: float = car.suspension.height
	var prev_ruedas := PackedFloat32Array([car.suspension.road[0], car.suspension.road[1], car.suspension.road[2], car.suspension.road[3]])
	var planos: Array = []
	var restantes := 12
	var saltos_plano := 0
	var ticks := int(D_SEGUNDOS * 120.0)
	for tick in ticks:
		station = _nearest_station(car.global_position, station)
		var paso := 0.0
		var cursor := previo
		while cursor != station:
			var siguiente := (cursor + 1) % puntos.size()
			paso += puntos[cursor].distance_to(puntos[siguiente])
			cursor = siguiente
			if paso > 200.0:
				break
		arco += paso
		previo = station
		# Seguidor de trazada por adelanto (`pure pursuit`), el mismo lazo que usa
		# `driving_probe` para la vuelta completa.
		var adelanto: float = 8.0 + car.speed_mps * 0.7
		var distancia := 0.0
		var objetivo := station
		while distancia < adelanto:
			var siguiente := (objetivo + 1) % puntos.size()
			distancia += puntos[objetivo].distance_to(puntos[siguiente])
			objetivo = siguiente
		var local := car.to_local(puntos[objetivo])
		var alfa := atan2(local.x, -local.z)
		var angulo_rueda := atan2(2.0 * car.wheelbase_m * sin(alfa), adelanto)
		var tope := lerpf(car.steering_at_low_speed_rad, car.steering_at_high_speed_rad,
			pow(clampf(car.speed_mps / 100.0, 0.0, 1.0), 0.68))
		var mando := clampf(angulo_rueda / tope * 0.55, -1.0, 1.0)
		var pedida: float = clampf(float(linea.speed_ideal[station]) * D_FACTOR_LINEA, 8.0, D_VELOCIDAD_MAX)
		# El desvío lateral frena al seguidor: mantener la trazada manda sobre la
		# velocidad pedida por la línea, que es lo que hace quien conduce.
		var desvio_actual := _desvio(station)
		pedida *= clampf(1.0 - maxf(0.0, absf(desvio_actual) - 1.5) * 0.12, 0.35, 1.0)
		var error: float = pedida - car.speed_mps
		var gas := clampf(error * 0.2 + 0.1, 0.0, 1.0)
		var freno := clampf(-error * 0.15, 0.0, 0.8)
		if gas < 0.03:
			gas = 0.0
		if freno < 0.03:
			freno = 0.0
		_demand(gas, freno, mando)
		await physics_frame
		# Salto de la MEDIDA (no de la física): el plano del asfalto y cada rueda.
		var plano: float = car.suspension.height
		var salto_plano: float = (plano - prev_plano) * 1000.0
		if car.wheel_contacts > 0 and absf(salto_plano) >= D_SALTO_PLANO_MM:
			saltos_plano += 1
			restantes -= 1
			if restantes >= 0:
				var ruedas_hoy := PackedFloat32Array([car.suspension.road[0], car.suspension.road[1],
					car.suspension.road[2], car.suspension.road[3]])
				var ruedas_salto := PackedFloat32Array()
				for k in 4:
					ruedas_salto.append((ruedas_hoy[k] - prev_ruedas[k]) * 1000.0)
				planos.append({"t": tick / 120.0, "station": station, "kph": car.speed_mps * 3.6,
					"salto_mm": salto_plano, "cruda_mm": (plano - car.global_position.y) * 1000.0,
					"contacts": car.wheel_contacts, "surface": car.ground_surface,
					"tilt_deg": car.debug_ground_tilt_deg,
					"ruedas_salto_mm": ruedas_salto, "rueda_mayor": _rueda_mayor(ruedas_salto),
					"desvio_m": _desvio(station), "compresion_mm": car.suspension.compression * 1000.0,
					"recortada": absf(plano - car.global_position.y) > 0.25,
					"saturadas": int(car.suspension.saturated)})
		prev_plano = plano
		prev_ruedas = PackedFloat32Array([car.suspension.road[0], car.suspension.road[1],
			car.suspension.road[2], car.suspension.road[3]])
		var aplicada: float = car.model_root.position.y
		var cruda: float = car.suspension.height - car.global_position.y
		var y := car.global_position.y
		var speed: float = car.speed_mps
		var pop := (aplicada - prev_aplicada) * 1000.0
		var salto := (y - prev_y) * 1000.0
		velocidad_max = maxf(velocidad_max, speed)
		if absf(cruda) > 0.25:
			recortadas += 1
		if car.wheel_contacts == 0:
			aire += 1
		ruedas_bajo = mini(ruedas_bajo, car.wheel_contacts)
		if car.wheel_contacts > 0 and ASFALTO.has(car.ground_surface):
			var ganada: float = (speed - prev_speed) / TICK
			var perdida: float = ganada - car.debug_longitudinal_accel
			perdida_suma += perdida
			perdida_peor = maxf(perdida_peor, absf(perdida))
			perdida_muestra += 1
		if absf(salto) >= 20.0:
			saltos_cuerpo += 1
		if absf(pop) >= D_POP_MM or absf(cruda) > 0.30:
			pops.append({"t": tick / 120.0, "station": station, "kph": speed * 3.6,
				"pop_mm": pop, "cruda_mm": cruda * 1000.0, "anterior_mm": prev_cruda * 1000.0,
				"aplicada_mm": aplicada * 1000.0, "tilt_deg": car.debug_ground_tilt_deg,
				"contacts": car.wheel_contacts, "loaded": int(car.suspension.loaded_contacts),
				"saturated": int(car.suspension.saturated), "compresion_mm": car.suspension.compression * 1000.0,
				"desvio_m": _desvio(station), "gas": gas, "freno": freno, "mando": mando,
				"surface": car.ground_surface, "pitch_deg": rad_to_deg(car.suspension.pitch),
				"roll_deg": rad_to_deg(car.suspension.roll)})
		if not ASFALTO.has(car.ground_surface) and car.wheel_contacts > 0:
			salidas += 1
		prev_aplicada = aplicada
		prev_cruda = cruda
		prev_y = y
		prev_speed = speed
		if tick % 600 == 0:
			print("MARCHA VUELTA %6.2f %7.1f %6.2f %6.2f %7.1f %+7.1f %+8.1f %+8.1f %6.2f %4d %4d %-8s est=%d arco=%.0f m" % [
				tick / 120.0, speed * 3.6, car.throttle_input, car.brake_input, mando,
				(car.suspension.height - y) * 1000.0, pop, salto, car.debug_ground_tilt_deg,
				car.wheel_contacts, int(car.suspension.loaded_contacts), car.ground_surface, station, arco])
	_demand(0.0, 0.0, 0.0)
	var perdida_media := perdida_suma / maxf(1.0, float(perdida_muestra))
	info("vuelta guiada: %.0f m recorridos sobre la trazada, %.1f km/h de máxima, %d fotogramas sin ninguna rueda en el suelo de %d, %d saltos del cuerpo de más de 20 mm, %d fotogramas con el modelo RECORTADO, %.0f m fuera del asfalto" % [
		arco, velocidad_max * 3.6, aire, ticks, saltos_cuerpo, recortadas, salidas * 0.7])
	info("vuelta guiada: pérdida NO modelada media %+.3f m/s² (peor %.3f) sobre %d fotogramas de asfalto; %d saltos del modelo de más de %.0f mm o con el recorte tocado" % [
		perdida_media, perdida_peor, perdida_muestra, pops.size(), D_POP_MM])
	pops.sort_custom(func(a, b): return absf(float(a["pop_mm"])) > absf(float(b["pop_mm"])))
	var peor_pop := 0.0
	for j in mini(12, pops.size()):
		var fila: Dictionary = pops[j]
		peor_pop = maxf(peor_pop, absf(float(fila["pop_mm"])))
		info("  salto del modelo %d: t=%.2f estación=%d %.1f km/h salto_vertical=%+.1f mm cruda=%+.1f mm (antes %+.1f mm) aplicada=%+.1f mm inclinación=%.2f° ruedas=%d cargadas=%d saturadas=%d compresión=%+.1f mm cabeceo=%.2f° balanceo=%.2f° desvío=%+.2f m gas=%.2f freno=%.2f mando=%+.2f %s" % [
			j + 1, float(fila["t"]), int(fila["station"]), float(fila["kph"]), float(fila["pop_mm"]),
			float(fila["cruda_mm"]), float(fila["anterior_mm"]), float(fila["aplicada_mm"]),
			float(fila["tilt_deg"]), int(fila["contacts"]), int(fila["loaded"]), int(fila["saturated"]),
			float(fila["compresion_mm"]), float(fila["pitch_deg"]), float(fila["roll_deg"]),
			float(fila["desvio_m"]), float(fila["gas"]), float(fila["freno"]), float(fila["mando"]),
			String(fila["surface"])])
	info("vuelta guiada: %d saltos de la MEDIDA del asfalto de más de %.0f mm en un fotograma" % [
		saltos_plano, D_SALTO_PLANO_MM])
	planos.sort_custom(func(a, b): return absf(float(a["salto_mm"])) > absf(float(b["salto_mm"])))
	for j in mini(10, planos.size()):
		var fila: Dictionary = planos[j]
		info("  medida %d: t=%.2f estación=%d %.1f km/h el plano del asfalto salta %+.1f mm (rueda %d salta %+.1f mm; las cuatro %+.1f/%+.1f/%+.1f/%+.1f) cruda=%+.1f mm recortada=%s inclinación=%.2f° ruedas=%d saturadas=%d compresión=%+.1f mm desvío=%+.2f m %s" % [
			j + 1, float(fila["t"]), int(fila["station"]), float(fila["kph"]), float(fila["salto_mm"]),
			int(fila["rueda_mayor"]), float(fila["ruedas_salto_mm"][int(fila["rueda_mayor"])]),
			float(fila["ruedas_salto_mm"][0]), float(fila["ruedas_salto_mm"][1]),
			float(fila["ruedas_salto_mm"][2]), float(fila["ruedas_salto_mm"][3]),
			float(fila["cruda_mm"]), str(fila["recortada"]), float(fila["tilt_deg"]),
			int(fila["contacts"]), int(fila["saturadas"]), float(fila["compresion_mm"]),
			float(fila["desvio_m"]), String(fila["surface"])])
	check(perdida_muestra > 1200, "la vuelta guiada ha conducido lo suficiente para medir (%.0f m de trazada, %d fotogramas de asfalto)" % [arco, perdida_muestra])
	check(absf(perdida_media) <= PERDIDA_MAX_M_S2,
		"en conducción por la pista el coche gana la velocidad que declara su balance (pérdida no modelada %.3f m/s², tope %.2f)" % [
			perdida_media, PERDIDA_MAX_M_S2])


func _resumen() -> void:
	var fisicos := 0
	var visuales := 0
	var graves := 0
	var peor := 0.0
	var peor_visual := 0.0
	var peor_camara := 0.0
	var por_superficie := {}
	for salto in saltos:
		peor = maxf(peor, absf(float(salto["dy_mm"])))
		peor_visual = maxf(peor_visual, absf(float(salto["dy_visual_mm"])))
		peor_camara = maxf(peor_camara, absf(float(salto["dy_camera_mm"])))
		if absf(float(salto["dy_mm"])) >= SALTO_MM:
			fisicos += 1
			if absf(float(salto["dy_mm"])) >= 20.0:
				graves += 1
		if absf(float(salto["dy_visual_mm"])) >= SALTO_VISUAL_MM:
			visuales += 1
		var clave: String = String(salto["surface"]) + "/" + ("con contacto" if int(salto["contacts"]) > 0 else "sin contacto")
		por_superficie[clave] = int(por_superficie.get(clave, 0)) + 1
	info("saltos: %d físicos (de %.0f mm) y %d del modelo (de %.0f mm) en la recta; peor físico %.1f mm, peor del modelo %.1f mm, peor de la cámara %.1f mm" % [
		fisicos, SALTO_MM, visuales, SALTO_VISUAL_MM, peor, peor_visual, peor_camara])
	for clave in por_superficie:
		info("  %s: %d" % [clave, int(por_superficie[clave])])
	saltos.sort_custom(func(a, b): return absf(float(a["dy_mm"])) > absf(float(b["dy_mm"])))
	for j in mini(10, saltos.size()):
		var salto: Dictionary = saltos[j]
		info("  salto %d: t=%.2f estación=%d %.1f km/h dy_cuerpo=%+.1f mm dy_modelo=%+.1f mm dy_camara=%+.1f mm ruedas=%d inclinación=%.1f° superficie=%s suelo=%s desvio=%+.2f m" % [
			j + 1, float(salto["t"]), int(salto["station"]), float(salto["kph"]), float(salto["dy_mm"]),
			float(salto["dy_visual_mm"]), float(salto["dy_camera_mm"]), int(salto["contacts"]),
			float(salto["tilt_deg"]), String(salto["surface"]), str(salto["off_center"]), float(salto["desvio_m"])])
	check(graves <= SALTOS_GRAVES_MAX,
		"sobre el asfalto de la recta el coche no da saltos físicos de más de 20 mm por fotograma (%d, tope %d)" % [
			graves, SALTOS_GRAVES_MAX])
