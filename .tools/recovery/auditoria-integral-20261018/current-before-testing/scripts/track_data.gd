extends RefCounted

const BARCELONA := "barcelona"
const SUZUKA := "suzuka"
const AC_COORDINATE_TO_GODOT := "(-X, Y, -Z)"
const SURFACE_KEYS := ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "CONCRETE", "PITS", "GRAVEL", "SAND", "GRASS", "GREEN", "CARPET", "OUT", "TURF", "CUT", "PITLANE", "CNCPTS", "GRILL", "BUMP", "MARBLES", "TRAV", "WALL"]

const TRACKS := {
	BARCELONA: {
		"fast_line": "res://assets/BarcelonaMoto.fast_lane.ai",
		"ideal_line": "res://assets/BarcelonaMoto.ideal_line.ai",
		"surfaces": "res://assets/BarcelonaMoto.surfaces.json",
		"length": 4727.0,
		"name": "Barcelona-Catalunya · Moto",
		"track_scene": "res://assets/BarcelonaMoto-Tutorial.glb",
		"rotation_y": PI,
	},
	SUZUKA: {
		"fast_line": "res://assets/Suzuka.fast_lane.ai",
		"ideal_line": "res://assets/Suzuka.ideal_line.ai",
		"surfaces": "res://assets/Suzuka.surfaces.json",
		"length": 5770.5,
		"name": "Suzuka · Grand Prix",
		"track_scene": "res://assets/suzuka-gp.gltf",
		"rotation_y": 0.0,
	},
}

static var selected_track := BARCELONA
static var selected_vehicle := "redbull"
static var _centerline := PackedVector3Array()
static var _runoff_points := PackedVector3Array()
static var _speed_hints := PackedFloat32Array()
static var _surface_data: Dictionary = {}
static var _ideal_line := PackedVector3Array()
static var _loaded_track := ""
static var _ideal_line_loaded_track := ""

static func select_track(track_id: String) -> bool:
	if not TRACKS.has(track_id):
		push_error("Unknown circuit selection: " + track_id)
		return false
	selected_track = track_id
	_ensure_loaded()
	return not _centerline.is_empty()

static func select_vehicle(vehicle_id: String) -> bool:
	if not get_vehicle_options().has(vehicle_id):
		push_error("Unknown vehicle selection: " + vehicle_id)
		return false
	selected_vehicle = vehicle_id
	return true

static func set_user_selection(track_id: String, vehicle_id: String) -> bool:
	if not TRACKS.has(track_id) or not get_vehicle_options().has(vehicle_id):
		return false
	if not select_track(track_id):
		return false
	return select_vehicle(vehicle_id)

static func reset_selection() -> void:
	selected_track = BARCELONA
	selected_vehicle = "redbull"
	_loaded_track = ""
	_ideal_line_loaded_track = ""
	_centerline.clear()
	_runoff_points.clear()
	_speed_hints.clear()
	_surface_data.clear()
	_ideal_line.clear()

static func _ensure_loaded() -> void:
	if _loaded_track == selected_track:
		return
	_loaded_track = selected_track
	_ideal_line_loaded_track = ""
	_centerline.clear()
	_runoff_points.clear()
	_speed_hints.clear()
	_surface_data.clear()
	_ideal_line.clear()
	var config: Dictionary = TRACKS[selected_track]
	var path := String(config["fast_line"])
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing Assetto Corsa fast_lane.ai: " + path)
		return
	var raw := file.get_buffer(file.get_length())
	if raw.size() < 16:
		push_error("Truncated Assetto Corsa AI line: " + path)
		return
	var point_count := raw.decode_s32(4)
	var detail_offset := 16 + point_count * 20
	var expected_size := detail_offset + point_count * 72
	if point_count < 100 or point_count > 10000 or raw.size() < expected_size:
		push_error("Invalid AC AI line data: count=%d size=%d expected>=%d" % [point_count, raw.size(), expected_size])
		return
	var distance_values := PackedFloat32Array()
	for i in point_count:
		var record := 16 + i * 20
		_centerline.append(Vector3(-raw.decode_float(record), raw.decode_float(record + 4), -raw.decode_float(record + 8)))
		distance_values.append(raw.decode_float(detail_offset + i * 72 + 4))
	_speed_hints = distance_values
	_runoff_points = _centerline.duplicate()
	_load_surfaces()
	_validate_line()

