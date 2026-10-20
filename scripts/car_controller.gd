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
@export var model_forward_sign := -1.0
@export var model_lateral_sign := -1.0
@export var model_up_sign := 1.0

@export_category("Longitudinal dynamics")
@export var max_engine_force_n := 13800.0
@export var max_brake_force_n := 24800.0
@export var rolling_resistance_n := 95.0
@export var engine_braking_force_n := 210.0
@export var max_forward_speed_ms := 97.0
# Base del recorte de acelerador por velocidad: entra como `base + v/80` y limita
# cuánto par llega al suelo al arrancar. Se calibró en 0,62 para el F1 (evita que
# el pedal a fondo convierta cada salida en humo) y ahora es declarable por coche:
# un prototipo de 1100 kg con 12.340 N de tope de tracción no necesita el mismo
# recorte, y con 0,62 se quedaba en 88 km/h a los 3,5 s de plena carga.
@export var launch_throttle_factor := 0.62
@export var wheel_radius_m := 0.3783
@export var final_drive_ratio := 3.75
@export var idle_rpm := 3800.0
@export var shift_rpm := 12300.0
@export var downshift_rpm := 5200.0
@export var gears := PackedFloat32Array([0.0, 3.15, 2.35, 1.85, 1.52, 1.28, 1.10, 0.96, 0.85])

@export_category("Motor y transmisión desde AC (opcional)")
# Curvas del `data.acd`, en pares [régimen, valor]. Si están vacías el controlador usa
# el modelo agrupado de siempre (potencia de pico y tope de tracción), así que sólo los
# coches cuya receta las declara cambian de comportamiento.
#
# `engine_torque_curve` es `power.lut`: par BASE en el cigüeñal. `engine_boost_curve`
# es `turbo0.lut`/`turbo1.lut`: fracción de sobrepresión frente al régimen, de 0 a
# MAX_BOOST. AC compone `T = T_base * (1 + Σ boost)`, de modo que dos turbos idénticos
# suman dos veces la misma curva; por eso el número de turbos va aparte.
@export var engine_torque_curve := PackedVector2Array()
@export var engine_boost_curve := PackedVector2Array()
@export var engine_boost_count := 0.0
# Pérdida de la cadena de transmisión (caja, diferencial, palieres). AC no declara
# ninguna y aplica el par del cigüeñal a la rueda, así que el valor por defecto es 1,0;
# una receta puede bajarlo si quiere modelar pérdidas fuera del mod.
@export var drivetrain_efficiency := 1.0
# Régimen al que el embrague patina en la salida (AUTOCLUTCH MAX_RPM del mod). Con 0
# se usa el régimen que imponen las ruedas, que es lo que hacía el modelo anterior.
@export var clutch_launch_rpm := 0.0
# EBD: el ala que AC mueve con el acelerador. El valor de carga y el CD·A con el pedal
# suelto salen de evaluar las mismas tablas a gas=0; con -1 no hay dependencia.
@export var aero_downforce_n_at_100ms_off_throttle := -1.0
@export var drag_area_m2_off_throttle := -1.0
# `DY_CURVE` de cada eje: pares [carga por rueda (N), coeficiente de agarre]. Sustituye
# a la ley `pow(carga/2000, -sensibilidad)` cuando la receta los declara.
@export var front_tyre_grip_curve := PackedVector2Array()
@export var rear_tyre_grip_curve := PackedVector2Array()

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

@export_category("Suspension")
@export var suspension_rate_front_n_per_m := 150000.0
@export var suspension_rate_rear_n_per_m := 130000.0
@export var suspension_travel_bump_m := 0.035
@export var suspension_travel_droop_m := 0.030
@export var suspension_damper_tau := 0.05

