extends RefCounted

# Suspensión de las cuatro ruedas del Red Bull.
#
# POR QUÉ ESTE MODELO Y NO UN COCHE DE RAYOS COMPLETO
# ---------------------------------------------------
# El coche es un `CharacterBody3D` con UNA caja de colisión (1,2 × 0,55 × 3,4 m) y su
# contacto con el suelo lo decide esa caja, no las ruedas. Sustituir eso por un vehículo
# de cuatro rayos de verdad significa reescribir el sistema de conducción entero
# (fuerzas por rueda, integración del chasis, guiñada, deriva y agarre), que es justo lo
# que la fase 2 dejó medido y verificado. Aquí se conserva esa conducción y se añade lo
# que faltaba: cada rueda tiene su propio recorrido vertical y el chasis se apoya en las
# cuatro suspensiones.
#
# El modelo es el de un cuerpo suspendido sobre cuatro muelles lineales (los de un
# monoplaza: barras de torsión, 100-200 N/mm en la rueda) con amortiguador. Las
# ecuaciones son el equilibrio del chasis, no una animación:
#
#   u_i = s_i - (A + B·x_i + C·z_i)      recorrido de la rueda i (+, comprimida)
#   Σ k_i·u_i        = 0                 equilibrio vertical: el peso ya lo lleva el
#                                        hundimiento de diseño, aquí sólo entran las
#                                        transferencias de carga
#   Σ k_i·u_i·z_i    = m·a_x·cg          momento de cabeceo (aceleración/frenada)
#   Σ k_i·u_i·x_i    = m·a_y·cg          momento de balanceo (curva)
#
# donde (A, B, C) es el plano del chasis: A su altura sobre el origen del coche y B, C
# sus pendientes; s_i es la altura del asfalto medida con un rayo bajo cada rueda, en el
# sistema del coche. Las tres incógnitas salen de resolver ese sistema 3×3, que es a la
# vez el ajuste por mínimos cuadrados ponderado por los muelles: de ahí salen el cabeceo
# y el balanceo FÍSICOS (no hay ninguna inclinación prefijada) y de ahí sale también que
# en una curva las ruedas exteriores se compriman y las interiores se extiendan, y que
# al frenar se hunda el morro.
#
# La rueda nunca atraviesa el asfalto: su recorrido es exactamente el residuo medido
# (u_i), la compresión se limita al tope de recorrido subiendo el chasis (que es lo que
# pasa cuando un badén agota la suspensión) y la extensión se limita al tope de
# descompresión, con lo que la rueda queda colgando por encima del suelo.
#
# Uso desde `car_controller`:
#   suspension.configure(corners, is_front)
#   suspension.step(delta, alturas_bajo_cada_rueda, hay_suelo, a_x, a_y)
#   model_root.rotation.x = suspension.pitch ; rotation.z = suspension.roll
#   model_root.position.y = suspension.height
#   wheel.position.y = rest_y[i] + suspension.offset[i]

const GRAVITY := 9.81

# --- geometría y masas (fijadas desde el controlador) -------------------------
var corner := PackedVector3Array()          # (x, 0, z) de cada rueda, sistema del coche
var is_front := PackedInt32Array()          # 1 delantera, 0 trasera
var mass_kg := 798.0
var front_weight_fraction := 0.46
var cg_height_m := 0.33
var wheelbase_m := 3.72
var track_front_m := 1.86
var track_rear_m := 1.78

