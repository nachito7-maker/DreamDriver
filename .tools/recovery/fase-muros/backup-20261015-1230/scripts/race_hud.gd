extends CanvasLayer

# Botón de cambio de vista. Va arriba a la DERECHA, que es la única esquina libre
# de la pantalla: el mando está abajo a la izquierda, los pedales abajo a la
# derecha, la telemetría arriba a la izquierda y el cronómetro arriba al centro.
# Su geometría (tamaño, márgenes y anclaje al borde derecho) está copiada en
# `.tools/recovery/screen_geometry.py`, que es quien dice al inyector de toques
# dónde pisar; si se mueve aquí, se mueve allí.
signal camera_toggle_pressed

const BOTON_MARGEN_X := 24.0
const BOTON_MARGEN_Y := 20.0
const BOTON_TAM := Vector2(196.0, 52.0)

var _root: Control
var _speed_label: Label
var _gear_label: Label
var _lap_label: Label
var _previous_label: Label
var _best_label: Label
var _lap_count_label: Label
var _surface_label: Label
var _delta_label: Label
var _recovery_label: Label
var _speed_bar: ProgressBar
var _lap_tracker: Node
var _camera_button: Button
var _last_lap_count := 0
var _flash_timer := 0.0

func _ready() -> void:
	_root = Control.new()
	_root.name = "Telemetry layout"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_create_hud()
	_layout_hud()
	get_viewport().size_changed.connect(_layout_hud)

func _process(delta: float) -> void:
	_flash_timer = maxf(0.0, _flash_timer - delta)
	if _lap_tracker != null:
		if _lap_tracker.laps != _last_lap_count:
			_last_lap_count = _lap_tracker.laps
			_flash_timer = 2.2
		_update_lap_labels()

func update_telemetry(car: CharacterBody3D) -> void:
	if car == null:
		return
	if _speed_label != null:
		_speed_label.text = str(roundi(car.speed_kph))
		_speed_bar.value = clampf(car.speed_kph, 0.0, 360.0)
		_gear_label.text = "N" if car.speed_kph < 3.0 else str(car.gear)
		_surface_label.text = _surface_text(car.surface_grip)
		_surface_label.modulate = Color("#66d8a4") if car.surface_grip > 0.9 else (Color("#f2c456") if car.surface_grip > 0.7 else Color("#ff7164"))
		_delta_label.text = "SLIP  %.0f%%" % (car.lateral_slip * 100.0) if absf(car.lateral_slip) > 0.08 else "TRACK  READY"
		_delta_label.modulate = Color("#ff9a67") if absf(car.lateral_slip) > 0.25 else Color("#a7c5d0")
		if _lap_tracker == null and car.lap_tracker != null:
			_lap_tracker = car.lap_tracker
		_update_lap_labels()

