extends SceneTree

# ============================================================================
# ¿SUBVIRA EL COCHE, Y POR QUÉ? Descomposición medida del subviraje.
#
# La queja es de TRAYECTORIA («el tren delantero no cierra la curva y el coche se
# abre»), así que esta sonda mide las piezas que la explican, por separado y por el
# canal de entrada real (los mismos metadatos `touch_*` que lee el juego, con la capa de
# controles detenida para que nadie los sobrescriba):
#
# PARTE A — BANCO (losa de asfalto plana, sin circuito ni muros). En cada velocidad y
#   cada recorrido del mando separa los eslabones que pueden quitar giro:
#     * el TOPE de esa velocidad y CUÁL de los dos límites lo fija —el recorrido del
#       manillar (`lean`) o el agarre disponible (`grip`)—: dice si el problema es de
#       ángulo;
#     * el ángulo APLICADO y el RADIO GEOMÉTRICO que pide ese ángulo (batalla/tan δ): lo
#       que están ordenando las ruedas;
#     * el radio REALMENTE recorrido (v / régimen de guiñada) y, con él, el MARGEN DE
#       SUBVIRAJE = radio real / radio geométrico: cuánto se abre la trayectoria respecto
#       a lo que piden las ruedas. 1,00 es un coche neutro; por encima de 1,00, la
#       diferencia con 1,00 es lo que el tren delantero no consigue cerrar;
#     * el AGARRE DISPONIBLE (g) y su reparto delantero/trasero, que es el techo contra
#       el que choca el radio real.
#   De ahí salen, por velocidad, el TECHO de agarre, el RECORRIDO del mando que hace
#   falta para alcanzarlo y el RADIO MÍNIMO; con las cuatro velocidades se ve cómo crece
#   la capacidad con la velocidad (carga aerodinámica).
#
# PARTE B — TRAYECTORIA EN CURVAS REALES. Tres curvas del circuito (lenta, media y
#   rápida) elegidas por su radio entre los vértices de la trazada. Para cada una se
#   calcula V70, la velocidad a la que el coche describe exactamente ese radio con el
#   70 % del recorrido del mando (lo que un dedo sostiene sin llegar al tope), a partir
#   del agarre medido en el banco; después se CONDUCE la curva de verdad a la mayor de
#   V70 y la velocidad ideal de la línea de asistencia, y se mide el DESVÍO HACIA FUERA
#   respecto a la trazada. Ese desvío es la queja en metros: 0 quiere decir que el coche
#   cierra la curva; cuanto mayor, más se abre.
#
# Uso:  Godot --headless --path . --script res://scripts/understeer_probe.gd
# ============================================================================

const TrackScript = preload("res://scripts/track_data.gd")

const TICK := 1.0 / 120.0
# La medida del banco se hace sobre una losa plana y sin obstáculos, como la sonda de
# dirección: en la recta real el coche acaba tocando las barreras y la medida del modelo
# se contamina.
const PAD_HEIGHT := 1500.0
const PAD_HALF := 4000.0
const APPROACH_TICKS := 900
const CORNER_TICKS := 168          # 1,4 s de curva: el régimen se establece y se mide
const SUSTAINED_FROM := 108        # media desde aquí
const SPEED_TOLERANCE := 0.6       # m/s
const MAX_OSCILACION := 0.35
const MAX_DIFERENCIA_IZQ_DER := 0.15
# Margen de subviraje (radio real / radio geométrico) que se admite CON EL MANDO A FONDO.
# No es 1,00 porque el tope de dirección deja pedir un 25 % más de ángulo del que satura la
# goma (`max_steer = grip_steer * 1.25`), así que a fondo el coche pide un radio más cerrado
# del que la goma puede y la trayectoria sale un 25-35 % más ancha: es el margen declarado
# del modelo, no un defecto. El tope sirve para cazar el defecto de verdad (un coche que no
# gira: el margen se disparaba a 4 con el modelo viejo de 0,26 g).
const MAX_MARGEN_SUBVIRAJE := 1.45
# Y con el mando a media carrera la trayectoria tiene que ser la que piden las ruedas: ahí
# el modelo no debe esconder subviraje ninguno.
const MAX_MARGEN_MEDIO := 1.05

# Velocidades del banco y recorridos del mando. El recorrido se pide en % del anillo y se
# traduce a demanda con la curva declarada del mando (`steering_travel_for`), no con una
# copia: si la curva cambia, la sonda sigue pidiendo lo mismo.
const SPEEDS_KPH := [60.0, 120.0, 180.0, 240.0]
const STICKS := [0.2, 0.4, 0.6, 0.7, 0.8, 1.0]
# A 240 km/h la escalera se acorta: llegar a esa velocidad cuesta más tiempo de
# simulación que medirla, y los escalones que importan (el 70 % de V70 y el fondo) están.
const STICKS_240 := [0.5, 0.7, 0.85, 1.0]

# TECHO DE AGARRE EXIGIDO, por velocidad. No sale de la medida: sale de lo que es un
# monoplaza con carga aerodinámica, y es el criterio de aceptación del subviraje. Con 798
# kg de masa y una carga aerodinámica del orden de 1,5 veces el peso a 250 km/h
# (referencia conservadora de la categoría), la fuerza lateral disponible tiene que
# quedar por encima de estas cifras: 1,00 g a 60 km/h, 1,20 a 120, 1,70 a 180 y 2,20 a
# 240. Un coche que no llega abre la curva por falta de fuerza lateral del tren delantero,
# no por falta de ángulo.
#
# A 60 km/h la cifra exigida es 1,00 g y NO sube: a esa velocidad manda el agarre mecánico
# de la goma, que ya se mide en 1,03 g, y el encargo es explícito en no aumentar el agarre
# global del coche. Lo que falta es la parte que crece con la velocidad: 1,10 g medidos a
# 120 km/h frente a 1,20 exigidos, 1,21 frente a 1,70 a 180 y 1,36 frente a 2,20 a 240.
const TECHO_EXIGIDO := [
	{"kph": 60.0, "g": 1.00},
	{"kph": 120.0, "g": 1.20},
	{"kph": 180.0, "g": 1.70},
	{"kph": 240.0, "g": 2.20},
]
# El tope de dirección del modelo deja pedir un 25 % más de ángulo que el que satura la
# goma (`max_steer = grip_steer * 1.25` en `car_controller.gd`), así que con el 70 % del
# recorrido la demanda lateral es `_steering_curve(0.70) * 1,25` de la capacidad. Es el
# factor con el que se pasa de la capacidad EXIGIDA a la velocidad que el coche tiene que
# poder recorrer con el 70 % del mando.
const MARGEN_DEL_TOPE := 1.25
# El tope de dirección tiene que alcanzarse sin llegar al final del recorrido: es la
# petición «cerrar curvas sin necesitar el joystick al máximo».
const STICK_PARA_TOPE := 0.85
# La capacidad tiene que crecer con la velocidad (hay carga aerodinámica), pero sin
# convertir el coche en un arcade de agarre plano: la diferencia entre la curva rápida y
# la lenta queda declarada en este margen.
const GANANCIA_MIN := 1.35
const GANANCIA_MAX := 3.4

