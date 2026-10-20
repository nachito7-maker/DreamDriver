extends CharacterBody3D

const TrackScript = preload("res://scripts/track_data.gd")
const SuspensionScript = preload("res://scripts/wheel_suspension.gd")

@export_category("Vehicle baseline (approximation, not Red Bull factory data)")
@export var mass_kg := 798.0
@export var wheelbase_m := 3.72
@export var cg_height_m := 0.33
@export var engine_peak_power_w := 640000.0
# Carga aerodinámica a 100 m/s (360 km/h). Es la pieza que faltaba para el subviraje a
# media y alta velocidad, y su valor sale de la exigencia, no de un número elegido a ojo:
# un monoplaza de 2023 genera del orden de 2,0-2,7 veces su peso en carga aerodinámica a
# 250 km/h, y 34.000 N a 100 m/s son 16.400 N a 250 km/h, es decir 2,09 veces el peso
# (798 kg): el extremo bajo del rango real, a propósito.
#
# ¿Por qué 34.000 y no 24.000? Porque el encargo pide cerrar las curvas CON EL 70 % del
# recorrido del mando, y ese 70 % no entrega el 70 % de la capacidad: la curva del mando
# (`touch_controls`) da 0,714 de demanda en el 70 % del recorrido, y el tope de dirección
# deja pedir un 25 % más de ángulo del que satura la goma, así que el 70 % del mando
# entrega el 0,714 × 1,25 = 89,3 % de la capacidad. Para que la capacidad exigida sea
# alcanzable con el 70 % del mando, la capacidad del coche tiene que estar un 12 % por
# encima de la exigida. Con 34.000 N la fuerza lateral disponible medida por
# `understeer_probe` queda en 1,10/1,41/1,96/2,65 g (60/120/180/240 km/h) frente a la
# tabla exigida de 1,00/1,20/1,70/2,20, es decir entre un 12 % y un 20 % por encima.
# El agarre MECÁNICO no se toca (ver `front_grip_fraction`): lo que crece es la carga que
# crece con la velocidad, que es lo que el coche necesita para cerrar las curvas sin pedir
# más ángulo de rueda.
@export var aero_downforce_n_at_100ms := 34000.0
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
# Reparto del agarre entre los ejes: 0,5 = el MISMO coeficiente en los dos. Estaba en
# 0,47, que daba al eje delantero un 0,94 del coeficiente y al trasero un 1,06 —es decir,
# un coche declarado con el reparto cargado atrás, que es la receta del subviraje—. Se
# deja neutro. Medido con `understeer_probe`, el cambio mueve menos del 1 % de la
# capacidad total (el modelo lateral es una fuerza única sobre el cuerpo, no dos fuerzas
# de eje con su momento), así que NO es la corrección: es quitar una declaración que
# sesgaba el coche hacia el subviraje.
@export var front_grip_fraction := 0.50
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
var _front_wheels: Array[Node3D] = []
var _rear_wheels: Array[Node3D] = []
var suspension                     # WheelSuspension: recorrido vertical de cada rueda
var _suspension_wheels: Array[Node3D] = []
var _suspension_rest_y: Array[float] = []
var _wheel_road := PackedFloat32Array()      # última altura de asfalto medida por rueda
var _wheel_road_seen := PackedInt32Array()
var _wheel_spin := 0.0
var _audio_player: AudioStreamPlayer3D
var _engine_tone: AudioStreamGeneratorPlayback
var _audio_phase := 0.0
var _wheel_rest := {}
var _body_node: Node3D
var _body_rest := Basis()
var _collision_shape: CollisionShape3D
# --- Telemetría de la cadena de dirección (SÓLO LECTURA) ----------------------
# La escribe `_update_engine_and_forces` cada fotograma y la leen las sondas
# (`steering_probe`, `steering_response_probe`) para poder decir EN QUÉ ESLABÓN se
# pierde el giro: demanda del mando, ángulo pedido, ángulo aplicado, tope de la
# moto, tope del agarre, tope del régimen de guiñada y adherencia disponible. El
# juego no las usa para nada: no intervienen en la física.
var debug_lean_steer := 0.0        # tope por recorrido del manillar (rad)
var debug_grip_steer := 0.0        # ángulo que satura la adherencia a esta velocidad (rad)
var debug_max_steer := 0.0         # tope efectivo = min(lean_steer, grip_steer × margen) (rad)
var debug_target_steer := 0.0      # ángulo pedido por el mando (rad)
var debug_yaw_cap := 0.0           # régimen de guiñada que aguanta la adherencia (rad/s)
var debug_lateral_limit_g := 0.0   # adherencia lateral disponible en g
var debug_front_limit_g := 0.0     # capacidad lateral del eje DELANTERO con su carga (g)
var debug_rear_limit_g := 0.0      # capacidad lateral del eje TRASERO con su carga (g)
var debug_front_load_fraction := 0.0   # fracción de carga que lleva el eje delantero

