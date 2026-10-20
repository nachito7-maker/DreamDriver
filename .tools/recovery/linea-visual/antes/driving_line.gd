extends MeshInstance3D

# ============================================================================
# LÍNEA DINÁMICA DE ASISTENCIA A LA CONDUCCIÓN
#
# Segunda línea visual, dibujada ENCIMA de la goma de la trazada que ya trae el
# circuito, que dice qué conviene hacer con el gas y el freno:
#
#   ROJO     frenar
#   AMARILLO soltar el acelerador
#   VERDE    acelerar
#
# No toca la física: no pisa el freno, ni el acelerador, ni la dirección. Es una
# ayuda visual y sólo escribe en su propia malla y en su propia textura de estado.
#
# ---------------------------------------------------------------------------
# 1. VELOCIDAD IDEAL DE CADA PUNTO DE LA TRAZADA (se calcula UNA vez al arrancar)
# ---------------------------------------------------------------------------
#
# Para cada uno de los 3057 puntos de la trazada (paso 1,51 m) se mide el giro por
# metro contra sus vecinos, se filtra la mediana (la línea de IA tiembla punto a
# punto) y se convierte en velocidad con la capacidad lateral MEDIDA de este coche
# (sonda_direccion: 1,03 g a 60 km/h y 1,21 g a 180 km/h, con el manillar a fondo):
#
#   a_lat(v)   = 9,81 · (0,95 + 0,27 · min(v/50 m·s⁻¹, 1))     [m/s²]
#   v_ideal(i) = sqrt(0,90 · a_lat(v) · R),   R = 1/turn       [m/s], tope 360 km/h
#
# El 0,90 es el margen declarado: la velocidad ideal es el 90 % de lo que el coche
# aguanta de verdad. Cada curva tiene así SU velocidad, no una igual para todas.
#
# ---------------------------------------------------------------------------
# 2. TRES ENVOLVENTES DE FRENADA (también una sola vez)
# ---------------------------------------------------------------------------
#
# Hacia atrás sobre la vuelta completa, con tres deceleraciones distintas:
#
#   E_roja(i)   = mínimo sobre todo lo que viene detrás de
#                 sqrt(v_ideal(j)² + 2·a_roja·(s_j − s_i))
#   E_fuerte(i) = lo mismo con a = a_freno
#   E_suave(i)  = lo mismo levantando el pie: 0,45·a_freno
#
# a_freno = 28 m/s²: medido 33,02 m/s² de pico en la sonda de suspensión, y se toma el
# 85 % como referencia utilizable. La envolvente es, punto a punto, la velocidad a la
# que HAY QUE IR para poder frenar a tiempo en todas las curvas que vienen después.
# Es realizable punto a punto por construcción: E(i)² = E(i+1)² + 2·a·Δ nunca se pasa.
#
# E_roja es la que DIBUJA el tramo rojo, y usa a_roja = a_freno/(1 + antelación): la
# frenada de la que avisa es la FÍSICA con un margen declarado por delante (25 %, que
# a 300 km/h frenando a 100 son 27 m ≈ 0,33 s). E_fuerte queda como referencia de la
# física pura —la usa la sonda para medir que el rojo nunca llega tarde— y E_suave es
# el aviso de levantar el pie, que sigue estando 1/0,45 = 2,2 veces más lejos.
#
# ---------------------------------------------------------------------------
# 3. LA RECOMENDACIÓN, cada fotograma, con la velocidad real del coche
# ---------------------------------------------------------------------------
#
# En cada punto de la línea, a `ds` metros por delante del coche:
#
#   ROJO     si la velocidad del coche supera la envolvente ROJA
#   AMARILLO si supera la envolvente SUAVE (frenar cómodo, levantando el pie)
#   VERDE    en el resto
#
# El adelanto del aviso no es un margen añadido a ojo sino la DISTANCIA entre las
# envolventes: la roja se cruza 1 + antelación = 1,25 veces antes que la fuerte, y la
# suave 1/0,45 = 2,2 veces antes todavía; el descenso de esta última nunca pasa de los
# 12,6 m/s² con los que baja el coche al levantar el pie (así está construida, hacia
# atrás), de modo que quien obedece el amarillo llega al vértice a la velocidad del plan
# sin tener que frenar más fuerte.
#
# De ahí salen justo las tres cosas que se piden, y son consecuencia de la física, no
# de una secuencia escrita:
#   * El tramo rojo empieza donde la envolvente roja corta a la velocidad actual, que
#     por construcción está a (1 + antelación) veces la distancia de frenada de la
#     velocidad que lleva el coche: (v² − v_curva²)/(2·d_rojo) = a_freno/(1+antelación).
#     Es decir, empieza ANTES del punto de frenada (nunca después) y con un margen que
#     crece con la velocidad: a 300 km/h son 27 m, a 120 km/h 6 m. Si va más rápido, el
#     rojo empieza antes; si va más despacio, se acerca a la curva. La sonda comprueba
#     las dos cosas: que el rojo nunca llega tarde y que la distancia medida es esa.
#   * El tramo amarillo empieza donde corta la envolvente SUAVE, que está 1/0,45 = 2,2
#     veces más lejos: es el aviso de levantar el pie antes del punto de frenada, con
#     más margen cuanto más rápido se va (a 200 km/h, 62 m ≈ 1,1 s de aviso).
#   * El verde vuelve en cuanto la velocidad del coche queda por debajo de la cómoda,
#     que es lo que pasa al salir de la curva, cuando la ideal delante vuelve a subir.
#   * En curva a la velocidad ideal la línea está amarilla (no conviene acelerar más);
#     en cuanto el coche va por encima de la ideal de ese tramo, roja.
#
# La velocidad que entra en la comparación se filtra (τ = 0,15 s) para que el temblor
# de la rueda no mueva las bandas, y los colores se suavizan a lo largo de la línea:
# no hay saltos de color ni parpadeo.
#
# ---------------------------------------------------------------------------
# 4. GEOMETRÍA ESTÁTICA + TEXTURA DE ESTADO
# ---------------------------------------------------------------------------
#
# La malla del listón se construye UNA vez (3057 anillos, 1,51 m de paso, con la
# coordenada de arco en la UV.x). Conduciendo sólo se reescriben los ~230 texeles
# visibles de una textura de estado de 4096 (una por tramo de 1,13 m) con el color que
# toca: no se reconstruye ninguna malla ni se recorre la vuelta entera.
#
# El listón va pegado al asfalto: se separa del suelo 2 cm y el shader lo sube además
# en proporción a la distancia a la CÁMARA (0,6 mm por metro), de modo que la
# separación en el búfer de profundidad es siempre ≥ 3 veces su resolución en
# cualquier punto visible (a 10 m, 83 veces; a 200 m, 4,2 veces) mientras el
# desplazamiento en pantalla se queda en medio píxel a cualquier distancia: no hay
# z-fighting y no parece flotar.
#
# Sondas: `scripts/driving_line_probe.gd` comprueba estas cuentas sin GPU (velocidad
# ideal, envolventes, punto de frenada, monotonía con la velocidad, una vuelta
# conducida sólo con lo que dice la línea y la geometría del listón);
# `.tools/recovery/linea/capturar.gd` y `.tools/recovery/linea/linea_pixeles.py` lo
# comprueban en píxeles con la cámara real del juego.
# ============================================================================

