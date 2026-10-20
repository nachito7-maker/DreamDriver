extends CharacterBody3D

const TrackScript = preload("res://scripts/track_data.gd")

@export_category("Vehicle baseline (approximation, not Red Bull factory data)")
@export var mass_kg := 798.0
@export var wheelbase_m := 3.72
@export var cg_height_m := 0.33
@export var engine_peak_power_w := 640000.0
@export var aero_downforce_n_at_100ms := 7100.0
@export var drag_area_m2 := 0.72
@export var front_weight_fraction := 0.46

@export_category("Longitudinal dynamics")
@export var max_engine_force_n := 13800.0
@export var max_brake_force_n := 24800.0
@export var rolling_resistance_n := 95.0
@export var max_forward_speed_ms := 97.0
@export var idle_rpm := 3800.0
@export var shift_rpm := 12300.0
@export var gears := PackedFloat32Array([0.0, 3.15, 2.35, 1.85, 1.52, 1.28, 1.10, 0.96, 0.85])

@export_category("Lateral grip and steering")
@export var front_cornering_stiffness_n_per_rad := 105000.0
@export var rear_cornering_stiffness_n_per_rad := 118000.0
@export var steering_at_low_speed_rad := 0.51
@export var steering_at_high_speed_rad := 0.11
@export var steering_response := 4.8
@export var front_grip_fraction := 0.47
@export var tire_load_sensitivity := 0.075
@export var slip_recovery_rate := 0.8

var model_root: Node3D
var lap_tracker: Node
var previous_gate_local_z := -1.0
var speed_mps := 0.0
var speed_kph := 0.0
var engine_rpm := 3800.0
var throttle_input := 0.0
var brake_input := 0.0
var steering_input := 0.0
var steering_angle := 0.0
var gear := 1
var surface_grip := 1.0
var lateral_slip := 0.0
var longitudinal_slip := 0.0
var acceleration_longitudinal := 0.0
var acceleration_lateral := 0.0
var downforce_n := 0.0
var _last_speed := 0.0
var _gear_timer := 0.0
var _surface_scan_timer := 0.0
var _time := 0.0
var _body_roll := 0.0
var _body_pitch := 0.0
var _front_wheels: Array[Node3D] = []
var _rear_wheels: Array[Node3D] = []
var _wheel_spin := 0.0
var _audio_player: AudioStreamPlayer3D
var _engine_tone: AudioStreamGeneratorPlayback
var _audio_phase := 0.0
var _wheel_rest := {}
var _body_node: Node3D
var _body_rest := Basis()
var ground_normal := Vector3.UP
var wheel_contacts := 0
var _ground_height := 0.0
var ground_surface := ""
var _surface_votes: Dictionary = {}

func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_snap_length = 0.65
	floor_stop_on_slope = false
	floor_constant_speed = true
	_find_wheels()
	_make_engine_audio()

func _physics_process(delta: float) -> void:
	_time += delta
	_gear_timer = maxf(0.0, _gear_timer - delta)
	_read_controls()
	_sample_ground()
	var forward := -global_basis.z
	var right := global_basis.x
	var forward_speed := velocity.dot(forward)
	var lateral_speed := velocity.dot(right)
	speed_mps = maxf(0.0, forward_speed)
	speed_kph = speed_mps * 3.6
	_surface_scan_timer -= delta
	if _surface_scan_timer <= 0.0:
		_surface_scan_timer = 0.08
		surface_grip = _sample_surface_grip()
	_update_gearbox(delta)
	_update_engine_and_forces(delta, forward, right, forward_speed, lateral_speed)
	move_and_slide()
	if wheel_contacts > 0:
		apply_floor_snap()
	# La muestra de suelo se toma al principio del fotograma, ANTES de moverse.
	# Usarla para colocar el modelo dejaba la carrocería un fotograma por detrás del
	# coche y, cuesta arriba o abajo, las ruedas quedaban en el aire en proporción
	# a la velocidad: 4 mm a 75 km/h y 13-15 mm a 206 km/h sobre una pendiente de
	# en torno al 1,4%. La física sigue usando la muestra previa (de ella salen la
	# normal y el agarre del fotograma); el modelo usa la del punto donde está.
	_sample_ground()
	speed_mps = maxf(0.0, velocity.dot(-global_basis.z))
	speed_kph = speed_mps * 3.6
	_update_visuals(delta)
	_update_engine_sound()

