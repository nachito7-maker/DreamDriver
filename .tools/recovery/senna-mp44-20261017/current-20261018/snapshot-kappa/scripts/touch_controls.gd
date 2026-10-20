extends CanvasLayer

var car: CharacterBody3D
var _control_root: Control
var _steering_ring: Control
var _steering_knob: Control
var _throttle_pedal: Control
var _brake_pedal: Control
var _steer_touch_id := -1
var _throttle_touch_id := -1
var _brake_touch_id := -1
var _active_touches: Dictionary = {}
var _steer_value := 0.0
var _throttle_value := 0.0
var _brake_value := 0.0
var _viewport_size := Vector2.ZERO
var _steer_center := Vector2.ZERO
var _pedal_rects := {"throttle": Rect2(), "brake": Rect2()}
var _steer_zone := Rect2()
var _knob_offset := Vector2.ZERO

func _ready() -> void:
	_control_root = Control.new()
	_control_root.name = "Touch overlay"
	_control_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_control_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_control_root)
	_build_static_elements()
	_layout_controls()
	get_viewport().size_changed.connect(_layout_controls)

func _process(delta: float) -> void:
	if _steer_touch_id < 0:
		_knob_offset *= exp(-delta * 14.0)
		if _knob_offset.length() < 0.2:
			_knob_offset = Vector2.ZERO
		_steer_value = _steering_curve(_knob_offset.x / maxf(1.0, _steering_ring.size.x * 0.46))
	_steering_knob.position = _steer_center + _knob_offset - _steering_knob.size * 0.5
	_publish()
	_update_visuals()