# Telemetría de la CADENA DE DIRECCIÓN para la validación EN EL DISPOSITIVO: deja en el
# registro del aparato una línea `[mando]` cada medio segundo con la demanda del mando, el
# ángulo aplicado a las ruedas, el tope de esa velocidad, el régimen de guiñada y la
# aceleración lateral. La lee `.tools/recovery/screen_check.py mando`, que conduce con
# dedos reales por el inyector multitáctil y comprueba que el mando gira las ruedas y que
# el coche responde. Sólo se imprime en compilación de DEPURACIÓN (el APK de pruebas): en
# una de release no dice nada.
var _telemetry_age := 0.0
# Instrumentación TEMPORAL de la curva rápida (se retira al terminar el diagnóstico).
var _curva_log := 0
var _telemetry_yaw := 0.0
var _telemetry_yaw_rate := 0.0

# Telemetría de la CADENA LONGITUDINAL (SÓLO LECTURA): cada término que entra en el
# balance de fuerzas y el resultado que el modelo manda a la velocidad. La escribe
# `_update_engine_and_forces` y la lee `ride_probe` para poder decir EN QUÉ ESLABÓN se
# pierde la aceleración: demanda del pedal, límite de agarre del pedal, par del motor,
# resistencia, tope de punta o pérdida NO modelada entre la aceleración que el modelo pide
# y la que el coche gana de verdad. El juego no las usa para nada.
var debug_actual_throttle := 0.0      # demanda del pedal ya recortada por el límite de agarre
var debug_engine_force_n := 0.0       # par convertido en fuerza en la rueda
var debug_brake_force_n := 0.0
var debug_drag_force_n := 0.0         # resistencia aerodinámica
var debug_roll_force_n := 0.0         # rodadura + freno de motor
var debug_longitudinal_force_n := 0.0 # suma del balance
var debug_longitudinal_accel := 0.0   # aceleración que el modelo pide (m/s²)
var debug_safe_speed_ms := 0.0        # tope de punta declarado a esta velocidad
var debug_top_speed_limited := false  # si ese tope está recortando la aceleración
var debug_ground_tilt_deg := 0.0      # inclinación de la calzada pisada (grados)
var debug_ground_speed_mps := 0.0     # velocidad medida SOBRE el plano de la calzada

# --- altura de apoyo del cuerpo (ver `_apoyar_sobre_la_calzada`) ----------------
# Altura a la que el cuerpo va sobre el plano medido del asfalto. Es lo que deja el
# desplazamiento del modelo (la calzada respecto al cuerpo) en un valor pequeño y
# constante, en vez de pegado al tope que lo recorta. El fondo de la caja de colisión está
# 15 mm por encima del origen del cuerpo, así que con 20 mm la caja queda rasando el
# asfalto: ni atraviesa ni flota.
@export var ride_height_m := 0.01
# Constante de tiempo del cierre de altura y topes de la corrección (m/s).
@export var ride_tau_s := 0.12
@export var ride_correction_max_m_s := 4.0
# Banda de altura en la que el servo NO manda: dentro de ella el cuerpo se queda donde el
# asfalto lo deja (cabeceo, badenes, bordillos) y no se le añade ninguna velocidad
# vertical. 20 mm son menos que el recorrido de la suspensión y más que el ruido de la
# medida del plano (unos 5 mm), así que en régimen estable el servo no manda nada —y por
# tanto no inventa velocidad— y en cuanto el cuerpo se aleja de su sitio (una vuelta a
# pista lo deja 0,45 m arriba) recupera el error a velocidad de suspensión.
@export var ride_deadband_m := 0.02
# Tope de la referencia (lo que la calzada sube bajo el coche): una rampa del 10 % a
# 90 m/s sube 9 m/s, y por encima de eso la referencia no puede crecer sin mentir.
@export var ride_climb_max_m_s := 12.0
var _ride_reference := 0.0
var _ride_ready := false

var ground_normal := Vector3.UP
var wheel_contacts := 0
var _ground_height := 0.0
var ground_surface := ""
var _surface_votes: Dictionary = {}