func _read_controls() -> void:
	var touch_steer: float = float(get_meta("touch_steer", 0.0)) if has_meta("touch_steer") else 0.0
	var touch_throttle: float = float(get_meta("touch_throttle", 0.0)) if has_meta("touch_throttle") else 0.0
	var touch_brake: float = float(get_meta("touch_brake", 0.0)) if has_meta("touch_brake") else 0.0
	var key_steer := Input.get_axis("steer_left", "steer_right")
	var key_throttle := Input.get_action_strength("throttle")
	var key_brake := Input.get_action_strength("brake")
	steering_input = clampf(key_steer + touch_steer, -1.0, 1.0)
	throttle_input = maxf(key_throttle, touch_throttle)
	brake_input = maxf(key_brake, touch_brake)
	# The analog brake's bottom few pixels produce tiny floating-point demands.
	# Ignore those consistently here and in the force calculation below: the
	# previous >0.0 check turned a residual 4e-8 brake request into full braking
	# and silently cancelled all engine torque while the accelerator was held.
	if brake_input <= 0.03:
		brake_input = 0.0
	if brake_input > 0.0:
		# Brake overrides throttle when two separate fingers engage pedals.
		throttle_input = 0.0

func _update_engine_and_forces(delta: float, forward: Vector3, right: Vector3, forward_speed: float, lateral_speed: float) -> void:
	var dynamic_pressure := 0.5 * 1.225 * speed_mps * speed_mps
	downforce_n = aero_downforce_n_at_100ms * pow(speed_mps / 100.0, 2.0)
	var max_grip_force := (mass_kg * 9.81 + downforce_n) * surface_grip
	var speed_ratio := clampf(speed_mps / 100.0, 0.0, 1.2)
	# Tope de dirección a esta velocidad: el menor entre el tope de la moto y el
	# ángulo que satura el agarre. El ángulo que satura cae como 1/v², así que sin
	# este segundo límite a 120 km/h el manillar tenía ocho veces más recorrido del
	# necesario: el primer cuarto del recorrido ya entregaba el máximo (1,10 g) y el
	# resto no hacía nada. Con el tope físico el agarre se alcanza en el último
	# cuarto del recorrido y el mando reparte su recorrido por todo el rango.
	var lean_steer := lerpf(steering_at_low_speed_rad, steering_at_high_speed_rad, pow(clampf(speed_ratio, 0.0, 1.0), 0.68))
	var grip_steer := atan(max_grip_force / mass_kg * wheelbase_m / maxf(speed_mps * speed_mps, 1.0))
	var max_steer := minf(lean_steer, grip_steer * 1.25)
	var target_steer := steering_input * max_steer
	steering_angle = move_toward(steering_angle, target_steer, steering_response * delta)
	var actual_throttle := throttle_input * _throttle_grip_limit()
	var power_force := engine_peak_power_w / maxf(speed_mps, 19.0)
	var engine_force := minf(max_engine_force_n, power_force) * actual_throttle
	var braking_force := max_brake_force_n * brake_input
	var drag_force := dynamic_pressure * drag_area_m2
	var rolling := rolling_resistance_n if speed_mps > 0.1 else 0.0
	var engine_braking := 210.0 * (1.0 - throttle_input) if speed_mps > 3.0 else 0.0
	var longitudinal_force := engine_force - braking_force - drag_force - rolling - engine_braking
	if speed_mps <= 0.15 and brake_input <= 0.02 and throttle_input > 0.02:
		longitudinal_force = maxf(longitudinal_force, 3200.0 * surface_grip)
	elif speed_mps <= 0.15 and longitudinal_force < 0.0:
		longitudinal_force = 0.0
	if brake_input > 0.0 and speed_mps > 0.15:
		longitudinal_force = minf(longitudinal_force, -max_brake_force_n * brake_input * 0.92)
	var longitudinal_accel := longitudinal_force / mass_kg
	longitudinal_accel = clampf(longitudinal_accel, -max_brake_force_n / mass_kg, 13.0)
	acceleration_longitudinal = (speed_mps - _last_speed) / maxf(delta, 0.0001)
	_last_speed = speed_mps
	var safe_speed := max_forward_speed_ms * _top_speed_factor()
	if speed_mps > safe_speed and longitudinal_accel > 0.0:
		longitudinal_accel = minf(longitudinal_accel, -(speed_mps - safe_speed) * 0.8)
	# Positive input is right; Godot's positive Y rotation turns local -Z left.
	var desired_yaw_rate := -speed_mps / wheelbase_m * tan(steering_angle)
	var lateral_demand := speed_mps * desired_yaw_rate
	var requested_lateral_force := mass_kg * lateral_demand
	var front_load := maxf(0.15, front_weight_fraction + maxf(0.0, -longitudinal_accel) * cg_height_m / (wheelbase_m * 9.81))
	front_load = clampf(front_load, 0.25, 0.72)
	var rear_load := 1.0 - front_load
	var front_axle_load := max_grip_force * front_load
	var rear_axle_load := max_grip_force * rear_load
	var front_normal_load_sensitivity := pow(maxf(front_axle_load / 2.0, 1.0) / 2000.0, -tire_load_sensitivity)
	var rear_normal_load_sensitivity := pow(maxf(rear_axle_load / 2.0, 1.0) / 2000.0, -tire_load_sensitivity)
	# Capacidad lateral del coche: la suma de lo que puede dar cada eje con su
	# carga. El reparto delantero/trasero (front_grip_fraction, 0.5 = el mismo
	# agarre en ambos ejes) fija el equilibrio, no el total. Con minf(front_limit,
	# rear_limit) se descartaba entero el eje trasero y el coche sólo giraba a
	# 0.26 g: a 60 km/h necesitaba 112 m de radio y a 120 km/h, 397 m.
	var front_limit := front_axle_load * front_grip_fraction * 2.0 * front_normal_load_sensitivity
	var rear_limit := rear_axle_load * (1.0 - front_grip_fraction) * 2.0 * rear_normal_load_sensitivity
	var lateral_limit := front_limit + rear_limit
	var lateral_force := clampf(requested_lateral_force, -lateral_limit, lateral_limit)
	var target_slip := (requested_lateral_force - lateral_force) / maxf(lateral_limit, 1.0)
	lateral_slip = move_toward(lateral_slip, clampf(target_slip, -1.7, 1.7), slip_recovery_rate * delta * (1.0 + speed_mps * 0.035))
	acceleration_lateral = lateral_force / mass_kg
	# El régimen de guiñada no puede pedir más aceleración lateral de la que el
	# coche está entregando de verdad. Antes se limitaba con la fuerza de agarre
	# total y encima se recortaba hasta un 32% por girar mucho el manillar, así
	# que girar más hacía girar menos: a 120 km/h el manillar a fondo daba 0.29 g
	# y a medio recorrido 0.31 g.
	# El tope es una magnitud: la fuerza lateral lleva el signo del giro pedido y
	# usarla tal cual convertía el límite en un rango invertido (mínimo positivo y
	# máximo negativo) que daba la vuelta al sentido de la dirección. Lo detecta la
	# sonda `steer_sign_probe`.
	var achieved_lateral := absf(lateral_force) / mass_kg
	var yaw_rate := desired_yaw_rate
	if speed_mps > 1.0:
		var yaw_cap := achieved_lateral / speed_mps
		yaw_rate = clampf(yaw_rate, -yaw_cap, yaw_cap)
	if wheel_contacts == 0 and is_inside_tree() and Engine.is_in_physics_frame():
		yaw_rate *= 0.15
	rotation.y += yaw_rate * delta
	# Vector-based body dynamics integrate acceleration with 120 Hz CharacterBody motion.
	forward = -global_basis.z
	right = global_basis.x
	var vertical_speed := velocity.y
	var new_speed := clampf(forward_speed + longitudinal_accel * delta, 0.0, max_forward_speed_ms)
	velocity = forward * new_speed + right * lateral_speed * exp(-delta * (5.0 + surface_grip * 4.0))
	if wheel_contacts > 0:
		velocity = velocity.slide(ground_normal)
	else:
		# Preserve accumulated vertical velocity: overwriting it each frame made
		# the old car hover/fall at 0.08 m/s and never acquire proper floor contact.
		velocity.y = vertical_speed - 9.81 * delta
	var demand_ratio := sqrt(pow(longitudinal_force / maxf(max_grip_force, 1.0), 2.0) + pow(lateral_force / maxf(max_grip_force, 1.0), 2.0))
	longitudinal_slip = clampf(demand_ratio - 0.94, 0.0, 1.0)
	# Balanceo y cabeceo de la masa suspendida, en el sentido físico: al
	# acelerar se agacha la cola (morro arriba) y al frenar se hunde el morro. El
	# signo del cabeceo estaba invertido y por eso al acelerar el morro bajaba.
	# Los topes son de 2° en ambos sentidos: más inclinación sólo se ve como una
	# carrocería que se hunde en el asfalto, porque con ruedas rígidas no hay
	# recorrido de suspensión que lo compense.
	_body_roll = move_toward(_body_roll, clampf(-acceleration_lateral * 0.008, -0.035, 0.035), delta * 0.9)
	_body_pitch = move_toward(_body_pitch, clampf(acceleration_longitudinal * 0.0035, -0.035, 0.035), delta * 1.2)

