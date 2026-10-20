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
	if car != null:
		car.set_meta("touch_steer", _steer_value)
		car.set_meta("touch_throttle", _throttle_value)
		car.set_meta("touch_brake", _brake_value)
	_update_visuals()

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
	# Every pointer is independent. The former else-if made touch acceptance
	# depend on left-zone membership before even checking the pedal positions.
	if _steer_touch_id < 0 and point.x < _viewport_size.x * 0.42 and point.y > _viewport_size.y * 0.25:
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

func _handle_touch_motion(id: int, point: Vector2) -> void:
	if id == _steer_touch_id:
		_set_steering(point)
	elif id == _throttle_touch_id:
		_update_pedal("throttle", point)
	elif id == _brake_touch_id:
		_update_pedal("brake", point)

func _steer_ring_center() -> Vector2:
	return _steering_ring.position + _steering_ring.size * 0.5

func _steering_curve(value: float) -> float:
	var magnitude := clampf((absf(value) - 0.035) / 0.965, 0.0, 1.0)
	return signf(value) * pow(magnitude, 1.6)

func _set_steering(point: Vector2) -> void:
	var radius := maxf(1.0, _steering_ring.size.x * 0.46)
	_knob_offset = (point - _steer_center).limit_length(radius)
	_steer_value = _steering_curve(_knob_offset.x / radius)
	_steering_knob.position = _steer_center + _knob_offset - _steering_knob.size * 0.5

func _update_pedal(kind: String, point: Vector2) -> void:
	var rect: Rect2 = _pedal_rects[kind]
	# Touchscreens do not report force reliably. Vertical pedal travel is analog:
	# bottom = zero, upper edge = full; sliding outside horizontally releases it.
	var pressure := smoothstep(0.0, 0.8, clampf((rect.end.y - point.y) / rect.size.y, 0.0, 1.0))
	# The touch hitbox extends beyond the visual panel for easier thumbs. In the
	# horizontal padding keep the pedal captured, but do not apply accidental
	# analog pressure just because a finger landed outside the drawn pedal.
	var pedal_visual: Control = _throttle_pedal if kind == "throttle" else _brake_pedal
	var visual := Rect2(pedal_visual.position, pedal_visual.size)
	if point.x < visual.position.x or point.x > visual.end.x:
		pressure = 0.0
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
	_pedal_rects["throttle"] = Rect2(_throttle_pedal.position - Vector2(22, 16) * scale, _throttle_pedal.size + Vector2(44, 32) * scale)
	_pedal_rects["brake"] = Rect2(_brake_pedal.position - Vector2(22, 16) * scale, _brake_pedal.size + Vector2(44, 32) * scale)
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