var vehicle_kind := "rb22_2026"
var model_root: Node3D
var _model_basis_car := Basis.IDENTITY
var _model_origin_car := Vector3.ZERO
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
var ground_ray_exclude: Array[RID] = []
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
var debug_engine_torque_nm := 0.0     # par en el cigüeñal, ya con la sobrepresión de los turbos
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
# Altura del ORIGEN del cuerpo sobre la calzada, que es lo que fija dónde queda el fondo de
# la caja de colisión: 15 mm por debajo del origen. Con 20 mm el fondo queda 5 mm POR ENCIMA
# del asfalto —ni lo atraviesa ni flota— y el cuerpo no toca la calzada, así que el motor de
# colisiones no proyecta la velocidad contra su superficie.
#
# Estuvo en 10 mm (el fondo 5 mm POR DEBAJO del asfalto) y eso se paga en los dos sitios
# donde se mide la trayectoria: con el fondo dentro de la calzada el cuerpo colisiona con
# ella en cada fotograma y `move_and_slide` desvía el vector velocidad sobre la superficie;
# en una curva rápida esa desviación sale por el lado y se ve entera en las sondas —medido
# con `understeer_probe` en la curva rápida de 216 m a 222 km/h: deriva lateral 2,55 m/s,
# apertura 1,32 m y 89 % del recorrido del mando, contra 0,28 m/s, 0,25 m y 69 % con los
# 20 mm de la entrega—, y la composición de la cámara del morro, que se aprueba con la
# altura de la entrega, dejaba a los neumáticos fuera de encuadre.
@export var ride_height_m := 0.02
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
# Agarre de cada rueda que tiene suelo en el último muestreo. El coche no tiene un agarre
# único: cada neumático lleva el de la superficie que pisa, y con dos ruedas en el bordillo
# (0,88) y dos en el asfalto (1,00) rueda con el promedio (0,94), no con el de la
# superficie mayoritaria. Además de ser lo que dice la física, es lo que hace medible el
# bordillo: mide 1,2-3,5 m de ancho y las cuatro ruedas de un monoplaza (1,7 m de vía,
# 3,45 m entre ejes) no caben dentro NUNCA, así que la única muestra posible es montada.
var _wheel_grips: Array[float] = []

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
	# La condición es que la SUSPENSIÓN tenga un plano medido, no que algún rayo haya
	# dado en algo: si los cuatro rayos se descartan por lectura falsa, `suspension.height`
	# sigue siendo la del sitio anterior y `wheel_contacts` ya cuenta el nuevo. Servir esa
	# altura vieja es exactamente el disparo que dejaba el coche en el aire.
	if suspension != null and suspension.seated:
		var apoyo: float = suspension.height + ride_height_m
		var subida := 0.0
		var first_ground_frame := not _ride_ready
		if _ride_ready:
			subida = clampf((apoyo - _ride_reference) / maxf(delta, 0.0001), -ride_climb_max_m_s, ride_climb_max_m_s)
		_ride_reference = apoyo
		_ride_ready = true
		# Initial road acquisition establishes a reference; it does not teleport the
		# chassis to the measured height or manufacture a vertical velocity. The
		# suspension catches up through its bounded correction over subsequent ticks.
		if first_ground_frame:
			# Seed the follower from the current calibrated road height, avoiding a
			# high-speed capture burst while keeping subsequent grade tracking exact.
			_ride_reference = global_position.y
			return
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
		var exceso := absf(error) - ride_deadband_m
		var correccion := 0.0
		if exceso > 0.0:
			correccion = signf(error) * minf(exceso / maxf(ride_tau_s, 0.0001), ride_correction_max_m_s)
		velocity.y = subida + correccion
	else:
		_ride_ready = false