const TrackScript := preload("res://scripts/track_data.gd")

@export_category("Geometría del listón")
# Ancho total: 0,56 m, dentro de la banda de goma del circuito (medida: 1,2-1,4 m).
@export var line_half_width_m := 0.28
# Separación del asfalto (m). Pequeña a propósito: el resto de la separación para el
# búfer de profundidad la pone el sesgo por distancia del shader.
@export var line_lift_m := 0.02
# Sesgo de profundidad por metro de distancia a la cámara (adimensional).
@export var depth_bias_per_m := 0.0006
# Hasta dónde se dibuja por delante del coche (m). La frenada más larga del circuito
# desde el techo del coche son ~135 m: 260 m cubren cualquier aviso.
@export var visible_window_m := 260.0
# Cuántos metros por detrás del coche sigue dibujada la línea.
@export var visible_tail_m := 3.0
# Texeles de la textura de estado (uno por tramo de `track_length / 4096` ≈ 1,13 m).
@export var state_texture_width := 4096

@export_category("Colores (moderados: nada de neón ni saturación plena)")
# Valores en sRGB: son los que se quieren VER. Al shader se le entregan convertidos a
# lineal, que es el espacio en el que trabaja el motor.
@export var color_accelerate := Color(0.20, 0.55, 0.27)
@export var color_hold := Color(0.87, 0.68, 0.18)
@export var color_brake := Color(0.74, 0.16, 0.13)
# Gris de la goma de la trazada: los bordes del listón se funden con ella para que no
# parezca una pegatina de color pegada encima.
@export var color_rubber := Color(0.30, 0.30, 0.30)
# Anchura relativa de esa fusión en cada borde (0 = borde duro).
@export var color_edge_blend := 0.35

