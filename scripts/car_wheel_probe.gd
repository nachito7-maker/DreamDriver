extends SceneTree

# Auditoría de las ruedas del Red Bull EN EJECUCIÓN (no del asset suelto).
#
# Mide, sobre el árbol real de la escena de carrera:
#   * jerarquía y transforms (model_root, chasis, las cuatro ruedas)
#   * caja de la malla de cada rueda en su espacio local: radio, anchura y
#     DESPLAZAMIENTO DEL PIVOTE (centro de la malla respecto al origen del nodo)
#   * eje real de giro (dirección del eje de la malla llevada al mundo)
#   * fondo de cada rueda en el mundo y altura del asfalto justo debajo (rayo)
#   * residuo de cada rueda respecto al PLANO de la calzada que forman los
#     cuatro contactos que mide el propio juego
#   * radio de órbita: cuánto se mueve el centro de la rueda al aplicarle la
#     MISMA transformación que usa car_controller._update_visuals — si el centro
#     de la malla no está en el origen del nodo, la rueda orbita en vez de girar
# Después renderiza vistas (trasera, lateral, tres cuartos, frontal, cenital) y
# repite las medidas con el coche en marcha.
#
# La sonda TIENE DIENTES: termina con código distinto de cero si alguna rueda
# flota o se hunde, si el pivote no está centrado, si el eje de giro no es el
# lateral o si la rueda orbita. Los umbrales están declarados abajo y el estado
# previo a la corrección (pivote 11,7 mm, 69,9 mm de aire bajo la rueda,
# 2,0 mm de órbita) los incumple.
#
# Uso: "$GODOT" --path . --script scripts/car_wheel_probe.gd

const OUT_DIR := "res://.tools/recovery/fase2-ruedas/vistas"
const DATA_PATH := "res://.tools/recovery/fase2-ruedas/medidas.json"
const TrackScript = preload("res://scripts/track_data.gd")

# Parado: el coche debe apoyar de verdad. En marcha el modelo se inclina a
# propósito (balanceo y cabeceo de suspensión), así que la exigencia de contacto
# se relaja y sólo se mantienen las de geometría del propio modelo.
const PIVOTE_MAX := 0.0015      # desplazamiento del centro de la malla (m)
const ORBITA_MAX := 0.0010      # movimiento del centro al girar la rueda (m)
const AIRE_MAX_REPOSO := 0.012  # separación fondo/asfalto parado (m)
const AIRE_MAX_MARCHA := 0.030  # idem en marcha
const RESIDUO_MAX_REPOSO := 0.012
const RESIDUO_MAX_MARCHA := 0.030
const POSE_MAX_GRADOS := 1.0    # desvío del "arriba" del modelo respecto al suelo
const RADIO := Vector2(0.30, 0.45)
const ANCHURA := Vector2(0.25, 0.55)

var race: Node3D
var car: CharacterBody3D
var errores: Array[String] = []
var medidas: Dictionary = {}
var line: PackedVector3Array
var index := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		TrackScript.select_vehicle(String(user_args[0]))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 180:
		await physics_frame
	car = race.car
	_audit("REPOSO", true)
	await _shots("reposo")
	await _drive()
	race.queue_free()
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DATA_PATH).get_base_dir())
	FileAccess.open(DATA_PATH, FileAccess.WRITE).store_string(JSON.stringify(medidas, "  "))
	var ok: bool = errores.is_empty()
	for error in errores:
		print("  ERROR %s" % error)
	print("RUEDAS passed=%s errores=%d medidas=%s" % [str(ok), errores.size(), DATA_PATH])
	quit(0 if ok else 1)