func _update_engine_and_forces(delta: float, forward: Vector3, right: Vector3, forward_speed: float, lateral_speed: float) -> void:
	var dynamic_pressure := 0.5 * 1.225 * speed_mps * speed_mps
	# EBD: el ala que el `aero.ini` mueve con el acelerador cambia CL·A entre el pedal
	# suelto y el pedal a fondo. Se interpola con la demanda real del pedal y la carga
	# sigue creciendo con v², que es la forma de las tablas (el CL no depende de la
	# velocidad en este mod, sólo la altura y el gas).
	var downforce_at_100 := aero_downforce_n_at_100ms
	var drag_area := drag_area_m2
	var gas_blend := clampf(throttle_input, 0.0, 1.0)
	if aero_downforce_n_at_100ms_off_throttle >= 0.0:
		downforce_at_100 = lerpf(aero_downforce_n_at_100ms_off_throttle, aero_downforce_n_at_100ms, gas_blend)
	if drag_area_m2_off_throttle >= 0.0:
		drag_area = lerpf(drag_area_m2_off_throttle, drag_area_m2, gas_blend)
	downforce_n = downforce_at_100 * pow(speed_mps / 100.0, 2.0)
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
	# Keep the front axle's commanded tire angle and the simulated body yaw
	# kinematically consistent. The old 3.72 m nominal lever arm disagreed with
	# the imported pivots (about 3.2 m on some vehicles), so the visual tires
	# pointed into a turn the chassis did not actually follow.
	var measured_wheelbase: float = suspension.wheelbase_m if suspension != null and suspension.wheelbase_m > 0.5 else wheelbase_m
	var actual_throttle := throttle_input * _throttle_grip_limit()
	# Fuerza en la rueda. Con curvas de AC sale del par real del motor en este régimen
	# y de la marcha engranada; `max_engine_force_n` sigue siendo el tope de agarre del
	# eje trasero (el modelo no simula deslizamiento de rueda, sino que recorta pedal).
	var engine_force := 0.0
	if engine_torque_curve.size() >= 2:
		var ratio: float = gears[clampi(gear, 1, gears.size() - 1)] * final_drive_ratio
		debug_engine_torque_nm = _engine_torque_nm(engine_rpm)
		var wheel_force := debug_engine_torque_nm * ratio * drivetrain_efficiency / maxf(wheel_radius_m, 0.1)
		engine_force = minf(max_engine_force_n, wheel_force) * actual_throttle
	else:
		var power_force := engine_peak_power_w / maxf(speed_mps, 19.0)
		var legacy_force := minf(max_engine_force_n, power_force)
		var legacy_ratio: float = maxf(gears[clampi(gear, 1, gears.size() - 1)] * final_drive_ratio, 0.01)
		debug_engine_torque_nm = legacy_force * maxf(wheel_radius_m, 0.1) / legacy_ratio
		engine_force = legacy_force * actual_throttle
	var braking_force := max_brake_force_n * brake_input
	var drag_force := dynamic_pressure * drag_area
	var rolling := rolling_resistance_n if speed_mps > 0.1 else 0.0
	var engine_braking := engine_braking_force_n * (1.0 - throttle_input) if speed_mps > 3.0 else 0.0
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
	var desired_yaw_rate: float = -speed_mps / measured_wheelbase * tan(steering_angle)
	# In the car frame +X is right and forward is -Z. A positive yaw rotates
	# forward toward -X, so centripetal acceleration expressed along car-right is
	# -v * yaw_rate. Keep this sign consistent with WheelSuspension's corner.x
	# when transferring load to the outside wheels.
	var lateral_demand: float = -speed_mps * desired_yaw_rate
	var requested_lateral_force: float = mass_kg * lateral_demand
	# The production model already places the measured pivots in this car frame;
	# keep suspension sign conventions tied to the physics axes, not GLB axis signs.
	var front_load := maxf(0.15, front_weight_fraction + maxf(0.0, -longitudinal_accel) * cg_height_m / (wheelbase_m * 9.81))
	front_load = clampf(front_load, 0.25, 0.72)
	var rear_load := 1.0 - front_load
	var front_axle_load := max_grip_force * front_load
	var rear_axle_load := max_grip_force * rear_load
	var front_normal_load_sensitivity := _tyre_grip(front_tyre_grip_curve, front_axle_load / 2.0)
	var rear_normal_load_sensitivity := _tyre_grip(rear_tyre_grip_curve, rear_axle_load / 2.0)
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
	var target_slip: float = (requested_lateral_force - lateral_force) / maxf(lateral_limit, 1.0)
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
	var yaw_delta := wrapf(rotation.y - _telemetry_yaw, -PI, PI)
	var ground_plane := _plano_de_apoyo()
	var new_forward: Vector3 = forward.rotated(Vector3.UP, yaw_delta).slide(ground_plane)
	if new_forward.length_squared() < 0.5:
		new_forward = -global_basis.z
	new_forward = new_forward.normalized()
	var new_right := Vector3.UP.cross(new_forward).normalized()
	velocity = new_forward * new_speed + new_right * lateral_speed * exp(-delta * (5.0 + surface_grip * 4.0))
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

# Interpolación lineal de una curva [x, y] muestreada. Fuera de rango devuelve el
# extremo, que es lo que hace AC con sus LUT (no extrapola).
func _curve_at(curve: PackedVector2Array, x: float) -> float:
	var count := curve.size()
	if count == 0:
		return 0.0
	if x <= curve[0].x:
		return curve[0].y
	if x >= curve[count - 1].x:
		return curve[count - 1].y
	for i in range(1, count):
		if x <= curve[i].x:
			var a := curve[i - 1]
			var b := curve[i]
			if is_equal_approx(a.x, b.x):
				return b.y
			return lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
	return curve[count - 1].y