# --- parte B: curvas reales ---------------------------------------------------
# Radio de las tres curvas que se buscan entre los vértices de la trazada.
const CURVAS := [
	{"nombre": "lenta", "radio": 32.0},
	{"nombre": "media", "radio": 95.0},
	{"nombre": "rapida", "radio": 210.0},
]
const MANDO_CURVA_REAL := 0.70     # recorrido del mando sostenido en la curva real
const PUNTOS_ENTRADA := 26         # ~39 m antes del vértice: el punto de giro
const PUNTOS_SALIDA := 30          # ~45 m después del vértice: la salida
const DESVIO_FUERA_MAX_M := 2.0    # desvío hacia fuera permitido respecto a la trazada
# Mando MÁXIMO que el seguidor necesita para cerrar la curva a la velocidad exigida. El
# criterio es «sin necesitar el joystick al máximo», así que se deja un 15 % de reserva
# antes del tope del recorrido. La fracción de tiempo con el tope del 70 % alcanzado NO se
# exige —en el punto de giro el seguidor pide un instante de más para meter el morro—: se
# informa como diagnóstico y el criterio es el pico de mando, que es lo que pregunta el
# encargo.
const MANDO_MAX_EXIGIDO := 0.85
# Deslizamiento lateral máximo admitido en la curva. En una curva sostenida la velocidad
# lateral del cuerpo es casi cero (el coche gira de morro); si el eje trasero derrapa,
# crece. Tres metros por segundo es un derrape franco, no un apoyo.
const DERIVA_MAX_M_S := 3.0
# Trompo: el morro más de 45° fuera de la trazada. Es «cruzado», no una corrección.
const ANGULO_TROMPO_DEG := 45.0
# Pedal que se usa en cada tramo conducido.
const MODO_SOSTENER := 0        # mantiene la velocidad de la prueba
const MODO_GAS := 1             # acelerador a fondo desde la entrada
const MODO_SIN_GAS := 2         # sin acelerador desde la entrada
const MODO_SALIDA := 3          # mantiene hasta el vértice y acelera progresivo a la salida
const MODO_FRENO := 4           # mantiene hasta el vértice y frena a la salida (hasta el 70 %)
const APEX_VENTANA := 10           # puntos a cada lado para declarar un vértice
# Traza de la aproximación. Se deja apagada en la medida normal.
const TRAZA := false

var failures := 0
var race: Node3D
var car: CharacterBody3D
var ui: CanvasLayer
var linea = null
var puntos := PackedVector3Array()

var ultimo_limite_alcanzado := false   # el seguidor quiso más mando que el tope pedido
var ultimo_pedido_sin_tope := 0.0      # lo que pedía el seguidor antes de recortarlo
var banco: Array = []              # una fila por (velocidad, recorrido, lado)
var techos: Dictionary = {}        # velocidad -> techo, recorrido del tope, radio mínimo


func check(ok: bool, message: String) -> void:
	print("SUBVIRAJE ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1


func info(message: String) -> void:
	print("SUBVIRAJE INFO ", message)


func _initialize() -> void:
	call_deferred("_run")


func _group_of(body: Node) -> String:
	if body == null:
		return "NONE"
	var upper := (String(body.name) + " " + String(body.get_meta("ac_surface", ""))).to_upper()
	for key in ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "GRAVEL", "SAND", "GRASS", "GREEN", "OUT", "CONCRETE", "WALL"]:
		if key in upper:
			return key
	return "OTHER"


# Demandas de pedal y dirección por el canal real de entrada.
func _demand(throttle: float, brake: float, steer: float) -> void:
	car.set_meta("touch_throttle", throttle)
	car.set_meta("touch_brake", brake)
	car.set_meta("touch_steer", steer)


func _speed_control(target: float) -> void:
	var error: float = target - car.speed_mps
	var throttle := clampf(error * 0.4 + 0.1, 0.0, 1.0)
	var brake := clampf(-error * 0.3, 0.0, 1.0)
	if throttle < 0.05:
		throttle = 0.0
	if brake < 0.05:
		brake = 0.0
	_demand(throttle, brake, 0.0)


func _run() -> void:
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	# Sin tope de fotogramas: la medida va por fotogramas de FÍSICA, así que correr el
	# bucle lo más rápido que pueda no cambia el resultado y acorta la sonda.
	Engine.max_fps = 0
	for i in 120:
		await physics_frame
	car = race.car
	ui = race.controls
	ui.set_process(false)              # la inyección manda; el joystick no sobrescribe
	linea = race.assistance_line
	puntos = TrackScript.get_centerline()
	_build_pad()

	await _parte_a()
	await _parte_b()
	_resumen()

	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


# ---------------------------------------------------------------- PARTE A: banco

# Losa de asfalto de pruebas: cuerpo estático llamado TRM-BRC para que el controlador la
# reconozca como asfalto, plana y sin nada alrededor.
func _build_pad() -> void:
	var pad := StaticBody3D.new()
	pad.name = "TRM-BRC banco de subviraje"
	pad.collision_layer = 1
	pad.collision_mask = 0
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(PAD_HALF * 2.0, 40.0, PAD_HALF * 2.0)
	collision.shape = box
	pad.add_child(collision)
	pad.position = Vector3(0.0, PAD_HEIGHT - 20.0, 0.0)
	race.add_child(pad)


func _parte_a() -> void:
	print("SUBVIRAJE INFO banco: losa plana de asfalto, mando por el canal táctil real")
	print("SUBVIRAJE INFO recorrido del mando -> demanda: 20%%->%.3f  40%%->%.3f  60%%->%.3f  70%%->%.3f  80%%->%.3f  100%%->%.3f" % [
		float(ui._steering_curve(0.2)), float(ui._steering_curve(0.4)), float(ui._steering_curve(0.6)),
		float(ui._steering_curve(0.7)), float(ui._steering_curve(0.8)), float(ui._steering_curve(1.0))])
	for kph in SPEEDS_KPH:
		var escalera: Array = STICKS_240 if kph >= 240.0 else STICKS
		for stick in escalera:
			await _medir_banco(float(kph), float(stick), 1.0)
	# El mismo recorrido a la izquierda, para comprobar la simetría del reparto.
	for stick in STICKS:
		await _medir_banco(120.0, float(stick), -1.0)
	for stick in STICKS:
		var derecha := _fila_de(120.0, float(stick), 1.0)
		var izquierda := _fila_de(120.0, float(stick), -1.0)
		if derecha.is_empty() or izquierda.is_empty():
			continue
		var peor: float = absf(float(derecha["g"]) - float(izquierda["g"])) / maxf(absf(float(derecha["g"])), 1e-6)
		check(peor <= MAX_DIFERENCIA_IZQ_DER,
			"a 120 km/h gira igual a izquierda y derecha con el %.0f %% del mando (%.2f g frente a %.2f g, %.0f %%)" % [
				float(stick) * 100.0, float(derecha["g"]), float(izquierda["g"]), peor * 100.0])


func _fila_de(kph: float, stick: float, lado: float) -> Dictionary:
	for fila in banco:
		if absf(float(fila["kph"]) - kph) < 0.001 and absf(float(fila["stick"]) - stick) < 0.001 and absf(float(fila["lado"]) - lado) < 0.001:
			return fila
	return {}