@export_category("Física de la recomendación")
# Capacidad lateral medida de este coche (sonda_direccion).
@export var lateral_g_base := 0.95
@export var lateral_g_gain := 0.27
@export var lateral_g_full_kph := 180.0
# Margen de la velocidad ideal respecto a esa capacidad medida.
@export var lateral_safety := 0.90
# Tope de la velocidad ideal: por encima del techo medido del coche (97,2 m/s) para que
# en recta el objetivo sea "todo lo que da".
@export var top_speed_mps := 100.0
# Deceleración de referencia de la frenada. Medida: 33,02 m/s² de pico
# (sonda_suspension); se toma el 85 % como referencia utilizable.
@export var brake_reference_m_s2 := 28.0
# Cuánto frena la envolvente "suave": el tramo amarillo es el aviso de levantar el pie
# antes del punto de frenada, y sale de esta envolvente, que corta a la velocidad del
# coche 1/0,45 = 2,2 veces más lejos que la fuerte (a 200 km/h, 62 m de aviso).
@export var soft_brake_ratio := 0.45
# Aceleración que se le supone al conductor de referencia en la sonda funcional
# (medida: 11,49 m/s² de pico; se toma el 70 %). No interviene en los colores.
@export var accel_m_s2 := 8.0
# Antelación del tramo rojo: fracción de la distancia de frenada de referencia que se
# adelanta su inicio. El rojo se dibuja con la envolvente calculada con
# a_freno/(1 + antelación), de modo que avisa cuando la frenada disponible ya pide sólo
# el 80 % de la capacidad medida del coche: margen para decidir y empezar a frenar sin
# llegar nunca tarde. 0 dejaría el rojo EXACTAMENTE en el punto de frenada (sin margen de
# reacción); 0,25 son 27 m ≈ 0,33 s en la frenada más larga del circuito (300 → 100
# km/h) y 6 m ≈ 0,18 s en una de 120 km/h.
@export var frenada_antelacion := 0.25
# Margen del amarillo: diminuto a propósito, porque el adelanto lo da la propia
# envolvente suave (ver arriba). Medido en la sonda: cualquier adelanto añadido aquí
# deja al coche por encima del plan antes de que el color avise (con 0,15 s de adelanto,
# 0,88 m/s de exceso sobre la velocidad ideal al entrar en el vértice).
@export var hold_margin_s := 0.005
@export var hold_margin_ratio := 0.001
# Constante de tiempo del filtro de velocidad (s).
@export var speed_filter_tau := 0.15
# Suavizado de los colores a lo largo de la línea (texeles a cada lado).
@export var color_smooth_texels := 3
var turn_median_half_window := 2
var min_turn_deg_per_m := 0.02