func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	# SIN ASENTAMIENTO AUTOMÁTICO (floor_snap_length = 0). El asentamiento pegaba el
	# cuerpo al asfalto por su caja de colisión: cada fotograma bajaba el cuerpo hasta que
	# el fondo de la caja rasaba la calzada y, en cuanto la rasante o la comba del perfil
	# cambiaban, el motor de colisiones devolvía el cuerpo hacia arriba mientras el
	# servosistema de altura lo volvía a bajar. Esa pelea se pagaba en velocidad —medido
	# con `ride_probe`, entre 280 y 310 km/h el coche ganaba 4 m/s² menos de los que
	# declaraba su balance y la velocidad se quedaba clavada cerca de 300 km/h con el pedal
	# a fondo, que es el segundo defecto del encargo— y dejaba la altura del cuerpo en
	# manos del motor de colisiones en vez de en las de la suspensión. La altura la lleva
	# ahora `_apoyar_sobre_la_calzada`, un servosistema con referencia de velocidad: es lo
	# que hace un cuerpo suspendido sobre cuatro ruedas.
	floor_snap_length = 0.0
	floor_stop_on_slope = false
	floor_constant_speed = true
	_telemetry_yaw = rotation.y
	_find_wheels()
	_make_engine_audio()

# Plano sobre el que rueda el coche: la normal medida por los rayos cuando hay suelo.
# Sin suelo no hay plano de apoyo y la base vuelve a ser horizontal (en el aire el coche
# vuela, y ahí la gravedad entera sí se aplica).
func _plano_de_apoyo() -> Vector3:
	if wheel_contacts > 0 and ground_normal.y > 0.2:
		return ground_normal
	return Vector3.UP

# Base de la carrocería PROYECTADA sobre el plano de la calzada: `adelante` en el sentido
# de la marcha y `derecha` su perpendicular DENTRO del plano. Es la base en la que se mide
# la velocidad del coche, y con ella subir una pendiente deja de costar un cos por
# fotograma (ver el comentario de `_update_engine_and_forces`).
func _base_de_apoyo(plano: Vector3) -> Array:
	var adelante := (-global_basis.z).slide(plano)
	if adelante.length_squared() < 0.5:
		adelante = -global_basis.z
	adelante = adelante.normalized()
	var derecha := global_basis.x.slide(plano)
	derecha = derecha - adelante * derecha.dot(adelante)
	if derecha.length_squared() < 0.05:
		derecha = global_basis.x
	else:
		derecha = derecha.normalized()
	if derecha.dot(global_basis.x) < 0.0:
		derecha = -derecha
	return [adelante, derecha]

func _physics_process(delta: float) -> void:
	_time += delta
	_gear_timer = maxf(0.0, _gear_timer - delta)
	_read_controls()
	_sample_ground()
	debug_ground_tilt_deg = rad_to_deg(acos(clampf(ground_normal.y, -1.0, 1.0)))
	var plano := _plano_de_apoyo()
	var base := _base_de_apoyo(plano)
	var forward: Vector3 = base[0]
	var right: Vector3 = base[1]
	var forward_speed := velocity.dot(forward)
	var lateral_speed := velocity.dot(right)
	speed_mps = maxf(0.0, forward_speed)
	debug_ground_speed_mps = speed_mps
	speed_kph = speed_mps * 3.6
	_surface_scan_timer -= delta
	if _surface_scan_timer <= 0.0:
		_surface_scan_timer = 0.08
		surface_grip = _sample_surface_grip()
	_update_gearbox(delta)
	_update_engine_and_forces(delta, forward, right, forward_speed, lateral_speed)
	_apoyar_sobre_la_calzada(delta)
	move_and_slide()
	# La muestra de suelo que coloca el modelo se toma al principio del fotograma,
	# ANTES de moverse: usarla para colocar el modelo dejaba la carrocería un
	# fotograma por detrás del coche y, cuesta arriba o abajo, las ruedas quedaban
	# en el aire en proporción a la velocidad (4 mm a 75 km/h y 13-15 mm a 206 km/h
	# sobre una pendiente en torno al 1,4%). Aquí abajo se vuelve a medir el suelo,
	# ahora con un rayo por RUEDA, y es esa medida la que resuelve la suspensión.
	_sample_wheel_contacts(delta)
	# La velocidad se vuelve a medir con el plano que acaba de dar la suspensión, no con el
	# horizontal: es la misma magnitud que la del principio del fotograma y la que ve el HUD.
	var base_final := _base_de_apoyo(_plano_de_apoyo())
	speed_mps = maxf(0.0, velocity.dot(base_final[0]))
	speed_kph = speed_mps * 3.6
	debug_ground_speed_mps = speed_mps
	_registro_curva(delta)
	_update_visuals(delta)
	_update_engine_sound()
	_report_steering_telemetry(delta)

