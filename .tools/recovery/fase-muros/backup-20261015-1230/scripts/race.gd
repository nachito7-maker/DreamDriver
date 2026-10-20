extends Node3D

const CarScript = preload("res://scripts/car_controller.gd")
const HudScript = preload("res://scripts/race_hud.gd")
const TouchScript = preload("res://scripts/touch_controls.gd")
const TrackScript = preload("res://scripts/track_data.gd")
const CAR_MODEL: PackedScene = preload("res://assets/RedBull.tscn")
const TRACK_SCENE_PATH := "res://assets/BarcelonaMoto-Tutorial.glb"

var car: CharacterBody3D
var hud: CanvasLayer
var controls: CanvasLayer
var camera: Camera3D
var start_gate: Area3D
var track_mesh: Node3D
var spawn_position := Vector3.ZERO

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
#   techo de la carrocería EN LA Z DE LA CÁMARA (z = −1,33): y = +0,82 m
#
# La cámara se pone DETRÁS del eje delantero (para que los neumáticos sigan
# delante y se vean a los lados, como en la referencia) y por encima del techo de
# la carrocería en esa estación (para quedar fuera del carenado, sin atravesarlo).
# Los dos márgenes se declaran y se miden: `nose_behind_axle_m` y
# `nose_above_wheels_m` se suman a esos hitos medidos, y la composición que
# producen (morro en la franja inferior, neumáticos a los lados, pista por
# delante) está medida en `scripts/camera_nose_probe.gd`.
@export_category("Nose camera")
# Cuánto detrás del eje delantero se pone el punto de vista (0 lo pondría sobre
# el eje y los neumáticos quedarían cortados por el borde inferior).
@export var nose_behind_axle_m := 0.30
# Cuánto por encima del alto del neumático delantero. Con 0,20 la cámara queda
# 0,13 m sobre el techo de la carrocería en su vertical (medido: 0,82 m).
@export var nose_above_wheels_m := 0.26
# Inclinación hacia abajo y campo de visión propios, ajustados para que el morro
# ocupe la franja inferior y la pista se vea de cerca a lo lejos.
@export var nose_pitch_down_deg := 17.0
@export var nose_fov := 74.0
@export var nose_near_m := 0.1
@export var nose_far_m := 2000.0
# Cambio de vista: la cámara que entra arranca EXACTAMENTE donde estaba la que
# sale (por eso no hay salto), y llega a su sitio en este tiempo describiendo un
# arco por encima del coche. El arco es lo que evita que el camino entre las dos
# posiciones pase por dentro de la carrocería.
@export var nose_switch_seconds := 0.22
@export var nose_switch_arc_m := 0.55

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
	print("[track] tutorial mesh batches=", meshes.size(), " original hidden collision batches=", collision_count)

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

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Chase camera"
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
	nose_camera.current = false
	add_child(nose_camera)
	_update_nose_camera()
	nose_camera.global_position = _nose_eye
	nose_camera.look_at(_nose_target, _nose_up)

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
