extends Node3D

const CarScript = preload("res://scripts/car_controller.gd")
const HudScript = preload("res://scripts/race_hud.gd")
const TouchScript = preload("res://scripts/touch_controls.gd")
const AssistanceLineScript = preload("res://scripts/driving_line.gd")
const TrackScript = preload("res://scripts/track_data.gd")
const CAR_MODEL: PackedScene = preload("res://assets/RedBull.tscn")
const HIGH_DETAIL_WHEEL: PackedScene = preload("res://assets/RedBull-Wheel.glb")
const TRACK_SCENE_PATH := "res://assets/BarcelonaMoto-Tutorial.glb"

var car: CharacterBody3D
var hud: CanvasLayer
var controls: CanvasLayer
var camera: Camera3D
var start_gate: Area3D
var track_mesh: Node3D
var spawn_position := Vector3.ZERO
# Línea dinámica de asistencia (segunda línea visual, encima de la goma de la
# trazada). Es sólo dibujo: no toca la física, ni la cámara, ni las colisiones.
var assistance_line = null

# --- relieve de calzada de la malla de física de AC ----------------------------
#
# El circuito trae del original de Assetto Corsa una malla de física cuyos grupos
# no son suelo ni muro sino RELIEVE de la calzada: la goma de las ruedas
# (MARBLES), las tiras de badenes (BUMP), las rejillas (GRILLE), los cruces
# (TRAV) y los escalones de hormigón (CNCPTS). En AC se ruedan por encima, porque
# su coche son cuatro rayos de rueda; aquí el coche es una caja rígida contra una
# malla trimesh, así que cualquier borde que sobresalga es un muro, y como esas
# mallas no se dibujan (son sólo formas de colisión), el muro es INVISIBLE.
#
# Medido en esta fase (sondas `relief_probe.gd` y `visual_cover_probe.gd`,
# registros en `.tools/recovery/fase-muros/`): de las 16 668 caras de relieve,
# 865 sobresalen más de 5 cm del suelo que tienen justo debajo y la peor sube
# +0,09 m; y de las que sobresalen, 244 no tienen nada dibujado a menos de 25 cm
# (144 de BUMP en la banda de 0 a 0,5 m, 43 de MARBLES y 12 de GRILLE). A fondo por
# la recta el coche se clavaba contra una de ellas: 313,5 km/h -> clavado en la
# estación 549, sobre asfalto y a 4,84 m de la trazada, y sólo 8,75 m en los 3 s
# siguientes con el acelerador a fondo.
#
# La corrección hunde estas geometrías por debajo de la calzada: ninguna de sus
# caras puede volver a sobresalir, el coche rueda sobre la pista de verdad —que es
# la que tiene debajo, porque el relieve no es más que un relieve de 5 a 9 cm— y
# ninguna otra colisión cambia: ni muros, ni vallas, ni guardarraíles, ni
# bordillos, ni las superficies de la pista.
#
# El hundimiento es una constante, y su valor sale de medir cara a cara contra el
# suelo que cada una tiene debajo (es lo que hace la sonda `sonda_relieve` de
# verify.sh en cada pasada): la cara de relieve más alta sobresale +0,09 m de su
# suelo, así que 1,5 m la deja 1,41 m POR DEBAJO del asfalto en cualquier punto. Se
# evita así lo que costaba el aplanado cara a cara —una consulta al espacio por
# vértice, 50 000 rayos contra mallas de 300 000 caras, más de siete minutos— y el
# arranque no paga nada (la escena entera arranca en 5,63 s, sin una consulta más).
const RELIEF_GROUPS := ["MARBLES", "BUMP", "GRILLE", "GRILL", "CNCPTS", "TRAV"]
const RELIEF_SINK_M := 1.5
var relief_bodies: Array[StaticBody3D] = []

# --- cámara de persecución -----------------------------------------------------
#
# La cámara anterior medía su posición con un suavizado exponencial sobre una
# referencia MÓVIL: `camera.position = lerp(camera.position, car + offset)` con
# λ = 6 s⁻¹. Ese filtro, contra un objetivo que se traslada a v, no converge al
# offset: se queda con un error de seguimiento ESTACIONARIO de v/λ metros. A
# 107 km/h eran 4,9 m de más y a 191 km/h 8,8 m de más sobre los 9 m de
# separación base (de 13,9 a 17,8 m), y por eso el coche se veía más pequeño
# cuanto más corría aunque ninguna línea del código cambiase la distancia.
#
# Se arregla en la capa correcta: el desplazamiento se construye en el sistema
# DEL COCHE —donde es constante en régimen y por tanto no acumula error— y lo
# que se filtra es el PARÁMETRO de velocidad, no la posición. La distancia es
# una función decreciente de la velocidad, con topes declarados aquí abajo y
# constantes de tiempo distintas al acercarse y al alejarse.
#
# El único filtro que queda sobre la geometría es el de la DIRECCIÓN (el retardo
# de guiñada), acotado a `camera_max_yaw_lag_rad`: en curva la cámara se queda
# un poco por fuera en vez de girar con el coche. El retardo no toca la
# distancia, porque la cámara se coloca a esa distancia del coche pase lo que
# pase.
@export_category("Chase camera")
# Distancia al coche: lejos para maniobrar, cerca para correr.
@export var camera_distance_stopped_m := 11.4
@export var camera_distance_fast_m := 7.2
@export var camera_height_stopped_m := 3.45
@export var camera_height_fast_m := 2.70
# Cuánto se adelanta el punto al que mira: más lejos cuanto más corre, que es lo
# que deja pista visible por delante al acercar la cámara.
@export var camera_ahead_stopped_m := 11.0
@export var camera_ahead_fast_m := 24.0
@export var camera_aim_height_m := 0.8
# Velocidad a la que la cámara está "a tope" (≈ 198 km/h).
@export var camera_full_speed_mps := 55.0
# Constantes de tiempo del parámetro: acercarse es la respuesta deportiva
# (rápida) y alejarse la recuperación de maniobra (más lenta), de modo que un
# toque de freno no devuelva la cámara de golpe.
@export var camera_tau_closing := 0.55
@export var camera_tau_opening := 0.85
# Retardo de guiñada y su tope (0,44 rad ≈ 25°).
@export var camera_tau_yaw := 0.20
@export var camera_max_yaw_lag_rad := 0.44
# Anticolisión del muro y topes de la distancia aplicada.
@export var camera_min_distance_m := 3.6
@export var camera_wall_margin_m := 0.35
@export var camera_tau_wall := 0.08
# Si la anticolisión acorta la distancia, la cámara baja y mira más cerca en la
# misma proporción (0,25 = al máximo acortamiento se queda con el 25 % de su
# altura y de su adelanto). Acercarse sin bajar deja la cola del coche fuera del
# encuadre —medido con el muro de prueba: 142 px por debajo del borde—, y bajar
# cuesta menos que quedarse mirando el muro.
@export var camera_squeeze_ratio := 0.25