# Conduce con las entradas REALES del mapa de acciones (la capa de controles de
# toque reescribe las meta cada fotograma, así que las meta no sirven para
# pilotar desde una sonda) y con persecución pura sobre la trazada, para que el
# coche vaya por el asfalto y a una velocidad de régimen: es la situación en la
# que se quiere medir el apoyo de las ruedas.
func _drive() -> void:
	line = TrackScript.get_centerline()
	index = _nearest(0, true)
	Input.action_press("throttle", 0.55)
	for i in 420:
		var target: Vector3 = line[mini(line.size() - 1, index + 14)]
		var to_target: Vector3 = target - car.global_position
		var desired := atan2(-to_target.x, -to_target.z)
		var error := wrapf(desired - car.rotation.y, -PI, PI)
		_press_steer(clampf(-error * 1.6, -1.0, 1.0))
		index = _nearest(index)
		await physics_frame
	_audit("MARCHA", false)
	await _shots("marcha")
	Input.action_release("throttle")
	Input.action_release("steer_right")
	Input.action_release("steer_left")
	for i in 30:
		await physics_frame

func _press_steer(steer: float) -> void:
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if steer > 0.001:
		Input.action_press("steer_right", clampf(steer, 0.0, 1.0))
	elif steer < -0.001:
		Input.action_press("steer_left", clampf(-steer, 0.0, 1.0))

func _nearest(from: int, everywhere := false) -> int:
	var best := from
	var best_distance := INF
	var offsets := range(-25, 26)
	if everywhere:
		offsets = range(-line.size() + 1, line.size())
	for offset in offsets:
		var at := wrapi(from + offset, 0, line.size())
		var distance := Vector2(line[at].x - car.global_position.x, line[at].z - car.global_position.z).length()
		if distance < best_distance:
			best_distance = distance
			best = at
	return best

func _check(ok: bool, message: String) -> void:
	if not ok:
		errores.append(message)

func _audit(tag: String, strict: bool) -> void:
	var root_node: Node3D = car.model_root
	print("=== %s car.global=%s rotation_y=%.3f speed=%.1f m/s contacts=%d suelo_medido=%.4f on_floor=%s vel=%s" % [
		tag, _v(car.global_position), car.rotation.y, car.speed_mps, car.wheel_contacts,
		car._ground_height, str(car.is_on_floor()), _v(car.velocity)])
	var recorrido := "--"
	if car.suspension != null:
		var parts: Array[String] = []
		for i in car.suspension.offset.size():
			parts.append("%.1f" % (car.suspension.offset[i] * 1000.0))
		recorrido = "[" + ", ".join(parts) + "]"
	print("    aceleracion=%.2f m/s2  cabeceo_chasis=%.3f rad  balanceo_chasis=%.3f rad  lateral=%.2f m/s2  recorrido_ruedas_mm=%s" % [
		car.acceleration_longitudinal, car.model_root.rotation.x, car.model_root.rotation.z,
		car.acceleration_lateral, recorrido])
	print("    model_root.local pos=%s rot=(%.4f,%.4f,%.4f) escala=%s global_origen=%s escala_global=%s" % [
		_v(root_node.position), root_node.rotation.x, root_node.rotation.y, root_node.rotation.z,
		_v(root_node.scale), _v(root_node.global_position), _v(root_node.global_basis.get_scale())])
	_check(root_node.global_basis.get_scale().is_equal_approx(Vector3.ONE),
		"%s: la escala global del modelo es %s" % [tag, _v(root_node.global_basis.get_scale())])
	# Prueba decisiva de la pose: el "arriba" del modelo debe coincidir con la
	# normal del suelo que el propio coche ha medido. Si no coinciden, el modelo
	# va inclinado al revés y las ruedas se hunden o flotan sobre el asfalto.
	var up: Vector3 = root_node.global_basis.y.normalized()
	var normal: Vector3 = car.ground_normal.normalized()
	var angulo := rad_to_deg(acos(clampf(up.dot(normal), -1.0, 1.0)))
	print("    pose: arriba_modelo=(%.4f,%.4f,%.4f) normal_suelo=(%.4f,%.4f,%.4f) punto=%.5f angulo=%.2f°" % [
		up.x, up.y, up.z, normal.x, normal.y, normal.z, up.dot(normal), angulo])
	if strict:
		_check(angulo <= POSE_MAX_GRADOS,
			"%s: el arriba del modelo se separa %.2f° de la normal del suelo (máx %.1f°)" % [tag, angulo, POSE_MAX_GRADOS])
	medidas[tag] = {"pose_grados": angulo, "velocidad_m_s": car.speed_mps, "contactos": car.wheel_contacts, "ruedas": {}}
	_plane_check(tag, strict)
	for child in car.get_children():
		if child is CollisionShape3D:
			var shape: CollisionShape3D = child
			var box: BoxShape3D = shape.shape
			var centre: Vector3 = shape.global_transform * Vector3.ZERO
			print("    collider centro=%s fondo=%.4f (caja %s en y=%.3f)" % [
				_v(centre), centre.y - box.size.y * 0.5, _v(box.size), shape.position.y])
	var meshes: Array[Node3D] = []
	var wheel_pivots := ["wheel_fl", "wheel_fr", "wheel_rl", "wheel_rr"]
	for child in root_node.find_children("*", "MeshInstance3D", true, false):
		# Canonical wheel pivots alone are subject to tire-radius/contact criteria;
		# cockpit steering-wheel assets must not be classified as vehicle tires.
		if wheel_pivots.has(String(child.name).to_lower()):
			meshes.append(child)
	print("    pivotes de rueda canónicos auditados=%d" % meshes.size())
	_check(meshes.size() == 4, "%s: se encontraron %d pivotes de rueda canónicos y se esperan 4" % [tag, meshes.size()])
	for child in meshes:
		if not wheel_pivots.has(String(child.name).to_lower()):
			continue
		_report_wheel(child, tag, strict)