func _medir_banco(kph: float, stick: float, lado: float) -> void:
	var target: float = kph / 3.6
	car.recover_to(Vector3(0.0, PAD_HEIGHT + 0.4, -float(APPROACH_TICKS) * 0.02), 0.0)
	car.velocity = Vector3.ZERO
	_demand(0.0, 0.0, 0.0)
	for i in 30:
		await physics_frame
	# Aproximación: se alcanza la velocidad pedida en línea recta.
	var settled := 0
	for tick in APPROACH_TICKS:
		await physics_frame
		_speed_control(target)
		if absf(car.speed_mps - target) <= SPEED_TOLERANCE:
			settled += 1
			if settled > 90:
				break
		else:
			settled = 0
	var demanda: float = float(ui._steering_curve(stick)) * lado
	var last_yaw := car.rotation.y
	var samples: Array = []
	var walls := 0
	for tick in CORNER_TICKS:
		_speed_control(target)
		car.set_meta("touch_steer", demanda)
		await physics_frame
		var yaw := car.rotation.y
		var yaw_rate := wrapf(yaw - last_yaw, -PI, PI) / TICK
		last_yaw = yaw
		samples.append({"speed": car.speed_mps, "yaw_rate": yaw_rate, "angle": car.steering_angle,
			"limit_g": car.debug_lateral_limit_g, "front_g": car.debug_front_limit_g,
			"rear_g": car.debug_rear_limit_g, "front_load": car.debug_front_load_fraction,
			"lean": car.debug_lean_steer, "grip": car.debug_grip_steer, "max": car.debug_max_steer})
		for i in car.get_slide_collision_count():
			var collision := car.get_slide_collision(i)
			if _group_of(collision.get_collider() as Node) == "WALL" and absf(collision.get_normal().y) < 0.7:
				walls += 1
	var g_sum := 0.0
	var yaw_sum := 0.0
	var speed_sum := 0.0
	var angle_sum := 0.0
	var peak := 0.0
	var yaw_values: Array = []
	for index in samples.size():
		var sample: Dictionary = samples[index]
		var speed: float = sample["speed"]
		var yaw_rate: float = absf(sample["yaw_rate"])
		peak = maxf(peak, speed * yaw_rate / 9.81)
		if index >= SUSTAINED_FROM:
			g_sum += speed * yaw_rate / 9.81
			yaw_sum += yaw_rate
			speed_sum += speed
			angle_sum += absf(float(sample["angle"]))
			yaw_values.append(yaw_rate)
	var cuenta := maxf(1.0, float(samples.size() - SUSTAINED_FROM))
	var g := g_sum / cuenta
	var mean_yaw := yaw_sum / cuenta
	var mean_speed := speed_sum / cuenta
	var aplicado := angle_sum / cuenta
	var oscillation := 0.0
	if mean_yaw > 0.0001:
		var spread := 0.0
		for value in yaw_values:
			spread = maxf(spread, absf(float(value) - mean_yaw))
		oscillation = spread / mean_yaw
	var radius := 100000.0
	if mean_yaw > 0.0001:
		radius = mean_speed / mean_yaw
	# Radio geométrico: el que piden las ruedas giradas ese ángulo, con la batalla del
	# coche. Es lo que el volante está ordenando.
	var radius_geo := 100000.0
	if aplicado > 0.0001:
		radius_geo = car.wheelbase_m / tan(aplicado)
	var margen := radius / maxf(radius_geo, 0.001)
	var last: Dictionary = samples[samples.size() - 1]
	# Cuál de los dos límites fija el tope de esa velocidad.
	var tope_fijado_por := "recorrido"
	if float(last["grip"]) * 1.25 < float(last["lean"]):
		tope_fijado_por = "agarre"
	_demand(0.0, 0.0, 0.0)
	for i in 60:
		await physics_frame
	banco.append({
		"kph": kph, "stick": stick, "lado": lado, "g": g, "peak_g": peak, "radius": radius,
		"radius_geo": radius_geo, "margen": margen, "aplicado_deg": rad_to_deg(aplicado),
		"tope_deg": rad_to_deg(float(last["max"])), "lean_deg": rad_to_deg(float(last["lean"])),
		"grip_deg": rad_to_deg(float(last["grip"])), "tope_fijado_por": tope_fijado_por,
		"limit_g": float(last["limit_g"]), "front_g": float(last["front_g"]),
		"rear_g": float(last["rear_g"]), "front_load": float(last["front_load"]),
		"oscillation": oscillation, "walls": walls,
	})
	print("SUBVIRAJE BANCO %3.0f km/h mando=%3.0f%% aplicado=%5.2f° tope=%5.2f° [lean %5.2f° agarre %5.2f°] fija=%s agarre_disponible=%.2f g g_sostenida=%.3f radio=%.0f m radio_geometrico=%.0f m margen=%.3f eje_delantero=%.2f g eje_trasero=%.2f g carga_delantera=%.2f oscilacion=%.2f muros=%d" % [
		kph, stick * 100.0, rad_to_deg(aplicado), rad_to_deg(float(last["max"])),
		rad_to_deg(float(last["lean"])), rad_to_deg(float(last["grip"])), tope_fijado_por,
		float(last["limit_g"]), g, radius, radius_geo, margen, float(last["front_g"]),
		float(last["rear_g"]), float(last["front_load"]), oscillation, walls])
	check(walls == 0, "sin contacto con muro en el banco a %.0f km/h con el %.0f %% del mando" % [kph, stick * 100.0])
	check(oscillation <= MAX_OSCILACION,
		"régimen regular sin oscilar a %.0f km/h con el %.0f %% del mando (%.2f)" % [kph, stick * 100.0, oscillation])
	if stick >= 0.999:
		check(margen <= MAX_MARGEN_SUBVIRAJE,
			"con el mando a fondo a %.0f km/h la trayectoria no se abre más de un %.0f %% respecto al ángulo de las ruedas (margen %.3f: radio real %.0f m de %.0f m geométricos)" % [
				kph, (MAX_MARGEN_SUBVIRAJE - 1.0) * 100.0, margen, radius, radius_geo])
	if absf(stick - MANDO_CURVA_REAL) < 0.001 and lado > 0.0:
		check(margen <= MAX_MARGEN_MEDIO,
			"con el %.0f %% del mando a %.0f km/h el coche describe el radio que piden las ruedas, sin subviraje escondido (margen %.3f: radio real %.0f m de %.0f m geométricos)" % [
				stick * 100.0, kph, margen, radius, radius_geo])


# Agarre sostenido con un recorrido dado, interpolado entre las velocidades medidas.
func _a_para(stick: float, speed_mps: float) -> float:
	var tabla: Array = []
	for kph in SPEEDS_KPH:
		var fila := _fila_de(kph, stick, 1.0)
		if not fila.is_empty():
			tabla.append({"v": kph / 3.6, "g": float(fila["g"])})
	if tabla.is_empty():
		return 0.0
	if speed_mps <= float(tabla[0]["v"]):
		return float(tabla[0]["g"])
	for i in range(1, tabla.size()):
		if speed_mps <= float(tabla[i]["v"]):
			var a: Dictionary = tabla[i - 1]
			var b: Dictionary = tabla[i]
			var t: float = (speed_mps - float(a["v"])) / maxf(float(b["v"]) - float(a["v"]), 1e-6)
			return lerpf(float(a["g"]), float(b["g"]), t)
	return float(tabla[tabla.size() - 1]["g"])