# --- muelles y amortiguadores -------------------------------------------------
# Rigidez en la rueda: 150 N/mm delante y 130 N/mm detrás, dentro del rango de un
# monoplaza (barras de torsión, 100-200 N/mm). Con los repartos de peso reales (46 %
# delante) el hundimiento estático de diseño es 12,0 mm delante y 16,3 mm detrás: entra
# de sobra en el recorrido y es el que ya trae el modelo entregado.
# Recorridos: 35 mm de compresión y 30 mm de extensión desde esa posición de diseño,
# comparables a los ~30 mm de bump y 30 mm de rebote de un F1.
# Amortiguador: con la masa de cada esquina (m/4 ≈ 200 kg) y k = 150 kN/m, el
# amortiguamiento crítico es c = 2·√(k·m/4) = 10 954 N·s/m; con ζ = 0,7 queda
# τ = c/k ≈ 50 ms, que es la constante de tiempo con la que se filtran la actitud y la
# compresión del chasis respecto a la calzada.
var rate_front_n_per_m := 150000.0
var rate_rear_n_per_m := 130000.0
var travel_bump_m := 0.035
var travel_droop_m := 0.030
var damper_tau := 0.05
# Velocidad vertical máxima del CHASIS (m/s). El chasis es una masa: no puede subir medio
# metro en un fotograma porque una rueda encuentre un escalón. 8 m/s es lo que sube el
# chasis al tragarse un bordillo de 50 mm a 250 km/h (que ya es una buena hostia), y por
# encima de eso lo que tiene que hacer el coche es despegar, no flotar.
var chassis_vertical_speed_max_m := 8.0
# Cuánto puede mentir una lectura de asfalto: si una rueda queda más de esto por encima del
# plano que forman las demás, esa lectura no era la calzada (ver el paso 2 de `step`).
var road_outlier_m := 0.15

# --- estado -------------------------------------------------------------------
var offset := PackedFloat32Array()          # recorrido de cada rueda (m, + = comprimida)
var load := PackedFloat32Array()            # carga vertical sobre cada rueda (N)
var road := PackedFloat32Array()            # altura del asfalto bajo cada rueda (mundo)
var grounded := PackedInt32Array()          # 1 si esa rueda tiene suelo bajo el rayo
var loaded := PackedInt32Array()            # 1 si además lleva carga (hace fuerza)
var loaded_contacts := 0                    # ruedas que sostienen el chasis (las que fijan el plano)
var height := 0.0                           # A: altura del plano del chasis
var height_target := 0.0
var compression := 0.0                       # parte de esa altura que aporta la suspensión
var slope_x := 0.0                          # B: dy/dx del plano
var slope_z := 0.0                          # C: dy/dz del plano
var pitch := 0.0                            # rotación x del modelo (rad)
var roll := 0.0                             # rotación z del modelo (rad)
# Actitud de la SUSPENSIÓN, medida contra el plano de la calzada: es lo que el
# chasis se inclina por las cargas (transferencia longitudinal y lateral), sin
# contar el peralte ni la rasante del circuito. Es la magnitud que mide la sonda
# para comprobar el signo (acelerar → morro arriba, frenar → morro abajo, y en
# curva el lado exterior se hunde) sin que la inclinación del asfalto la tape.
var pitch_relative := 0.0
var roll_relative := 0.0
var road_slope_x := 0.0
var road_slope_z := 0.0
var road_height := 0.0
var contacts := 0                           # ruedas con suelo
# 1 si la altura `height` es un plano MEDIDO en el sitio donde está el coche ahora. Se
# pone a cero en `reset()` —que es lo que hace `recover_to` al teletransportar— y sólo
# vuelve a 1 cuando `step` resuelve el plano con al menos un rayo que ha dado en asfalto.
# Es la condición que separa "no hay medida todavía" de "la medida vale 0 m", que es la
# diferencia entre asentarse y salir disparado.
var seated := false
var saturated := 0                          # ruedas que topan con el recorrido
var bump_peak := 0.0                        # máxima compresión vista (diagnóstico)
var droop_peak := 0.0                       # máxima extensión vista (diagnóstico)
var last_height := 0.0                      # altura del chasis en el fotograma anterior
var _max_x := 0.93                          # semivía máxima (m): cuánto inclina el balanceo
var _max_z := 1.95                          # semibatalla máxima (m): cuánto inclina el cabeceo
var _configured := false
var _first_frame := true

