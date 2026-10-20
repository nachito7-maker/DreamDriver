extends RefCounted

const FAST_LINE_PATH := "res://assets/BarcelonaMoto.fast_lane.ai"
const IDEAL_LINE_PATH := "res://assets/BarcelonaMoto.ideal_line.ai"
const SURFACES_PATH := "res://assets/BarcelonaMoto.surfaces.json"
const TRACK_LENGTH_M := 4727.0
const TRACK_NAME := "Barcelona 2023 Moto layout (no final chicane)"
const AC_COORDINATE_TO_GODOT := "(-X, Y, -Z)"

static var _centerline: PackedVector3Array = PackedVector3Array()
static var _runoff_points: PackedVector3Array = PackedVector3Array()
static var _speed_hints: PackedFloat32Array = PackedFloat32Array()
static var _surface_data: Dictionary = {}
static var _loaded := false

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var file := FileAccess.open(FAST_LINE_PATH, FileAccess.READ)
	if file == null:
		push_error("Missing Assetto Corsa fast_lane.ai: " + FAST_LINE_PATH)
		return
	var raw := file.get_buffer(file.get_length())
	if raw.size() < 16:
		push_error("Truncated Assetto Corsa AI line.")
		return
	var point_count := raw.decode_s32(4)
	var expected_size := 16 + point_count * 20 + point_count * 72
	if point_count < 100 or point_count > 10000 or raw.size() < expected_size:
		push_error("Invalid AC AI line data: count=%d size=%d expected>=%d" % [point_count, raw.size(), expected_size])
		return
	var line := PackedVector3Array()
	var distance_values := PackedFloat32Array()
	var detail_offset := 16 + point_count * 20
	var detail_count := int((raw.size() - detail_offset) / 72)
	for i in point_count:
		var record := 16 + i * 20
		var ac_x := raw.decode_float(record)
		var ac_elevation := raw.decode_float(record + 4)
		var ac_z := raw.decode_float(record + 8)
		var point := Vector3(-ac_x, ac_elevation, -ac_z)
		line.append(point)
		if detail_count >= point_count:
			# The AC detail format's field 1 is a speed target; units are intentionally not assumed.
			distance_values.append(raw.decode_float(detail_offset + i * 72 + 4))
		else:
			distance_values.append(0.0)
	_centerline = line
	_speed_hints = distance_values
	_runoff_points = line.duplicate()
	_load_surfaces()
	_validate_line()

static func _load_surfaces() -> void:
	if not FileAccess.file_exists(SURFACES_PATH):
		return
	var file := FileAccess.open(SURFACES_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_surface_data = parsed

static func _validate_line() -> void:
	var total := 0.0
	var min_height := INF
	var max_height := -INF
	for i in _centerline.size():
		var a := _centerline[i]
		var b := _centerline[(i + 1) % _centerline.size()]
		var length := a.distance_to(b)
		if length < 0.05 or length > 15.0:
			push_error("AC AI line has invalid segment length at %d: %.3f m" % [i, length])
		total += length
		min_height = minf(min_height, a.y)
		max_height = maxf(max_height, a.y)
	if _centerline.size() < 2800 or total < 4500.0 or total > 5100.0:
		push_error("Moto line failed track length sanity check: points=%d length=%.1f m" % [_centerline.size(), total])
	print("[track] %s | source fast_lane.ai | points=%d | sampled spline length=%.1f m | elevation range %.1f..%.1f m" % [TRACK_NAME, _centerline.size(), total, min_height, max_height])

static func get_centerline() -> PackedVector3Array:
	_ensure_loaded()
	return _centerline

static func get_runoff_points() -> PackedVector3Array:
	_ensure_loaded()
	return _runoff_points

static func get_spawn_position() -> Vector3:
	_ensure_loaded()
	if _centerline.size() < 3:
		return Vector3.ZERO
	var tangent := (_centerline[1] - _centerline[0]).normalized()
	return _centerline[0] - tangent * 18.0 + Vector3.UP * 0.03

static func get_spawn_yaw() -> float:
	_ensure_loaded()
	if _centerline.size() < 3:
		return 0.0
	var tangent := (_centerline[1] - _centerline[0]).normalized()
	# Godot's local forward axis is -Z.
	return atan2(-tangent.x, -tangent.z)

static func get_track_length_m() -> float:
	return TRACK_LENGTH_M

static func get_layout_name() -> String:
	return TRACK_NAME

static func get_ac_coordinate_transform() -> String:
	return AC_COORDINATE_TO_GODOT

static func get_surface_metadata() -> Dictionary:
	_ensure_loaded()
	return _surface_data

# Nombres de objeto del circuito que identifican cada superficie. El cuerpo de
# la malla de física conserva el nombre original de AC (01TRM-BRC004, 06GRASS008,
# 10GRAVEL009...), de modo que el grupo se puede leer del propio nombre.
const SURFACE_KEYS := ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "CONCRETE", "PITS",
	"GRAVEL", "SAND", "GRASS", "GREEN", "CARPET", "OUT"]

static func classify_surface(label: String) -> String:
	var upper := label.to_upper()
	for key in SURFACE_KEYS:
		if key in upper:
			return key
	return ""

static func get_surface_grip(prefix: String) -> float:
	var key := prefix.to_upper()
	match key:
		"TRM-BRC", "ROAD", "TARMAC", "ASPHALT":
			return 1.0
		"KERB", "CURB", "RUMBLE":
			return 0.88
		"CONCRETE", "PITS":
			return 0.84
		"GRAVEL", "SAND":
			return 0.46
		"GRASS", "GREEN", "CARPET", "OUT":
			return 0.58
		_:
			return 0.92