func _create_hud() -> void:
	var left_panel := _panel(Vector2(24, 22), Vector2(362, 148), Color(0.02, 0.045, 0.065, 0.84), Color(0.42, 0.75, 0.92, 0.52))
	left_panel.name = "Telemetry card"
	_speed_label = _label("000", 48, Color("#f4fbff"), Vector2(26, 18), Vector2(176, 60), HORIZONTAL_ALIGNMENT_LEFT)
	_speed_label.add_theme_font_size_override("font_size", 52)
	left_panel.add_child(_speed_label)
	var unit := _label("KM/H", 12, Color("#8ca8b4"), Vector2(188, 43), Vector2(60, 22), HORIZONTAL_ALIGNMENT_LEFT)
	left_panel.add_child(unit)
	_gear_label = _label("1", 30, Color("#ffcc58"), Vector2(266, 24), Vector2(58, 45), HORIZONTAL_ALIGNMENT_CENTER)
	left_panel.add_child(_gear_label)
	var gear_caption := _label("GEAR", 10, Color("#89a4af"), Vector2(266, 70), Vector2(58, 17), HORIZONTAL_ALIGNMENT_CENTER)
	left_panel.add_child(gear_caption)
	_speed_bar = ProgressBar.new()
	_speed_bar.position = Vector2(26, 91)
	_speed_bar.size = Vector2(302, 8)
	_speed_bar.max_value = 360
	_speed_bar.show_percentage = false
	_speed_bar.add_theme_stylebox_override("background", _flat_box(Color(0.18, 0.27, 0.32, 0.86), Color(0.18, 0.27, 0.32, 0)))
	_speed_bar.add_theme_stylebox_override("fill", _flat_box(Color("#58ddad"), Color("#58ddad")))
	left_panel.add_child(_speed_bar)
	_surface_label = _label("ASPHALT · GRIP 100%", 11, Color("#66d8a4"), Vector2(26, 112), Vector2(210, 18), HORIZONTAL_ALIGNMENT_LEFT)
	left_panel.add_child(_surface_label)
	_delta_label = _label("TRACK READY", 10, Color("#a7c5d0"), Vector2(220, 112), Vector2(108, 18), HORIZONTAL_ALIGNMENT_RIGHT)
	left_panel.add_child(_delta_label)
	var lap_panel := _panel(Vector2.ZERO, Vector2(330, 142), Color(0.02, 0.045, 0.065, 0.84), Color(0.42, 0.75, 0.92, 0.52))
	lap_panel.name = "Lap timing"
	var overline := _label("SESSION · BARCELONA MOTO", 10, Color("#89a4af"), Vector2(18, 14), Vector2(280, 16), HORIZONTAL_ALIGNMENT_LEFT)
	lap_panel.add_child(overline)
	_lap_label = _label("00:00.000", 26, Color("#f4fbff"), Vector2(18, 34), Vector2(280, 38), HORIZONTAL_ALIGNMENT_LEFT)
	lap_panel.add_child(_lap_label)
	_previous_label = _label("LAST   --:--.---", 12, Color("#b4cbd2"), Vector2(18, 78), Vector2(138, 20), HORIZONTAL_ALIGNMENT_LEFT)
	lap_panel.add_child(_previous_label)
	_best_label = _label("BEST   --:--.---", 12, Color("#f4cf6a"), Vector2(172, 78), Vector2(144, 20), HORIZONTAL_ALIGNMENT_LEFT)
	lap_panel.add_child(_best_label)
	_lap_count_label = _label("LAP  01", 11, Color("#76dcb5"), Vector2(18, 111), Vector2(140, 16), HORIZONTAL_ALIGNMENT_LEFT)
	lap_panel.add_child(_lap_count_label)
	var help := _label("R  ·  RECOVER", 10, Color(0.8, 0.88, 0.91, 0.82), Vector2(171, 111), Vector2(145, 16), HORIZONTAL_ALIGNMENT_RIGHT)
	lap_panel.add_child(help)
	_recovery_label = help
	_create_camera_button()