# --- cámara del morro ----------------------------------------------------------
#
# Segunda perspectiva jugable, en el morro del monoplaza, con su propio nodo de
# cámara: la anticolisión y la distancia dinámica de la persecución viven en
# `_update_chase_camera` y sólo escriben en `camera`, así que no pueden tocar
# esta. El punto de vista no se inventa: sale de los hitos MEDIDOS del propio
# modelo (`.tools/recovery/fase-fp/geometria_modelo.gd`), en el marco del coche:
#
#   eje delantero            z = −1,511 m
#   alto del neumático       y = +0,748 m   (radio 0,374)
#   punta del alerón         z = −2,763 m
#   alto de la carrocería    y = +1,232 m
#   techo de la carrocería EN LA Z DE LA CÁMARA (z = +0,19): y = aprox. +0,74 m
#
# La cámara se coloca detrás del eje delantero, dentro del puesto del piloto,
# para dejar los neumáticos por delante y a los lados. Se baja el punto de vista
# y la inclinación para que el morro quede en el borde inferior y la pista domine
# el encuadre, como en una cámara onboard de F1.
@export_category("Nose camera")
# Cuánto detrás del eje delantero se pone el punto de vista (0 lo pondría sobre
# el eje y los neumáticos quedarían cortados por el borde inferior).
@export var nose_behind_axle_m := 1.25
# Cuánto por encima del alto del neumático delantero. Se eleva respecto a la
# iteración anterior para mostrar más flanco y reducir el recorte de la rueda.
@export var nose_above_wheels_m := 0.25
# Inclinación hacia abajo y campo de visión propios, ajustados para que el morro
# ocupe la franja inferior y la pista se vea de cerca a lo lejos.
@export var nose_pitch_down_deg := 4.0
@export var nose_fov := 61.0
@export var nose_near_m := 0.1
@export var nose_far_m := 2000.0
# Cambio de vista: la cámara que entra arranca EXACTAMENTE donde estaba la que
# sale (por eso no hay salto), y llega a su sitio en este tiempo describiendo un
# arco por encima del coche. El arco es lo que evita que el camino entre las dos
# posiciones pase por dentro de la carrocería.
@export var nose_switch_seconds := 0.22
@export var nose_switch_arc_m := 0.95

const MODO_PERSECUCION := 0
const MODO_MORRO := 1

var _camera_blend := 0.0                 # parámetro de velocidad filtrado (0..1)
var _camera_dir := Vector3.FORWARD       # dirección horizontal hacia delante de la cámara
var _camera_distance := 0.0              # distancia aplicada tras la anticolisión
var _camera_pose_ready := false

var nose_camera: Camera3D                # segunda cámara, su propio nodo
var camera_mode := MODO_PERSECUCION
var _nose_offset := Vector3.ZERO         # punto de vista en el marco del coche, medido
var _nose_anclaje_medido := false        # si se pudo medir el modelo o se usó el respaldo
var _switch_arc := 0.0                   # progreso lineal de la transición (para el arco)
var _chase_eye := Vector3.ZERO           # pose resuelta de la persecución
var _chase_target := Vector3.ZERO
var _nose_eye := Vector3.ZERO            # pose resuelta del morro
var _nose_target := Vector3.ZERO
var _nose_up := Vector3.UP
var _active_target := Vector3.ZERO       # a dónde mira la cámara activa (para la transición)
var _switch_blend := 1.0                 # 1 = vista asentada
var _switch_from := Vector3.ZERO         # dónde estaba la cámara que sale
var _switch_from_target := Vector3.ZERO  # y a dónde miraba
var _switch_from_up := Vector3.UP

func _ready() -> void:
	Engine.max_fps = 60
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# La cámara se resuelve en el paso de FÍSICA y DESPUÉS de que el coche se
	# haya movido. Antes se resolvía en `_process`, que va al ritmo del dibujado:
	# entre los dos fotogramas el coche avanza y la cámara se queda con la
	# posición anterior, de modo que la separación real crecía con la velocidad
	# (0,92 m a 200 km/h con el dibujado a 60 Hz) y temblaba al desfasarse los dos
	# relojes. Con la prioridad más alta que la del coche, la cámara y el coche
	# son del mismo fotograma y la distancia es la de diseño a cualquier
	# velocidad y a cualquier frecuencia de dibujado.
	process_physics_priority = 10
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_world()
	_build_car()
	_build_assistance_line()
	_measure_nose_offset()
	_build_camera()
	_build_nose_camera()
	_build_lap_gate()
	hud = CanvasLayer.new()
	hud.name = "Race telemetry"
	hud.set_script(HudScript)
	add_child(hud)
	hud.camera_toggle_pressed.connect(toggle_camera)
	hud.set_camera_mode(camera_mode)
	controls = CanvasLayer.new()
	controls.name = "Touch controls"
	controls.set_script(TouchScript)
	controls.car = car
	add_child(controls)
	if OS.get_name() == "Android":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

func _physics_process(delta: float) -> void:
	if car == null:
		return
	if camera != null:
		_update_chase_camera(delta)
	if nose_camera != null:
		_update_nose_camera()
	_apply_camera_mode(delta)
	if car.global_position.y < -80.0 or Input.is_action_just_pressed("reset_car"):
		var points := TrackScript.get_centerline()
		var nearest := 0
		var distance := INF
		for i in points.size():
			var d := car.global_position.distance_squared_to(points[i])
			if d < distance:
				distance = d
				nearest = i
		var tangent := points[(nearest + 5) % points.size()] - points[nearest]
		car.recover_to(points[nearest] + Vector3.UP * 0.2, atan2(-tangent.x, -tangent.z))
	car.lap_tracker.advance(delta, car)
	var local := start_gate.to_local(car.global_position)
	if car.previous_gate_local_z > 0.0 and local.z <= 0.0 and absf(local.x) < 9.0 and absf(local.y) < 4.0:
		car.register_line_crossing(car.previous_gate_local_z, local.z)
	car.previous_gate_local_z = local.z

func _process(delta: float) -> void:
	if hud != null and car != null:
		hud.update_telemetry(car)

