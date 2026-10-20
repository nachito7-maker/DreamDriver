extends SceneTree

# Capturas de validación visual de las ruedas, con el coche en tres situaciones
# (parado sobre el asfalto, en recta y en curva) y desde la cámara del juego más
# cinco puntos de vista. En cada situación mide, además, el residuo de cada rueda
# respecto al plano de la calzada, que es la magnitud que describe si el coche
# apoya o no.
#
# El coche conduce solo con persecución pura sobre la trazada (mismo lazo que un
# piloto: apunta 15 m más adelante y gira hacia ahí), así que las capturas son de
# un coche circulando de verdad, no empujado a mano.
#
# Uso: "$GODOT" --path . --script scripts/car_delivery_probe.gd

const OUT_DIR := "res://.tools/recovery/fase2-ruedas/capturas"
const TrackScript = preload("res://scripts/track_data.gd")

var race: Node3D
var car: CharacterBody3D
var line: PackedVector3Array
var index := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 150:
		await physics_frame
	car = race.car
	line = TrackScript.get_centerline()
	var stations := _stations()
	print("PUESTOS recta=%d curvatura=%.4f  curva=%d curvatura=%.4f  n=%d" % [
		stations["recta"], stations["recta_k"], stations["curva"], stations["curva_k"], line.size()])
	# 1. parado sobre el asfalto, en la recta de meta.
	_place(stations["recta"])
	for i in 60:
		await physics_frame
	await _capture("parado", false, "en reposo sobre la calzada")
	# 2. en recta: arranca 80 m antes y conduce hasta el punto elegido.
	_place(stations["recta"] - 80)
	for i in 30:
		await physics_frame
	# 90 fotogramas más de conducción en la recta antes de medir: con la dirección
	# centrada el balanceo es nulo y el residuo de las ruedas es el de apoyo puro.
	await _drive_until(stations["recta"], 1.0, 14.0, 90)
	await _capture("recta", true, "circulando por la recta")
	# 3. en curva: se coloca antes del vértice y se conduce hasta él.
	_place(stations["curva"] - 80)
	for i in 30:
		await physics_frame
	await _drive_until(stations["curva"], 0.55, 16.0, 45)
	await _capture("curva", true, "circulando por la curva")
	race.queue_free()
	await process_frame
	quit(0)

func _place(at: int) -> void:
	index = at
	car.recover_to(line[at], _yaw(at))
	_drive_inputs(0.0, 0.0)

# Entradas REALES del mapa de acciones: la capa de controles de toque reescribe
# las meta cada fotograma, así que la única forma de conducir desde una sonda es
# pisar los mismos ejes que pisa un dedo (`Input.get_axis`/`get_action_strength`
# en car_controller._read_controls).
func _drive_inputs(throttle: float, steer: float) -> void:
	if throttle > 0.001:
		Input.action_press("throttle", clampf(throttle, 0.0, 1.0))
	else:
		Input.action_release("throttle")
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if steer > 0.001:
		Input.action_press("steer_right", clampf(steer, 0.0, 1.0))
	elif steer < -0.001:
		Input.action_press("steer_left", clampf(-steer, 0.0, 1.0))

# Persecución pura: apunta 14 puntos por delante sobre la trazada y gira hacia
# ahí. El signo lo fija la convención ya medida en `steer_sign_probe` (mando a la
# derecha → la guiñada disminuye). Termina al llegar al índice pedido o, como
# mucho, en `max_seconds` segundos.
func _drive_until(until_index: int, throttle: float, max_seconds: float, extra_frames := 0) -> void:
	var start := index
	var frames := int(max_seconds * 60.0)
	var arrived := false
	var remaining := extra_frames
	for i in frames:
		var target: Vector3 = line[mini(line.size() - 1, index + 14)]
		var to_target: Vector3 = target - car.global_position
		var desired := atan2(-to_target.x, -to_target.z)
		var error := wrapf(desired - car.rotation.y, -PI, PI)
		_drive_inputs(throttle, clampf(-error * 1.6, -1.0, 1.0))
		index = _nearest(index)
		if not arrived and index >= until_index:
			arrived = true
		if arrived:
			if remaining <= 0:
				break
			remaining -= 1
		await physics_frame
	var travelled := line[maxi(0, index - 1)] - line[start]
	print("   [conduccion] recorrido %d -> %d indices, velocidad=%.1f km/h, avance=%.1f m, pedido=%.2f" % [
		start, index, car.speed_kph, Vector2(travelled.x, travelled.z).length(), car.throttle_input])

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