# Régimen de guiñada y una línea de registro cada medio segundo (sólo depuración).
func _report_steering_telemetry(delta: float) -> void:
	_telemetry_yaw_rate = wrapf(rotation.y - _telemetry_yaw, -PI, PI) / maxf(delta, 0.0001)
	_telemetry_yaw = rotation.y
	if not OS.is_debug_build():
		return
	_telemetry_age -= delta
	if _telemetry_age > 0.0:
		return
	_telemetry_age = 0.5
	if absf(steering_input) < 0.02 and speed_mps < 2.0:
		return
	print("[mando] kmh=%.1f mando=%+.3f demanda=%+.3f aplicado=%+.2f tope=%.2f guinada=%+.3f lateral=%+.2f ruedas=%d" % [
		speed_kph, float(get_meta("touch_steer", 0.0)), steering_input, rad_to_deg(steering_angle),
		rad_to_deg(debug_max_steer), _telemetry_yaw_rate, speed_mps * _telemetry_yaw_rate / 9.81,
		wheel_contacts])

# Registro FOTOGRAMA A FOTOGRAMA de la curva rápida (instrumentación temporal).
func _registro_curva(delta: float) -> void:
	if not OS.is_debug_build() or _curva_log >= 3000:
		return
	if speed_mps < 45.0 or absf(acceleration_lateral) < 12.0:
		return
	_curva_log += 1
	print("[curva] #%d t=%.2f kmh=%.1f vy=%.2f deriva=%.2f ruedas=%d/%d piso=%s n=%s altura=%.4f calzada=%.4f comp=%.0f cargadas=%d choques=%d a=%s r=%s" % [
		_curva_log, _time, speed_kph, velocity.y, velocity.dot(global_basis.x), wheel_contacts,
		suspension.contacts, is_on_floor(), str(ground_normal.snapped(Vector3(0.001, 0.001, 0.001))),
		suspension.height, suspension.road_height, (suspension.height - suspension.road_height) * 1000.0,
		suspension.loaded_contacts, get_slide_collision_count(), str(_wheel_road),
		str(suspension.offset)])

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