func configure(corners: PackedVector3Array, front: PackedInt32Array) -> void:
	corner = corners
	is_front = front
	offset.resize(corner.size())
	load.resize(corner.size())
	road.resize(corner.size())
	grounded.resize(corner.size())
	loaded.resize(corner.size())
	_max_x = 0.0
	_max_z = 0.0
	for i in corner.size():
		offset[i] = 0.0
		load[i] = 0.0
		grounded[i] = 0
		loaded[i] = 0
		_max_x = maxf(_max_x, absf(corner[i].x))
		_max_z = maxf(_max_z, absf(corner[i].z))
	_configured = true

# Coloca las cuatro ruedas sobre el asfalto medido, con el plano del chasis que hay en
# `height`, `slope_x` y `slope_z`. Es el paso que convierte el plano en recorrido.
func _recolocar_ruedas(alturas: PackedFloat32Array, hay_suelo: PackedInt32Array) -> void:
	for i in corner.size():
		if hay_suelo[i] == 1:
			offset[i] = alturas[i] - (height + slope_x * corner[i].x + slope_z * corner[i].z)
		else:
			offset[i] = -travel_droop_m

# `alturas` y `hay_suelo` vienen del controlador, que es quien puede lanzar los rayos.
func step(delta: float, alturas: PackedFloat32Array, hay_suelo: PackedInt32Array,
		acceleration_longitudinal: float, acceleration_lateral: float) -> void:
	if not _configured:
		return
	var count := corner.size()
	contacts = 0
	loaded_contacts = 0
	for i in count:
		road[i] = alturas[i]
		grounded[i] = hay_suelo[i]
		if grounded[i] == 1:
			contacts += 1
	# 1. Carga de cada rueda: reparto estático + transferencia longitudinal (altura del
	#    centro de gravedad sobre la batalla) + transferencia lateral (sobre la vía). Una
	#    rueda descargada del todo deja de sostener el chasis: sale del equilibrio, pero
	#    se sigue colocando sobre el asfalto que ha medido su rayo (si lo hay).
	var static_front := mass_kg * GRAVITY * front_weight_fraction * 0.5
	var static_rear := mass_kg * GRAVITY * (1.0 - front_weight_fraction) * 0.5
	var axle_transfer := mass_kg * acceleration_longitudinal * cg_height_m / wheelbase_m
	for i in count:
		var track: float = track_front_m if is_front[i] == 1 else track_rear_m
		var lateral := signf(corner[i].x) * mass_kg * acceleration_lateral * cg_height_m / track
		var longitudinal: float = -axle_transfer * 0.5 if is_front[i] == 1 else axle_transfer * 0.5
		var base: float = static_front if is_front[i] == 1 else static_rear
		load[i] = maxf(0.0, base + longitudinal + lateral)
		if grounded[i] == 1 and load[i] > 1.0:
			loaded[i] = 1
			loaded_contacts += 1
		else:
			loaded[i] = 0
	# 2. Equilibrio del chasis: sistema 3×3 en (A, B, C) ponderado por los muelles.
	var rates := PackedFloat32Array()
	rates.resize(count)
	var heights := PackedFloat32Array()
	heights.resize(count)
	for i in count:
		rates[i] = rate_front_n_per_m if is_front[i] == 1 else rate_rear_n_per_m
		heights[i] = alturas[i]
	var moment_z := mass_kg * acceleration_longitudinal * cg_height_m
	var moment_x := mass_kg * acceleration_lateral * cg_height_m
	var solved := _solve_plane(rates, heights, moment_z, moment_x, slope_x, slope_z)
	# Descarte de una lectura que no es la calzada. El ajuste reparte el error entre las
	# cuatro ruedas, así que una sola lectura falsa —la cara de un bordillo, la base de un
	# muro, un objeto de la pista— no deja su marca sólo en su propia rueda: la reparte
	# entre todas y, encima, el tope de recorrido del paso 5 sube el chasis lo que pida esa
	# lectura. Medido con `ride_probe`, un escalón falso de 0,5 m bajo una rueda levantaba
	# el chasis 0,5 m en un fotograma, y con él el modelo (que es de donde vienen los saltos
	# del vídeo sobre asfalto aparentemente normal). La calzada que pisa el coche es una
	# superficie continua: ninguna rueda puede quedar más de 15 cm por encima del plano que
	# forman las otras tres. Cuando alguna lo hace, esa lectura se descarta y el plano se
	# vuelve a resolver sin ella; la rueda se queda sin suelo, que es lo correcto.
	# La lista de candidatas es la de ruedas CON SUELO, no la de ruedas cargadas: en una
	# curva rápida el reparto de carga descarga las dos interiores y, si sólo se miran las
	# cargadas, quedan dos puntos del mismo lado; entonces la altura y la actitud del plano
	# no están determinadas y oscilan. Medido con la instrumentación de la curva rápida:
	# el asfalto medido era plano (cuatro lecturas dentro de 90 mm) y el plano del chasis
	# saltaba 1,6 m de un fotograma a otro mientras las ruedas topaban con el recorrido.
	if contacts >= 4:
		var peor := -1
		var peor_residuo := 0.0
		for i in count:
			if grounded[i] == 0:
				continue
			var residuo := heights[i] - (solved.x + solved.y * corner[i].x + solved.z * corner[i].z)
			if absf(residuo) > peor_residuo:
				peor_residuo = absf(residuo)
				peor = i
		if peor >= 0 and peor_residuo > road_outlier_m:
			grounded[peor] = 0
			loaded[peor] = 0
			contacts -= 1
			loaded_contacts -= 1
			solved = _solve_plane(rates, heights, moment_z, moment_x, slope_x, slope_z)
	# El mismo sistema sin momentos es el plano de la CALZADA: la actitud estática
	# que dicta el suelo. La diferencia entre los dos es lo que aporta la suspensión.
	var road_plane := _solve_plane(rates, heights, 0.0, 0.0, road_slope_x, road_slope_z)
	road_height = road_plane.x
	road_slope_x = clampf(road_plane.y, -0.15, 0.15)
	road_slope_z = clampf(road_plane.z, -0.15, 0.15)
	# Guarda numérica: el plano no puede alejarse del asfalto medido ni inclinarse
	# más de 8,6°, y una solución no finita deja la pose anterior. Nunca se propaga
	# un valor absurdo a la geometría del coche.
	var plano_medido := contacts > 0
	if not _finite(solved.x) or not _finite(solved.y) or not _finite(solved.z):
		solved = Vector3(height, slope_x, slope_z)
		plano_medido = false
	elif contacts > 0:
		var lowest := INF
		var highest := -INF
		for i in count:
			if grounded[i] == 1:
				lowest = minf(lowest, heights[i])
				highest = maxf(highest, heights[i])
		solved.x = clampf(solved.x, lowest - 0.5, highest + 0.5)
		solved.y = clampf(solved.y, -0.15, 0.15)
		solved.z = clampf(solved.z, -0.15, 0.15)
	# El plano vale lo que vale su medida: si no había ni un rayo sobre asfalto, `height`
	# sigue siendo la del sitio anterior (o el cero del `reset`) y NO está asentada.
	seated = plano_medido
	# 3. Amortiguadores. La altura del chasis se separa en dos partes: la que dicta el
	#    ASFALTO (el plano de la calzada, que se sigue sin retardo porque es la
	#    carretera, no la suspensión) y la COMPRESIÓN que añaden las cargas. Filtrar
	#    la altura total sería un error: en una bajada la calzada baja a 0,3 m/s y un
	#    filtro de 40 ms dejaría el coche 12 mm por encima, con las ruedas extendidas
	#    (medido: hasta -30 mm, el tope de extensión). Filtrando sólo la compresión, la
	#    rampa se sigue exactamente y lo que amortigua es la respuesta del muelle: el
	#    badén lo absorbe primero el recorrido de la rueda y el chasis sube después.
	#    La actitud va filtrada con la misma constante del amortiguador.
	var target_compression := solved.x - road_height
	height_target = solved.x
	if _first_frame:
		compression = target_compression
	else:
		compression += (target_compression - compression) * (1.0 - exp(-delta / maxf(damper_tau, 0.0001)))
	height = road_height + compression
	slope_x += (solved.y - slope_x) * (1.0 - exp(-delta / maxf(damper_tau, 0.0001)))
	slope_z += (solved.z - slope_z) * (1.0 - exp(-delta / maxf(damper_tau, 0.0001)))
	# 4. Recorrido de cada rueda con el plano YA filtrado: el residuo es lo que la rueda
	#    sube o baja para quedarse en el asfalto.
	_recolocar_ruedas(heights, grounded)
	# 5. Si el badén agota la compresión, sube el chasis: es lo que hace un coche real
	#    cuando la suspensión tope; la rueda se queda en el suelo en vez de hundirse.
	saturated = 0
	for pass_index in 2:
		var excess := 0.0
		for i in count:
			if grounded[i] == 1 and offset[i] > travel_bump_m:
				excess = maxf(excess, offset[i] - travel_bump_m)
		if excess <= 0.0:
			break
		height += excess
		for i in count:
			if grounded[i] == 1:
				offset[i] = heights[i] - (height + slope_x * corner[i].x + slope_z * corner[i].z)
	# 5-bis. COTA POR RECORRIDO. El chasis no puede separarse del plano medido más de lo
	#    que alcanzan sus ruedas: el recorrido es el recorrido. Sin esta cota, la altura y
	#    la actitud salían del equilibrio de fuerzas y de momentos SIN TOPE: medido con
	#    `suspension_probe`, un golpe de badén —un pico de aceleración longitudinal espurio
	#    en un solo fotograma— descuadraba la transferencia de carga y dejaba el plano
	#    110 mm por debajo del asfalto, con las ruedas atravesándolo 141 mm. Y es la misma
	#    cuenta que producía los rebotes de la versión entregada: el plano del chasis
	#    separándose del asfalto y volviendo, con las ruedas siguiéndolo. Con la cota, la
	#    rueda que se queda sin recorrido deja de apoyar (despega, que es lo que hace un
	#    coche) en vez de atravesar el asfalto.
	var compresion := clampf(height - road_height, -travel_droop_m, travel_bump_m)
	var rel_x := slope_x - road_slope_x
	var rel_z := slope_z - road_slope_z
	var uso := absf(rel_x) * _max_x + absf(rel_z) * _max_z
	var actitud_recortada := false
	if uso > travel_droop_m:
		var escala := travel_droop_m / uso
		rel_x *= escala
		rel_z *= escala
		slope_x = road_slope_x + rel_x
		slope_z = road_slope_z + rel_z
		actitud_recortada = true
	var altura_recortada := absf(compresion - (height - road_height)) > 0.000001
	if altura_recortada:
		height = road_height + compresion
	if altura_recortada or actitud_recortada:
		_recolocar_ruedas(heights, grounded)
	# El tope de compresión ha subido el chasis a mano: la parte de suspensión de esa
	# altura es la que ha quedado, para que el filtro del fotograma siguiente no la
	# deshaga.
	compression = height - road_height
	# 5-ter. El chasis es una masa: la altura que ha salido de los pasos anteriores se
	#    alcanza con VELOCIDAD VERTICAL ACOTADA, no de golpe. Hasta aquí, la altura del
	#    plano salía directamente de la medida del asfalto (más el empujón del tope de
	#    recorrido), así que un cambio de lectura de un fotograma a otro se convertía en un
	#    salto del modelo de esa misma magnitud. El recorrido de las ruedas se recalcula con
	#    la altura que el chasis tiene DE VERDAD, así que la rueda no miente: toca el tope
	#    de recorrido y el chasis sube a continuación. Es lo que hace un coche.
	if _first_frame:
		last_height = height
	var tope := chassis_vertical_speed_max_m * delta
	var salto := height - last_height
	if absf(salto) > tope:
		height = last_height + signf(salto) * tope
		compression = height - road_height
		_recolocar_ruedas(heights, grounded)
	last_height = height
	compression = height - road_height
	for i in count:
		if offset[i] > travel_bump_m:
			offset[i] = travel_bump_m
			saturated += 1
		elif offset[i] < -travel_droop_m:
			offset[i] = -travel_droop_m
			saturated += 1
		bump_peak = maxf(bump_peak, offset[i])
		droop_peak = minf(droop_peak, offset[i])
	# 6. Actitud del modelo a partir del plano del chasis. Con y = A + B·x + C·z la
	#    normal es (-B, 1, -C): el cabeceo es +atan2(n.z, n.y) = -C y el balanceo
	#    -atan2(n.x, n.y) = +B, los mismos signos que ya quedaron verificados.
	pitch = -slope_z
	roll = slope_x
	# La actitud de suspensión es pequeña por construcción (barras de torsión de
	# monoplaza): se acota a 2,9°, que ya es más de lo que se inclina un F1.
	pitch_relative = clampf(-(slope_z - road_slope_z), -0.05, 0.05)
	roll_relative = clampf(slope_x - road_slope_x, -0.05, 0.05)
	_first_frame = false