# Par en el cigüeñal con la sobrepresión de los turbos: `T = T_base * (1 + Σ boost)`.
func _engine_torque_nm(rpm: float) -> float:
	var base := _curve_at(engine_torque_curve, rpm)
	if engine_boost_curve.size() < 2 or engine_boost_count <= 0.0:
		return base
	return base * (1.0 + engine_boost_count * _curve_at(engine_boost_curve, rpm))

# Coeficiente de agarre de un neumático con esa carga vertical. Con la curva `DY_CURVE`
# del mod sale de los datos; sin ella se mantiene la ley de sensibilidad a la carga.
func _tyre_grip(curve: PackedVector2Array, load_n: float) -> float:
	if curve.size() >= 2:
		return maxf(_curve_at(curve, load_n), 0.05)
	return pow(maxf(load_n, 1.0) / 2000.0, -tire_load_sensitivity)

# Convierte los pares de la receta en una curva utilizable.
func _to_curve(value: Variant) -> PackedVector2Array:
	var curve := PackedVector2Array()
	if value is Array:
		for point in value:
			if point is Array and point.size() >= 2:
				curve.append(Vector2(float(point[0]), float(point[1])))
	return curve

func _throttle_grip_limit() -> float:
	var speed_factor := clampf(launch_throttle_factor + speed_mps / 80.0, 0.0, 1.0)
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
	var wheel_rpm := speed_mps / (2.0 * PI * maxf(wheel_radius_m, 0.1)) * 60.0
	var ratio := gears[clampi(gear, 1, gears.size() - 1)]
	engine_rpm = clampf(maxf(idle_rpm, wheel_rpm * ratio * final_drive_ratio), idle_rpm, shift_rpm + 900.0)
	# Salida: el embrague patina (AUTOCLUTCH del mod) y mantiene el motor por encima del
	# régimen que impondrían las ruedas. Sin esto el motor caía al ralentí en primera y el
	# coche arrancaba con el par de 2.250 rpm en vez de con el de la zona de embrague.
	if clutch_launch_rpm > 0.0 and gear == 1 and throttle_input > 0.05 and speed_mps < 20.0:
		engine_rpm = maxf(engine_rpm, clampf(clutch_launch_rpm, idle_rpm, shift_rpm))
	if _gear_timer > 0.0:
		return
	if engine_rpm > shift_rpm and gear < gears.size() - 1:
		gear += 1
		_gear_timer = 0.22
		engine_rpm *= 0.82
	elif engine_rpm < downshift_rpm and gear > 1 and speed_mps > 7.0:
		gear -= 1
		_gear_timer = 0.18