func _report_wheel(wheel: Node3D, tag: String, strict: bool) -> void:
	var mesh: Mesh = wheel.mesh
	var aabb := mesh.get_aabb()
	var size := aabb.size
	var centre_local := aabb.get_center()
	var indices := _wheel_axes(size)
	var axle_index: int = indices[0]
	var axle_local: Vector3 = indices[2]
	var diameter: float = size[indices[1]]
	var width: float = size[axle_index]
	var axle_world: Vector3 = (wheel.global_basis * axle_local).normalized()
	var axle_car: Vector3 = (car.global_basis.inverse() * axle_world).normalized()
	var hub_world: Vector3 = wheel.global_transform * centre_local
	var ground := _ground_below(hub_world)
	var bottom := _bottom(hub_world, axle_world, diameter, width)
	var name := String(wheel.name).replace("wheel_", "")
	print("  %-10s origen_local=%s malla=%s" % [String(wheel.name), _v(wheel.position), _v(size)])
	print("      pivote: centro_malla_local=%s  desplazamiento=%.4f m" % [_v(centre_local), centre_local.length()])
	print("      eje de giro en el marco del COCHE=(%+.3f,%+.3f,%+.3f)  dominante=%s" % [
		axle_car.x, axle_car.y, axle_car.z,
		"X lateral (correcto)" if absf(axle_car.x) > 0.98 else ("Y vertical" if absf(axle_car.y) > 0.98 else ("Z longitudinal" if absf(axle_car.z) > 0.98 else "OBLICUO"))])
	print("      radio=%.4f m anchura=%.4f m centro_mundo=%s" % [diameter * 0.5, width, _v(hub_world)])
	print("      fondo_mundo=%+.4f asfalto=%+.4f aire_bajo_rueda=%+.4f rot_nodo=%s escala_nodo=%s" % [
		bottom, ground, bottom - ground, _v(wheel.rotation), _v(wheel.scale)])
	# --- criterios de la geometría del propio modelo ---------------------------
	_check(centre_local.length() <= PIVOTE_MAX,
		"%s %s: el pivote está descentrado %.4f m (máx %.4f)" % [tag, name, centre_local.length(), PIVOTE_MAX])
	_check(absf(axle_car.x) > 0.98,
		"%s %s: el eje de giro no es el lateral (%.3f,%.3f,%.3f)" % [tag, name, axle_car.x, axle_car.y, axle_car.z])
	_check(wheel.scale.is_equal_approx(Vector3.ONE), "%s %s: escala del nodo %s" % [tag, name, _v(wheel.scale)])
	var radio := diameter * 0.5
	_check(radio >= RADIO.x and radio <= RADIO.y,
		"%s %s: radio %.4f m fuera de %.2f-%.2f" % [tag, name, radio, RADIO.x, RADIO.y])
	_check(width >= ANCHURA.x and width <= ANCHURA.y,
		"%s %s: anchura %.4f m fuera de %.2f-%.2f" % [tag, name, width, ANCHURA.x, ANCHURA.y])
	var aire_max: float = AIRE_MAX_REPOSO if strict else AIRE_MAX_MARCHA
	_check(absf(bottom - ground) <= aire_max,
		"%s %s: fondo de la rueda a %+.4f m del asfalto (máx %.4f)" % [tag, name, bottom - ground, aire_max])
	var rest: Basis = wheel.basis
	var parent_g: Transform3D = wheel.get_parent().global_transform
	var orbita_max := 0.0
	for combo in [[0.0, 0.0], [0.3, 0.0], [0.0, 1.5708], [0.3, 3.0]]:
		var steer: float = combo[0]
		var spin: float = combo[1]
		var basis_new: Basis = Basis(Vector3.UP, -steer) * Basis(Vector3.RIGHT, -spin) * rest
		var hub_new: Vector3 = parent_g * (basis_new * centre_local + wheel.position)
		var axle_new: Vector3 = (parent_g.basis * basis_new * axle_local).normalized()
		var orbita: float = (hub_new - hub_world).length()
		orbita_max = maxf(orbita_max, orbita)
		print("      [direccion=%.2f giro=%.2f] centro=%s orbita=%.4f m fondo=%+.4f m eje=(%+.2f,%+.2f,%+.2f)" % [
			steer, spin, _v(hub_new), orbita, _bottom(hub_new, axle_new, diameter, width),
			axle_new.x, axle_new.y, axle_new.z])
	_check(orbita_max <= ORBITA_MAX,
		"%s %s: al girar, el centro de la rueda orbita %.4f m (máx %.4f)" % [tag, name, orbita_max, ORBITA_MAX])
	medidas[tag]["ruedas"][name] = {
		"pivote_m": centre_local.length(), "radio_m": radio, "anchura_m": width,
		"aire_bajo_rueda_m": bottom - ground, "orbita_max_m": orbita_max,
		"eje_lateral_x": axle_car.x, "escala_nodo": [wheel.scale.x, wheel.scale.y, wheel.scale.z]}