# Resuelve, por mínimos cuadrados ponderados por la rigidez de cada muelle, el plano
# (A, B, C) que cumple el equilibrio de fuerzas y los dos momentos:
#   Σ k·(s - A - Bx - Cz) = 0 ;  Σ k·(s - A - Bx - Cz)·z = m·a_x·cg ;
#   Σ k·(s - A - Bx - Cz)·x = m·a_y·cg
func _solve_plane(rates: PackedFloat32Array, s: PackedFloat32Array,
		moment_z: float, moment_x: float, target_slope_x: float, target_slope_z: float) -> Vector3:
	# GEOMETRÍA ANTES QUE CARGA. El plano que pisan las ruedas se resuelve con las ruedas
	# que TIENEN SUELO: una rueda descargada sigue tocando el asfalto y sigue midiendo
	# dónde está. La carga entra en el sistema como el momento que es (parámetro
	# `moment_*`), no como un filtro de qué lecturas valen: filtrando por carga, el plano
	# se quedaba con las ruedas del mismo lado y su altura absoluta quedaba libre.
	if contacts == 0:
		return Vector3(height, target_slope_x, target_slope_z)
	# With fewer than three contact patches, road-plane attitude is not fully
	# observable. Solving the singular/near-singular 3×3 system (especially when
	# the two remaining wheels share an axle side) magnifies tiny FBX triangle
	# height differences into alternating ±8° pitch/roll. Preserve the previous
	# measured attitude and solve only the supported height; the missing axis is
	# an inertial degree of freedom until another wheel contacts the road.
	if contacts < 3:
		var support_weight := 0.0
		var support_height := 0.0
		for i in corner.size():
			if grounded[i] == 0:
				continue
			var support_rate: float = rates[i]
			support_weight += support_rate
			support_height += support_rate * (s[i] - target_slope_x * corner[i].x - target_slope_z * corner[i].z)
		if support_weight > 0.0:
			return Vector3(support_height / support_weight, target_slope_x, target_slope_z)
		return Vector3(height, target_slope_x, target_slope_z)
	var sum_k := 0.0
	var sum_kx := 0.0
	var sum_kz := 0.0
	var sum_kxx := 0.0
	var sum_kxz := 0.0
	var sum_kzz := 0.0
	var sum_ks := 0.0
	var sum_ksz := 0.0
	var sum_ksx := 0.0
	for i in corner.size():
		if grounded[i] == 0:
			continue
		var k := rates[i]
		var x := corner[i].x
		var z := corner[i].z
		sum_k += k
		sum_kx += k * x
		sum_kz += k * z
		sum_kxx += k * x * x
		sum_kxz += k * x * z
		sum_kzz += k * z * z
		sum_ks += k * s[i]
		sum_ksz += k * s[i] * z
		sum_ksx += k * s[i] * x
	var m: Array[Vector3] = [
		Vector3(sum_k, sum_kx, sum_kz),
		Vector3(sum_kz, sum_kxz, sum_kzz),
		Vector3(sum_kx, sum_kxx, sum_kxz),
	]
	var rhs := Vector3(sum_ks, sum_ksz - moment_z, sum_ksx - moment_x)
	if contacts < 3:
		# Con menos de tres ruedas cargadas el plano no está determinado: la actitud
		# la fija la inercia del chasis, no un momento que no tiene con qué
		# equilibrarse. Se tira hacia la actitud anterior (regularización de
		# Tikhonov) y con más fuerza cuantas menos ruedas sostengan el coche: con
		# una sola, la actitud prácticamente se mantiene y lo único que se resuelve
		# es dónde queda el plano; con dos, todavía se inclina un poco.
		var eps := 150000.0 * float(3 - contacts)
		var row_roll: Vector3 = m[1]
		var row_pitch: Vector3 = m[2]
		row_roll.y += eps
		row_pitch.z += eps
		m[1] = row_roll
		m[2] = row_pitch
		rhs.y += eps * target_slope_z
		rhs.z += eps * target_slope_x
	return _solve3(m, rhs)