func _sample_ground() -> void:
	if not is_inside_tree() or get_world_3d() == null:
		return
	# For production cars, the suspension probes under the imported tire hubs are
	# the sole contact source. The old fixed body-footprint rays reported pavement
	# contact even when the wheels had no surface, which then suppressed gravity
	# and falsely made the chassis "grounded".
	if not _suspension_wheels.is_empty():
		return
	# This legacy, fixed-chassis footprint is only a fallback for vehicles without
	# wheel pivots. For production cars, suspension rays below are the contact truth;
	# the duplicate body rays could report floor contact even when the actual tires
	# had lost the surface and would suppress gravity/flight response.
	if not _suspension_wheels.is_empty():
		return
	wheel_contacts = 0
	_surface_votes.clear()
	_wheel_grips.clear()
	var normals := Vector3.ZERO
	var heights := 0.0
	for point in [Vector3(-0.85, 0, -1.5), Vector3(0.85, 0, -1.5), Vector3(-0.85, 0, 1.95), Vector3(0.85, 0, 1.95)]:
		var world: Vector3 = global_transform * point
		var query := PhysicsRayQueryParameters3D.create(world + Vector3.UP * 5.0, world - Vector3.UP * 5.0, 1)
		query.exclude = ground_ray_exclude
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		wheel_contacts += 1
		normals += hit.normal
		heights += hit.position.y
		var surface := _surface_of(hit.collider as Node)
		if not surface.is_empty():
			_surface_votes[surface] = int(_surface_votes.get(surface, 0)) + 1
			_wheel_grips.append(TrackScript.get_surface_grip(surface))
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
	if surface.is_empty():
		ground_surface = ""
		return _grip_from_last_contact()
	# `ground_surface` sigue siendo la superficie MAYORITARIA (es la que anuncia el HUD),
	# pero el agarre es el promedio de las ruedas: montar el bordillo agarra menos aunque
	# el asfalto siga siendo mayoría, y pisar hierba con una sola rueda ya cobra su parte.
	ground_surface = surface
	if _wheel_grips.is_empty():
		return TrackScript.get_surface_grip(surface)
	var total := 0.0
	for grip in _wheel_grips:
		total += grip
	return total / float(_wheel_grips.size())

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
	var local_pos: Vector3 = global_position
	var line := TrackScript.get_centerline()
	var track: Node3D
	for sibling in get_parent().get_children():
		if sibling is Node3D and String(sibling.name).ends_with(" original AC track"):
			track = sibling as Node3D
			break
	if track != null:
		local_pos = track.global_transform.affine_inverse() * global_position
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
	var initial_model_basis: Basis = global_basis.inverse() * model_root.global_basis
	_model_basis_car = Basis(
		initial_model_basis.x * model_lateral_sign,
		initial_model_basis.y * model_up_sign,
		initial_model_basis.z * model_forward_sign)
	_model_origin_car = global_transform.affine_inverse() * model_root.global_position
	var wheels: Array[Node3D] = []
	var front_flags: Array[int] = []
	# The RB22 exports each tire as a MeshInstance beneath a named Node3D hub.
	# `race.gd` canonicalizes those hubs, while Godot suffixes their child mesh
	# names. Resolve the canonical pivot so steering, spin and suspension move the
	# complete tire assembly. The MP4/4's canonical wheels are meshes and remain
	# supported because MeshInstance3D also derives from Node3D.
	for wheel_name in ["wheel_fl", "wheel_fr", "wheel_rl", "wheel_rr"]:
		var wheel := model_root.find_child(wheel_name, true, false) as Node3D
		if wheel == null:
			push_error("Missing canonical wheel pivot " + wheel_name)
			continue
		_wheel_rest[wheel] = wheel.basis
		var front: bool = wheel_name.ends_with("fl") or wheel_name.ends_with("fr")
		if front:
			_front_wheels.append(wheel)
		else:
			_rear_wheels.append(wheel)
		wheels.append(wheel)
		front_flags.append(1 if front else 0)

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
	var model_to_car := global_basis.inverse() * model_root.global_basis
	for i in wheels.size():
		var wheel := wheels[i]
		# `wheel.position` is relative to its immediate imported parent (which can
		# carry the GLB's 90° wheel-pivot rotation). Convert the node origin through
		# the full hierarchy into the controller's car frame; using local position
		# here swaps front/rear Z and puts each ground ray 30–75 mm from its hub.
		var pivot_car: Vector3 = global_transform.affine_inverse() * wheel.global_position
		pivot_car = model_to_car.inverse() * (pivot_car - _model_origin_car)
		var corner_car := Vector3(pivot_car.x * model_lateral_sign, 0.0, pivot_car.z * model_forward_sign)
		corners.append(corner_car)
		flags.append(front_flags[i])
		_suspension_rest_y.append(pivot_car.y)
		if front_flags[i] == 1:
			front_z += corner_car.z
			front_x += absf(corner_car.x)
			front_count += 1
		else:
			rear_z += corner_car.z
			rear_x += absf(corner_car.x)
			rear_count += 1
	suspension.configure(corners, flags)
	suspension.mass_kg = mass_kg
	suspension.front_weight_fraction = front_weight_fraction
	suspension.cg_height_m = cg_height_m
	suspension.rate_front_n_per_m = suspension_rate_front_n_per_m
	suspension.rate_rear_n_per_m = suspension_rate_rear_n_per_m
	suspension.travel_bump_m = suspension_travel_bump_m
	suspension.travel_droop_m = suspension_travel_droop_m
	suspension.damper_tau = suspension_damper_tau
	# Batalla y vías MEDIDAS en el modelo (no los valores nominales del export): son
	# las que reparten la carga entre las ruedas.
	if front_count > 0 and rear_count > 0:
		suspension.wheelbase_m = absf(rear_z / rear_count - front_z / front_count)
		suspension.track_front_m = front_x / front_count * 2.0
		suspension.track_rear_m = rear_x / rear_count * 2.0