# V70: la velocidad a la que el coche describe exactamente el radio dado con el 70 % del
# recorrido del mando. La capacidad depende de la velocidad (carga aerodinámica), así que
# se resuelve iterando tres veces, como la velocidad ideal de la línea.
func _v70(radio: float) -> float:
	var v := sqrt(maxf(_a_para(MANDO_CURVA_REAL, 30.0), 0.1) * 9.81 * radio)
	for _iteration in 3:
		v = sqrt(maxf(_a_para(MANDO_CURVA_REAL, v), 0.1) * 9.81 * radio)
	return v


# Capacidad exigida (g) a una velocidad, interpolada de la tabla de aceptación.
func _a_exigida(speed_mps: float) -> float:
	var kph := speed_mps * 3.6
	var first: Dictionary = TECHO_EXIGIDO[0]
	if kph <= float(first["kph"]):
		return float(first["g"])
	for i in range(1, TECHO_EXIGIDO.size()):
		var a: Dictionary = TECHO_EXIGIDO[i - 1]
		var b: Dictionary = TECHO_EXIGIDO[i]
		if kph <= float(b["kph"]):
			var span := maxf(float(b["kph"]) - float(a["kph"]), 1e-6)
			return lerpf(float(a["g"]), float(b["g"]), (kph - float(a["kph"])) / span)
	return float(TECHO_EXIGIDO[TECHO_EXIGIDO.size() - 1]["g"])


# Velocidad exigida en una curva: la que permite la capacidad EXIGIDA con el 70 % del
# recorrido del mando. Es el criterio «cerrar la curva sin llevar el joystick al tope»
# puesto en km/h, y no depende de la medida del coche.
func _v_exigida(radio: float) -> float:
	var factor: float = float(ui._steering_curve(MANDO_CURVA_REAL)) * MARGEN_DEL_TOPE
	var v := sqrt(maxf(_a_exigida(30.0), 0.1) * 9.81 * radio * factor)
	for _iteration in 4:
		v = sqrt(maxf(_a_exigida(v), 0.1) * 9.81 * radio * factor)
	return v


func _techos() -> void:
	for kph in SPEEDS_KPH:
		var mejor := 0.0
		var radio_minimo := 100000.0
		for fila in banco:
			if absf(float(fila["kph"]) - kph) > 0.001 or float(fila["lado"]) < 0.0:
				continue
			if float(fila["g"]) > mejor:
				mejor = float(fila["g"])
				radio_minimo = float(fila["radius"])
		var recorrido := 1.0
		for fila in banco:
			if absf(float(fila["kph"]) - kph) > 0.001 or float(fila["lado"]) < 0.0:
				continue
			if float(fila["g"]) >= mejor * 0.95 and float(fila["stick"]) <= recorrido:
				recorrido = float(fila["stick"])
		var fila_tope := _fila_de(kph, recorrido, 1.0)
		techos[kph] = {
			"g": mejor, "recorrido": recorrido, "radio_minimo": radio_minimo,
			"fija": String(fila_tope.get("tope_fijado_por", "?")),
			"limit_g": float(fila_tope.get("limit_g", 0.0)),
			"front_g": float(fila_tope.get("front_g", 0.0)),
			"rear_g": float(fila_tope.get("rear_g", 0.0)),
			"g70": float(_a_para(MANDO_CURVA_REAL, kph / 3.6)),
		}
		print("SUBVIRAJE TECHO %3.0f km/h agarre=%.2f g (disponible %.2f g: eje delantero %.2f g + trasero %.2f g) recorrido_para_el_tope=%.0f%% agarre_con_70%%=%.2f g radio_minimo=%.0f m lo_fija=%s" % [
			kph, float(techos[kph]["g"]), float(techos[kph]["limit_g"]), float(techos[kph]["front_g"]),
			float(techos[kph]["rear_g"]), float(techos[kph]["recorrido"]) * 100.0,
			float(techos[kph]["g70"]), float(techos[kph]["radio_minimo"]), String(techos[kph]["fija"])])


# ------------------------------------------------------------------ PARTE B: curvas

func _radio(indice: int) -> float:
	var count := puntos.size()
	var before := puntos[(indice - 1 + count) % count]
	var current := puntos[indice]
	var after := puntos[(indice + 1) % count]
	var incoming := (current - before).normalized()
	var outgoing := (after - current).normalized()
	var segment := maxf(current.distance_to(after), 0.001)
	var turn := acos(clampf(incoming.dot(outgoing), -1.0, 1.0)) / segment
	return 1.0 / maxf(turn, 1.0e-4)


func _radio_mediana(indice: int, half: int) -> float:
	var valores: Array = []
	for k in range(-half, half + 1):
		valores.append(_radio(posmod(indice + k, puntos.size())))
	valores.sort()
	return float(valores[valores.size() / 2])


# Radio del punto MÁS CERRADO del entorno del vértice: una curva no se pasa por su radio
# medio, se pasa por su vértice, y es ahí donde el coche se abre. Se busca sobre la mediana
# suavizada para que el ruido del muestreo no invente un vértice que no existe.
func _radio_minima(indice: int, half: int) -> float:
	var mejor := INF
	for k in range(-half, half + 1):
		mejor = minf(mejor, _radio_mediana(posmod(indice + k, puntos.size()), 3))
	return mejor


# Vértices de la trazada: los puntos donde el radio es el más cerrado de su entorno.
func _vertices() -> Array:
	var count := puntos.size()
	var out: Array = []
	for i in count:
		var r := _radio(i)
		var es_vertice := true
		for k in range(-APEX_VENTANA, APEX_VENTANA + 1):
			if k == 0:
				continue
			if _radio(posmod(i + k, count)) < r:
				es_vertice = false
				break
		if es_vertice:
			out.append({"indice": i, "radio": r})
	return out


func _elegir_vertices() -> Array:
	var vertices := _vertices()
	var elegidos: Array = []
	for curva in CURVAS:
		var objetivo := float(curva["radio"])
		var mejor := -1
		var mejor_error := INF
		var mejor_radio := 0.0
		for vertice in vertices:
			var indice: int = int(vertice["indice"])
			var usado := false
			for ya in elegidos:
				if absi(int(ya["indice"]) - indice) < 60:
					usado = true
					break
			if usado:
				continue
			var r := _radio_mediana(indice, 4)
			var error: float = absf(r - objetivo)
			if error < mejor_error:
				mejor_error = error
				mejor = indice
				mejor_radio = r
		if mejor >= 0:
			elegidos.append({"nombre": String(curva["nombre"]), "indice": mejor, "radio": mejor_radio})
	return elegidos


func _avanzar(indice: int, metros: float, hacia_atras: bool) -> int:
	var count := puntos.size()
	var recorrido := 0.0
	var actual := indice
	while recorrido < metros:
		var siguiente := (actual - 1 + count) % count if hacia_atras else (actual + 1) % count
		recorrido += puntos[actual].distance_to(puntos[siguiente])
		actual = siguiente
	return actual


# Signo del giro en un punto: +1 si la curva tira a la IZQUIERDA de la marcha, -1 si a la
# derecha. Sale de la segunda diferencia de la trazada (apunta al centro de la curva)
# proyectada sobre la normal izquierda.
func _signo_giro(indice: int) -> float:
	var count := puntos.size()
	var centro := puntos[(indice + 1) % count] + puntos[(indice - 1 + count) % count] - puntos[indice] * 2.0
	var tangente := (puntos[(indice + 1) % count] - puntos[(indice - 1 + count) % count]).normalized()
	var izquierda := Vector3(tangente.z, 0.0, -tangente.x).normalized()
	return signf(Vector2(centro.x, centro.z).dot(Vector2(izquierda.x, izquierda.z)))