# --- estado ------------------------------------------------------------------
var car: Node3D = null
var points := PackedVector3Array()          # trazada (centro de la calzada)
var arc := PackedFloat32Array()             # longitud de arco de cada punto
var turn := PackedFloat32Array()            # giro por metro de cada punto (°/m)
var speed_ideal := PackedFloat32Array()     # velocidad ideal de cada punto (m/s)
var envelope_rojo := PackedFloat32Array()   # envolvente del tramo rojo (con antelación)
var envelope_hard := PackedFloat32Array()   # envolvente de frenada fuerte (la física)
var envelope_soft := PackedFloat32Array()   # envolvente de frenada suave
var step_next := PackedFloat32Array()       # distancia de cada punto al siguiente
var track_length := 0.0
var step_m := 1.5                           # separación media entre puntos
var ready_for_use := false

var _nearest := 0
var _speed_filtered := 0.0
var _material: ShaderMaterial
var _state_texture: ImageTexture
var _state_image: Image
var _forced := false
var _color_accelerate_linear := Vector3.ZERO
var _color_hold_linear := Vector3.ZERO
var _color_brake_linear := Vector3.ZERO
var _color_rubber_linear := Vector3.ZERO

# El shader va aquí dentro, como texto, para que viaje con el script: un archivo
# `.gdshader` suelto habría que declararlo además en el filtro del preset de
# exportación, y un olvido así no se ve en el anfitrión y deja el APK a medias.
const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D u_state;
uniform float u_track_length;
uniform float u_car_s;
uniform float u_window;
uniform float u_tail;
uniform vec3 u_rubber;
uniform float u_edge_blend;
// Sesgo de profundidad proporcional a la distancia a la cámara: medio píxel de
// desplazamiento en pantalla a cualquier distancia, y separación de sobra en el búfer
// de profundidad (siempre ≥ 3 veces su resolución en la zona visible).
uniform float u_depth_bias_per_m;

void vertex() {
	float distance_to_camera = length(INV_VIEW_MATRIX[3].xyz - VERTEX);
	VERTEX += NORMAL * (u_depth_bias_per_m * distance_to_camera);
}