func apply_vehicle_physics(config: Dictionary) -> void:
	if config.is_empty():
		return
	mass_kg = float(config.get("mass_kg", mass_kg))
	wheelbase_m = float(config.get("wheelbase_m", wheelbase_m))
	cg_height_m = float(config.get("cg_height_m", cg_height_m))
	engine_peak_power_w = float(config.get("engine_peak_power_w", engine_peak_power_w))
	aero_downforce_n_at_100ms = float(config.get("aero_downforce_n_at_100ms", aero_downforce_n_at_100ms))
	drag_area_m2 = float(config.get("drag_area_m2", drag_area_m2))
	front_weight_fraction = float(config.get("front_weight_fraction", front_weight_fraction))
	max_engine_force_n = float(config.get("max_engine_force_n", max_engine_force_n))
	max_brake_force_n = float(config.get("max_brake_force_n", max_brake_force_n))
	rolling_resistance_n = float(config.get("rolling_resistance_n", rolling_resistance_n))
	engine_braking_force_n = float(config.get("engine_braking_force_n", engine_braking_force_n))
	max_forward_speed_ms = float(config.get("max_forward_speed_ms", max_forward_speed_ms))
	launch_throttle_factor = float(config.get("launch_throttle_factor", launch_throttle_factor))
	top_speed_factor = float(config.get("top_speed_factor", top_speed_factor))
	wheel_radius_m = float(config.get("wheel_radius_m", wheel_radius_m))
	final_drive_ratio = float(config.get("final_drive_ratio", final_drive_ratio))
	idle_rpm = float(config.get("idle_rpm", idle_rpm))
	shift_rpm = float(config.get("shift_rpm", shift_rpm))
	downshift_rpm = float(config.get("downshift_rpm", downshift_rpm))
	if config.has("gears"):
		var raw_gears: Array = config["gears"]
		var packed_gears := PackedFloat32Array()
		for ratio in raw_gears:
			packed_gears.append(float(ratio))
		if packed_gears.size() >= 2:
			gears = packed_gears
	front_cornering_stiffness_n_per_rad = float(config.get("front_cornering_stiffness_n_per_rad", front_cornering_stiffness_n_per_rad))
	rear_cornering_stiffness_n_per_rad = float(config.get("rear_cornering_stiffness_n_per_rad", rear_cornering_stiffness_n_per_rad))
	steering_at_low_speed_rad = float(config.get("steering_at_low_speed_rad", steering_at_low_speed_rad))
	steering_at_high_speed_rad = float(config.get("steering_at_high_speed_rad", steering_at_high_speed_rad))
	steering_response = float(config.get("steering_response", steering_response))
	front_grip_fraction = float(config.get("front_grip_fraction", front_grip_fraction))
	tire_load_sensitivity = float(config.get("tire_load_sensitivity", tire_load_sensitivity))
	# Curvas opcionales del data.acd. Se reinician a vacío cuando la receta no las trae,
	# para que al cambiar de coche no queden las del anterior.
	engine_torque_curve = _to_curve(config.get("engine_torque_curve", []))
	engine_boost_curve = _to_curve(config.get("engine_boost_curve", []))
	engine_boost_count = float(config.get("engine_boost_count", 0.0))
	drivetrain_efficiency = float(config.get("drivetrain_efficiency", 1.0))
	clutch_launch_rpm = float(config.get("clutch_launch_rpm", 0.0))
	aero_downforce_n_at_100ms_off_throttle = float(config.get("aero_downforce_n_at_100ms_off_throttle", -1.0))
	drag_area_m2_off_throttle = float(config.get("drag_area_m2_off_throttle", -1.0))
	front_tyre_grip_curve = _to_curve(config.get("front_tyre_grip_curve", []))
	rear_tyre_grip_curve = _to_curve(config.get("rear_tyre_grip_curve", []))
	slip_recovery_rate = float(config.get("slip_recovery_rate", slip_recovery_rate))
	suspension_rate_front_n_per_m = float(config.get("suspension_rate_front_n_per_m", suspension_rate_front_n_per_m))
	suspension_rate_rear_n_per_m = float(config.get("suspension_rate_rear_n_per_m", suspension_rate_rear_n_per_m))
	suspension_travel_bump_m = float(config.get("suspension_travel_bump_m", suspension_travel_bump_m))
	suspension_travel_droop_m = float(config.get("suspension_travel_droop_m", suspension_travel_droop_m))
	suspension_damper_tau = float(config.get("suspension_damper_tau", suspension_damper_tau))
	engine_rpm = idle_rpm
	if suspension != null:
		suspension.mass_kg = mass_kg
		suspension.front_weight_fraction = front_weight_fraction
		suspension.cg_height_m = cg_height_m
		suspension.rate_front_n_per_m = suspension_rate_front_n_per_m
		suspension.rate_rear_n_per_m = suspension_rate_rear_n_per_m
		suspension.travel_bump_m = suspension_travel_bump_m
		suspension.travel_droop_m = suspension_travel_droop_m
		suspension.damper_tau = suspension_damper_tau