func _parte_b() -> void:
	print("SUBVIRAJE INFO curvas: el coche ENTRA sobre la trazada a la velocidad de la prueba y sigue la línea con el mando topado al %.0f %% del recorrido" % (MANDO_CURVA_REAL * 100.0))
	for curva in _elegir_vertices():
		var vertice: int = int(curva["indice"])
		var radio: float = float(curva["radio"])
		var ideal: float = float(linea.speed_ideal[vertice])
		# La exigencia se calcula sobre el punto MÁS CERRADO de la curva, no sobre su radio
		# medio: si el coche sostiene el vértice, sostiene la curva.
		var radio_vertice := _radio_minima(vertice, APEX_VENTANA)
		var v70 := _v70(radio_vertice)
		# Velocidad de la prueba: la EXIGIDA (la capacidad de la tabla con el 70 % del mando)
		# y, si la línea de asistencia pide más, la de la línea. No se prueba a la capacidad
		# propia V70: el criterio es «cerrar la curva SIN llevar el joystick al máximo», así
		# que probar justo en el borde de la propia capacidad sería contradecirse.
		var exigida := _v_exigida(radio_vertice)
		var prueba := maxf(exigida, ideal)
		var entrada := _avanzar(vertice, 39.0, true)
		var salida := _avanzar(vertice, 45.0, false)
		var giro := _signo_giro(vertice)
		var resultado: Dictionary = await _tramo(prueba, entrada, vertice, salida, giro, MODO_SOSTENER, entrada)
		print("SUBVIRAJE CURVA %s radio_medio=%.0f m radio_del_vertice=%.0f m v70=%.0f km/h (con el 70 %% del mando) velocidad_exigida=%.0f km/h velocidad_ideal_de_la_linea=%.0f km/h velocidad_de_la_prueba=%.0f km/h velocidad_media_medida=%.0f km/h mando_maximo_necesario=%.2f desvio_hacia_fuera_max=%.2f m desvio_en_el_vertice=%.2f m radio_real=%.0f m g_max=%.2f g_media=%.2f deriva_lateral_max=%.2f m/s mando_topado=%3.0f%% del tiempo superficie=%s muros=%d" % [
			String(curva["nombre"]), radio, radio_vertice, v70 * 3.6, exigida * 3.6, ideal * 3.6, prueba * 3.6,
			float(resultado["velocidad"]) * 3.6, float(resultado["mando_max"]),
			float(resultado["fuera_max"]), float(resultado["fuera_vertice"]),
			float(resultado["radio_real"]), float(resultado["g_max"]), float(resultado["g"]),
			float(resultado["deriva_max"]),
			float(resultado["topeados"]) * 100.0, String(resultado["superficie"]), int(resultado["walls"])])
		check(float(resultado["fuera_max"]) <= DESVIO_FUERA_MAX_M,
			"en la curva %s (radio %.0f m) a %.0f km/h el coche CIERRA con el %.0f %% del mando: se abre %.2f m hacia fuera (tope %.1f m)" % [
				String(curva["nombre"]), radio, prueba * 3.6, MANDO_CURVA_REAL * 100.0,
				float(resultado["fuera_max"]), DESVIO_FUERA_MAX_M])
		check(float(resultado["mando_max"]) <= MANDO_MAX_EXIGIDO,
			"en la curva %s (%.0f km/h) al coche le basta el %.0f %% del recorrido del mando, con el tope al %.0f %%: el pico pedido fue %.0f %%" % [
				String(curva["nombre"]), prueba * 3.6, MANDO_MAX_EXIGIDO * 100.0, 100.0,
				float(resultado["mando_max"]) * 100.0])
		check(v70 >= exigida,
			"en la curva %s (vértice de %.0f m) el coche cierra con el 70 %% del mando a la velocidad exigida de %.0f km/h (V70 medida %.0f km/h)" % [
				String(curva["nombre"]), radio_vertice, exigida * 3.6, v70 * 3.6])
		check(int(resultado["walls"]) == 0 and int(resultado["vueltas"]) == 0,
			"sin muro ni trompo en la curva %s" % String(curva["nombre"]))
		check(float(resultado["deriva_max"]) <= DERIVA_MAX_M_S,
			"sin derrape sostenido en la curva %s (deslizamiento lateral máximo %.2f m/s, tope %.2f)" % [
				String(curva["nombre"]), float(resultado["deriva_max"]), DERIVA_MAX_M_S])
	await _parte_c()