# Mide, para cada rueda, la distancia de su fondo al PLANO que forman los cuatro
# puntos de contacto medidos por el juego. Es la magnitud que ve el ojo: cuánto
# se hunde o flota cada neumático respecto al asfalto bajo el coche.
func _plane_check(tag: String, strict: bool) -> void:
	# Reuse the actual measured wheel-pivot locations in the car frame. The
	# legacy Red Bull probe points (±0.85 m, -1.5/+1.95 m) were not MP4/4 hubs.
	var local: Array[Vector3] = []
	for wheel in car._suspension_wheels:
		var model_point: Vector3 = car._model_basis_car.inverse() * (wheel.position - car._model_origin_car)
		local.append(Vector3(model_point.x * car.model_lateral_sign, 0.0, model_point.z * car.model_forward_sign))
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
	var normal: Vector3 = lateral.cross(forward)
	if normal.length() < 0.000001:
		return
	normal = normal.normalized()
	if normal.dot(Vector3.UP) < 0.0:
		normal = -normal
	print("    plano de la calzada por los 4 contactos: punto=%s normal=(%.4f,%.4f,%.4f) (inclinación %.2f°)" % [
		_v(centre), normal.x, normal.y, normal.z, rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))])
	var residuo_max: float = RESIDUO_MAX_REPOSO if strict else RESIDUO_MAX_MARCHA
	for child in car._suspension_wheels:
		var mesh: Mesh = child.mesh
		var aabb := mesh.get_aabb()
		var axes := _wheel_axes(aabb.size)
		var axle: Vector3 = (child.global_basis * axes[2]).normalized()
		var centre_world: Vector3 = child.global_transform * aabb.get_center()
		var bottom: float = _bottom(centre_world, axle, aabb.size[axes[1]], aabb.size[axes[0]])
		# Punto del plano en la vertical de la rueda: se usa su (x, z), no su altura.
		var hub := Vector3(centre_world.x, centre.y, centre_world.z)
		var plane_y: float = centre.y - ((hub - centre).dot(normal)) / normal.y
		var residuo := bottom - plane_y
		print("      %-10s fondo=%.4f  calzada_en_su_vertical=%.4f  residuo=%+.4f m" % [
			String(child.name), bottom, plane_y, residuo])
		_check(absf(residuo) <= residuo_max,
			"%s %s: residuo %+.4f m respecto al plano de la calzada (máx %.4f)" % [
				tag, String(child.name), residuo, residuo_max])
		var key := String(child.name).replace("wheel_", "")
		if not medidas[tag]["ruedas"].has(key):
			medidas[tag]["ruedas"][key] = {}
		medidas[tag]["ruedas"][key]["residuo_plano_m"] = residuo