# Un rayo por rueda, desde 0,8 m por encima de su punto de contacto hasta 0,9 m por
# debajo. Es la medida que resuelve la suspensión (altura del asfalto bajo cada
# rueda) y la que sigue alimentando la normal del suelo, la superficie pisada y el
# recuento de contactos que usa la conducción.
func _sample_wheel_contacts(delta: float) -> void:
	if suspension == null or not is_inside_tree() or get_world_3d() == null:
		return
	wheel_contacts = 0
	_surface_votes.clear()
	_wheel_grips.clear()
	var normals := Vector3.ZERO
	var count := _suspension_wheels.size()
	var heights := PackedFloat32Array()
	var grounded := PackedInt32Array()
	heights.resize(count)
	grounded.resize(count)
	var height_sum := 0.0
	for i in count:
		# wheel.position belongs to its immediate parent. Use its global hub and
		# project to the ground plane, so every contact ray starts under the actual
		# imported tire pivot, even when the source GLB adds a rotated parent node.
		var hub_car: Vector3 = global_transform.affine_inverse() * _suspension_wheels[i].global_position
		var world: Vector3 = global_transform * Vector3(
			hub_car.x, 0.0, hub_car.z)
		# Suzuka's imported concave FBX has small gaps at some triangle joins. A
		# center ray can miss even when the tire is over the road, so retry within
		# the tire's contact patch (at most 20 cm). The first valid sample wins.
		var offsets := [Vector2.ZERO, Vector2(0.12, 0.0), Vector2(-0.12, 0.0), Vector2(0.0, 0.12), Vector2(0.0, -0.12), Vector2(0.14, 0.14), Vector2(-0.14, 0.14), Vector2(0.14, -0.14), Vector2(-0.14, -0.14), Vector2(0.22, 0.0), Vector2(-0.22, 0.0), Vector2(0.0, 0.22), Vector2(0.0, -0.22)]
		var hit: Dictionary = {}
		var measured := 0.0
		var best_candidate: Dictionary = {}
		var best_distance := INF
		var has_road_sample: bool = _wheel_road_seen[i] != 0
		var expected_y: float = _wheel_road[i] if has_road_sample else global_position.y - ride_height_m
		var road_sample_tolerance := 0.4 if has_road_sample else 0.75
		for offset in offsets:
			var sample_world := world + Vector3(offset.x, 0.0, offset.y)
			var query := PhysicsRayQueryParameters3D.create(sample_world + Vector3.UP * 5.0, sample_world - Vector3.UP * 5.0, 1)
			if has_road_sample:
				query.hit_back_faces = true
			query.exclude = ground_ray_exclude
			var candidate := get_world_3d().direct_space_state.intersect_ray(query)
			if candidate.is_empty():
				continue
			var candidate_y: float = candidate.position.y
			# Wall meshes are excluded. Allow the road up to 2 m above the chassis
			# to recover a climb; reject surfaces over 1 m below to avoid treating
			# another level of the circuit as wheel support.
			if candidate_y > global_position.y + 2.0 or candidate_y < global_position.y - 1.0:
				continue
			var candidate_distance := absf(candidate_y - expected_y)
			if candidate_distance > road_sample_tolerance:
				continue
			# Prefer the actual hub contact when present. Choosing the closest
			# height to the PREVIOUS tick among all offsets lags a slope by up
			# to 22 cm of travel and can put the tire through the road. Offset
			# samples remain a seam fallback, not a replacement for valid center.
			if offset == Vector2.ZERO:
				best_candidate = candidate
				break
			if candidate_distance < best_distance:
				best_distance = candidate_distance
				best_candidate = candidate
		if not best_candidate.is_empty():
			hit = best_candidate
			measured = float(hit.position.y)
			heights[i] = measured
			if not has_road_sample:
				_wheel_road[i] = measured
				_wheel_road_seen[i] = 1
		else:
			# A brief triangle seam is not a real vertical road edge. Carry the
			# most recent surface height into the suspension plane, but leave
			# grounded=0 and the contact count truthful for this tick.
			heights[i] = _wheel_road[i] if has_road_sample else 0.0
			grounded[i] = 0
			continue
		if hit.is_empty():
			continue
		_wheel_road[i] = measured
		_wheel_road_seen[i] = 1

		wheel_contacts += 1
		normals += hit.normal
		heights[i] = measured
		height_sum += measured
		grounded[i] = 1
		var surface := _surface_of(hit.collider as Node)
		if not surface.is_empty():
			_surface_votes[surface] = int(_surface_votes.get(surface, 0)) + 1
			_wheel_grips.append(TrackScript.get_surface_grip(surface))
	if wheel_contacts > 0:
		ground_normal = normals.normalized()
		_ground_height = height_sum / wheel_contacts
		# When only one or two wheel rays find road, the contact heights cannot
		# uniquely determine both road-plane slopes. Use the averaged triangle
		# normal to constrain the missing axes instead of retaining an arbitrary
		# previous plane and alternating the chassis height on Suzuka's descent.
		if wheel_contacts < 3 and ground_normal.y > 0.2:
			var normal_car: Vector3 = global_basis.inverse() * ground_normal
			if normal_car.y > 0.2:
				var sampled_slope_x := clampf(-normal_car.x / normal_car.y, -0.15, 0.15)
				var sampled_slope_z := clampf(-normal_car.z / normal_car.y, -0.15, 0.15)
				suspension.road_slope_x = move_toward(suspension.road_slope_x, sampled_slope_x, delta * 0.5)
				suspension.road_slope_z = move_toward(suspension.road_slope_z, sampled_slope_z, delta * 0.5)


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
		model_root.rotation.x = suspension.pitch * model_forward_sign * model_up_sign
		model_root.rotation.z = suspension.roll * model_lateral_sign * model_up_sign
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

	# The physically correct spin rate aliases to a nearly stationary wheel in
	# 30/60 Hz phone captures at racing speeds. Preserve true rotation at low
	# speeds, then cap only the rendered angular rate so the spokes remain visibly
	# in motion on a sampled display. This does not affect vehicle physics.
	var physical_wheel_rate := speed_mps / maxf(wheel_radius_m, 0.1)
	var visible_wheel_rate := minf(physical_wheel_rate, 36.0)
	_wheel_spin = fposmod(_wheel_spin + visible_wheel_rate * delta, TAU)
	for i in _suspension_wheels.size():
		var wheel := _suspension_wheels[i]
		if not _wheel_rest.has(wheel):
			continue
		# El GIRO de dirección y el RECORRIDO de suspensión se aplican por separado:
		# el primero es un giro alrededor de la vertical y el segundo una traslación
		# vertical. Mezclarlos es lo que dejaba la rueda atravesando el asfalto.
		var steer := -steering_angle if wheel in _front_wheels else 0.0
		# Keep the complete imported pivot orientation. Its model-space Y axle is
		# intentional (the GLB pivot rotates it to the car's lateral X axle); only append
		# actual steer and spin to that rest basis. A synthetic upright changes the axle
		# axis and breaks the measured tire contact.
		wheel.position.y = _suspension_rest_y[i] + suspension.offset[i]
		wheel.basis = Basis(Vector3.UP, steer) * Basis(Vector3.RIGHT, -_wheel_spin) * (_wheel_rest[wheel] as Basis)

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
	# EL SERVO DE ALTURA NO HEREDA LA REFERENCIA DEL SITIO ANTERIOR. `suspension.reset()`
	# deja `height` a cero y la referencia del servo (`_ride_reference`) seguía apuntando
	# al asfalto de donde venía el coche. Con las dos cosas a la vez, el primer fotograma
	# pedía subir a los 12 m/s del tope de rasante y el error respecto a `height = 0`
	# añadía los 4 m/s de la corrección: medido con `diag_ride_servo` al colocar el coche
	# en la estación 2760, `velocity.y` salía a +16 m/s, el cuerpo volaba 2,1 m y se
	# quedaba sin ninguna rueda sobre el asfalto durante casi un segundo. TODAS las sondas
	# colocan el coche con esta función, así que el disparo contaminaba sus medidas: las
	# curvas de `suspension_probe` no pasaban de 0,17 g porque el coche iba por el aire.
	# Aquí se declara el coche SIN CONTACTO: el servo no manda nada en este fotograma, al
	# final del mismo se miden las cuatro ruedas en el sitio nuevo y la suspensión resuelve
	# su altura desde cero (`_first_frame`) sin filtrar ni disparar.
	wheel_contacts = 0
	_ride_ready = false
	_ride_reference = 0.0
	acceleration_longitudinal = 0.0
	acceleration_lateral = 0.0
	_last_speed = 0.0
	lateral_slip = 0.0
	longitudinal_slip = 0.0
	if lap_tracker != null:
		lap_tracker.valid_lap = false