func _curvature(at: int) -> float:
	var back: Vector3 = line[(at - 25 + line.size()) % line.size()]
	var here: Vector3 = line[at]
	var ahead: Vector3 = line[(at + 25) % line.size()]
	var v1 := Vector2(here.x - back.x, here.z - back.z).normalized()
	var v2 := Vector2(ahead.x - here.x, ahead.z - here.z).normalized()
	return v1.x * v2.y - v1.y * v2.x

func _stations() -> Dictionary:
	var best_straight := 0
	var best_curve := 0
	var k_straight := INF
	var k_curve := 0.0
	# Rango alejado del cierre de la vuelta (los índices bajos y altos se tocan en
	# la línea de meta y elegir ahí un puesto complica la persecución) y buscando
	# una curva de radio medio: la más cerrada de la trazada de motos es un
	# horquilla donde este piloto automático no se sostiene.
	for at in range(200, line.size() - 200, 5):
		var k := absf(_curvature(at))
		if k < k_straight:
			k_straight = k
			best_straight = at
		if k > k_curve and k < 0.35 and _curvature(at) * _curvature(at + 100) > 0.0:
			k_curve = k
			best_curve = at
	return {"recta": best_straight, "recta_k": k_straight,
		"curva": best_curve, "curva_k": k_curve}

func _capture(tag: String, moving: bool, note: String) -> void:
	print("== %s (%s) velocidad=%.1f km/h contacto=%d suelo=%s curvas=%d" % [
		tag, note, car.speed_kph, car.wheel_contacts,
		car.ground_surface if not car.ground_surface.is_empty() else "(sin dato)", index])
	_measure(tag)
	# La vista del juego, con el controlador de cámara de race.gd en marcha.
	await _shot(tag, "camara_del_juego", Vector3.ZERO, Vector3.ZERO, true)
	# Para las vistas de medida hay que parar el controlador de cámara: race.gd
	# reescribe posición y mirada en cada fotograma, así que cualquier cámara
	# colocada a mano vuelve a la persecución en unos pocos fotogramas. La física
	# del coche sigue corriendo.
	race.set_process(false)
	# Los puntos de vista van en el sistema DEL COCHE y se recalculan en cada
	# fotograma: a 206 km/h el coche recorre casi un metro por fotograma y una
	# cámara fija deja al coche fuera del encuadre.
	var views := [
		["trasera_baja", Vector3(0.0, 0.45, 6.0), Vector3(0.0, 0.4, 0.0)],
		["trasera", Vector3(0.0, 1.2, 6.5), Vector3(0.0, 0.4, 0.0)],
		["lateral", Vector3(6.5, 1.0, 0.2), Vector3(0.0, 0.4, 0.0)],
		["tres_cuartos", Vector3(3.5, 1.7, 4.5), Vector3(0.0, 0.4, 0.0)],
		["frontal", Vector3(0.0, 1.1, -6.0), Vector3(0.0, 0.4, 0.0)],
		# Primer plano de la rueda a la altura del neumático: es la vista donde se
		# ve si la goma toca la calzada o queda aire debajo.
		["rueda_trasera", Vector3(-2.9, 0.75, 1.95), Vector3(-0.89, 0.38, 1.95)],
		["rueda_delantera", Vector3(-2.93, 0.75, -1.51), Vector3(-0.93, 0.38, -1.51)],
	]
	for view in views:
		await _shot(tag, view[0], view[1], view[2], false)
	race.set_process(true)
	for i in 3:
		await physics_frame