# Altura de apoyo del cuerpo sobre la calzada medida.
#
# POR QUÉ HACE FALTA
# -----------------
# Hasta aquí la velocidad del cuerpo se componía SIEMPRE en horizontal y la componente
# vertical sólo aparecía como efecto del deslizamiento sobre el plano del suelo. Eso deja
# la altura del cuerpo LIBRE: la que tuviera al empezar. Como los rayos de las ruedas ven
# asfalto desde 0,9 m de altura, el coche nunca llegaba a caer y se quedaba donde lo
# dejara la última colocación (medido con la sonda `ride_probe`, tras una vuelta a pista:
# 833 mm por encima del asfalto, con el modelo recortado por el tope de ±250 mm en el
# 100 % de los fotogramas y saltos de 500 mm al cruzar ese tope).
#
# El cuerpo es una masa colgada de las cuatro ruedas: su altura respecto al asfalto no es
# libre. Aquí se sigue el plano medido con una REFERENCIA de velocidad —lo que sube la
# calzada, para no quedarse atrás en una rampa— y un término proporcional que cierra el
# error de altura. Es un servosistema de primer orden, no un teletransporte: la corrección
# va acotada, así que recuperar 0,45 m de vuelta a pista se hace a velocidad de suspensión.
func _apoyar_sobre_la_calzada(delta: float) -> void:
	if wheel_contacts > 0 and suspension != null:
		var apoyo: float = suspension.height + ride_height_m
		var subida := 0.0
		if _ride_ready:
			subida = clampf((apoyo - _ride_reference) / maxf(delta, 0.0001), -ride_climb_max_m_s, ride_climb_max_m_s)
		_ride_reference = apoyo
		_ride_ready = true
		# BANDA MUERTA. Dentro de ella la altura la lleva el asfalto: los rayos de las
		# ruedas y el asentamiento del cuerpo sobre él (el fondo de la caja rasa la
		# calzada). El servo sólo manda velocidad vertical cuando el cuerpo está LEJOS de
		# donde le toca —la vuelta a pista, que lo deja 0,45 m por encima, o una caída—,
		# y entonces también manda: recupera el metro que falte a velocidad de
		# suspensión y sin teletransportar nada. Fuera quedaría un error permanente que el
		# propio asentamiento no deja cerrar (el cuerpo está apoyado donde está), y ese
		# error se convierte en una velocidad vertical que el coche no tiene: medido con
		# `ride_probe` en el banco de pendientes, 0,28 m/s de subida de más que el suelo se
		# comía como 1,7 m/s² de aceleración gratis al proyectar la velocidad sobre la
		# rasante (3,4× g·sen θ a 3°, justo el residuo que quedaba sin explicar).
		var error := apoyo - global_position.y
		if absf(error) <= ride_deadband_m:
			velocity.y = subida
		else:
			var exceso := absf(error) - ride_deadband_m
			var correccion := minf(exceso / maxf(ride_tau_s, 0.0001), ride_correction_max_m_s)
			velocity.y = subida + signf(error) * correccion
	else:
		_ride_ready = false

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
	debug_lean_steer = lean_steer
	debug_grip_steer = grip_steer
	debug_max_steer = max_steer
	debug_target_steer = target_steer
	steering_angle = move_toward(steering_angle, target_steer, steering_response * delta)
	var actual_throttle := throttle_input * _throttle_grip_limit()
	var power_force := engine_peak_power_w / maxf(speed_mps, 19.0)
	var engine_force := minf(max_engine_force_n, power_force) * actual_throttle
	var braking_force := max_brake_force_n * brake_input
	var drag_force := dynamic_pressure * drag_area_m2
	var rolling := rolling_resistance_n if speed_mps > 0.1 else 0.0
	var engine_braking := 210.0 * (1.0 - throttle_input) if speed_mps > 3.0 else 0.0
	# Lo que cuesta subir cuesta: la componente del peso en la rasante. El sentido de la
	# marcha (`forward`) viene proyectado sobre el plano de la calzada, así que su altura
	# sobre el horizonte es el seno de la pendiente en ese sentido y el signo sale solo. Es
	# la única fuerza que debe cobrar una pendiente; sin ella el coche subía las cuestas
	# gratis (y bajaba las bajadas gratis), y con el deslizamiento mal medido además las
	# subía pagando hasta treinta veces lo que cuesta (medido con `ride_probe`: 14,1 veces
	# g·sen θ a 1°, 25,7 a 2° y 33,5 a 3°).
	var grade_force := -mass_kg * 9.81 * forward.y
	var longitudinal_force := engine_force - braking_force - drag_force - rolling - engine_braking + grade_force
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
	debug_actual_throttle = actual_throttle
	debug_engine_force_n = engine_force
	debug_brake_force_n = braking_force
	debug_drag_force_n = drag_force
	debug_roll_force_n = rolling + engine_braking
	debug_longitudinal_force_n = longitudinal_force
	var safe_speed := max_forward_speed_ms * _top_speed_factor()
	debug_safe_speed_ms = safe_speed
	debug_top_speed_limited = false
	if speed_mps > safe_speed and longitudinal_accel > 0.0:
		longitudinal_accel = minf(longitudinal_accel, -(speed_mps - safe_speed) * 0.8)
		debug_top_speed_limited = true
	debug_longitudinal_accel = longitudinal_accel
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
	debug_front_limit_g = front_limit / mass_kg / 9.81
	debug_rear_limit_g = rear_limit / mass_kg / 9.81
	debug_front_load_fraction = front_load
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
	debug_lateral_limit_g = lateral_limit / mass_kg / 9.81
	debug_yaw_cap = 0.0
	if speed_mps > 1.0:
		var yaw_cap := achieved_lateral / speed_mps
		debug_yaw_cap = yaw_cap
		yaw_rate = clampf(yaw_rate, -yaw_cap, yaw_cap)
	if wheel_contacts == 0 and is_inside_tree() and Engine.is_in_physics_frame():
		yaw_rate *= 0.15
	rotation.y += yaw_rate * delta
	# Vector-based body dynamics integrate acceleration with 120 Hz CharacterBody motion.
	#
	# La composición va SOBRE LA BASE DEL PLANO DE LA CALZADA (`forward` y `right` llegan
	# ya proyectados en él). Antes se componía en horizontal y después se deslizaba el
	# resultado sobre el plano del suelo (`velocity.slide(ground_normal)`), que es una
	# operación distinta de componer en el plano y que se cobraba velocidad en cada
	# fotograma: proyectar una velocidad horizontal sobre un plano inclinado θ deja su
	# componente horizontal multiplicada por cos²θ, y la componente que desaparece en cada
	# fotograma es v·sen²θ. A 120 Hz eso son 6,8 m/s² a 300 km/h sobre una rasante del
	# 1,5 % —treinta veces lo que cuesta subir esa misma rasante—, y la medición con
	# `ride_probe` lo confirmaba: el modelo pedía +4,04 m/s² y el coche ganaba −1,17, así
	# que la velocidad se quedaba clavada en 299-313 km/h con el pedal a fondo, que es
	# exactamente lo que se ve en los vídeos del encargo. Componiendo en la base del plano
	# la pérdida no existe, y la pendiente la cobra `grade_force`, una sola vez y con el
	# signo que le toca.
	var vertical_speed := velocity.y
	var new_speed := clampf(forward_speed + longitudinal_accel * delta, 0.0, max_forward_speed_ms)
	velocity = forward * new_speed + right * lateral_speed * exp(-delta * (5.0 + surface_grip * 4.0))
	if wheel_contacts > 0:
		velocity.y = vertical_speed
	else:
		# Preserve accumulated vertical velocity: overwriting it each frame made
		# the old car hover/fall at 0.08 m/s and never acquire proper floor contact.
		velocity.y = vertical_speed - 9.81 * delta
	var demand_ratio := sqrt(pow(longitudinal_force / maxf(max_grip_force, 1.0), 2.0) + pow(lateral_force / maxf(max_grip_force, 1.0), 2.0))
	longitudinal_slip = clampf(demand_ratio - 0.94, 0.0, 1.0)
	# El cabeceo y el balanceo de la masa suspendida ya no se imponen aquí: salen
	# del equilibrio de los cuatro muelles en _sample_wheel_contacts, con el signo
	# físico (al acelerar se agacha la cola, al frenar se hunde el morro, y en curva
	# se hunden las ruedas exteriores). Con ruedas rígidas había que inventarlos y
	# topaban en 2°; ahora valen lo que valen las cargas.