# Escenarios de pedal y de transición que pide el encargo. La curva MEDIA es el banco: con
# el acelerador puesto la velocidad sube y el desvío con ella, así que aquí lo que se exige
# no es el desvío sino que el coche siga obedeciendo, no se cruce y no toque muro.
func _parte_c() -> void:
	print("SUBVIRAJE INFO escenarios de pedal y transición, curva media, mando topado al %.0f %% del recorrido" % (MANDO_CURVA_REAL * 100.0))
	var media := {}
	for curva in _elegir_vertices():
		if String(curva["nombre"]) == "media":
			media = curva
	if media.is_empty():
		return
	var vertice: int = int(media["indice"])
	var exigida := _v_exigida(float(media["radio"]))
	var entrada := _avanzar(vertice, 39.0, true)
	var salida := _avanzar(vertice, 45.0, false)
	var giro := _signo_giro(vertice)
	# La salida de la curva se mide más lejos que en la parte B (90 m en vez de 45): el
	# pedal necesita distancia para notarse, y una salida que sólo dura 45 m no da tiempo a
	# nada —ni al coche ni a la medida—.
	# La salida se mide al menos 70 m después del vértice para que el pedal tenga donde
	# notarse, y no más allá de donde la curva se abre (para no invadir la siguiente).
	var salida_larga := _fin_de_curva(vertice, float(media["radio"]), 90.0)
	if _arco_entre(vertice, salida_larga) < 70.0:
		salida_larga = _avanzar(vertice, 70.0, false)
	var con_gas: Dictionary = await _tramo(exigida, entrada, vertice, salida_larga, giro, MODO_GAS, entrada)
	print("SUBVIRAJE ESCENARIO entrada_con_acelerador v_entrada=%.0f km/h v_media=%.0f km/h v_salida=%.0f km/h desvio_hacia_fuera_max=%.2f m deriva_lateral_max=%.2f m/s vueltas=%d muros=%d superficie=%s" % [
		exigida * 3.6, float(con_gas["velocidad"]) * 3.6, float(con_gas["velocidad_salida"]) * 3.6,
		float(con_gas["fuera_max"]), float(con_gas["deriva_max"]), int(con_gas["vueltas"]), int(con_gas["walls"]),
		String(con_gas["superficie"])])
	check(float(con_gas["velocidad_salida"]) > exigida + 2.0 and int(con_gas["vueltas"]) == 0 and int(con_gas["walls"]) == 0,
		"entrando con el acelerador a fondo y girando, el coche gana velocidad (%.0f km/h de salida frente a %.0f de entrada) sin cruzarse ni tocar muro" % [
			float(con_gas["velocidad_salida"]) * 3.6, exigida * 3.6])
	var sin_gas: Dictionary = await _tramo(exigida, entrada, vertice, salida_larga, giro, MODO_SIN_GAS, entrada)
	print("SUBVIRAJE ESCENARIO entrada_soltando_el_acelerador v_media=%.0f km/h v_salida=%.0f km/h g_media=%.2f deriva_lateral_max=%.2f m/s vueltas=%d muros=%d superficie=%s" % [
		float(sin_gas["velocidad"]) * 3.6, float(sin_gas["velocidad_salida"]) * 3.6, float(sin_gas["g"]),
		float(sin_gas["deriva_max"]), int(sin_gas["vueltas"]), int(sin_gas["walls"]), String(sin_gas["superficie"])])
	check(int(sin_gas["vueltas"]) == 0 and int(sin_gas["walls"]) == 0 and float(sin_gas["velocidad_salida"]) < exigida - 2.0,
		"soltando el acelerador en la entrada el coche pierde velocidad (%.0f km/h de salida frente a %.0f de entrada) y sigue girando (%.2f g de media) sin cruzarse" % [
			float(sin_gas["velocidad_salida"]) * 3.6, exigida * 3.6, float(sin_gas["g"])])
	var salida_gas: Dictionary = await _tramo(exigida, entrada, vertice, salida_larga, giro, MODO_SALIDA, entrada)
	print("SUBVIRAJE ESCENARIO salida_acelerando_progresivo v_media=%.0f km/h v_salida=%.0f km/h deriva_lateral_max=%.2f m/s vueltas=%d muros=%d superficie=%s" % [
		float(salida_gas["velocidad"]) * 3.6, float(salida_gas["velocidad_salida"]) * 3.6,
		float(salida_gas["deriva_max"]), int(salida_gas["vueltas"]), int(salida_gas["walls"]),
		String(salida_gas["superficie"])])
	check(float(salida_gas["velocidad_salida"]) > float(sin_gas["velocidad_salida"]) + 20.0 and int(salida_gas["vueltas"]) == 0,
		"acelerando progresivo desde el vértice el coche gana velocidad frente a soltar el pedal (%.0f km/h de salida frente a %.0f) sin cruzarse" % [
			float(salida_gas["velocidad_salida"]) * 3.6, float(sin_gas["velocidad_salida"]) * 3.6])
	var con_freno: Dictionary = await _tramo(exigida, entrada, vertice, salida_larga, giro, MODO_FRENO, entrada)
	print("SUBVIRAJE ESCENARIO freno_mientras_gira v_media=%.0f km/h v_salida=%.0f km/h deriva_lateral_max=%.2f m/s vueltas=%d muros=%d superficie=%s" % [
		float(con_freno["velocidad"]) * 3.6, float(con_freno["velocidad_salida"]) * 3.6,
		float(con_freno["deriva_max"]), int(con_freno["vueltas"]), int(con_freno["walls"]),
		String(con_freno["superficie"])])
	check(float(con_freno["velocidad_salida"]) < exigida - 5.0 and float(con_freno["velocidad_salida"]) > 5.0 and int(con_freno["vueltas"]) == 0,
		"frenando a mitad de curva el coche frena (%.0f km/h de salida frente a %.0f de entrada) y sigue rodando, sin cruzarse" % [
			float(con_freno["velocidad_salida"]) * 3.6, exigida * 3.6])
	# Transición entre curvas de sentidos opuestos: se conduce desde antes del vértice de la
	# primera hasta pasado el de la segunda con el mismo tope de mando, y se mide el desvío
	# de la SEGUNDA (que es donde se paga haber entrado mal en la primera).
	var ese := _ese()
	if ese.is_empty():
		info("el circuito no ofrece dos curvas de sentidos opuestos a menos de 400 m: transición no medida")
		return
	var primera: int = int(ese[0])
	var segunda: int = int(ese[1])
	var radio_segunda := _radio_minima(segunda, APEX_VENTANA)
	var radio_primera := _radio_minima(primera, APEX_VENTANA)
	# Se conduce a la velocidad EXIGIDA por la más lenta de las dos curvas (no a la capacidad
	# propia del coche): probar en el borde de la capacidad propia convierte la transición en
	# un ejercicio de derrape, que no es lo que se pide.
	var prueba := minf(_v_exigida(radio_primera), _v_exigida(radio_segunda))
	var resultado: Dictionary = await _tramo(prueba, _avanzar(primera, 40.0, true), segunda,
		_avanzar(segunda, 45.0, false), _signo_giro(segunda), MODO_SOSTENER, _avanzar(segunda, 39.0, true))
	var ideal_minima := INF
	var indice_ideal := _avanzar(primera, 40.0, true)
	var indice_final := _avanzar(segunda, 45.0, false)
	while indice_ideal != indice_final:
		ideal_minima = minf(ideal_minima, float(linea.speed_ideal[indice_ideal]))
		indice_ideal = (indice_ideal + 1) % puntos.size()
	print("SUBVIRAJE TRANSICION radio_1=%.0f m radio_2=%.0f m separacion=%.0f m velocidad_ideal_minima_del_tramo=%.0f km/h velocidad=%.0f km/h desvio_hacia_fuera_max_en_la_2=%.2f m deriva_lateral_max=%.2f m/s vueltas=%d muros=%d superficie=%s" % [
		radio_primera, radio_segunda, _arco_entre(primera, segunda), ideal_minima * 3.6, prueba * 3.6,
		float(resultado["fuera_max"]), float(resultado["deriva_max"]), int(resultado["vueltas"]),
		int(resultado["walls"]), String(resultado["superficie"])])
	check(float(resultado["fuera_max"]) <= DESVIO_FUERA_MAX_M and int(resultado["vueltas"]) == 0 and int(resultado["walls"]) == 0,
		"encadenando dos curvas de sentidos opuestos a %.0f km/h con el %.0f %% del mando el coche cierra la segunda (se abre %.2f m) sin cruzarse ni tocar muro" % [
			prueba * 3.6, MANDO_CURVA_REAL * 100.0, float(resultado["fuera_max"])])


# Punto donde la curva se puede dar por terminada: el primero en el que el radio se abre a
# más del doble del vértice, con un tope de metros por si la curva se encadena con otra.
# Sirve para medir la salida sin invadir la curva siguiente.
func _fin_de_curva(vertice: int, radio: float, max_metros: float) -> int:
	var count := puntos.size()
	var recorrido := 0.0
	var actual := vertice
	while recorrido < max_metros:
		var siguiente := (actual + 1) % count
		recorrido += puntos[actual].distance_to(puntos[siguiente])
		actual = siguiente
		if _radio_mediana(actual, 3) > radio * 2.0:
			break
	return actual# Par de vértices de sentidos opuestos (una ese) para la prueba de transición. Se busca la