# Cámara de persecución: distancia inversamente proporcional a la velocidad,
# con transición suave y acotada. Ver el comentario de los parámetros arriba.
# La función es de sólo lectura respecto al coche: no toca su posición, su
# tamaño ni la geometría del circuito.
func _update_chase_camera(delta: float) -> void:
	var base := car.global_position
	# 1. Dirección horizontal del coche. Se proyecta sobre el plano del mundo
	#    para que la actitud de suspensión o el peralte no inclinen la cámara.
	var heading := -car.global_basis.z
	heading.y = 0.0
	if heading.length_squared() < 0.000001:
		heading = Vector3.FORWARD
	heading = heading.normalized()
	# 2. Retardo de guiñada, de primer orden y acotado.
	if not _camera_pose_ready:
		_camera_dir = heading
		_camera_blend = clampf(car.speed_mps / maxf(camera_full_speed_mps, 0.001), 0.0, 1.0)
		_camera_distance = camera_distance_stopped_m
		_camera_pose_ready = true
	var flat := Vector3(_camera_dir.x, 0.0, _camera_dir.z)
	flat = (heading if flat.length_squared() < 0.000001 else flat.normalized())
	flat = flat.lerp(heading, 1.0 - exp(-delta / maxf(camera_tau_yaw, 0.0001)))
	flat = Vector3(flat.x, 0.0, flat.z)
	flat = (heading if flat.length_squared() < 0.000001 else flat.normalized())
	var lag := acos(clampf(flat.dot(heading), -1.0, 1.0))
	if lag > camera_max_yaw_lag_rad:
		var axis := flat.cross(heading)
		if axis.length_squared() > 0.000001:
			flat = flat.rotated(axis.normalized(), lag - camera_max_yaw_lag_rad)
			flat = Vector3(flat.x, 0.0, flat.z).normalized()
	_camera_dir = flat
	# 3. Parámetro de velocidad filtrado: al subir usa una constante de tiempo y
	#    al bajar otra, así acercarse es inmediato y alejarse es progresivo.
	var demand := clampf(car.speed_mps / maxf(camera_full_speed_mps, 0.001), 0.0, 1.0)
	var tau: float = camera_tau_closing if demand > _camera_blend else camera_tau_opening
	_camera_blend = clampf(_camera_blend + (demand - _camera_blend) * (1.0 - exp(-delta / maxf(tau, 0.0001))), 0.0, 1.0)
	var distance := lerpf(camera_distance_stopped_m, camera_distance_fast_m, _camera_blend)
	var height := lerpf(camera_height_stopped_m, camera_height_fast_m, _camera_blend)
	var ahead := lerpf(camera_ahead_stopped_m, camera_ahead_fast_m, _camera_blend)
	# 4. Anticolisión: si el muro del circuito queda ENTRE el coche y la cámara,
	#    la cámara se trae por delante de él. Sólo se acorta la distancia, que
	#    además se filtra, para que rozar un muro no produzca un salto.
	var wanted := distance
	var origin := base + Vector3.UP * camera_aim_height_m
	var eye := base + Vector3.UP * height - flat * distance
	var ray := PhysicsRayQueryParameters3D.create(origin, eye, 1)
	var hit := car.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		var reach := origin.distance_to(eye)
		var blocked := origin.distance_to(hit["position"])
		if reach > 0.0001:
			wanted = maxf(camera_min_distance_m, distance * (blocked / reach) - camera_wall_margin_m)
	_camera_distance = maxf(0.0, _camera_distance + (wanted - _camera_distance) * (1.0 - exp(-delta / maxf(camera_tau_wall, 0.0001))))
	var squeeze := clampf(_camera_distance / maxf(distance, 0.001), 0.0, 1.0)
	var shrink := lerpf(camera_squeeze_ratio, 1.0, squeeze)
	# La pose se resuelve aquí y se APLICA en `_apply_camera_mode`, que es quien
	# sabe qué cámara está activa. Así la persecución sigue calculando su estado
	# (distancia, retardo de guiñada) aunque esté en segundo plano, y volver a
	# ella no da un salto.
	_chase_eye = base + Vector3.UP * (height * shrink) - flat * _camera_distance
	_chase_target = base + heading * (ahead * shrink) + Vector3.UP * camera_aim_height_m

# Punto de vista del morro: se deriva de los hitos medidos del modelo, en el
# marco DEL COCHE (no en el del mundo), así que es rígido respecto al coche por
# construcción: ni la velocidad ni el sistema de distancia dinámica de la
# persecución lo pueden mover. Lo único que hereda son los giros del chasis
# (cabeceo y balanceo de la suspensión), que es lo que hace una cámara onboard.
func _measure_nose_offset() -> void:
	var inv := car.global_transform.affine_inverse()
	var eje_delantero := INF
	var alto_rueda := -INF
	for child in car.model_root.find_children("*", "MeshInstance3D", true, false):
		if not String(child.name).to_lower().contains("wheel"):
			continue
		# El buje (origen del nodo) no se mueve al girar la rueda, y el radio sale
		# de la caja de la MALLA, que tampoco: medir las esquinas de la caja a
		# través del giro daba un alto distinto en cada vuelta (0,748 m con la
		# rueda en cruz y 0,52 m a 45°, medido), porque una caja girada proyecta
		# otra caja. Con buje + radio la medida es la misma siempre.
		var aabb: AABB = child.mesh.get_aabb()
		var tamano := aabb.size
		var grueso := 0
		for eje in range(1, 3):
			if tamano[eje] < tamano[grueso]:
				grueso = eje
		var diametro := 1 if grueso != 1 else 2
		var radio: float = tamano[diametro] * 0.5
		var buje: Vector3 = inv * child.global_transform.origin
		if buje.z < 0.0:                      # rueda delantera: hacia delante del coche
			eje_delantero = buje.z
			alto_rueda = maxf(alto_rueda, buje.y + radio)
	if is_finite(eje_delantero) and is_finite(alto_rueda):
		_nose_offset = Vector3(0.0, alto_rueda + nose_above_wheels_m,
			eje_delantero + nose_behind_axle_m)
		_nose_anclaje_medido = true
		print("[nose] anclaje medido del modelo: eje_delantero_z=%+.3f alto_neumatico=%+.3f punto_de_vista=%s"
			% [eje_delantero, alto_rueda, _v(_nose_offset)])
	else:
		# Respaldo declarado con las medidas del activo entregado (15 de octubre de
		# 2026): el juego arranca igual y el informe lo dice.
		_nose_offset = Vector3(0.0, 0.748 + nose_above_wheels_m, -1.511 + nose_behind_axle_m)
		_nose_anclaje_medido = false
		push_warning("[nose] no se pudieron medir las ruedas delanteras; se usa el respaldo %s" % _v(_nose_offset))

func _update_nose_camera() -> void:
	var base := car.global_transform
	_nose_eye = base * _nose_offset
	_nose_up = base.basis.y.normalized()
	# Giro hacia abajo sobre el eje LATERAL del coche: la cámara mira por donde
	# mira el coche y baja el morro en el encuadre. Se conserva la inclinación
	# lateral del chasis (el horizonte se tumba con el coche), que es lo que hace
	# una cámara montada en el morro.
	var adelante := -base.basis.z
	if _nose_up.length_squared() < 0.5:
		_nose_up = Vector3.UP
	var direccion := adelante.rotated(base.basis.x.normalized(), -deg_to_rad(nose_pitch_down_deg))
	_nose_target = _nose_eye + direccion * 30.0

# Cambio de vista. La cámara que ENTRA arranca donde estaba la que SALE, así que
# el corte es invisible, y llega a su pose en `nose_switch_seconds` describiendo
# un arco por encima del coche (si fuese en línea recta, el camino entre el
# puesto de persecución y el morro pasa por dentro de la carrocería).
func toggle_camera() -> void:
	set_camera_mode(MODO_MORRO if camera_mode == MODO_PERSECUCION else MODO_PERSECUCION)