func _throttle_grip_limit() -> float:
	var speed_factor := clampf(0.62 + speed_mps / 80.0, 0.0, 1.0)
	# Círculo de adherencia: al acelerador le queda lo que la curva no está gastando. El
	# reparto se mide contra la capacidad lateral REAL del coche a esa velocidad (que crece
	# con la carga aerodinámica) y no contra una recta fija en g: antes el pedal se quedaba
	# en el 41 % en una curva de 1,04 g teniendo el coche 1,36 g de capacidad, y el coche no
	# salía de las curvas. En recta el número no cambia (0,58 + 0,25), así que la
	# aceleración y la punta siguen igual; lo que cambia es que el pedal vuelve a estar
	# disponible cuando el coche tiene agarre de sobra.
	var lateral_use := clampf(absf(acceleration_lateral) / maxf(debug_lateral_limit_g * 9.81, 1.0), 0.0, 1.0)
	var remaining := sqrt(maxf(0.0, 1.0 - lateral_use * lateral_use))
	var rear_capacity := maxf(0.15, 0.58 * remaining)
	return minf(1.0, surface_grip * speed_factor * rear_capacity + 0.25)

# Factor de velocidad punta declarado. Antes salía del término aerodinámico
# (`0,72 + downforce/40000`), de modo que subir la carga aerodinámica habría subido
# también el tope de velocidad —un efecto que no se pide—. El valor es el que tenía con
# la carga anterior: 0,8975 × 97,0 m/s = 313 km/h, que es la punta medida en el aparato
# (309-314 km/h en las pruebas de mando).
@export var top_speed_factor := 0.8975

func _top_speed_factor() -> float:
	return top_speed_factor

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
	# La caja de colisión del chasis es hija directa del cuerpo (la monta `race.gd`). Se
	# guarda para poder ponerla paralela al asfalto: ver `_update_visuals`.
	for child in get_children():
		if child is CollisionShape3D:
			_collision_shape = child
			break
	if model_root == null:
		return
	var wheels: Array[Node3D] = []
	var front_flags: Array[int] = []
	for child in model_root.find_children("*", "MeshInstance3D", true, false):
		if String(child.name).to_lower().contains("wheel"):
			_wheel_rest[child] = child.basis
			var front := "fl" in String(child.name).to_lower() or "fr" in String(child.name).to_lower()
			if front:
				_front_wheels.append(child)
			else:
				_rear_wheels.append(child)
			wheels.append(child)
			front_flags.append(1 if front else 0)
		else:
			# La malla que no es rueda es el chasis. Desde la fase 3 no recibe
			# ninguna inclinación prefijada: el cabeceo y el balanceo del coche
			# salen del equilibrio de las cuatro suspensiones.
			_body_node = child
			_body_rest = child.basis
	_configure_suspension(wheels, front_flags)