# pareja de EXIGENCIAS PARECIDAS: encadenar dos curvas de sentidos opuestos a una sola
# velocidad sólo tiene sentido si las dos piden algo parecido, porque si la primera es mucho
# más lenta el ejercicio deja de ser una transición y pasa a ser llegar demasiado rápido a
# una curva que no toca —que es exactamente lo que pasaba con la primera pareja elegida
# (50 m de radio pidiendo 78 km/h y la segunda pidiendo 154)—.
func _ese() -> Array:
	var vertices := _vertices()
	var mejor: Array = []
	var mejor_diferencia := INF
	for i in vertices.size():
		for j in range(i + 1, mini(i + 5, vertices.size())):
			var a: int = int(vertices[i]["indice"])
			var b: int = int(vertices[j]["indice"])
			if _signo_giro(a) * _signo_giro(b) >= 0.0:
				continue
			var radio_a := _radio_minima(a, APEX_VENTANA)
			var radio_b := _radio_minima(b, APEX_VENTANA)
			# Los dos vértices tienen que ser curvas de verdad: la lista incluye puntos
			# donde la mediana del radio es un tramo casi recto (2.000 m), y emparejar dos
			# de esos no es una ese.
			if radio_a > 400.0 or radio_b > 400.0 or radio_a < 25.0 or radio_b < 25.0:
				continue
			var arco := _arco_entre(a, b)
			if arco < 60.0 or arco > 300.0:
				continue
			var diferencia := absf(_v_exigida(radio_a) - _v_exigida(radio_b))
			if diferencia < mejor_diferencia:
				mejor_diferencia = diferencia
				mejor = [a, b]
	return mejor


# Un tramo conducido desde un punto de la trazada hasta otro, con el mando TOPADO al 70 %
# del recorrido y el pedal según el escenario. El coche se coloca SOBRE la trazada, mirando
# por donde va y A LA VELOCIDAD DE LA PRUEBA: una aproximación larga cruzaba otras curvas y
# llegaba a la entrada con otra velocidad, con lo que la curva se medía a escondidas a una
# velocidad distinta de la exigida. Lo que se mide es lo que produce la dirección, no cómo
# se llegó hasta aquí. Devuelve el desvío HACIA FUERA (positivo = se abre) respecto a la
# trazada desde `desde_desvio`, el deslizamiento lateral, la oscilación de guiñada y los
# trompos contados como instantes con el morro a más de 45° de la trazada.
func _tramo(prueba: float, entrada: int, vertice: int, salida: int, giro: float,
		modo: int, desde_desvio: int) -> Dictionary:
	var tangente := (puntos[(entrada + 1) % puntos.size()] - puntos[entrada]).normalized()
	car.recover_to(puntos[entrada], atan2(-tangente.x, -tangente.z))
	car.velocity = Vector3.ZERO
	_demand(0.0, 0.0, 0.0)
	for i in 30:
		await physics_frame
	car.velocity = -car.global_transform.basis.z * prueba
	for i in 12:
		await physics_frame
	var nearest := entrada
	var arco := 0.0
	var arco_salida := _arco_entre(entrada, salida)
	var arco_vertice := _arco_entre(entrada, vertice)
	var arco_desde := _arco_entre(entrada, desde_desvio)
	var limite: float = float(ui._steering_curve(MANDO_CURVA_REAL))
	var fuera_max := 0.0
	var fuera_vertice := 0.0
	var g_max := 0.0
	var g_sum := 0.0
	var yaw_sum := 0.0
	var speed_sum := 0.0
	var cuenta := 0
	var deriva_max := 0.0
	var mando_max := 0.0
	var vueltas := 0
	var walls := 0
	var contactos := 4
	var topeados := 0
	var yaw_values: Array = []
	var last_yaw := car.rotation.y
	var pasos := 0
	# El tramo termina al salir del punto de medida, o antes si el coche se ha quedado
	# parado (soltar el pedal deja el coche frenado por el propio modelo, y esperar los
	# 4.500 fotogramas restantes sólo alargaba la sonda sin medir nada nuevo).
	while arco <= arco_salida and pasos < 4500 and car.speed_mps > 1.5:
		pasos += 1
		match modo:
			MODO_GAS:
				_demand(1.0, 0.0, 0.0)
			MODO_SIN_GAS:
				_demand(0.0, 0.0, 0.0)
			MODO_SALIDA:
				# El pedal se aprieta progresivamente DESDE el vértice (empieza 10 m antes y
				# llega al fondo 10 m después), que es lo que hace un piloto: esperar a salir
				# de la curva para pisar deja al coche frenado por su propio modelo.
				if arco >= arco_vertice - 10.0:
					_demand(clampf((arco - arco_vertice + 10.0) / 20.0, 0.0, 1.0), 0.0, 0.0)
				else:
					_speed_control(prueba)
			MODO_FRENO:
				# Freno de verdad, no una clavada de pedal: el objetivo baja al 70 % de la
				# velocidad de entrada, que es lo que hace quien frena de apoyo en mitad de
				# una curva.
				if arco >= arco_vertice:
					_speed_control(prueba * 0.7)
				else:
					_speed_control(prueba)
			_:
				_speed_control(prueba)
		_perseguir(nearest, limite)
		topeados += int(ultimo_limite_alcanzado)
		mando_max = maxf(mando_max, float(ui.steering_travel_for(ultimo_pedido_sin_tope)))
		await physics_frame
		var previo := nearest
		nearest = _cercano(previo)
		var paso := _arco_entre(previo, nearest)
		if paso <= 60.0:
			arco += paso
		var yaw := car.rotation.y
		var yaw_rate := wrapf(yaw - last_yaw, -PI, PI) / TICK
		last_yaw = yaw
		var g: float = float(car.speed_mps) * absf(yaw_rate) / 9.81
		g_max = maxf(g_max, g)
		g_sum += g
		yaw_sum += absf(yaw_rate)
		yaw_values.append(absf(yaw_rate))
		speed_sum += car.speed_mps
		cuenta += 1
		contactos = mini(contactos, car.wheel_contacts)
		# Deslizamiento lateral: la velocidad lateral del cuerpo. En una curva sostenida es
		# casi cero, porque el coche gira de morro; si crece, el eje trasero está derrapando.
		deriva_max = maxf(deriva_max, absf(car.velocity.dot(car.global_transform.basis.x)))
		# Trompo: el morro a más de 45° de la trazada.
		var tangente_actual := (puntos[(nearest + 1) % puntos.size()] - puntos[nearest]).normalized()
		var morro := -car.global_transform.basis.z
		if absf(rad_to_deg(morro.signed_angle_to(tangente_actual, Vector3.UP))) > ANGULO_TROMPO_DEG:
			vueltas += 1
		# Desvío HACIA FUERA medido desde el punto pedido (en la ese, desde la entrada de la
		# segunda curva): positivo = el coche se ha ido al lado exterior, que es «abrirse».
		if arco >= arco_desde:
			var desvio := -giro * _desvio_lateral(nearest)
			fuera_max = maxf(fuera_max, desvio)
			if absi(nearest - vertice) <= 2:
				fuera_vertice = desvio
		if TRAZA and pasos % 24 == 0:
			print("SUBVIRAJE TRAZACURVA modo=%d paso=%d idx=%d arco=%.0f/%.0f v=%.0f desvio=%+.2f radio=%.0f guinada=%+.2f deriva=%.2f superficie=%s ruedas=%d" % [
				modo, pasos, nearest, arco, arco_salida, float(car.speed_mps) * 3.6, _desvio_lateral(nearest),
				float(car.speed_mps) / maxf(absf(yaw_rate), 1e-4), yaw_rate, deriva_max,
				String(car.ground_surface), int(car.wheel_contacts)])
		for i in car.get_slide_collision_count():
			var collision := car.get_slide_collision(i)
			if _group_of(collision.get_collider() as Node) == "WALL" and absf(collision.get_normal().y) < 0.7:
				walls += 1
	var velocidad_salida: float = car.speed_mps
	_demand(0.0, 0.0, 0.0)
	for i in 60:
		await physics_frame
	var media_yaw := yaw_sum / maxf(1.0, float(cuenta))
	var media_speed := speed_sum / maxf(1.0, float(cuenta))
	var radio_real := 100000.0
	if media_yaw > 0.0001:
		radio_real = media_speed / media_yaw
	var oscilacion := 0.0
	if media_yaw > 0.0001:
		var spread := 0.0
		for value in yaw_values:
			spread = maxf(spread, absf(float(value) - media_yaw))
		oscilacion = spread / media_yaw
	return {"fuera_max": fuera_max, "fuera_vertice": fuera_vertice,
		"radio_real": radio_real, "g_max": g_max, "g": g_sum / maxf(1.0, float(cuenta)),
		"velocidad": media_speed, "velocidad_salida": velocidad_salida, "mando_max": mando_max,
		"walls": walls, "contactos": contactos, "superficie": car.ground_surface,
		"deriva_max": deriva_max, "oscilacion": oscilacion, "vueltas": vueltas,
		"topeados": float(topeados) / maxf(1.0, float(pasos)), "entrada": entrada}