func set_camera_mode(mode: int) -> void:
	if mode == camera_mode:
		return
	var saliente: Camera3D = nose_camera if camera_mode == MODO_MORRO else camera
	_switch_from = saliente.global_position
	_switch_from_target = _active_target if _active_target != Vector3.ZERO else saliente.global_position - saliente.global_basis.z
	_switch_from_up = saliente.global_basis.y.normalized()
	camera_mode = mode
	_switch_blend = 0.0
	_switch_arc = 0.0
	if hud != null:
		hud.set_camera_mode(mode)

func _apply_camera_mode(delta: float) -> void:
	var activa: Camera3D = nose_camera if camera_mode == MODO_MORRO else camera
	if activa == null:
		return
	var ojo := _nose_eye if camera_mode == MODO_MORRO else _chase_eye
	var objetivo := _nose_target if camera_mode == MODO_MORRO else _chase_target
	var arriba := _nose_up if camera_mode == MODO_MORRO else Vector3.UP
	if _switch_blend < 1.0:
		_switch_blend = minf(1.0, _switch_blend + delta / maxf(nose_switch_seconds, 0.0001))
		_switch_arc = minf(1.0, _switch_arc + delta / maxf(nose_switch_seconds, 0.0001))
		var t := smoothstep(0.0, 1.0, _switch_blend)
		var posicion := _switch_from.lerp(ojo, t)
		# El arco se mide con el progreso LINEAL, no con el suavizado: al 15 % del
		# cambio el suavizado sólo ha subido el 6 % de la altura, y con el arco
		# suavizado la cámara pasaba por encima de la toma de aire 2 cm POR DENTRO
		# de la carrocería (medido: holgura −0,019 m en el fotograma 2 de la vuelta
		# a la persecución). Con el lineal, la subida llega antes de que la cámara
		# esté sobre el carenado.
		posicion.y += nose_switch_arc_m * sin(PI * _switch_arc)
		var mirada := _switch_from_target.lerp(objetivo, t)
		var up := _switch_from_up.lerp(arriba, t)
		if up.length_squared() < 0.5:
			up = Vector3.UP
		activa.global_position = posicion
		if (mirada - posicion).length_squared() > 0.0001:
			activa.look_at(mirada, up.normalized())
		_active_target = mirada
	else:
		activa.global_position = ojo
		if (objetivo - ojo).length_squared() > 0.0001:
			activa.look_at(objetivo, arriba)
		_active_target = objetivo
	activa.current = true

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#4e85b5")
	sky_mat.sky_horizon_color = Color("#b7d3e4")
	sky.sky_material = sky_mat
	env.sky = sky
	# Con AMBIENT_SOURCE_SKY a 0.65 el cielo azul teñia toda la escena: el asfalto
	# de AC, de albedo neutro (asph_updt (80,80,80)), salia (146,180,202) y el
	# canal azul de las lineas blancas se recortaba a 255. El cielo se mantiene
	# como fondo, pero la luz ambiental pasa a ser neutra y el sol lleva el peso,
	# que es lo que hace que el circuito se parezca al original.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.76, 0.78)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -24.0, 0.0)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)
	var packed := load(TRACK_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Tutorial circuit import cannot load.")
		return
	track_mesh = packed.instantiate()
	track_mesh.name = "Barcelona Moto original AC track"
	# AC AI uses (-X,Y,-Z). The Blender Y-up export preserves AC coordinates.
	track_mesh.rotation.y = PI
	add_child(track_mesh)
	var collision_count := 0
	for node in track_mesh.find_children("*", "StaticBody3D", true, false):
		var body := node as StaticBody3D
		var extras: Dictionary = body.get_meta("extras", {})
		if extras.get("kn5_source_obj", "") == "4.obj":
			body.collision_layer = 0
			continue
		body.collision_layer = 1
		body.collision_mask = 0
		body.set_meta("ac_surface", extras.get("ac_source_nodes", body.name))
		body.set_meta("ac_source", extras.get("kn5_source_obj", ""))
		var relieve := _relief_group_of(String(extras.get("ac_source_nodes", "")) + " " + String(body.name))
		body.set_meta("ac_relief", relieve)
		if relieve != "":
			relief_bodies.append(body)
		collision_count += 1
	var meshes := track_mesh.find_children("*", "MeshInstance3D", true, false)
	for node in meshes:
		var mesh := node as MeshInstance3D
		var physics: bool = bool(mesh.get_meta("ac_physics", false)) or String(mesh.name).ends_with("-colonly")
		if physics:
			mesh.visible = false
			# AC_START/AC_TIME marker boxes are metadata, not road obstacles.
			if String(mesh.get_meta("kn5_source_obj", "")) == "4.obj":
				continue
			# Runtime glTF generation does not process editor import suffixes.
			var body := StaticBody3D.new()
			body.name = "AC physics " + mesh.name
			var sources := String(mesh.get_meta("kn5_source_obj", ""))
			body.set_meta("ac_surface", String(mesh.get_meta("ac_source_nodes", mesh.name)))
			body.set_meta("ac_source", sources)
			body.collision_layer = 1
			body.collision_mask = 0
			mesh.add_child(body)
			var shape := CollisionShape3D.new()
			shape.shape = mesh.mesh.create_trimesh_shape()
			body.add_child(shape)
			collision_count += 1
		else:
			for i in mesh.mesh.get_surface_count():
				var mat := mesh.mesh.surface_get_material(i) as StandardMaterial3D
				if mat != null:
					mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
					var material_extras: Dictionary = mat.get_meta("extras", {})
					var metadata: Dictionary = JSON.parse_string(String(material_extras.get("ac_material", "{}")))
					if metadata.get("alpha_tested", false) or metadata.get("alpha_blend", false) or "Alpha" in String(metadata.get("shader", "")):
						mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
						mat.alpha_scissor_threshold = 0.35
					if _es_goma_de_trazada(mat) and not goma_sin_corregir:
						_neutralizar_goma(mesh, i, mat)
	_hundir_relieve_de_calzada()
	_informar_goma()
	print("[track] tutorial mesh batches=", meshes.size(), " original hidden collision batches=", collision_count)

# --- goma de la trazada: de dónde sale el tono azulado -------------------------
#
# La franja gris-azulada que recorre la trazada no es un defecto de importación ni
# de iluminación: es la GOMA que trae el propio mod. La dibujan las superficies del
# material `barcelona_remastered::groove` (textura groove.png, 1024x1024, media
# medida (82,86,102) → un 19,9 % de dominante azul sobre su canal mayor) y las de
# `groove3` (tyres_add2.png, media (30,33,40), 25,2 % de azul), y se dibujan casi
# opacas: el recorte de alfa de 0,35 que aplica `_build_world` descarta lo tenue y
# deja pasar ese azul tal cual.
#
# La corrección va donde NACE el tono, en el material de ESA goma y sólo en él: se
# multiplica su albedo por el gris que neutraliza la media de su propia textura y la
# deja un 22 % más oscura que el albedo del asfalto de AC (asph_updt (80,80,80)). No
# se cambia ninguna textura, ni el material de la pista, ni las líneas pintadas, ni
# ningún otro objeto del circuito: la lista es la de las marcas de neumático del mod.
#
# El material se DUPLICA por superficie antes de tocarlo, porque el GLB comparte el
# mismo material entre varias mallas (medido: 2 usuarios de `groove` y 3 de
# `groove3`); sin duplicar, la corrección alcanzaría a quien lo comparta. Las mallas,
# en cambio, no se comparten (comprobado: 119 mallas para 119 nodos), así que
# `surface_set_material` no puede salpicar a otro nodo.
const RUBBER_TEXTURES := ["groove", "tyres_add2"]
# Gris del asfalto de AC (asph_updt (80,80,80) → 80/255, en sRGB, que es como están
# escritas las texturas) y cuánto más oscura debe quedar la goma respecto a él.
#
# El factor está elegido por la LUZ QUE SE VE, no por el número del albedo: el motor
# multiplica en lineal, así que comparar albedos en sRGB engaña. Medido sobre los
# píxeles de la franja (`.tools/recovery/linea/linea_pixeles.py`, comparando la misma pose
# con el material del GLB y con el corregido): con 0,78 la franja salía un 24-36 % más
# oscura que el asfalto de al lado —casi una banda negra, que no es "ligeramente más
# oscura"— y con 0,88 un 26 %. Con 0,92 queda un ~15 % más oscura en luz reflejada: se lee
# la trazada, no parece un agujero y sigue siendo el mismo gris del asfalto.
const ASPHALT_ALBEDO := 0.314
const RUBBER_DARKEN := 0.92
# La corrección de albedo neutraliza la MEDIA de la textura, pero cada texel conserva
# su propio azul (medido en pantalla sobre la franja: 9/255 de dominante tras la
# corrección, contra 19/255 con el material del GLB). Pasar la textura a escala de
# grises —conservando el alfa del recorte y el detalle de luminancia— deja cada texel
# con el tinte del asfalto y ningún azul propio. El "antes" se captura con
# `goma_sin_corregir` para comparar las dos versiones con la misma cámara y la misma luz.
const GOMA_EN_ESCALA_DE_GRISES := true
# Modo de depuración (no lo usa el juego): deja la goma tal como viene en el GLB.
var goma_sin_corregir := false
var goma_corregida: Array = []

func _relief_group_of(label: String) -> String:
	var upper := label.to_upper()
	for key in RELIEF_GROUPS:
		if key in upper:
			return key
	return ""

# ¿Es el material de una de las gomas de la trazada del mod?
func _es_goma_de_trazada(mat: StandardMaterial3D) -> bool:
	if mat.albedo_texture == null:
		return false
	var extras: Dictionary = mat.get_meta("extras", {})
	var etiqueta := ("%s %s %s" % [
		String(mat.albedo_texture.resource_path).get_file(),
		String(mat.resource_name),
		String(extras.get("ac_material", ""))]).to_lower()
	for clave in RUBBER_TEXTURES:
		if clave in etiqueta:
			return true
	return false

# Deja el albedo de la goma en gris neutro, algo más oscuro que el asfalto. El tono
# de partida se MIDE de la propia textura (media de los texeles que el recorte de
# alfa deja pasar, que son los que se ven), no de una constante escrita a mano.
# La corrección se hace en LINEAL, que es donde el motor multiplica: la media de la
# textura se lee en sRGB (son los bytes de la imagen) pero el motor la usa ya
# convertida a lineal, así que neutralizar la media en sRGB dejaba el tono azulado
# intacto —el azul de esta textura pesa un 27 % más en lineal que en sRGB— y ni
# siquiera oscurecía: medido en píxeles sobre la propia malla de la goma, la franja
# salía con 15/255 de dominante azul y sólo un 1,1 % más oscura que el asfalto.
func _neutralizar_goma(mesh: MeshInstance3D, surface: int, mat: StandardMaterial3D) -> void:
	var medida := _media_de_textura(mat.albedo_texture, mat.alpha_scissor_threshold, GOMA_EN_ESCALA_DE_GRISES)
	if medida.is_empty():
		return
	var media: Vector3 = medida["media"]
	if media.x < 0.004 or media.y < 0.004 or media.z < 0.004:
		return
	var gris := ASPHALT_ALBEDO * RUBBER_DARKEN
	var objetivo := Color(gris, gris, gris).srgb_to_linear()
	var medio := Color(media.x, media.y, media.z).srgb_to_linear()
	var corregido := Color(
		objetivo.r / maxf(medio.r, 0.0004),
		objetivo.g / maxf(medio.g, 0.0004),
		objetivo.b / maxf(medio.b, 0.0004))
	var nuevo := mat.duplicate() as StandardMaterial3D
	nuevo.albedo_color = corregido
	if GOMA_EN_ESCALA_DE_GRISES and medida.has("imagen"):
		nuevo.albedo_texture = ImageTexture.create_from_image(medida["imagen"] as Image)
	mesh.mesh.surface_set_material(surface, nuevo)
	goma_corregida.append({
		"nodo": String(mesh.name),
		"superficie": surface,
		"material": String(mat.resource_name),
		"media": media,
		"albedo": corregido,
		"escala_de_grises": GOMA_EN_ESCALA_DE_GRISES and medida.has("imagen"),
		"pixeles_visibles": int(medida["pixeles_visibles"]),
		"pixeles_muestreados": int(medida["pixeles_muestreados"]),
		# Referencias para poder poner y quitar la corrección DENTRO de la misma
		# ejecución: la sonda de captura mide así el antes/después en el mismo
		# fotograma (misma pose, misma luz) en vez de comparar dos ejecuciones.
		"malla": mesh,
		"original": mat,
		"corregido": nuevo,
	})

# Pone la goma en el material del GLB (`original = true`) o en el corregido. Es de
# depuración y lo usa la sonda de captura: el juego nunca lo llama. El material se
# asigna a la superficie de la malla (no a un nodo), así que quitar la corrección
# devuelve exactamente el aspecto que traía el circuito.
func goma_modo(original: bool) -> int:
	var puestas := 0
	for entrada in goma_corregida:
		var malla: MeshInstance3D = entrada.get("malla")
		if malla == null or not is_instance_valid(malla):
			continue
		var material: StandardMaterial3D = entrada["original"] if original else entrada["corregido"]
		malla.mesh.surface_set_material(int(entrada["superficie"]), material)
		puestas += 1
	return puestas

# Media de color de una textura: la de los texeles que sobreviven al recorte de alfa
# (los que de verdad se dibujan) y, si ninguno sobrevive, la de toda la textura.
func _media_de_textura(tex: Texture2D, alpha_scissor: float, en_grises := false) -> Dictionary:
	var imagen := tex.get_image()
	if imagen == null:
		return {}
	imagen = imagen.duplicate()
	if imagen.get_format() != Image.FORMAT_RGBA8:
		imagen.convert(Image.FORMAT_RGBA8)
	# En escala de grises se conserva el alfa (el recorte del material sigue igual) y se
	# tira la crominancia: la media que se devuelve es la del gris que se va a dibujar.
	if en_grises:
		imagen.adjust_bcs(1.0, 1.0, 0.0)
	var paso_x := maxi(1, imagen.get_width() / 128)
	var paso_y := maxi(1, imagen.get_height() / 128)
	var visibles := Vector3.ZERO
	var visibles_cuentas := 0
	var todas := Vector3.ZERO
	var todas_cuentas := 0
	for y in range(0, imagen.get_height(), paso_y):
		for x in range(0, imagen.get_width(), paso_x):
			var color := imagen.get_pixel(x, y)
			todas += Vector3(color.r, color.g, color.b)
			todas_cuentas += 1
			if color.a >= alpha_scissor:
				visibles += Vector3(color.r, color.g, color.b)
				visibles_cuentas += 1
	if visibles_cuentas == 0:
		visibles = todas
		visibles_cuentas = todas_cuentas
	if visibles_cuentas == 0:
		return {}
	var salida := {
		"media": visibles / float(visibles_cuentas),
		"pixeles_visibles": visibles_cuentas,
		"pixeles_muestreados": todas_cuentas,
	}
	if en_grises:
		salida["imagen"] = imagen
	return salida

# Informe de la corrección de la goma, en una línea (va al registro del dispositivo).
func _informar_goma() -> void:
	if goma_corregida.is_empty():
		print("[track] goma de la trazada: ninguna superficie de goma encontrada")
		return
	var primera: Dictionary = goma_corregida[0]
	var media: Vector3 = primera["media"]
	var albedo: Color = primera["albedo"]
	var mayor := maxf(media.x, maxf(media.y, media.z))
	var menor := minf(media.x, minf(media.y, media.z))
	var dominante := 0.0 if mayor <= 0.0 else (mayor - menor) / mayor * 100.0
	print("[track] goma de la trazada neutralizada en %d superficies de %d mallas (escala de grises=%s): textura media=(%d,%d,%d) en sRGB, dominante_azul=%.1f%% → albedo=(%.3f, %.3f, %.3f) con gris objetivo lineal %.4f (asfalto×%.2f en luz lineal)" % [
		goma_corregida.size(),
		_mallas_con_goma(),
		bool(primera.get("escala_de_grises", false)),
		roundi(media.x * 255.0), roundi(media.y * 255.0), roundi(media.z * 255.0),
		dominante, albedo.r, albedo.g, albedo.b,
		Color(ASPHALT_ALBEDO * RUBBER_DARKEN, ASPHALT_ALBEDO * RUBBER_DARKEN, ASPHALT_ALBEDO * RUBBER_DARKEN).srgb_to_linear().r,
		srgb_to_linear_scalar(ASPHALT_ALBEDO * RUBBER_DARKEN) / srgb_to_linear_scalar(ASPHALT_ALBEDO)])

# sRGB → lineal de un escalar (el mismo cambio que hace `Color.srgb_to_linear`).
func srgb_to_linear_scalar(valor: float) -> float:
	return Color(valor, valor, valor).srgb_to_linear().r

func _mallas_con_goma() -> int:
	var nombres: Array = []
	for entrada in goma_corregida:
		if not nombres.has(entrada["nodo"]):
			nombres.append(entrada["nodo"])
	return nombres.size()

# Hunde el relieve invisible de la calzada por debajo de la superficie.
#
# Los cuerpos de estos grupos son sólo formas de colisión (no tienen malla visible)
# y su papel en AC es ser relieve del suelo, no pared: se desplazan hacia abajo
# `RELIEF_SINK_M` metros con su forma de colisión, de modo que ninguna cara pueda
# sobresalir de la calzada. Los muros, bordillos, vallas y superficies de la pista
# no se tocan, y el arranque no paga ninguna consulta de geometría.
func _hundir_relieve_de_calzada() -> void:
	var hundidas := 0
	var cuerpos := 0
	var nombres: Array = []
	for body in relief_bodies:
		var bajado := false
		for hijo in body.get_children():
			var forma := hijo as CollisionShape3D
			if forma == null:
				continue
			forma.position.y -= RELIEF_SINK_M
			hundidas += 1
			bajado = true
		if bajado:
			cuerpos += 1
			body.set_meta("ac_relief_sunk_m", RELIEF_SINK_M)
			nombres.append(String(body.get_meta("ac_relief", "")) + " en " + String(body.name))
	print("[track] relieve de calzada hundido %.2f m: %d formas en %d cuerpos %s" % [
		RELIEF_SINK_M, hundidas, cuerpos, str(nombres)])

func _build_car() -> void:
	spawn_position = TrackScript.get_spawn_position() + Vector3.UP * 0.3
	car = CharacterBody3D.new()
	car.name = "Red Bull Racing RB"
	car.set_script(CarScript)
	car.position = spawn_position
	car.rotation.y = TrackScript.get_spawn_yaw()
	car.collision_layer = 2
	car.collision_mask = 1
	car.safe_margin = 0.005
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# Central chassis collider excludes wheels/overhang: no broad box snagging kerbs.
	box.size = Vector3(1.2, 0.55, 3.4)
	collision.shape = box
	collision.position.y = 0.29
	car.add_child(collision)
	var model := CAR_MODEL.instantiate() as Node3D
	model.name = "RedBull production model"
	car.add_child(model)
	car.model_root = model
	add_child(car)
	# The glTF wrapper populates its imported mesh tree in _ready(). Configure the
	# materials only after the car has entered the scene tree, otherwise the wheel
	# overrides and 4K anisotropic filtering run against an empty imported node.
	_configure_car_texture_filtering()

func _configure_car_texture_filtering() -> void:
	# The body has 4K albedo maps. Anisotropic filtering keeps those maps crisp
	# along the long, shallow nose surfaces in the onboard view.
	# The source car GLB has a visibly faceted tire sidewall at this close camera
	# distance. Replace only the rendered wheel mesh with the project's authored
	# high-detail LOD0 wheel; retain each original wheel node/pivot and scale the
	# replacement to the exact dimensions of the source wheel.
	var wheel_template_root := HIGH_DETAIL_WHEEL.instantiate()
	var wheel_template_node := wheel_template_root.find_child("*", true, false) as MeshInstance3D
	var wheel_template: Mesh = wheel_template_node.mesh if wheel_template_node != null else null
	if wheel_template == null:
		push_error("No se pudo cargar la malla LOD0 de rueda; se conserva la geometría original.")
	for node in car.model_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var is_wheel := String(mesh.name).to_lower().contains("wheel")
		if is_wheel and wheel_template != null:
			var source_bounds := mesh.mesh.get_aabb()
			var template_bounds := wheel_template.get_aabb()
			var source_radius := maxf(source_bounds.size.y, source_bounds.size.z)
			var template_radius := maxf(template_bounds.size.y, template_bounds.size.z)
			var fit := Vector3(
				source_bounds.size.x / template_bounds.size.x,
				source_radius / template_radius,
				source_radius / template_radius
			)
			mesh.mesh = _fit_mesh_to_bounds(wheel_template, fit)
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			if material == null:
				continue
			var filtered := material.duplicate() as StandardMaterial3D
			filtered.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			if is_wheel:
				# Matte black rubber and subdued graphite wheel faces keep the tire
				# legible without the silver, plastic-like highlights of the old mesh.
				filtered.clearcoat = 0.0
				filtered.clearcoat_enabled = false
				if surface == 0: # Banda y flanco: goma negra mate.
					filtered.albedo_color = Color(0.008, 0.009, 0.011)
					filtered.metallic = 0.0
					filtered.roughness = 0.98
					filtered.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
				elif surface == 1: # Llanta grafito: se distingue de la goma sin blanquearse.
					filtered.albedo_color = Color(0.065, 0.072, 0.080)
					filtered.metallic = 0.02
					filtered.roughness = 0.92
					filtered.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			elif String(mesh.name) == "Body":
				# The supplied body is painted carbon, not bare chrome. Its metallic=1
				# import setting was suppressing the livery's diffuse color and making
				# the cockpit/nose read as a flat black blob in the onboard camera.
				filtered.metallic = 0.22
				filtered.roughness = 0.46
			mesh.set_surface_override_material(surface, filtered)
	_build_driver_helmet(car.model_root)
	wheel_template_root.free()

func _fit_mesh_to_bounds(source: Mesh, fit: Vector3) -> Mesh:
	# Scale the replacement vertices instead of the wheel node: the node's
	# transform is also the steering/spin pivot and must remain unit scale.
	var fitted := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in vertices.size():
			vertices[i] *= fit
		arrays[Mesh.ARRAY_VERTEX] = vertices
		if arrays[Mesh.ARRAY_NORMAL] != null:
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			for i in normals.size():
				normals[i] = Vector3(normals[i].x / fit.x, normals[i].y / fit.y, normals[i].z / fit.z).normalized()
			arrays[Mesh.ARRAY_NORMAL] = normals
		fitted.add_surface_from_arrays(source.surface_get_primitive_type(surface), arrays)
		var material := source.surface_get_material(surface)
		if material != null:
			fitted.surface_set_material(surface, material)
	return fitted

func _build_driver_helmet_material() -> ShaderMaterial:
	# A subdued Verstappen-style navy shell with red side marks and an orange crown.
	var shader := Shader.new()
	shader.code = """shader_type spatial;
varying vec3 helmet_local;
void vertex() {
	helmet_local = VERTEX;
}
void fragment() {
	float orange_crown = (1.0 - smoothstep(0.010, 0.020, abs(helmet_local.x))) * smoothstep(-0.02, 0.055, helmet_local.y);
	float red_side = max(1.0 - smoothstep(0.010, 0.021, abs(abs(helmet_local.x) - 0.080)), 0.0);
	vec3 helmet = mix(vec3(0.010, 0.027, 0.075), vec3(0.025, 0.095, 0.25), smoothstep(-0.10, 0.10, helmet_local.y));
	helmet = mix(helmet, vec3(0.24, 0.012, 0.022), red_side);
	ALBEDO = mix(helmet, vec3(0.52, 0.13, 0.018), orange_crown);
	METALLIC = 0.08;
	ROUGHNESS = 0.42;
	CLEARCOAT = 0.25;
	CLEARCOAT_ROUGHNESS = 0.32;
}
"""
	var result := ShaderMaterial.new()
	result.shader = shader
	return result

func _build_driver_helmet(parent: Node3D) -> void:
	# The source car contains no driver mesh. Place a small helmet in the actual
	# cockpit behind the onboard eye, so it reads as part of the car from outside
	# without becoming a screen-space orb in the driver's view.
	var helmet := MeshInstance3D.new()
	helmet.name = "Driver helmet"
	var shell := SphereMesh.new()
	shell.radial_segments = 48
	shell.rings = 32
	shell.radius = 0.105
	shell.height = 0.198
	helmet.mesh = shell
	helmet.scale = Vector3(1.0, 0.96, 0.86)
	helmet.position = Vector3(0.0, 0.92, -0.02)
	helmet.material_override = _build_driver_helmet_material()
	helmet.layers = 1
	parent.add_child(helmet)
	var visor := MeshInstance3D.new()
	visor.name = "Driver helmet visor"
	var visor_mesh := SphereMesh.new()
	visor_mesh.radial_segments = 48
	visor_mesh.rings = 24
	visor_mesh.radius = 0.092
	visor_mesh.height = 0.09
	visor.mesh = visor_mesh
	visor.scale = Vector3(0.88, 0.48, 0.25)
	visor.position = Vector3(0.0, 0.90, -0.105)
	var visor_material := StandardMaterial3D.new()
	visor_material.albedo_color = Color(0.012, 0.022, 0.034)
	visor_material.metallic = 0.12
	visor_material.roughness = 0.24
	visor_material.clearcoat_enabled = true
	visor_material.clearcoat = 0.52
	visor_material.clearcoat_roughness = 0.18
	visor.material_override = visor_material
	visor.layers = 1
	parent.add_child(visor)

# Línea dinámica de asistencia: hermano del coche, con su propio script. Se monta
# después del coche porque necesita su velocidad y su posición sobre la trazada, y
# no toca nada más: ni física, ni cámara, ni colisiones, ni ruedas, ni suspensión.
func _build_assistance_line() -> void:
	assistance_line = MeshInstance3D.new()
	assistance_line.name = "Assistance line"
	assistance_line.set_script(AssistanceLineScript)
	assistance_line.car = car
	add_child(assistance_line)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Chase camera"
	# Layer 2 carries the onboard-only halo and dashboard; the chase camera must
	# not show those camera-attached details or they float above the car.
	camera.cull_mask = 1
	camera.current = true
	# El FOV no interviene en el acercamiento: se deja fijo a propósito. Subirlo
	# con la velocidad encogería el coche (lo contrario de lo pedido) y bajarlo
	# recortaría la pista por delante; lo que hace el trabajo es la distancia.
	camera.fov = 72.0
	camera.near = 0.1
	camera.far = 2000.0
	var heading := -car.global_basis.z
	heading.y = 0.0
	heading = heading.normalized()
	_camera_dir = heading
	_camera_distance = camera_distance_stopped_m
	_camera_blend = 0.0
	_camera_pose_ready = true
	camera.position = car.global_position + Vector3.UP * camera_height_stopped_m - heading * camera_distance_stopped_m
	add_child(camera)
	camera.look_at(car.global_position + heading * camera_ahead_stopped_m + Vector3.UP * camera_aim_height_m, Vector3.UP)

func _build_nose_camera() -> void:
	nose_camera = Camera3D.new()
	nose_camera.name = "Nose camera"
	nose_camera.fov = nose_fov
	nose_camera.near = nose_near_m
	nose_camera.far = nose_far_m
	# Layer 2 is reserved for cockpit details that should only appear in this view.
	nose_camera.cull_mask = 3
	nose_camera.current = false
	add_child(nose_camera)
	_update_nose_camera()
	nose_camera.global_position = _nose_eye
	nose_camera.look_at(_nose_target, _nose_up)
	_build_onboard_cockpit()

# The production model has no visible driver controls. Add a small, camera-local
# steering rim, dash and halo so the nose view reads as the cockpit view shown in
# the reference. Keeping these on layer 2 leaves the chase view and vehicle
# collision/physics untouched.
func _build_onboard_cockpit() -> void:
	var cockpit := Node3D.new()
	cockpit.name = "Onboard cockpit details"
	nose_camera.add_child(cockpit)
	var carbon := StandardMaterial3D.new()
	carbon.albedo_color = Color(0.025, 0.035, 0.045)
	carbon.metallic = 0.22
	carbon.roughness = 0.72
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color(0.008, 0.012, 0.017)
	rubber.roughness = 0.88
	var display := StandardMaterial3D.new()
	display.albedo_color = Color(0.05, 0.38, 0.48)
	display.emission_enabled = true
	display.emission = Color(0.04, 0.48, 0.64)
	display.emission_energy_multiplier = 0.7
	display.roughness = 0.3

	var wheel := MeshInstance3D.new()
	wheel.name = "Compact steering yoke"
	var wheel_mesh := BoxMesh.new()
	wheel_mesh.size = Vector3(0.42, 0.17, 0.055)
	wheel.mesh = wheel_mesh
	wheel.position = Vector3(0.0, -0.61, -0.93)
	wheel.material_override = rubber
	wheel.layers = 2
	cockpit.add_child(wheel)
	for side in [-1.0, 1.0]:
		var grip := MeshInstance3D.new()
		grip.name = "Steering yoke grip"
		var grip_mesh := BoxMesh.new()
		grip_mesh.size = Vector3(0.095, 0.22, 0.07)
		grip.mesh = grip_mesh
		grip.position = Vector3(side * 0.245, -0.61, -0.93)
		grip.rotation.z = -side * deg_to_rad(12.0)
		grip.material_override = rubber
		grip.layers = 2
		cockpit.add_child(grip)

	var screen := MeshInstance3D.new()
	screen.name = "Digital dash display"
	var screen_mesh := BoxMesh.new()
	screen_mesh.size = Vector3(0.19, 0.065, 0.012)
	screen.mesh = screen_mesh
	screen.position = Vector3(0.0, -0.59, -0.89)
	screen.material_override = display
	screen.layers = 2
	cockpit.add_child(screen)

	var halo_bar := MeshInstance3D.new()
	halo_bar.name = "Halo front crossbar"
	var halo_bar_mesh := BoxMesh.new()
	halo_bar_mesh.size = Vector3(0.96, 0.045, 0.055)
	halo_bar.mesh = halo_bar_mesh
	halo_bar.position = Vector3(0.0, -0.24, -1.18)
	halo_bar.material_override = carbon
	halo_bar.layers = 2
	cockpit.add_child(halo_bar)
	for side in [-1.0, 1.0]:
		var halo_side := MeshInstance3D.new()
		halo_side.name = "Halo side support"
		var halo_side_mesh := BoxMesh.new()
		halo_side_mesh.size = Vector3(0.055, 0.38, 0.06)
		halo_side.mesh = halo_side_mesh
		halo_side.position = Vector3(side * 0.40, -0.41, -1.18)
		halo_side.rotation.z = -side * deg_to_rad(26.0)
		halo_side.material_override = carbon
		halo_side.layers = 2
		cockpit.add_child(halo_side)

	var pillar := MeshInstance3D.new()
	pillar.name = "Halo center pillar"
	var pillar_mesh := BoxMesh.new()
	pillar_mesh.size = Vector3(0.032, 0.24, 0.045)
	pillar.mesh = pillar_mesh
	pillar.position = Vector3(0.0, -0.30, -1.15)
	pillar.material_override = carbon
	pillar.layers = 2
	cockpit.add_child(pillar)

func _v(value: Vector3) -> String:
	return "(%.3f, %.3f, %.3f)" % [value.x, value.y, value.z]

func _build_lap_gate() -> void:
	var points := TrackScript.get_centerline()
	var tangent := (points[1] - points[0]).normalized()
	start_gate = Area3D.new()
	start_gate.name = "Finish and start line"
	start_gate.position = points[0] + Vector3.UP
	start_gate.rotation.y = atan2(-tangent.x, -tangent.z)
	start_gate.collision_layer = 0
	start_gate.collision_mask = 0
	add_child(start_gate)
	var tracker := LapTracker.new()
	tracker.name = "Lap tracker"
	add_child(tracker)
	tracker.set_course(points)
	car.lap_tracker = tracker
	car.previous_gate_local_z = start_gate.to_local(car.global_position).z

class LapTracker extends Node:
	var lap_time := 0.0
	var previous_lap := -1.0
	var best_lap := -1.0
	var laps := 0
	var valid_lap := true
	var last_progress := 0.0
	var armed := false
	var course := PackedVector3Array()
	var accumulated_distance := PackedFloat32Array()
	var total_distance := 0.0
	var next_sector := 1
	var _scan_time := 0.0

	func set_course(points: PackedVector3Array) -> void:
		course = points
		total_distance = 0.0
		accumulated_distance.resize(points.size() + 1)
		accumulated_distance[0] = 0.0
		for i in points.size():
			total_distance += points[i].distance_to(points[(i + 1) % points.size()])
			accumulated_distance[i + 1] = total_distance

	func advance(delta: float, vehicle: CharacterBody3D) -> void:
		if armed:
			lap_time += delta
		_scan_time -= delta
		if _scan_time > 0.0:
			return
		_scan_time = 0.1
		var progress := _nearest_progress(vehicle.global_position)
		if _distance_to_track(vehicle.global_position) > 14.0:
			valid_lap = false
		if armed:
			var sector := int(progress / total_distance * 8.0)
			if sector == next_sector and next_sector <= 7:
				next_sector += 1
			if progress < last_progress - 50.0 and not (last_progress > total_distance * 0.9 and progress < 50.0):
				valid_lap = false
		last_progress = progress

	func register_crossing(previous_z: float, current_z: float) -> void:
		if previous_z <= 0.0 or current_z > 0.0:
			return
		if not armed:
			armed = true
			lap_time = 0.0
			valid_lap = true
			next_sector = 1
			return
		if lap_time < 25.0 or next_sector < 8:
			return
		previous_lap = lap_time
		laps += 1
		if valid_lap and (best_lap < 0.0 or previous_lap < best_lap):
			best_lap = previous_lap
		valid_lap = true
		lap_time = 0.0
		next_sector = 1
		last_progress = 0.0

	func _nearest_progress(position: Vector3) -> float:
		var best := INF
		var result := 0.0
		for i in range(0, course.size(), 3):
			var j := (i + 3) % course.size()
			var ab := course[j] - course[i]
			var t := clampf((position - course[i]).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
			var d := position.distance_squared_to(course[i] + ab * t)
			if d < best:
				best = d
				result = accumulated_distance[i] + ab.length() * t
		return result

	func _distance_to_track(position: Vector3) -> float:
		var best := INF
		for i in range(0, course.size(), 4):
			best = minf(best, Vector2(course[i].x - position.x, course[i].z - position.z).length())
		return best