# La suspensión trabaja en el sistema del MODELO: el punto de contacto de cada rueda
# es el (x, z) de su nodo y su altura de reposo la y (el fondo del neumático está en
# y = 0, tal y como lo dejó la fase 2). Se conserva el mismo orden de ruedas en el
# array para que `suspension.offset[i]` corresponda siempre a la misma.
func _configure_suspension(wheels: Array[Node3D], front_flags: Array[int]) -> void:
	if wheels.is_empty():
		return
	suspension = SuspensionScript.new()
	var corners := PackedVector3Array()
	var flags := PackedInt32Array()
	_suspension_wheels = wheels
	_suspension_rest_y = []
	_wheel_road.resize(wheels.size())
	_wheel_road_seen.resize(wheels.size())
	for i in wheels.size():
		_wheel_road[i] = 0.0
		_wheel_road_seen[i] = 0
	var front_z := 0.0
	var rear_z := 0.0
	var front_x := 0.0
	var rear_x := 0.0
	var front_count := 0
	var rear_count := 0
	for i in wheels.size():
		var wheel := wheels[i]
		corners.append(Vector3(wheel.position.x, 0.0, wheel.position.z))
		flags.append(front_flags[i])
		_suspension_rest_y.append(wheel.position.y)
		if front_flags[i] == 1:
			front_z += wheel.position.z
			front_x += absf(wheel.position.x)
			front_count += 1
		else:
			rear_z += wheel.position.z
			rear_x += absf(wheel.position.x)
			rear_count += 1
	suspension.configure(corners, flags)
	suspension.mass_kg = mass_kg
	suspension.front_weight_fraction = front_weight_fraction
	suspension.cg_height_m = cg_height_m
	# Batalla y vías MEDIDAS en el modelo (no los valores nominales del export): son
	# las que reparten la carga entre las ruedas.
	if front_count > 0 and rear_count > 0:
		suspension.wheelbase_m = absf(rear_z / rear_count - front_z / front_count)
		suspension.track_front_m = front_x / front_count * 2.0
		suspension.track_rear_m = rear_x / rear_count * 2.0