# local_eye/local_look son coordenadas del coche; con `game_camera` se deja la
# vista que ya tiene el juego sin tocar la cámara.
func _shot(tag: String, name: String, local_eye: Vector3, local_look: Vector3, game_camera: bool) -> void:
	for i in 3:
		if not game_camera:
			race.camera.global_position = car.global_transform * local_eye
			race.camera.look_at(car.global_transform * local_look, Vector3.UP)
		await process_frame
	var image: Image = root.get_texture().get_image()
	var path := "%s/%s-%s.png" % [OUT_DIR, tag, name]
	print("CAPTURA %s -> %s" % [name, image.save_png(path)])

func _measure(tag: String) -> void:
	var local := [Vector3(-0.85, 0, -1.5), Vector3(0.85, 0, -1.5),
		Vector3(-0.85, 0, 1.95), Vector3(0.85, 0, 1.95)]
	var points: Array[Vector3] = []
	for point in local:
		var world: Vector3 = car.global_transform * point
		var query := PhysicsRayQueryParameters3D.create(world + Vector3.UP * 1.0, world - Vector3.UP * 1.2, 1)
		var hit := root.world_3d.direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return
		points.append(hit["position"] as Vector3)
	var centre: Vector3 = (points[0] + points[1] + points[2] + points[3]) / 4.0
	var lateral: Vector3 = (points[1] + points[3]) * 0.5 - (points[0] + points[2]) * 0.5
	var forward: Vector3 = (points[0] + points[1]) * 0.5 - (points[2] + points[3]) * 0.5
	var normal: Vector3 = lateral.cross(forward).normalized()
	if normal.dot(Vector3.UP) < 0.0:
		normal = -normal
	print("   pose %.2f°  inclinación de la calzada %.2f°  escala %.3f" % [
		rad_to_deg(acos(clampf(car.model_root.global_basis.y.normalized().dot(normal), -1.0, 1.0))),
		rad_to_deg(acos(clampf(normal.y, -1.0, 1.0))),
		car.model_root.global_basis.get_scale().x])
	# Desglose del residuo: cuánto del desvío es el origen del modelo separado del
	# plano y cuánto es inclinación. El plano se evalúa en la vertical del origen
	# del modelo y en la de cada rueda, para que las dos cifras sean comparables.
	var origen: Vector3 = car.model_root.global_position
	var origen_plano: float = centre.y - ((Vector3(origen.x, centre.y, origen.z) - centre).dot(normal)) / normal.y
	print("   origen_mundo=%+.4f calzada_bajo_el_origen=%+.4f desvio_del_origen=%+.4f m  suelo_medido=%.4f carroceria_y_local=%.4f" % [
		origen.y, origen_plano, origen.y - origen_plano, car._ground_height, car.model_root.position.y])
	for child in car.model_root.find_children("*", "MeshInstance3D", true, false):
		if not String(child.name).to_lower().contains("wheel"):
			continue
		var mesh: Mesh = child.mesh
		var aabb := mesh.get_aabb()
		var size := aabb.size
		var small := 0
		for axis in range(1, 3):
			if size[axis] < size[small]:
				small = axis
		var big := 1 if small != 1 else 2
		var axle: Vector3 = (child.global_basis * [Vector3.RIGHT, Vector3.UP, Vector3.BACK][small]).normalized()
		var hub: Vector3 = child.global_transform * aabb.get_center()
		var radius: float = size[big] * 0.5
		var half_width: float = size[small] * 0.5
		var bottom: float = hub.y - (half_width * absf(axle.y)
			+ radius * sqrt(maxf(0.0, 1.0 - axle.y * axle.y)))
		var at := Vector3(hub.x, centre.y, hub.z)
		var plane_y: float = centre.y - ((at - centre).dot(normal)) / normal.y
		print("   %-10s fondo=%+.4f calzada=%+.4f residuo=%+.4f m radio=%.4f anchura=%.4f" % [
			String(child.name), bottom, plane_y, bottom - plane_y, radius, size[small]])