# La demanda que lee el coche se publica aquí y en cada evento táctil: un toque nuevo se ve en
# el mismo paso de física siguiente, sin esperar al fotograma de dibujado (a 60 Hz eso era
# hasta un fotograma de retraso entre pisar el pedal y que el motor lo leyera).
func _publish() -> void:
	if car != null and is_instance_valid(car):
		car.set_meta("touch_steer", _steer_value)
		car.set_meta("touch_throttle", _throttle_value)
		car.set_meta("touch_brake", _brake_value)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and not touch.canceled:
			_active_touches[touch.index] = touch.position
			_handle_touch_down(touch.index, touch.position)
		else:
			_active_touches.erase(touch.index)
			_handle_touch_up(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_active_touches[drag.index] = drag.position
		_handle_touch_motion(drag.index, drag.position)
	elif event is InputEventMouseButton and OS.has_feature("editor"):
		var mouse := event as InputEventMouseButton
		if mouse.pressed:
			_handle_touch_down(999, mouse.position)
		else:
			_handle_touch_up(999)
	elif event is InputEventMouseMotion and OS.has_feature("editor") and (_steer_touch_id == 999 or _throttle_touch_id == 999 or _brake_touch_id == 999):
		_handle_touch_motion(999, (event as InputEventMouseMotion).position)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_release_all_touches()

func _handle_touch_down(id: int, point: Vector2) -> void:
	# Cada dedo es independiente: un toque nuevo se prueba contra TODOS los controles libres
	# (no una cadena de `else`), así que pisar el acelerador no depende de dónde haya caído
	# antes el dedo de la dirección.
	_try_capture(id, point)
	_publish()

# Toma un control libre con este dedo. Lo usan tanto el toque nuevo como el dedo que ENTRA
# deslizando en una zona: no hace falta clavar el dedo en el punto exacto desde el primer
# instante.
func _try_capture(id: int, point: Vector2) -> void:
	if _steer_touch_id < 0 and _steer_zone.has_point(point):
		_steer_touch_id = id
		_set_steering(point)
	if _throttle_touch_id < 0 and _pedal_rects["throttle"].has_point(point):
		_throttle_touch_id = id
		_update_pedal("throttle", point)
	if _brake_touch_id < 0 and _pedal_rects["brake"].has_point(point):
		_brake_touch_id = id
		_update_pedal("brake", point)

func _release_all_touches() -> void:
	_active_touches.clear()
	_steer_touch_id = -1
	_throttle_touch_id = -1
	_brake_touch_id = -1
	_steer_value = 0.0
	_throttle_value = 0.0
	_brake_value = 0.0
	_knob_offset = Vector2.ZERO

func _handle_touch_up(id: int) -> void:
	if id == _steer_touch_id:
		_steer_touch_id = -1
		# Keep current steering demand: _process damps it to zero after release.
	if id == _throttle_touch_id:
		_throttle_touch_id = -1
		_throttle_value = 0.0
	if id == _brake_touch_id:
		_brake_touch_id = -1
		_brake_value = 0.0
	_publish()

func _handle_touch_motion(id: int, point: Vector2) -> void:
	if id == _steer_touch_id:
		_set_steering(point)
	elif id == _throttle_touch_id:
		_update_pedal("throttle", point)
	elif id == _brake_touch_id:
		_update_pedal("brake", point)
	elif id != 999:
		# Un dedo que no tiene control y entra deslizando en una zona libre la toma.
		_try_capture(id, point)
	_publish()

# Cuánta demanda pide un pedal si se pisa en ese punto (para las sondas y para el HUD).
func pedal_demand_at(kind: String, point: Vector2) -> float:
	return _pedal_pressure(kind, point)

func _steer_ring_center() -> Vector2:
	return _steering_ring.position + _steering_ring.size * 0.5

# Curva del mando: recorrido del dedo → demanda de dirección.
#
# Con el exponente 1,6 que había, medio recorrido entregaba sólo el 31 % de la demanda
# (y un cuarto, el 9 %). Eso no se notaba a poca velocidad, donde el coche satura el
# agarre con muy poco ángulo, pero a media y alta velocidad —donde una curva pide
# 0,8-1,1 g y el ángulo máximo útil es pequeño— dejaba el coche prácticamente recto:
# medido con `steering_response_probe` (mando táctil real) a 120 km/h, medio recorrido
# producía un radio de 265 m y hacía falta casi todo el anillo (88 %) para llegar al
# agarre. El exponente 0,90 entrega la demanda de forma casi lineal (medio recorrido =
# 52 %, tres cuartos = 76 %) y mantiene suave el primer 10 % (8 %): el mando manda y el
# coche responde en todo el recorrido.
const STEER_DEAD_ZONE := 0.04
const STEER_CURVE_EXPONENT := 0.90

func _steering_curve(value: float) -> float:
	var magnitude := clampf((absf(value) - STEER_DEAD_ZONE) / (1.0 - STEER_DEAD_ZONE), 0.0, 1.0)
	return signf(value) * pow(magnitude, STEER_CURVE_EXPONENT)

# Inversa exacta de `_steering_curve`: recorrido del dedo que produce esa demanda. La usan
# las sondas que conducen por el canal táctil de verdad (`driving_probe`, `drive_diag_probe`)
# para pedir una demanda concreta sin volver a escribir las constantes de la curva: si la
# curva cambia, la inversa cambia con ella y la sonda sigue pidiendo exactamente lo mismo.
func steering_travel_for(demand: float) -> float:
	var magnitude := clampf(pow(absf(demand), 1.0 / STEER_CURVE_EXPONENT), 0.0, 1.0)
	return signf(demand) * (magnitude * (1.0 - STEER_DEAD_ZONE) + STEER_DEAD_ZONE)

func _set_steering(point: Vector2) -> void:
	var radius := maxf(1.0, _steering_ring.size.x * 0.46)
	_knob_offset = (point - _steer_center).limit_length(radius)
	_steer_value = _steering_curve(_knob_offset.x / radius)
	_steering_knob.position = _steer_center + _knob_offset - _steering_knob.size * 0.5

# Recorrido del pedal: borde de abajo = cero, y el TOTAL a los 45 % del recorrido.
#
# El cero abajo es la convención declarada y probada del proyecto (las sondas piden demanda cero
# pisando el borde inferior del recuadro). Lo que cambió es lo rápido que sube: antes hacía
# falta el 80 % del recorrido para el total, así que un pulgar apoyado en la mitad baja del
# pedal —que es donde cae el pulgar— pedía un 19 % de gas, y en el margen lateral del recuadro
# la demanda se anulaba del todo aunque el pedal siguiera pisado: el pedal se iluminaba y el
# coche no andaba. Ese era el fallo de jugabilidad. Ahora media altura del pedal ya pide el
# total y el recorrido sigue siendo analógico de 0 a 1.
# Fracción del recorrido del pedal que ya pide el total (0,45 = a media altura, total).
const PEDAL_RAMP := 0.45
# Margen de la zona de toque más allá del panel dibujado (px de referencia, escala aparte):
# pulgares, guantes y cristales no aciertan a un panel de 114 px.
const PEDAL_ZONE_PAD := 34.0

# Inversa exacta de la curva del pedal: el recorrido del dedo que produce esa demanda. La usan
# las sondas que conducen pisando el pedal de verdad (`driving_probe`, `drive_diag_probe`):
# así, si la rampa cambia, la sonda sigue pidiendo exactamente la demanda que cree pedir. El
# 0,8 de la rampa vieja que llevaban copiado colocaba el dedo demasiado abajo y pedía casi el
# doble de gas del que la sonda creía estar pidiendo.
func pedal_travel_for(demand: float) -> float:
	var d := clampf(demand, 0.0, 1.0)
	var offset := asin(clampf(1.0 - 2.0 * d, -1.0, 1.0)) / 3.0
	return clampf(0.5 - sin(offset), 0.0, 1.0) * PEDAL_RAMP

func _pedal_pressure(kind: String, point: Vector2) -> float:
	var zone: Rect2 = _pedal_rects[kind]
	if not zone.has_point(point):
		# Fuera de la zona no se pide nada: es soltar el pie (el dedo que se va del pedal) y es
		# también el gesto que usan las sondas para pedir demanda cero.
		return 0.0
	var travel := clampf((zone.end.y - point.y) / zone.size.y, 0.0, 1.0)
	return smoothstep(0.0, PEDAL_RAMP, travel)

func _update_pedal(kind: String, point: Vector2) -> void:
	# La demanda de un pedal ya capturado depende SÓLO de la altura del dedo: moverse en
	# horizontal por dentro de la zona —lo natural al tirar del mando con el otro pulgar— no
	# interrumpe la pulsación. Se libera al levantar el dedo —o al sacarlo de la zona—, no al
	# moverse por dentro.
	var pressure := _pedal_pressure(kind, point)
	if kind == "throttle":
		_throttle_value = pressure
	else:
		_brake_value = pressure

func _build_static_elements() -> void:
	_steering_ring = Control.new()
	_steering_ring.name = "Analog steering zone"
	_steering_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_control_root.add_child(_steering_ring)
	_steering_ring.draw.connect(_draw_steering_ring)
	_steering_knob = Control.new()
	_steering_knob.name = "Steering thumb pad"
	_steering_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_control_root.add_child(_steering_knob)
	_steering_knob.draw.connect(_draw_steering_knob)
	_throttle_pedal = Control.new()
	_throttle_pedal.name = "Throttle pedal"
	_throttle_pedal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_control_root.add_child(_throttle_pedal)
	_throttle_pedal.draw.connect(_draw_throttle)
	_brake_pedal = Control.new()
	_brake_pedal.name = "Brake pedal"
	_brake_pedal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_control_root.add_child(_brake_pedal)
	_brake_pedal.draw.connect(_draw_brake)

func _layout_controls() -> void:
	_viewport_size = get_viewport().get_visible_rect().size
	if _viewport_size.x <= 0.0 or _viewport_size.y <= 0.0:
		return
	var scale := clampf(_viewport_size.y / 900.0, 0.68, 1.32)
	var ring_size := 214.0 * scale
	_steer_center = Vector2(155.0 * scale, _viewport_size.y - 154.0 * scale)
	_steering_ring.position = _steer_center - Vector2.ONE * ring_size * 0.5
	_steering_ring.size = Vector2.ONE * ring_size
	_steering_knob.size = Vector2.ONE * 78.0 * scale
	_steering_knob.position = _steer_center - _steering_knob.size * 0.5
	var pedal_width := 95.0 * scale
	var pedal_height := 192.0 * scale
	var right_margin := 46.0 * scale
	var bottom := _viewport_size.y - 33.0 * scale
	var gap := 52.0 * scale
	var throttle_x := _viewport_size.x - right_margin - pedal_width
	var brake_x := throttle_x - gap - pedal_width
	_throttle_pedal.position = Vector2(throttle_x, bottom - pedal_height)
	_throttle_pedal.size = Vector2(pedal_width, pedal_height)
	_brake_pedal.position = Vector2(brake_x, bottom - pedal_height)
	_brake_pedal.size = Vector2(pedal_width, pedal_height)
	# Zonas de toque: el acelerador se queda TODA la esquina inferior derecha y el freno la
	# banda de la izquierda hasta la mitad del hueco entre los dos pedales. Antes eran dos
	# recuadros con un margen y quedaba entre ellos una franja muerta por la que el dedo caía
	# sin pisar nada. Ahora son contiguas, no se solapan (un dedo no puede pisar los dos
	# pedales a la vez) y suben PEDAL_ZONE_PAD por encima del panel para el pulgar que llega
	# alto. El botón de cámara está arriba a la derecha: ninguna zona lo alcanza.
	# La zona acaba donde acaba el pedal dibujado: por debajo no hay nada que pisar (el dedo que
	# se baja por debajo del panel suelta el pedal, que es lo que espera cualquiera).
	var top := bottom - pedal_height - PEDAL_ZONE_PAD * scale
	var zone_height := bottom - top
	var split_x := throttle_x - gap * 0.5
	_pedal_rects["throttle"] = Rect2(
		Vector2(split_x, top), Vector2(_viewport_size.x - split_x, zone_height))
	_pedal_rects["brake"] = Rect2(
		Vector2(brake_x - PEDAL_ZONE_PAD * scale, top),
		Vector2(split_x - (brake_x - PEDAL_ZONE_PAD * scale), zone_height))
	_steer_zone = Rect2(Vector2(0.0, _viewport_size.y * 0.25),
		Vector2(_viewport_size.x * 0.42, _viewport_size.y * 0.75))
	_update_visuals()

func _update_visuals() -> void:
	if is_instance_valid(_steering_ring):
		_steering_ring.queue_redraw()
		_steering_knob.queue_redraw()
		_throttle_pedal.queue_redraw()
		_brake_pedal.queue_redraw()

func _draw_steering_ring() -> void:
	var center := _steering_ring.size * 0.5
	var radius := _steering_ring.size.x * 0.46
	_steering_ring.draw_circle(center, radius, Color(0.015, 0.025, 0.04, 0.28))
	_steering_ring.draw_arc(center, radius, 0, TAU, 64, Color(0.85, 0.9, 0.96, 0.48), 3.0, true)
	_steering_ring.draw_arc(center, radius * 0.72, 0, TAU, 64, Color(0.5, 0.65, 0.78, 0.18), 1.5, true)
	_steering_ring.draw_line(center - Vector2(radius * 0.6, 0), center + Vector2(radius * 0.6, 0), Color(0.8, 0.86, 0.92, 0.26), 1.4)
	_steering_ring.draw_line(center - Vector2(0, radius * 0.6), center + Vector2(0, radius * 0.6), Color(0.8, 0.86, 0.92, 0.26), 1.4)

func _draw_steering_knob() -> void:
	var center := _steering_knob.size * 0.5
	var radius := center.x * 0.9
	_steering_knob.draw_circle(center + Vector2(0, 3), radius, Color(0, 0, 0, 0.25))
	_steering_knob.draw_circle(center, radius, Color(0.13, 0.17, 0.21, 0.85))
	_steering_knob.draw_arc(center, radius, 0, TAU, 40, Color(0.85, 0.9, 0.95, 0.78), 2.5, true)
	_steering_knob.draw_line(center + Vector2(0, -radius * 0.58), center + Vector2(0, radius * 0.54), Color(0.92, 0.94, 0.97, 0.78), 3.0)

func _draw_throttle() -> void:
	var rect := Rect2(Vector2.ZERO, _throttle_pedal.size)
	var engaged := _throttle_touch_id >= 0
	var fill := Color(0.11, 0.48, 0.34, 0.87) if engaged else Color(0.10, 0.17, 0.18, 0.78)
	_throttle_pedal.draw_style_box(_panel_style(fill, Color("#62edb1")), rect)
	for x in range(18, int(rect.size.x) - 12, 16):
		_throttle_pedal.draw_line(Vector2(x, 18), Vector2(x + 6, rect.size.y - 50), Color(0.75, 0.95, 0.86, 0.28), 2.2)
	_throttle_pedal.draw_string(ThemeDB.fallback_font, Vector2(12, 30), "ACCEL", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24, 11, Color("#f4fff9"))
	_throttle_pedal.draw_colored_polygon(PackedVector2Array([Vector2(rect.size.x * 0.5, rect.size.y - 76), Vector2(rect.size.x * 0.32, rect.size.y - 43), Vector2(rect.size.x * 0.68, rect.size.y - 43)]), Color("#daf9e8"))
	_throttle_pedal.draw_string(ThemeDB.fallback_font, Vector2(10, rect.size.y - 16), "THROTTLE", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20, 10, Color("#c5ddd0"))
	if engaged:
		_throttle_pedal.draw_rect(Rect2(6, rect.size.y * (1.0 - _throttle_value), 4, rect.size.y * _throttle_value), Color("#6af5ac"))

func _draw_brake() -> void:
	var rect := Rect2(Vector2.ZERO, _brake_pedal.size)
	var engaged := _brake_touch_id >= 0
	var fill := Color(0.55, 0.17, 0.16, 0.9) if engaged else Color(0.20, 0.12, 0.14, 0.82)
	_brake_pedal.draw_style_box(_panel_style(fill, Color("#ff776a")), rect)
	for x in range(18, int(rect.size.x) - 12, 16):
		_brake_pedal.draw_line(Vector2(x, 18), Vector2(x + 6, rect.size.y - 50), Color(1.0, 0.8, 0.78, 0.28), 2.2)
	_brake_pedal.draw_string(ThemeDB.fallback_font, Vector2(12, 30), "BRAKE", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24, 11, Color("#fff5f4"))
	_brake_pedal.draw_arc(Vector2(rect.size.x * 0.5, rect.size.y - 62), 18, PI, TAU, 20, Color("#ffe4e1"), 4.0, true)
	_brake_pedal.draw_line(Vector2(rect.size.x * 0.5, rect.size.y - 62), Vector2(rect.size.x * 0.5, rect.size.y - 82), Color("#ffe4e1"), 4.0)
	_brake_pedal.draw_string(ThemeDB.fallback_font, Vector2(10, rect.size.y - 16), "BRAKE", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20, 10, Color("#ecd0cf"))
	if engaged:
		_brake_pedal.draw_rect(Rect2(6, rect.size.y * (1.0 - _brake_value), 4, rect.size.y * _brake_value), Color("#ff665e"))

func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 7
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