# Botón discreto de vista: dice cuál está puesta y alterna al tocarlo.
func _create_camera_button() -> void:
	_camera_button = Button.new()
	_camera_button.name = "Camera switch"
	_camera_button.text = "CÁMARA · PERSECUCIÓN"
	_camera_button.size = BOTON_TAM
	_camera_button.focus_mode = Control.FOCUS_NONE
	_camera_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_camera_button.add_theme_font_size_override("font_size", 13)
	_camera_button.add_theme_color_override("font_color", Color("#dff1f8"))
	_camera_button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	_camera_button.add_theme_color_override("font_pressed_color", Color("#58ddad"))
	_camera_button.add_theme_stylebox_override("normal", _camera_box(Color(0.02, 0.045, 0.065, 0.78), Color(0.42, 0.75, 0.92, 0.42)))
	_camera_button.add_theme_stylebox_override("hover", _camera_box(Color(0.03, 0.07, 0.10, 0.86), Color(0.55, 0.85, 0.98, 0.72)))
	_camera_button.add_theme_stylebox_override("pressed", _camera_box(Color(0.05, 0.10, 0.13, 0.9), Color(0.35, 0.86, 0.68, 0.9)))
	_camera_button.add_theme_stylebox_override("focus", _camera_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
	_camera_button.pressed.connect(_on_camera_button_pressed)
	_root.add_child(_camera_button)

func _camera_box(fill: Color, border: Color) -> StyleBoxFlat:
	var style := _flat_box(fill, border)
	style.content_margin_left = 10
	style.content_margin_right = 10
	return style

func _on_camera_button_pressed() -> void:
	camera_toggle_pressed.emit()

func set_camera_mode(mode: int) -> void:
	if _camera_button == null:
		return
	_camera_button.text = "CÁMARA · MORRO" if mode == 1 else "CÁMARA · PERSECUCIÓN"

func _layout_hud() -> void:
	if _root == null:
		return
	var size := get_viewport().get_visible_rect().size
	var scale := clampf(size.y / 900.0, 0.68, 1.3)
	var telemetry := _root.get_node_or_null("Telemetry card") as Panel
	var lap := _root.get_node_or_null("Lap timing") as Panel
	if telemetry != null:
		telemetry.scale = Vector2.ONE * scale
		telemetry.position = Vector2(24, 20) * scale
	if lap != null:
		lap.scale = Vector2.ONE * scale
		lap.position = Vector2(size.x * 0.5 - 165.0 * scale, 20.0 * scale)
	if _camera_button != null:
		# Anclado al borde DERECHO: al cambiar el ancho se mueve en píxeles, igual
		# que los pedales, y por eso su región no se puede expresar como fracción
		# del ancho (ver `screen_geometry.py`).
		_camera_button.scale = Vector2.ONE * scale
		_camera_button.position = Vector2(size.x - (BOTON_MARGEN_X + BOTON_TAM.x) * scale,
			BOTON_MARGEN_Y * scale)

func _panel(position: Vector2, size: Vector2, fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = position
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _flat_box(fill, border))
	_root.add_child(panel)
	return panel

func _label(text: String, font_size: int, color: Color, position: Vector2, size: Vector2, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _flat_box(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 8
	return style

func _update_lap_labels() -> void:
	if _lap_tracker == null or not is_instance_valid(_lap_tracker):
		return
	_lap_label.text = _format_time(_lap_tracker.lap_time)
	if _lap_tracker.previous_lap >= 0.0:
		_previous_label.text = "LAST  " + _format_time(_lap_tracker.previous_lap)
		_previous_label.add_theme_color_override("font_color", Color("#ff7164") if not _lap_tracker.valid_lap else Color("#b4cbd2"))
	if _lap_tracker.best_lap >= 0.0:
		_best_label.text = "BEST  " + _format_time(_lap_tracker.best_lap)
	_lap_count_label.text = "LAP  %02d%s" % [_lap_tracker.laps + 1, "  ·  INVALID" if not _lap_tracker.valid_lap else ""]
	if _flash_timer > 0.0:
		_lap_count_label.modulate = Color("#fff2a6")
	else:
		_lap_count_label.modulate = Color.WHITE

func _format_time(seconds: float) -> String:
	var mins := int(seconds / 60.0)
	var secs := fmod(seconds, 60.0)
	return "%02d:%06.3f" % [mins, secs]

func _surface_text(grip: float) -> String:
	if grip > 0.93:
		return "ASPHALT  ·  GRIP %d%%" % roundi(grip * 100.0)
	if grip > 0.77:
		return "KERB  ·  GRIP %d%%" % roundi(grip * 100.0)
	if grip > 0.52:
		return "GRASS  ·  GRIP %d%%" % roundi(grip * 100.0)
	return "GRAVEL  ·  GRIP %d%%" % roundi(grip * 100.0)