void fragment() {
	float s = UV.x;
	float ds = mod(s - u_car_s + u_track_length, u_track_length);
	// Sólo se dibuja por delante del coche (y un palmo por detrás), que es lo que hace
	// falta para conducir: el resto de la vuelta no aparece por ningún lado.
	if (ds > u_window && ds < u_track_length - u_tail) {
		discard;
	}
	vec3 action = texture(u_state, vec2(clamp(s / u_track_length, 0.0, 0.9995), 0.5)).rgb;
	float edge = smoothstep(0.0, u_edge_blend, UV.y) * smoothstep(1.0, 1.0 - u_edge_blend, UV.y);
	ALBEDO = mix(u_rubber, action, edge);
}
"""

func _ready() -> void:
	# Sin coche no hay recomendación que dar: la línea no se dibuja y el juego sigue
	# igual (es una ayuda visual, nunca toca la física).
	construir(TrackScript.get_centerline())
	if points.size() < 16:
		visible = false
		return
	_construir_malla()
	_construir_material()
	ready_for_use = true

# --- construcción de datos (sin GPU: también la usan las sondas) --------------

# Longitud de arco, giro por metro, velocidad ideal y las dos envolventes de frenada.
# O(n) y se ejecuta una sola vez.
func construir(puntos: PackedVector3Array) -> void:
	points = puntos
	var count := points.size()
	if count < 4:
		return
	arc.resize(count)
	turn.resize(count)
	step_next.resize(count)
	speed_ideal.resize(count)
	track_length = 0.0
	for i in count:
		arc[i] = track_length
		# El cierre de la vuelta (del último punto al primero) es el último tramo.
		var largo := points[i].distance_to(points[(i + 1) % count])
		step_next[i] = maxf(largo, 0.05)
		track_length += largo
	step_m = track_length / float(count)
	# Giro por metro en cada punto, con los vecinos inmediatos.
	for i in count:
		var before := points[(i - 1 + count) % count]
		var current := points[i]
		var after := points[(i + 1) % count]
		var incoming := (current - before).normalized()
		var outgoing := (after - current).normalized()
		var segment := maxf(current.distance_to(after), 0.001)
		turn[i] = rad_to_deg(acos(clampf(incoming.dot(outgoing), -1.0, 1.0))) / segment
	_suavizar_giro(count)
	_calcular_velocidad_ideal(count)
	envelope_hard = _envolvente(speed_ideal, brake_reference_m_s2)
	envelope_soft = _envolvente(speed_ideal, brake_reference_m_s2 * soft_brake_ratio)
	envelope_rojo = _envolvente(speed_ideal, deceleracion_del_rojo())
	actualizar_paleta()

# Mediana móvil del giro: la línea de IA trae temblor punto a punto, y sin filtrar la
# velocidad ideal hereda ese temblor y los colores salen a saltos. Es circular (la
# trazada es un circuito cerrado).
func _suavizar_giro(count: int) -> void:
	var half := maxi(0, turn_median_half_window)
	if half == 0:
		return
	var fuente := turn.duplicate()
	var ventana := PackedFloat32Array()
	for i in count:
		ventana.clear()
		for k in range(-half, half + 1):
			ventana.append(fuente[(i + k + count) % count])
		var ordenada := Array(ventana)
		ordenada.sort()
		turn[i] = ordenada[ordenada.size() / 2]

# Velocidad ideal: la que aguanta la curva según la capacidad lateral medida. Como esa
# capacidad depende de la propia velocidad (carga aerodinámica), la ecuación se
# resuelve iterando: tres pasadas la fijan con error < 0,1 %.
func _calcular_velocidad_ideal(count: int) -> void:
	var suelo := deg_to_rad(min_turn_deg_per_m)
	for i in count:
		var radius := 1.0 / maxf(deg_to_rad(turn[i]), suelo)
		var speed := top_speed_mps
		for _iteration in 3:
			speed = minf(sqrt(lateral_safety * capacidad_lateral(speed) * radius), top_speed_mps)
		speed_ideal[i] = speed

# Aceleración lateral que aguanta el coche a esa velocidad, en m/s².
func capacidad_lateral(speed_mps: float) -> float:
	var full := maxf(lateral_g_full_kph / 3.6, 0.001)
	return (lateral_g_base + lateral_g_gain * clampf(speed_mps / full, 0.0, 1.0)) * 9.81

# Envolvente de frenada hacia atrás sobre la vuelta completa: la velocidad máxima a la
# que se puede pasar por cada punto y aún cumplir la velocidad ideal de todos los que
# vienen detrás, frenando a `deceleration`. Dos barridos para cerrar la vuelta (el
# segundo propaga lo que el primero vio al cruzar la línea de meta).
func _envolvente(ideal: PackedFloat32Array, deceleration: float) -> PackedFloat32Array:
	var count := ideal.size()
	var envelope := ideal.duplicate()
	if deceleration <= 0.0:
		return envelope
	for _pass in 2:
		for k in range(count * 2 - 1, -1, -1):
			var i := k % count
			var next := (i + 1) % count
			var reachable := sqrt(maxf(envelope[next] * envelope[next] + 2.0 * deceleration * step_next[i], 0.0))
			envelope[i] = minf(ideal[i], reachable)
	return envelope

# --- posición del coche sobre la trazada --------------------------------------

# Longitud de arco del punto de la trazada más cercano al coche. Se apoya en el último
# índice conocido y sólo mira alrededor (±25 puntos ≈ ±38 m); si el coche se ha ido
# lejos (un reinicio, una sonda que lo coloca), vuelve a barrer.
func arc_of(position: Vector3) -> float:
	var count := points.size()
	if count == 0:
		return 0.0
	var best := _nearest
	var best_distance := _distancia_al_punto(best, position)
	if best_distance > 40.0 * 40.0:
		best_distance = INF
		for i in range(0, count, 4):
			var d := _distancia_al_punto(i, position)
			if d < best_distance:
				best_distance = d
				best = i
	else:
		for offset in range(-25, 26):
			var i := (best + offset + count) % count
			var d := _distancia_al_punto(i, position)
			if d < best_distance:
				best_distance = d
				best = i
	_nearest = best
	# Proyección sobre el segmento que sale de ese punto: la posición a lo largo de la
	# trazada es continua y no va a saltos de punto entero.
	var following := (best + 1) % count
	var ab := points[following] - points[best]
	var t := clampf((position - points[best]).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return arc[best] + ab.length() * t

func _distancia_al_punto(index: int, position: Vector3) -> float:
	return (points[index] - position).length_squared()

# Índice del punto cuya longitud de arco no supera `s` (búsqueda binaria sobre la tabla
# de arcos, que es monótona).
func _indice_de_arco(s: float) -> int:
	var low := 0
	var high := arc.size() - 1
	while low < high:
		var mid := (low + high + 1) / 2
		if arc[mid] <= s:
			low = mid
		else:
			high = mid - 1
	return low

# Envolvente (velocidad máxima admitida) en el punto que está a `ds` metros por delante
# del coche, INTERPOLADA entre los dos puntos que rodean esa estación. La línea se dibuja
# con una textura filtrada (4096 texeles, 1,13 m cada uno) y los texeles se suavizan entre
# vecinos, así que el límite que ve quien conduce es continuo; tomar el valor del punto más
# cercano convertía cada escalón de la trazada —en la entrada de un vértice la ideal baja
# 0,75 m/s entre dos puntos seguidos— en un salto que ningún coche puede seguir.
func limite_en(envelope: PackedFloat32Array, car_s: float, ds: float) -> float:
	if envelope.is_empty():
		return 0.0
	var count := envelope.size()
	var s := fposmod(car_s + ds, track_length)
	var low := _indice_de_arco(s)
	var following := (low + 1) % count
	var segment := arc[following] - arc[low]
	if following == 0:
		segment = track_length - arc[low]
	var t := clampf((s - arc[low]) / maxf(segment, 0.001), 0.0, 1.0)
	return lerpf(envelope[low], envelope[following], t)

# --- la recomendación ----------------------------------------------------------

# Estado de un punto a `ds` metros por delante, con la velocidad del coche:
#  +1 VERDE (la ideal de delante es más rápida que el coche: acelerar),
#   0 AMARILLO (el coche está en la envolvente cómoda: levantar el pie),
#  -1 ROJO (el coche está por encima de la envolvente fuerte: frenar).
# Deceleración de la banda cómoda (la de la envolvente suave): es a la que baja el
# coche cuando se levanta el pie, y la que se usa para adelantar el amarillo.
func deceleracion_comoda() -> float:
	return brake_reference_m_s2 * soft_brake_ratio

# Deceleración de la envolvente que dibuja el rojo: la de referencia repartida con la
# antelación declarada, es decir, la frenada que pide el aviso es (1 − 1/(1+antelación))
# = 20 % más floja que la que el coche tiene medida.
func deceleracion_del_rojo() -> float:
	return brake_reference_m_s2 / (1.0 + maxf(frenada_antelacion, 0.0))

func verdict(speed: float, car_s: float, ds: float) -> float:
	var rojo := limite_en(envelope_rojo, car_s, ds)
	var soft := limite_en(envelope_soft, car_s, ds)
	if speed > rojo:
		return -1.0
	if speed > soft + maxf(deceleracion_comoda() * hold_margin_s, soft * hold_margin_ratio):
		return 0.0
	return 1.0

func state_name(value: float) -> String:
	if value > 0.5:
		return "VERDE"
	if value < -0.5:
		return "ROJO"
	return "AMARILLO"

func color_of(value: float) -> Color:
	if value >= 0.5:
		return color_accelerate
	if value <= -0.5:
		return color_brake
	return color_hold

# Recomendación de cada punto de la ventana visible, en orden de `ds` creciente. La usan
# la propia línea y las sondas; no depende de la GPU.
func estados_adelante(speed: float, car_s: float, desde_ds: float, hasta_ds: float, paso: float) -> Array:
	var salida: Array = []
	var ds := desde_ds
	while ds <= hasta_ds:
		var estado := verdict(speed, car_s, ds)
		salida.append({"ds": ds, "estado": estado, "name": state_name(estado)})
		ds += maxf(paso, 0.1)
	return salida

# --- textura de estado y material ---------------------------------------------

# Paleta en LINEAL: es la que se escribe en la textura de estado y la que se le da al
# shader. Se calcula aquí y no al construir el material para que las cuentas que no
# dependen de la GPU (la sonda) tengan los mismos valores: `construir` la llama.
func actualizar_paleta() -> void:
	_color_accelerate_linear = _lineal(color_accelerate)
	_color_hold_linear = _lineal(color_hold)
	_color_brake_linear = _lineal(color_brake)
	_color_rubber_linear = _lineal(color_rubber)

func _construir_material() -> void:
	_state_image = Image.create_empty(state_texture_width, 1, false, Image.FORMAT_RGBA8)
	actualizar_paleta()
	_state_image.fill(Color(_color_accelerate_linear.x, _color_accelerate_linear.y, _color_accelerate_linear.z, 1.0))
	_state_texture = ImageTexture.create_from_image(_state_image)
	_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_material.shader = shader
	_material.set_shader_parameter("u_state", _state_texture)
	_material.set_shader_parameter("u_track_length", track_length)
	_material.set_shader_parameter("u_car_s", 0.0)
	_material.set_shader_parameter("u_window", visible_window_m)
	_material.set_shader_parameter("u_tail", visible_tail_m)
	_material.set_shader_parameter("u_depth_bias_per_m", depth_bias_per_m)
	_material.set_shader_parameter("u_edge_blend", color_edge_blend)
	# A la GPU se le entrega el valor LINEAL del color sRGB elegido arriba: ese es el
	# color que se quiere ver en pantalla.
	_material.set_shader_parameter("u_rubber", _color_rubber_linear)
	material_override = _material

func _lineal(color: Color) -> Vector3:
	var convertido := color.srgb_to_linear()
	return Vector3(convertido.r, convertido.g, convertido.b)

func _color_de_estado(value: float) -> Vector3:
	if value >= 0.5:
		return _color_accelerate_linear
	if value <= -0.5:
		return _color_brake_linear
	return _color_hold_linear

# Anillos a lo largo de la trazada. La coordenada de arco viaja en la UV.x (el shader
# necesita saber en qué punto de la vuelta está cada fragmento) y UV.y va de un borde al
# otro del listón. El paso de anillo sólo afecta a la silueta: con 1,51 m la curva más
# cerrada del circuito (27 m de radio) queda descrita con 3,2° por anillo.
func _construir_malla() -> void:
	var count := points.size()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var lift := Vector3.UP * line_lift_m
	for i in count:
		var current := points[i]
		var before := points[(i - 1 + count) % count]
		var after := points[(i + 1) % count]
		var forward := (after - before).normalized()
		var right := forward.cross(Vector3.UP)
		if right.length_squared() < 0.0001:
			right = Vector3.RIGHT
		right = right.normalized()
		vertices.append(current - right * line_half_width_m + lift)
		vertices.append(current + right * line_half_width_m + lift)
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		uvs.append(Vector2(arc[i], 0.0))
		uvs.append(Vector2(arc[i], 1.0))
	# La tira NO se cierra: el anillo último no se une con el primero. Si se uniera, el
	# tramo de 1,5 m que cruza la línea de meta interpolaría su arco de 4611 a 0 y el
	# shader pintaría ahí un color cualquiera.
	for i in count - 1:
		var base := i * 2
		indices.append(base)
		indices.append(base + 2)
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base + 3)
		indices.append(base + 1)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = array_mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# El listón ocupa toda la vuelta: su caja envolvente es enorme, y así el motor no se
	# lo salta al hacer el descarte por caja.
	custom_aabb = AABB(Vector3(-1000.0, -100.0, -1000.0), Vector3(2000.0, 200.0, 2000.0))

# --- cada fotograma -----------------------------------------------------------

# Lo único que se hace conduciendo: comparar la velocidad del coche con las dos
# envolventes y reescribir los texeles visibles. Ni malla, ni envolventes, ni perfil.
func _process(delta: float) -> void:
	if not ready_for_use or car == null or _material == null:
		return
	var speed := float(car.get("speed_mps"))
	var car_s := arc_of(car.global_position)
	var smoothing := 1.0 - exp(-maxf(delta, 0.0001) / maxf(speed_filter_tau, 0.0001))
	_speed_filtered = lerpf(_speed_filtered, speed, smoothing)
	_material.set_shader_parameter("u_car_s", car_s)
	if not _forced:
		actualizar_estado(_speed_filtered, car_s)

# Reescribe los texeles de la ventana visible. Devuelve cuántos texeles ha tocado.
func actualizar_estado(speed: float, car_s: float) -> int:
	if _state_image == null:
		return 0
	var perfil := perfil_de_colores(speed, car_s)
	var indices: PackedInt32Array = perfil["indices"]
	var colores: PackedVector3Array = perfil["colores"]
	for k in indices.size():
		var color: Vector3 = colores[k]
		_state_image.set_pixel(indices[k], 0, Color(color.x, color.y, color.z, 1.0))
	if indices.size() > 0:
		_state_texture.update(_state_image)
	return indices.size()

# Perfil de color de la ventana visible, texel a texel, con el suavizado a lo largo de la
# línea ya aplicado: es EXACTAMENTE lo que se escribe en la textura de estado. Lo escribe
# `actualizar_estado` y lo comprueba la sonda (`driving_line_probe.gd`) sin GPU, para
# poder medir desde fuera que la línea no tiene escalones de color.
func perfil_de_colores(speed: float, car_s: float) -> Dictionary:
	var width := maxi(state_texture_width, 1)
	var metres_per_texel := track_length / float(width)
	var ds := -visible_tail_m
	var crudos: Array = []
	var crudos_indices: Array = []
	while ds <= visible_window_m:
		crudos.append(_color_de_estado(verdict(speed, car_s, ds)))
		crudos_indices.append(int(round(fposmod(car_s + ds, track_length) / metres_per_texel)) % width)
		ds += metres_per_texel
	# Suavizado a lo largo de la línea: los tres colores se mezclan en los bordes de cada
	# banda, que es lo que evita los saltos de color y el parpadeo.
	var half := maxi(0, color_smooth_texels)
	var indices := PackedInt32Array()
	var colores := PackedVector3Array()
	for k in crudos.size():
		var total := Vector3.ZERO
		var cuenta := 0
		for offset in range(-half, half + 1):
			var index: int = k + offset
			if index < 0 or index >= crudos.size():
				continue
			total += crudos[index]
			cuenta += 1
		colores.append(total / maxf(1.0, float(cuenta)))
		indices.append(crudos_indices[k])
	return {"indices": indices, "colores": colores}

# Fuerza un color único en toda la línea (0 verde, 1 amarillo, 2 rojo). Lo usan las
# capturas de referencia para medir EN PÍXELES el color real de cada estado con la
# iluminación y el tonemap del juego; conduciendo nunca se llama.
func forzar_estado(indice: int) -> void:
	if _state_image == null:
		return
	var color := _color_accelerate_linear
	if indice == 1:
		color = _color_hold_linear
	elif indice == 2:
		color = _color_brake_linear
	_state_image.fill(Color(color.x, color.y, color.z, 1.0))
	_state_texture.update(_state_image)
	_forced = true

func soltar_estado() -> void:
	_forced = false
