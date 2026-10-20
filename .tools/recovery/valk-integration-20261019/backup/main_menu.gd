extends Control

const TrackScript = preload("res://scripts/track_data.gd")

const ACCENT := Color("#ffcc58")
const INK := Color("#eef7fb")
const MUTED := Color("#9bb0bb")
const PANEL := Color(0.02, 0.045, 0.065, 0.94)

var _track_id := TrackScript.BARCELONA
var _vehicle_id := "rb22_2026"
var _track_buttons: Dictionary = {}
var _vehicle_buttons: Dictionary = {}
var _summary: Label
var _map: TextureRect
var _status: Label

func _ready() -> void:
	_track_id = TrackScript.selected_track
	_vehicle_id = TrackScript.selected_vehicle
	_build_ui()
	_refresh_ui()

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#07131c")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 0)
	add_child(page)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 110
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_child(header)
	var brand := _label("FORMULA  ·  ONE SHOT", 14, ACCENT)
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(brand)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 30)
	content.add_theme_constant_override("margin_left", 48)
	content.add_theme_constant_override("margin_right", 48)
	content.add_theme_constant_override("margin_top", 18)
	content.add_theme_constant_override("margin_bottom", 40)
	page.add_child(content)

	var choices := VBoxContainer.new()
	choices.custom_minimum_size.x = 520
	choices.add_theme_constant_override("margin_left", 8)
	choices.add_theme_constant_override("margin_right", 8)
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation", 18)
	content.add_child(choices)

	var title := _label("ELIGE TU\nGRAN PREMIO", 40, INK)
	title.custom_minimum_size.y = 112
	choices.add_child(title)
	choices.add_child(_label("CIRCUITO", 12, MUTED))
	var track_row := HBoxContainer.new()
	track_row.add_theme_constant_override("separation", 12)
	choices.add_child(track_row)
	_add_choice(track_row, _track_buttons, TrackScript.BARCELONA, "BARCELONA\nMOTO · 4.7 KM", true)
	_add_choice(track_row, _track_buttons, TrackScript.SUZUKA, "SUZUKA\nGRAND PRIX · 5.8 KM", true)
	_add_choice(track_row, _track_buttons, TrackScript.MONTREAL, "MONTREAL\nCIRCUIT GILLES-VILLENEUVE · 4.4 KM", true)

	choices.add_child(_label("MONOPLAZA", 12, MUTED))
	var vehicle_row := HBoxContainer.new()
	vehicle_row.add_theme_constant_override("separation", 12)
	choices.add_child(vehicle_row)
	_add_choice(vehicle_row, _vehicle_buttons, "mclaren", "McLAREN\nMP4/4 · SENNA", false)
	_add_choice(vehicle_row, _vehicle_buttons, "rb22_2026", "RED BULL\nRB22 · 2026", false)

	_summary = _label("", 15, INK)
	_summary.custom_minimum_size.y = 48
	choices.add_child(_summary)

	var launch := Button.new()
	launch.name = "Start race"
	launch.text = "SALIR A PISTA   →"
	launch.custom_minimum_size = Vector2(0, 68)
	launch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	launch.focus_mode = Control.FOCUS_NONE
	launch.add_theme_font_size_override("font_size", 17)
	launch.add_theme_color_override("font_color", Color("#07131c"))
	launch.add_theme_color_override("font_hover_color", Color("#07131c"))
	launch.add_theme_stylebox_override("normal", _flat(ACCENT))
	launch.add_theme_stylebox_override("hover", _flat(Color("#ffdc82")))
	launch.pressed.connect(_start_race)
	choices.add_child(launch)
	_status = _label("", 12, Color("#ff8879"))
	choices.add_child(_status)

	var visual := PanelContainer.new()
	visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual.add_theme_stylebox_override("panel", _panel_style())
	content.add_child(visual)
	var preview := VBoxContainer.new()
	preview.add_theme_constant_override("separation", 16)
	visual.add_child(preview)
	_map = TextureRect.new()
	_map.name = "Track preview"
	_map.custom_minimum_size = Vector2(480, 180)
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_map.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	preview.add_child(_map)
	var detail := _label("TEMPORADA  ·  3 CIRCUITOS  ·  2 MONOPLAZAS", 11, MUTED)
	detail.name = "Track identification"
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(detail)

func _add_choice(row: HBoxContainer, group: Dictionary, id: String, text: String, is_track: bool) -> void:
	var button := Button.new()
	button.name = ("Track " if is_track else "Vehicle ") + id
	button.text = text
	button.custom_minimum_size = Vector2(0, 82)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", ACCENT)
	button.add_theme_stylebox_override("normal", _flat(PANEL, Color("#29414c")))
	button.add_theme_stylebox_override("hover", _flat(Color("#12252f"), Color("#618092")))
	button.pressed.connect(_on_choice_pressed.bind(id, is_track))
	row.add_child(button)
	group[id] = button

func _on_choice_pressed(id: String, is_track: bool) -> void:
	if is_track:
		_track_id = id
	else:
		_vehicle_id = id
	_refresh_ui()

func _refresh_ui() -> void:
	for id in _track_buttons:
		_track_buttons[id].add_theme_stylebox_override("normal", _flat(Color("#17352f"), ACCENT) if id == _track_id else _flat(PANEL, Color("#29414c")))
	for id in _vehicle_buttons:
		_vehicle_buttons[id].add_theme_stylebox_override("normal", _flat(Color("#17352f"), ACCENT) if id == _vehicle_id else _flat(PANEL, Color("#29414c")))
	var track: Dictionary = TrackScript.TRACKS[_track_id]
	var vehicle: Dictionary = TrackScript.get_vehicle_options()[_vehicle_id]
	var track_detail := find_child("Track identification", true, false) as Label
	if track_detail != null:
		track_detail.text = str(track["name"]).to_upper() + "  ·  " + str(roundi(float(track["length"]))) + " M  ·  " + str(vehicle["name"]).to_upper()
	_summary.text = "%s   /   %s" % [String(track["name"]), String(vehicle["name"])]
	var map_path := TrackScript.get_camera_map_path()
	if _track_id == TrackScript.MONTREAL:
		_map.texture = load("res://assets/montreal/preview.png") as Texture2D
	else:
		_map.texture = load(map_path) as Texture2D if not map_path.is_empty() else null

func _start_race() -> void:
	_status.text = ""
	if not TrackScript.set_user_selection(_track_id, _vehicle_id):
		_status.text = "No se pudo cargar la configuración elegida."
		return
	get_tree().change_scene_to_file("res://scenes/race.tscn")

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _flat(color: Color, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style

func _panel_style() -> StyleBoxFlat:
	return _flat(Color(0.025, 0.055, 0.075, 0.9), Color(0.22, 0.38, 0.46, 0.55))