static func _finite(value: float) -> bool:
	return absf(value) < 1.0e9

static func _solve3(m: Array[Vector3], rhs: Vector3) -> Vector3:
	var a: float = m[0].x
	var b: float = m[0].y
	var c: float = m[0].z
	var d: float = m[1].x
	var e: float = m[1].y
	var f: float = m[1].z
	var g: float = m[2].x
	var h: float = m[2].y
	var i: float = m[2].z
	var det: float = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
	if absf(det) < 1e-9:
		return Vector3.ZERO
	var det_a: float = rhs.x * (e * i - f * h) - b * (rhs.y * i - f * rhs.z) + c * (rhs.y * h - e * rhs.z)
	var det_b: float = a * (rhs.y * i - f * rhs.z) - rhs.x * (d * i - f * g) + c * (d * rhs.z - rhs.y * g)
	var det_c: float = a * (e * rhs.z - rhs.y * h) - b * (d * rhs.z - rhs.y * g) + rhs.x * (d * h - e * g)
	return Vector3(det_a / det, det_b / det, det_c / det)

func reset() -> void:
	for i in offset.size():
		offset[i] = 0.0
		loaded[i] = 0
	# `contacts` es estado del fotograma anterior y sobrevive al reinicio: el controlador
	# lo consulta para saber si puede apoyarse en el plano. Con el coche recién colocado
	# en otro sitio, esa cuenta habla del sitio del que viene.
	contacts = 0
	loaded_contacts = 0
	seated = false
	height = 0.0
	compression = 0.0
	slope_x = 0.0
	slope_z = 0.0
	pitch = 0.0
	roll = 0.0
	pitch_relative = 0.0
	roll_relative = 0.0
	bump_peak = 0.0
	droop_peak = 0.0
	_first_frame = true
	last_height = 0.0

func stats() -> Dictionary:
	return {
		"contacts": contacts,
		"loaded_contacts": loaded_contacts,
		"saturated": saturated,
		"height_m": height,
		"compression_mm": compression * 1000.0,
		"pitch_deg": rad_to_deg(pitch),
		"roll_deg": rad_to_deg(roll),
		"pitch_suspension_deg": rad_to_deg(pitch_relative),
		"roll_suspension_deg": rad_to_deg(roll_relative),
		"offset_mm": [offset[0] * 1000.0, offset[1] * 1000.0, offset[2] * 1000.0, offset[3] * 1000.0],
		"load_n": [load[0], load[1], load[2], load[3]],
		"bump_peak_mm": bump_peak * 1000.0,
		"droop_peak_mm": droop_peak * 1000.0,
	}