func _throttle_grip_limit() -> float:
	var speed_factor := clampf(0.62 + speed_mps / 80.0, 0.0, 1.0)
	var rear_capacity := maxf(0.15, 0.58 - absf(acceleration_lateral) / maxf(9.81 * surface_grip, 1.0) * 0.4)
	return minf(1.0, surface_grip * speed_factor * rear_capacity + 0.25)

func _top_speed_factor() -> float:
	return clampf(0.72 + aero_downforce_n_at_100ms / 40000.0, 0.85, 1.0)

func _update_gearbox(delta: float) -> void:
	var wheel_rpm := speed_mps / (2.0 * PI * 0.3783) * 60.0
	var ratio := gears[clampi(gear, 1, gears.size() - 1)]
	engine_rpm = clampf(maxf(idle_rpm, wheel_rpm * ratio * 3.75), idle_rpm, shift_rpm + 900.0)
	if _gear_timer > 0.0:
		return
	if engine_rpm > shift_rpm and gear < gears.size() - 1:
		gear += 1
		_gear_timer = 0.22
		engine_rpm *= 0.82
	elif engine_rpm < 5200.0 and gear > 1 and speed_mps > 7.0:
		gear -= 1
		_gear_timer = 0.18

func _sample_ground() -> void:
	if not is_inside_tree() or get_world_3d() == null:
		return
	wheel_contacts = 0
	_surface_votes.clear()
	var normals := Vector3.ZERO
	var heights := 0.0
	for point in [Vector3(-0.85, 0, -1.5), Vector3(0.85, 0, -1.5), Vector3(-0.85, 0, 1.95), Vector3(0.85, 0, 1.95)]:
		var world: Vector3 = global_transform * point
		var query := PhysicsRayQueryParameters3D.create(world + Vector3.UP, world - Vector3.UP * 1.2, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		wheel_contacts += 1
		normals += hit.normal
		heights += hit.position.y
		var surface := _surface_of(hit.collider as Node)
		if not surface.is_empty():
			_surface_votes[surface] = int(_surface_votes.get(surface, 0)) + 1
	if wheel_contacts > 0:
		ground_normal = normals.normalized()
		_ground_height = heights / wheel_contacts

# Superficie AC del cuerpo que se pisa. El nombre del cuerpo de física conserva
# el objeto original del circuito, y es lo que distingue hierba, grava y arena
# cuando el coche sale del asfalto.
func _surface_of(body: Node) -> String:
	if body == null:
		return ""
	return TrackScript.classify_surface(String(body.name) + " " + String(body.get_meta("ac_surface", "")))

func _sample_surface_grip() -> float:
	# El agarre sale de la superficie que hay bajo las cuatro ruedas, medida con
	# los rayos de _sample_ground. Antes se leía la última colisión del cuerpo y,
	# si el coche no figuraba apoyado (habitual fuera del asfalto, con 4 contactos
	# de rueda), se adivinaba por distancia a la trazada: sobre hierba, grava o la
	# escapatoria el coche seguía circulando con el agarre del asfalto y el HUD lo
	# anunciaba igual.
	if not is_inside_tree() or get_world_3d() == null:
		return surface_grip
	var surface := _dominant_surface()
	if not surface.is_empty():
		ground_surface = surface
		return TrackScript.get_surface_grip(surface)
	ground_surface = ""
	return _grip_from_last_contact()

func _dominant_surface() -> String:
	var best := ""
	var best_votes := 0
	for key in _surface_votes:
		var votes: int = int(_surface_votes[key])
		if votes > best_votes:
			best_votes = votes
			best = String(key)
	return best

# Reserva para las mallas de física sin grupo declarado (MARBLES, BUMP, GRILL,
# CNCPTS, TRAV): mantiene el comportamiento anterior. No se usa cuando los rayos
# sí identifican la superficie, que es el caso normal.
func _grip_from_last_contact() -> float:
	if is_on_floor() and get_slide_collision_count() > 0:
		var collision := get_last_slide_collision()
		if collision != null:
			var surface := _surface_of(collision.get_collider() as Node)
			if not surface.is_empty():
				return TrackScript.get_surface_grip(surface)
	var local_pos := global_position
	var line := TrackScript.get_centerline()
	var nearest := INF
	for idx in range(0, line.size(), 7):
		nearest = minf(nearest, Vector2(line[idx].x - local_pos.x, line[idx].z - local_pos.z).length())
	if nearest < 6.4:
		return 1.0
	if nearest < 9.0:
		return 0.87
	if nearest < 18.0:
		return 0.58
	if nearest < 28.0:
		return 0.47
	return 0.54

func _find_wheels() -> void:
	if model_root == null:
		return
	for child in model_root.find_children("*", "MeshInstance3D", true, false):
		if String(child.name).to_lower().contains("wheel"):
			_wheel_rest[child] = child.basis
			if "fl" in String(child.name).to_lower() or "fr" in String(child.name).to_lower():
				_front_wheels.append(child)
			else:
				_rear_wheels.append(child)
		else:
			# La malla que no es rueda es el chasis: la masa suspendida. El
			# balanceo y el cabeceo van en ella, no en el coche entero (ver
			# _update_visuals).
			_body_node = child
			_body_rest = child.basis

func _update_visuals(delta: float) -> void:
	if model_root != null:
		# El "arriba" del modelo tiene que coincidir con la normal del suelo que
		# mide _sample_ground. La rotación del nodo es YXZ y el morro va en -Z:
		# girar +X baja la cola y girar +Z sube el lado derecho, así que el
		# cabeceo es +atan2(n.z) y el balanceo -atan2(n.x). Los dos signos
		# estaban invertidos: el modelo se inclinaba en sentido contrario a la
		# calzada y, sobre el peralte de la recta de meta (1,48°), las ruedas
		# del lado cuesta abajo flotaban y las del otro se hundían. Medido
		# contra el plano de los cuatro contactos: de -6,9 cm a +5,9 cm.
		#
		# Sólo la CALZADA se aplica al modelo entero. El balanceo y el cabeceo de
		# suspensión van a la malla del chasis (_body_node): con las ruedas
		# rígidas al modelo, inclinar el conjunto las separaba del asfalto
		# —acelerando a 75 km/h, 3,2 cm por delante y 4,5 cm por detrás; en curva
		# a 1,2 g, hasta 8,4 cm—, que es el mismo defecto que se venía a corregir.
		# En un coche real la rueda no se inclina con la carrocería: se mueve la
		# suspensión.
		var local_normal := global_basis.inverse() * ground_normal
		var pitch := atan2(local_normal.z, local_normal.y)
		var roll := -atan2(local_normal.x, local_normal.y)
		model_root.rotation.x = lerp_angle(model_root.rotation.x, pitch, 1.0 - exp(-delta * 10.0))
		model_root.rotation.z = lerp_angle(model_root.rotation.z, roll, 1.0 - exp(-delta * 10.0))
		if _body_node != null:
			_body_node.basis = Basis(Vector3.RIGHT, _body_pitch) * Basis(Vector3.BACK, _body_roll) * _body_rest
		if wheel_contacts > 0:
			# Sin retardo: la altura del modelo es exactamente la del contacto
			# medido. El filtro de 71 ms que había antes sumaba su propio retardo al
			# de la muestra y, con las ruedas rígidas al modelo, eso se ve como aire
			# bajo el neumático.
			model_root.position.y = clampf(_ground_height - global_position.y, -0.25, 0.25)
	_wheel_spin = fposmod(_wheel_spin + speed_mps / 0.3783 * delta, TAU)
	for wheel in _front_wheels:
		wheel.basis = Basis(Vector3.UP, -steering_angle) * Basis(Vector3.RIGHT, -_wheel_spin) * _wheel_rest[wheel]
	for wheel in _rear_wheels:
		wheel.basis = Basis(Vector3.RIGHT, -_wheel_spin) * _wheel_rest[wheel]

func _make_engine_audio() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.name = "Engine note"
	_audio_player.max_distance = 85.0
	_audio_player.unit_size = 18.0
	_audio_player.volume_db = -18.0
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.12
	_audio_player.stream = generator
	add_child(_audio_player)
	_audio_player.play()
	_engine_tone = _audio_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _update_engine_sound() -> void:
	if _engine_tone == null:
		return
	var frames := _engine_tone.get_frames_available()
	var frequency := 42.0 + engine_rpm / 60.0 * 2.0
	var amplitude := 0.075 + throttle_input * 0.08
	for i in frames:
		_audio_phase = fposmod(_audio_phase + TAU * frequency / 22050.0, TAU)
		var sample := sin(_audio_phase) * amplitude * 0.7 + sin(_audio_phase * 2.0) * amplitude * 0.22
		_engine_tone.push_frame(Vector2(sample, sample))

func register_line_crossing(previous_z: float, current_z: float) -> void:
	if lap_tracker != null:
		lap_tracker.register_crossing(previous_z, current_z)

func recover_to(position: Vector3, yaw: float) -> void:
	global_position = position + Vector3.UP * 0.25
	rotation = Vector3(0.0, yaw, 0.0)
	velocity = Vector3.ZERO
	lateral_slip = 0.0
	longitudinal_slip = 0.0
	if lap_tracker != null:
		lap_tracker.valid_lap = false