# Índice de la trazada más cercano al coche, mirando alrededor del último conocido.
func _cercano(ultimo: int) -> int:
	var count := puntos.size()
	var mejor := ultimo
	var mejor_d := INF
	for offset in range(-14, 34):
		var indice := posmod(ultimo + offset, count)
		var d := (puntos[indice] - car.global_position).length_squared()
		if d < mejor_d:
			mejor_d = d
			mejor = indice
	return mejor


# Longitud de arco entre dos puntos yendo hacia delante (la vuelta es cerrada).
func _arco_entre(desde: int, hasta: int) -> float:
	var count := puntos.size()
	var recorrido := 0.0
	var actual := desde
	var pasos := 0
	while actual != hasta and pasos < count:
		var siguiente := (actual + 1) % count
		recorrido += puntos[actual].distance_to(puntos[siguiente])
		actual = siguiente
		pasos += 1
	return recorrido


# Desvío lateral respecto a la trazada en ese punto, con el signo de la normal izquierda.
func _desvio_lateral(indice: int) -> float:
	var count := puntos.size()
	var tangente := (puntos[(indice + 1) % count] - puntos[(indice - 1 + count) % count]).normalized()
	var izquierda := Vector3(tangente.z, 0.0, -tangente.x).normalized()
	var delta := car.global_position - puntos[indice]
	return Vector2(delta.x, delta.z).dot(Vector2(izquierda.x, izquierda.z))


# Perseguidor puro sobre la trazada, con el mismo lazo que usa la sonda de vuelta: mira
# por delante en proporción a la velocidad y pide la dirección que lleva a ese punto.
# Escribe SÓLO la dirección: los pedales los lleva el control de velocidad.
func _perseguir(nearest: int, limite: float = 1.0) -> float:
	var count := puntos.size()
	var distance := 0.0
	var target := nearest
	var lookahead: float = 8.0 + car.speed_mps * 0.7
	while distance < lookahead:
		var next := (target + 1) % count
		distance += puntos[target].distance_to(puntos[next])
		target = next
	var local := car.to_local(puntos[target])
	var alpha := atan2(local.x, -local.z)
	var kappa := 2.0 * sin(alpha) / maxf(lookahead, 1.0)
	# Corrección por desplazamiento lateral: el perseguidor puro recorta el error de rumbo
	# pero no el desplazamiento, y en la aproximación a una curva rápida el coche llegaba al
	# punto de giro desplazado hacia fuera, con lo que la curva se medía desde fuera. Es la
	# corrección que hace cualquier conductor mirando el vértice, no un aumento de agarre.
	# Se suma como CURVATURA (2·e/L², la de un lazo de rumbo crítico), no como ángulo suelto:
	# sumar el desvío como ángulo (e/L·0,5) pedía hasta 0,7° de rueda para un desvío de 1 m,
	# tres veces y media la curvatura que cancela ese desvío, y ese exceso era el pico de
	# mando que se medía como tope (0,89 del recorrido con el coche ya dentro de la trazada).
	var desvio := _desvio_lateral(nearest)
	kappa += clampf(2.0 * desvio / maxf(lookahead * lookahead, 1.0), -0.04, 0.04)
	var wheel_angle: float = atan(float(car.wheelbase_m) * kappa)
	var steering_max := maxf(car.debug_max_steer, 0.001)
	var demand := wheel_angle / steering_max
	ultimo_pedido_sin_tope = absf(demand)
	ultimo_limite_alcanzado = absf(demand) > limite
	demand = clampf(demand, -limite, limite)
	var raw: float = float(ui.steering_travel_for(demand))
	car.set_meta("touch_steer", raw)
	return demand


# ---------------------------------------------------------------- resumen y criterios

func _resumen() -> void:
	_techos()
	# El techo de agarre tiene que llegar a la cifra exigida a cada velocidad: es el
	# criterio de aceptación del subviraje (fuerza lateral, no ángulo).
	for exigencia in TECHO_EXIGIDO:
		var kph := float(exigencia["kph"])
		var exigido := float(exigencia["g"])
		var medido := float(techos[kph]["g"]) if techos.has(kph) else 0.0
		check(medido >= exigido,
			"a %.0f km/h el coche sostiene al menos %.2f g de curva (medido %.2f g)" % [kph, exigido, medido])
	# El tope de dirección se alcanza sin llegar al final del recorrido.
	for kph in SPEEDS_KPH:
		if not techos.has(kph):
			continue
		var recorrido := float(techos[kph]["recorrido"])
		check(recorrido <= STICK_PARA_TOPE,
			"a %.0f km/h el tope de dirección se alcanza con el %.0f %% del recorrido (tope %.0f %%)" % [
				kph, recorrido * 100.0, STICK_PARA_TOPE * 100.0])
	# La respuesta crece con la velocidad (carga aerodinámica) dentro del margen declarado.
	var lento := float(techos[SPEEDS_KPH[0]]["g"]) if techos.has(SPEEDS_KPH[0]) else 0.0
	var rapido := float(techos[SPEEDS_KPH[SPEEDS_KPH.size() - 1]]["g"]) if techos.has(SPEEDS_KPH[SPEEDS_KPH.size() - 1]) else 0.0
	var ganancia := rapido / maxf(lento, 0.001)
	check(ganancia >= GANANCIA_MIN and ganancia <= GANANCIA_MAX,
		"la capacidad crece con la velocidad dentro del margen declarado: %.2f veces de %.0f a %.0f km/h (entre %.2f y %.2f)" % [
			ganancia, SPEEDS_KPH[0], SPEEDS_KPH[SPEEDS_KPH.size() - 1], GANANCIA_MIN, GANANCIA_MAX])
	print("SUBVIRAJE RESUMEN techo 60=%.2f g 120=%.2f g 180=%.2f g 240=%.2f g ganancia=%.2f fallos=%d" % [
		float(techos.get(60.0, {}).get("g", 0.0)), float(techos.get(120.0, {}).get("g", 0.0)),
		float(techos.get(180.0, {}).get("g", 0.0)), float(techos.get(240.0, {}).get("g", 0.0)), ganancia, failures])