static func _load_surfaces() -> void:
	var path := String(TRACKS[selected_track]["surfaces"])
	if not FileAccess.file_exists(path):
		push_error("Missing track surface metadata: " + path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to read track surface metadata: " + path)
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
		var segment_length := a.distance_to(b)
		if segment_length < 0.05 or segment_length > 15.0:
			push_error("AC AI line has invalid segment length at %d: %.3f m" % [i, segment_length])
		total += segment_length
		min_height = minf(min_height, a.y)
		max_height = maxf(max_height, a.y)
	var expected_length := float(TRACKS[selected_track]["length"])
	var minimum_points := 2800 if selected_track == BARCELONA else 3000
	var length_tolerance := 160.0 if selected_track == BARCELONA else 100.0
	if _centerline.size() < minimum_points or absf(total - expected_length) > length_tolerance:
		push_error("Track line failed sanity check: track=%s points=%d length=%.1f m expected≈%.1f m" % [selected_track, _centerline.size(), total, expected_length])
	print("[track] %s | points=%d | sampled length=%.1f m | elevation %.1f..%.1f m" % [get_track_name(), _centerline.size(), total, min_height, max_height])

static func get_track_scene_path() -> String:
	return String(TRACKS[selected_track]["track_scene"])

static func get_track_rotation_y() -> float:
	return float(TRACKS[selected_track]["rotation_y"])

static func get_track_name() -> String:
	return String(TRACKS[selected_track]["name"])

static func get_selected_track_id() -> String:
	return selected_track

static func get_selected_track() -> Dictionary:
	return TRACKS[selected_track]

static func get_track_length_m() -> float:
	_ensure_loaded()
	return float(TRACKS[selected_track]["length"])

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
	return _centerline[0] - (_centerline[1] - _centerline[0]).normalized() * 18.0 + Vector3.UP * 0.03

static func get_spawn_yaw() -> float:
	_ensure_loaded()
	if _centerline.size() < 3:
		return 0.0
	var tangent := (_centerline[1] - _centerline[0]).normalized()
	return atan2(-tangent.x, -tangent.z)

static func get_ideal_line_path() -> String:
	return String(TRACKS[selected_track]["ideal_line"])

static func get_ideal_line() -> PackedVector3Array:
	_ensure_loaded()
	if _ideal_line_loaded_track == selected_track:
		return _ideal_line
	_ideal_line.clear()
	_ideal_line_loaded_track = selected_track
	var path := get_ideal_line_path()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing Assetto Corsa ideal_line.ai: " + path)
		return _ideal_line
	var raw := file.get_buffer(file.get_length())
	if raw.size() < 16:
		push_error("Truncated Assetto Corsa ideal line: " + path)
		return _ideal_line
	var point_count := raw.decode_s32(4)
	if point_count < 100 or point_count > 10000 or raw.size() < 16 + point_count * 20:
		push_error("Invalid AC ideal line data: count=%d size=%d" % [point_count, raw.size()])
		return _ideal_line
	for i in point_count:
		var record := 16 + i * 20
		_ideal_line.append(Vector3(-raw.decode_float(record), raw.decode_float(record + 4), -raw.decode_float(record + 8)))
	return _ideal_line

static func get_layout_name() -> String:
	return get_track_name()

static func get_ac_coordinate_transform() -> String:
	return AC_COORDINATE_TO_GODOT

static func get_surface_metadata() -> Dictionary:
	_ensure_loaded()
	return _surface_data

static func _source_node_names(label: String) -> Array:
	if not label.begins_with("["):
		return [label]
	var parsed: Variant = JSON.parse_string(label)
	if parsed is Array:
		return parsed
	return [label]

static func is_physics_node(node_name: String) -> bool:
	var metadata := get_surface_metadata()
	var physics_nodes: Dictionary = metadata.get("nodes", {})
	var unkeyed: Dictionary = metadata.get("unkeyed", {})
	var walls: Array = metadata.get("walls", [])
	for source_name in _source_node_names(node_name):
		var name := String(source_name)
		if physics_nodes.has(name) or unkeyed.has(name) or walls.has(name):
			return true
	return false

static func get_surface_for_node(node_name: String) -> String:
	var metadata := get_surface_metadata()
	var nodes: Dictionary = metadata.get("nodes", {})
	var unkeyed: Dictionary = metadata.get("unkeyed", {})
	for source_name in _source_node_names(node_name):
		var name := String(source_name)
		if nodes.has(name):
			return String(nodes[name])
		if unkeyed.has(name):
			return String(unkeyed[name])
		if metadata.get("walls", []).has(name):
			return "WALL"
		var inferred := classify_surface(name)
		if not inferred.is_empty():
			return inferred
	return classify_surface(node_name)

static func classify_surface(label: String) -> String:
	var upper := label.to_upper()
	for key in SURFACE_KEYS:
		if key in upper:
			return key
	return ""

static func get_surface_grip(prefix: String) -> float:
	var key := prefix.to_upper()
	var surface_table: Dictionary = get_surface_metadata().get("surfaces", {})
	if surface_table.has(key):
		return clampf(float(surface_table[key].get("friction", 0.9)), 0.2, 1.2)
	var surfaces_by_node: Dictionary = get_surface_metadata().get("nodes", {})
	if surfaces_by_node.has(prefix):
		var surface_key := String(surfaces_by_node[prefix])
		if surface_table.has(surface_key):
			return clampf(float(surface_table[surface_key].get("friction", 0.9)), 0.2, 1.2)
	if key.contains("WALL"):
		return 0.0
	match key:
		"TRM-BRC", "ROAD", "TARMAC", "ASPHALT":
			return 1.0
		"KERB", "CURB", "RUMBLE":
			return 0.88
		"CONCRETE", "PITS", "PITLANE":
			return 0.84
		"CUT":
			return 0.80
		"GRAVEL", "SAND":
			return 0.46
		"GRASS", "GREEN", "CARPET", "TURF", "OUT":
			return 0.58
		_:
			return 0.92

static func get_surface_grip_from_hit(label: String) -> float:
	return get_surface_grip(get_surface_for_node(label))

static func get_surface_fallback_name(label: String) -> String:
	var upper := label.to_upper()
	for key in SURFACE_KEYS:
		if upper.contains(key):
			return key
	return ""

static func get_vehicle_options() -> Dictionary:
	return {
		"redbull": {
			"name": "Red Bull RB22",
			"scene": "res://assets/RedBull.tscn",
			"model_path": "res://assets/RedBull-Drive.glb",
			"kind": "redbull",
			"forward_sign": -1.0,
			"lateral_sign": -1.0,
			"up_sign": 1.0,
		},
		"mclaren": {
			"name": "McLaren MP4/4 · Senna",
			"scene": "res://assets/MP44-Senna.glb",
			"model_path": "res://assets/MP44-Senna.glb",
			"kind": "mclaren",
			"forward_sign": 1.0,
			"lateral_sign": 1.0,
			"up_sign": 1.0,
		},
		"rb22_2026": {
			"name": "Red Bull RB22 · Verstappen 2026",
			"scene": "res://assets/RB22-2026-Verstappen.glb",
			"model_path": "res://assets/RB22-2026-Verstappen.glb",
			"kind": "rb22_2026",
			"forward_sign": -1.0,
			"lateral_sign": -1.0,
			"up_sign": 1.0,
		},
	}

static func get_selected_vehicle() -> Dictionary:
	return get_vehicle_options()[selected_vehicle]

static func get_selected_vehicle_id() -> String:
	return selected_vehicle

static func get_vehicle_name() -> String:
	return String(get_selected_vehicle().get("name", "Formula car"))

static func get_vehicle_name_for_id(vehicle_id: String) -> String:
	return String(get_vehicle_options().get(vehicle_id, get_vehicle_options()["redbull"])["name"])

static func get_car_model_path(vehicle_id: String = "") -> String:
	var id := vehicle_id if not vehicle_id.is_empty() else selected_vehicle
	return String(get_vehicle_options().get(id, get_vehicle_options()["redbull"])["model_path"])

static func get_track_wall_nodes() -> Array:
	return get_surface_metadata().get("walls", [])

static func is_wall_node(node_name: String) -> bool:
	return get_track_wall_nodes().has(node_name) or "WALL" in node_name.to_upper()

static func get_track_bounding_radius() -> float:
	return 600.0 if selected_track == BARCELONA else 1200.0

static func get_runoff_distance_m() -> float:
	return 9.0

static func get_track_height_difference() -> float:
	return -18.0 if selected_track == SUZUKA else 0.0

static func get_spawn_y_offset() -> float:
	return 0.3 + get_track_height_difference()

static func get_track_valid() -> bool:
	return validate_selection()

static func get_camera_map_path() -> String:
	return "res://assets/Suzuka-map.png" if selected_track == SUZUKA else ""

static func get_ideal_line_path_for_track(track_id: String = "") -> String:
	var id := track_id if not track_id.is_empty() else selected_track
	return String(TRACKS.get(id, TRACKS[BARCELONA])["ideal_line"])

static func get_surface_path() -> String:
	return String(TRACKS[selected_track]["surfaces"])

static func get_track_transform() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, get_track_rotation_y()), Vector3.ZERO)

static func get_track_summary() -> String:
	return "%s · %.1f km" % [get_track_name(), get_track_length_m() / 1000.0]

static func get_user_selection() -> Dictionary:
	return {"track": selected_track, "vehicle": selected_vehicle}

static func validate_selection() -> bool:
	_ensure_loaded()
	return not _centerline.is_empty() and FileAccess.file_exists(get_track_scene_path()) and FileAccess.file_exists(get_car_model_path())