# Un rayo por rueda, desde 0,8 m por encima de su punto de contacto hasta 0,9 m por
# debajo. Es la medida que resuelve la suspensión (altura del asfalto bajo cada
# rueda) y la que sigue alimentando la normal del suelo, la superficie pisada y el
# recuento de contactos que usa la conducción.
func _sample_wheel_contacts(delta: float) -> void:
	if suspension == null or not is_inside_tree() or get_world_3d() == null:
		return
	wheel_contacts = 0
	_surface_votes.clear()
	var normals := Vector3.ZERO
	var count := _suspension_wheels.size()
	var heights := PackedFloat32Array()
	var grounded := PackedInt32Array()
	heights.resize(count)
	grounded.resize(count)
	var height_sum := 0.0
	for i in count:
		var local := _suspension_wheels[i].position
		var world: Vector3 = global_transform * Vector3(local.x, 0.0, local.z)
		var query := PhysicsRayQueryParameters3D.create(world + Vector3.UP * 0.8, world - Vector3.UP * 0.9, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		heights[i] = 0.0
		grounded[i] = 0
		if hit.is_empty():
			continue
		# Filtro de cordura: el asfalto bajo una rueda no está por encima del coche ni
		# a más de un metro por debajo, y no puede subir ni bajar 40 cm de un fotograma
		# a otro. Cualquiera de las dos cosas significa que el rayo ha dado en otra
		# cosa (una valla, el borde de un muro o el fondo del mundo) y esa altura no se
		# le entrega a la suspensión: la rueda queda sin suelo, que es lo correcto.
		var measured: float = hit.position.y
		if measured > global_position.y + 0.5 or measured < global_position.y - 1.0:
			continue
		if _wheel_road_seen[i] and absf(measured - _wheel_road[i]) > 0.4:
			continue
		_wheel_road[i] = measured
		_wheel_road_seen[i] = true
		wheel_contacts += 1
		normals += hit.normal
		heights[i] = measured
		height_sum += measured
		grounded[i] = 1
		var surface := _surface_of(hit.collider as Node)
		if not surface.is_empty():
			_surface_votes[surface] = int(_surface_votes.get(surface, 0)) + 1
	if wheel_contacts > 0:
		ground_normal = normals.normalized()
		_ground_height = height_sum / wheel_contacts
	# La transferencia de carga longitudinal que resuelve el plano del chasis se calcula
	# con la aceleración DECLARADA por el balance de fuerzas, no con la medida fotograma a
	# fotograma. La medida `(v − v_prev)/dt` lleva el golpe de cada irregularidad: al pasar
	# sobre un resalto de 30 mm a 29 km/h, un fotograma da −100 m/s², la transferencia
	# descarga entero el eje delantero (las dos ruedas se quedan sin carga), y con dos
	# ruedas cargadas el plano del chasis queda indeterminado: es el origen medido de la
	# rueda que atravesaba el asfalto 141 mm en `suspension_probe`. La carga de cada rueda
	# la mueve la FUERZA longitudinal en la huella, que es la declarada y ya viene acotada.
	suspension.step(delta, heights, grounded, debug_longitudinal_accel, acceleration_lateral)

func _update_visuals(delta: float) -> void:
	# La actitud del modelo SALE de la suspensión: es el plano de equilibrio del
	# chasis sobre los cuatro muelles. La rotación del nodo es YXZ y el morro va en
	# -Z: girar +X baja la cola y girar +Z sube el lado derecho, así que el cabeceo
	# es +atan2(n.z) y el balanceo -atan2(n.x) —los signos que se corrigieron en la
	# fase 2 y que aquí salen de las cargas: al acelerar se agacha la cola, al
	# frenar se hunde el morro y en curva se hunden las ruedas exteriores.
	#
	# La altura es la del plano de apoyo, no la media de los cuatro contactos, y ya
	# no hay ningún vuelco prefijado en la malla del chasis: lo que inclina al coche
	# es el recorrido distinto de cada rueda. Es lo que hace un coche real.
	if model_root != null and suspension != null:
		model_root.rotation.x = suspension.pitch
		model_root.rotation.z = suspension.roll
		# Desplazamiento del modelo respecto al cuerpo: la calzada medida menos la altura
		# del propio cuerpo. Con el servosistema de altura de `_apoyar_sobre_la_calzada`
		# esta diferencia vale la altura de apoyo (unos −20 mm) y es CONSTANTE, así que el
		# tope de abajo no llega a hacer nada. Estaba en ±250 mm y en la práctica se
		# alcanzaba siempre: medido con `ride_probe` en la versión entregada, el modelo
		# estaba recortado por ese tope en el 100 % de los fotogramas, y cada vez que la
		# calzada medida cruzaba el tope el modelo daba un salto de medio metro —el salto
		# que se ve en los vídeos—. Se ensancha a ±0,6 m como red de seguridad para el caso
		# en que la medida del asfalto se pierda del todo (dejada atrás por un teletransporte
		# o por una caída fuera del mundo), y se deja escrito para que nadie lo confunda con
		# la suspensión: esto no es recorrido, es sólo el tope del desplazamiento visual.
		model_root.position.y = clampf(suspension.height - global_position.y, -0.6, 0.6)
	# La caja de colisión se pone PARALELA AL ASFALTO. La caja es un prisma horizontal de
	# 3,4 m de largo montado en el cuerpo, y el cuerpo NO cabecea con la rasante (sólo
	# gira en guiñada): sobre cualquier pendiente, el borde de ataque de la caja se mete
	# bajo la calzada. En una rasante del 1,5 % la calzada pasa 44 mm por encima de la
	# base de la caja en el morro y en un banco del 3 % (una pendiente normal de circuito),
	# 89 mm; el motor de colisiones devuelve el cuerpo hacia arriba cada fotograma y el
	# servosistema de altura lo vuelve a bajar, y esa pelea se paga en velocidad: medido
	# con `ride_probe` en el banco de pendientes, el coche ganaba 2,9 m/s² menos de los que
	# declaraba su propio balance de fuerzas a 3° (5,6× g·sen θ) y en la recta, a 300 km/h,
	# perdía hasta 5 m/s². Con la caja paralela a la calzada el hueco es el mismo en todo
	# su largo (los 35 mm de la altura de apoyo) y no hay pelea que pagar.
	if _collision_shape != null and suspension != null:
		_collision_shape.rotation.x = -suspension.road_slope_z
		_collision_shape.rotation.z = suspension.road_slope_x
	if _body_node != null:
		_body_node.basis = _body_rest
	_wheel_spin = fposmod(_wheel_spin + speed_mps / 0.3783 * delta, TAU)
	for i in _suspension_wheels.size():
		var wheel := _suspension_wheels[i]
		if not _wheel_rest.has(wheel):
			continue
		# El GIRO de dirección y el RECORRIDO de suspensión se aplican por separado:
		# el primero es un giro alrededor de la vertical y el segundo una traslación
		# vertical. Mezclarlos es lo que dejaba la rueda atravesando el asfalto.
		var steer := -steering_angle if wheel in _front_wheels else 0.0
		# La rueda NO se inclina con la carrocería: en un coche real la suspensión
		# mantiene el neumático alineado con la CALZADA, no con el chasis. Se deshace
		# la actitud de suspensión (la del asfalto se conserva, porque el modelo del
		# coche ya la lleva) y sin esto, con 2° de balanceo, el borde del neumático se
		# hunde unos 5 mm en el asfalto al inclinarse la rueda con el coche.
		var upright := Basis(Vector3.RIGHT, -suspension.pitch_relative) * Basis(Vector3.BACK, -suspension.roll_relative)
		wheel.position.y = _suspension_rest_y[i] + suspension.offset[i]
		wheel.basis = upright * Basis(Vector3.UP, steer) * Basis(Vector3.RIGHT, -_wheel_spin) * _wheel_rest[wheel]

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
	if suspension != null:
		# Tras una vuelta a pista la suspensión se resuelve de nuevo en el sitio: no
		# tiene sentido que el coche llegue con el recorrido del sitio anterior.
		suspension.reset()
		for i in _wheel_road_seen.size():
			_wheel_road_seen[i] = 0
	lateral_slip = 0.0
	longitudinal_slip = 0.0
	if lap_tracker != null:
		lap_tracker.valid_lap = false