# --- geometría de ayuda -----------------------------------------------------

# [indice del eje de giro, indice del eje del diámetro, vector unitario del giro].
# En una rueda, el eje de MENOR extensión de la caja es el eje de giro.
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

# --- vistas -----------------------------------------------------------------

func _shots(tag: String) -> void:
	var camera: Camera3D = race.camera
	var pos: Vector3 = car.global_position
	var fwd: Vector3 = -car.global_basis.z
	var right: Vector3 = car.global_basis.x
	# Primera toma SIN tocar la cámara: es la vista real del juego, comparable
	# pixel a pixel con las capturas del emulador.
	await _save(tag, "camara_del_juego")
	# Las vistas de medida necesitan que race.gd deje de reescribir la cámara en
	# cada fotograma; su controlador de persecución devolvería la cámara a su
	# sitio en unos pocos fotogramas.
	race.set_process(false)
	var rl: Vector3 = pos - fwd * 1.95 - right * 0.89
	var fl: Vector3 = pos + fwd * 1.50 - right * 0.93
	var views := [
		["trasera", pos - fwd * 7.0 + Vector3.UP * 1.3, pos + Vector3.UP * 0.4, true],
		["lateral", pos + right * 7.0 + Vector3.UP * 1.1, pos + Vector3.UP * 0.4, true],
		["tres_cuartos", pos - fwd * 5.0 + right * 4.0 + Vector3.UP * 1.9, pos + Vector3.UP * 0.4, true],
		["frontal", pos + fwd * 6.5 + Vector3.UP * 1.2, pos + Vector3.UP * 0.4, true],
		["trasera_baja", pos - fwd * 6.0 + Vector3.UP * 0.45, pos + Vector3.UP * 0.4, true],
		["rueda_trasera_izq", rl - right * 2.4 + Vector3.UP * 0.75, rl + Vector3.UP * 0.05, true],
		["rueda_delantera_izq", fl - right * 2.2 + Vector3.UP * 0.7, fl + Vector3.UP * 0.05, true],
		["planta", pos + Vector3.UP * 9.0, pos, false],
	]
	for view in views:
		camera.global_position = view[1]
		camera.look_at(view[2], fwd if not bool(view[3]) else Vector3.UP)
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

func _v(value: Vector3) -> String:
	return "(%.4f, %.4f, %.4f)" % [value.x, value.y, value.z]
