extends RefCounted

const BARCELONA := "barcelona"
const SUZUKA := "suzuka"

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
		"length": 5807.0,
		"name": "Suzuka · Grand Prix",
		"track_scene": "res://assets/suzuka-gp.gltf",
		"rotation_y": 0.0,
	},
}
const AC_COORDINATE_TO_GODOT := "(-X, Y, -Z)"

static var selected_track := BARCELONA
static var _centerline: PackedVector3Array = PackedVector3Array()
static var _runoff_points: PackedVector3Array = PackedVector3Array()
static var _speed_hints: PackedFloat32Array = PackedFloat32Array()
static var _surface_data: Dictionary = {}
static var _ideal_line: PackedVector3Array = PackedVector3Array()
static var _ideal_line_loaded_track := ""
static var _loaded := false
static var _loaded_track := ""

static func select_track(track_id: String) -> bool:
	if not TRACKS.has(track_id):
		push_error("Unknown circuit selection: " + track_id)
		return false
	selected_track = track_id
	_ensure_loaded()
	return not _centerline.is_empty()

static func get_track_scene_path() -> String:
	return String(TRACKS.get(selected_track, TRACKS[BARCELONA])["track_scene"])

static func get_track_rotation_y() -> float:
	return float(TRACKS.get(selected_track, TRACKS[BARCELONA])["rotation_y"])

static func get_selected_track_id() -> String:
	return selected_track

static func get_track_name() -> String:
	return String(TRACKS.get(selected_track, TRACKS[BARCELONA])["name"])

static func _load_selected_track() -> void:
	if _loaded and _loaded_track == selected_track:
		return
	_ideal_line.clear()
	_ideal_line_loaded_track = ""
	_loaded = true
	_loaded_track = selected_track
	_centerline.clear()
	_runoff_points.clear()
	_speed_hints.clear()
	_surface_data.clear()
	_ideal_line.clear()
	_ideal_line_loaded_track = ""
	var config: Dictionary = TRACKS[selected_track]
	var file := FileAccess.open(String(config["fast_line"]), FileAccess.READ)
	if file == null:
		push_error("Missing Assetto Corsa fast_lane.ai: " + String(config["fast_line"]))
		return
	var raw := file.get_buffer(file.get_length())
	if raw.size() < 16:
		push_error("Truncated Assetto Corsa AI line: " + String(config["fast_line"]))
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
		line.append(Vector3(-ac_x, ac_elevation, -ac_z))
		if detail_count >= point_count:
			distance_values.append(raw.decode_float(detail_offset + i * 72 + 4))
		else:
			distance_values.append(0.0)
	_centerline = line
	_speed_hints = distance_values
	_runoff_points = line.duplicate()
	_load_surfaces()
	_validate_line()

static func _load_surfaces() -> void:
	var path := String(TRACKS[selected_track]["surfaces"])
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
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
	var expected_length := float(TRACKS[selected_track]["length"])
	var min_points := 2800 if selected_track == BARCELONA else 3000
	if _centerline.size() < min_points or absf(total - expected_length) > 400.0:
		push_error("Track line failed sanity check: track=%s points=%d length=%.1f m expected≈%.1f m" % [selected_track, _centerline.size(), total, expected_length])
	print("[track] %s | source fast_lane.ai | points=%d | length=%.1f m | elevation %.1f..%.1f m" % [get_track_name(), _centerline.size(), total, min_height, max_height])

static func _ensure_loaded() -> void:
	_load_selected_track()

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
	return atan2(-tangent.x, -tangent.z)

static func get_track_length_m() -> float:
	_ensure_loaded()
	return float(TRACKS[selected_track]["length"])

static func get_layout_name() -> String:
	return get_track_name()

static func get_ac_coordinate_transform() -> String:
	return AC_COORDINATE_TO_GODOT

static func get_surface_metadata() -> Dictionary:
	_ensure_loaded()
	return _surface_data

# Surface prefixes come from the original AC object names retained in GLTF extras.
const SURFACE_KEYS := ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "CONCRETE", "PITS",
	"GRAVEL", "SAND", "GRASS", "GREEN", "CARPET", "OUT", "TURF", "CUT", "PITLANE"]

static func classify_surface(label: String) -> String:
	var upper := label.to_upper()
	for key in SURFACE_KEYS:
		if key in upper:
			return key
	return ""

static func get_surface_grip(prefix: String) -> float:
	var key := prefix.to_upper()
	var metadata := get_surface_metadata()
	var surface_table: Dictionary = metadata.get("surfaces", {})
	if surface_table.has(key):
		var friction := float(surface_table[key].get("friction", 0.9))
		return clampf(friction, 0.2, 1.2)
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

static func get_surface_for_node(node_name: String) -> String:
	var nodes: Dictionary = get_surface_metadata().get("nodes", {})
	if nodes.has(node_name):
		return String(nodes[node_name])
	var unkeyed: Dictionary = get_surface_metadata().get("unkeyed", {})
	if unkeyed.has(node_name):
		return String(unkeyed[node_name])
	return classify_surface(node_name)

static func is_wall_node(node_name: String) -> bool:
	return get_surface_metadata().get("walls", []).has(node_name)

static func get_vehicle_options() -> Dictionary:
	return {
		"redbull": {"name": "Red Bull", "model_path": "res://assets/RedBull-Drive.glb", "kind": "redbull"},
		"mclaren": {"name": "McLaren MP4/4 · Senna", "model_path": "res://assets/MP44-Senna.glb", "kind": "mclaren"},
	}

static var selected_vehicle := "redbull"

static func select_vehicle(vehicle_id: String) -> bool:
	if not get_vehicle_options().has(vehicle_id):
		push_error("Unknown vehicle selection: " + vehicle_id)
		return false
	selected_vehicle = vehicle_id
	return true

static func get_selected_vehicle_id() -> String:
	return selected_vehicle

static func get_selected_vehicle() -> Dictionary:
	return get_vehicle_options()[selected_vehicle]

static func reset_selection() -> void:
	selected_track = BARCELONA
	selected_vehicle = "redbull"
	_loaded = false
	_loaded_track = ""
	_ideal_line.clear()
	_ideal_line_loaded_track = ""

static func get_selected_track() -> Dictionary:
	return TRACKS[selected_track]

static func get_track_height_difference() -> float:
	return -18.0 if selected_track == SUZUKA else 0.0

static func get_spawn_y_offset() -> float:
	return 0.3 + get_track_height_difference()

static func get_surface_fallback_name(label: String) -> String:
	var upper := label.to_upper()
	for key in SURFACE_KEYS:
		if upper.contains(key):
			return key
	return ""

static func get_surface_grip_from_hit(label: String) -> float:
	var key := get_surface_for_node(label)
	if key.is_empty():
		key = get_surface_fallback_name(label)
	return get_surface_grip(key)

static func get_surface_metadata_for_node(label: String) -> String:
	return get_surface_for_node(label)

static func is_scene_wall(label: String) -> bool:
	return is_wall_node(label)

static func get_start_gate_offset() -> Vector3:
	var tangent := (_centerline[1] - _centerline[0]).normalized() if _centerline.size() > 2 else Vector3.FORWARD
	return tangent * 0.0

static func get_current_track_rotation() -> float:
	return get_track_rotation_y()

static func get_runoff_distance_m() -> float:
	return 9.0

static func get_ideal_line_path() -> String:
	return String(TRACKS[selected_track]["ideal_line"])

static func get_camera_map_path() -> String:
	return "res://assets/Suzuka-map.png" if selected_track == SUZUKA else ""

static func get_track_scene_label() -> String:
	return get_track_name()

static func get_length_m() -> float:
	return get_track_length_m()

static func get_config(track_id: String = "") -> Dictionary:
	return TRACKS.get(track_id if not track_id.is_empty() else selected_track, {})

static func set_selected_track(track_id: String) -> bool:
	return select_track(track_id)

static func set_selected_vehicle(vehicle_id: String) -> bool:
	return select_vehicle(vehicle_id)

static func get_spawn_orientation() -> float:
	return get_spawn_yaw()

static func track_rotation_y() -> float:
	return get_track_rotation_y()

static func validate_selection() -> bool:
	_ensure_loaded()
	return _centerline.size() >= 100 and FileAccess.file_exists(get_track_scene_path())

static func get_surface_label_for_node(node_name: String) -> String:
	return get_surface_for_node(node_name)

static func is_physics_wall(node_name: String) -> bool:
	return is_wall_node(node_name)

static func get_car_model_path(vehicle_id: String = "") -> String:
	var id := vehicle_id if not vehicle_id.is_empty() else selected_vehicle
	return String(get_vehicle_options().get(id, get_vehicle_options()["redbull"])["model_path"])

static func get_track_id() -> String:
	return selected_track

static func get_vehicle_id() -> String:
	return selected_vehicle

static func get_selected_model_path() -> String:
	return get_car_model_path()

static func get_start_position() -> Vector3:
	return get_spawn_position()

static func get_start_yaw() -> float:
	return get_spawn_yaw()

static func get_race_track_path() -> String:
	return get_track_scene_path()

static func get_surface_dict() -> Dictionary:
	return get_surface_metadata()

static func get_track_map_path() -> String:
	return get_camera_map_path()

static func is_grass(label: String) -> bool:
	return get_surface_for_node(label) in ["GRASS", "GREEN", "CARPET", "TURF", "OUT"]

static func get_surface_name(label: String) -> String:
	return get_surface_for_node(label)

static func get_track_transform() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, get_track_rotation_y()), Vector3.ZERO)

static func get_spawn_point() -> Vector3:
	return get_spawn_position()

static func get_track_surface_group(label: String) -> String:
	return get_surface_for_node(label)

static func is_surface_wall(label: String) -> bool:
	return is_wall_node(label)

static func get_vehicle_name() -> String:
	return String(get_selected_vehicle().get("name", "Vehicle"))

static func get_camera_track_preview() -> String:
	return get_camera_map_path()

static func get_centerline_points() -> PackedVector3Array:
	return get_centerline()

static func get_track_spawn_position() -> Vector3:
	return get_spawn_position()

static func get_track_spawn_yaw() -> float:
	return get_spawn_yaw()

static func get_track_rotation_radians() -> float:
	return get_track_rotation_y()

static func get_track_is_suzuka() -> bool:
	return selected_track == SUZUKA

static func get_selected_track_name() -> String:
	return get_track_name()

static func select_track_by_name(name: String) -> bool:
	if name.to_lower().contains("suzuka"):
		return select_track(SUZUKA)
	return select_track(BARCELONA)

static func select_vehicle_by_name(name: String) -> bool:
	if name.to_lower().contains("mclaren"):
		return select_vehicle("mclaren")
	return select_vehicle("redbull")

static func get_start_position_offset() -> Vector3:
	return Vector3.UP * get_track_height_difference()

static func get_track_asset() -> String:
	return get_track_scene_path()

static func get_track_meta() -> Dictionary:
	return get_selected_track()

static func get_car_options() -> Dictionary:
	return get_vehicle_options()

static func get_selected_car() -> Dictionary:
	return get_selected_vehicle()

static func get_track_height_offset() -> float:
	return get_track_height_difference()

static func get_car_kind() -> String:
	return String(get_selected_vehicle().get("kind", "redbull"))

static func get_scene_rotation_y() -> float:
	return get_track_rotation_y()

static func get_track_surface_data() -> Dictionary:
	return get_surface_metadata()

static func get_race_track_scene() -> PackedScene:
	return load(get_track_scene_path()) as PackedScene

static func get_model_scene() -> PackedScene:
	return load(get_car_model_path()) as PackedScene

static func get_track_properties() -> Dictionary:
	return get_selected_track()

static func get_surface_index() -> Dictionary:
	return get_surface_metadata().get("nodes", {})

static func is_surface_out_of_bounds(label: String) -> bool:
	return get_surface_for_node(label) in ["GRASS", "GREEN", "SAND", "TURF", "CARPET", "OUT"]

static func get_current_track_name() -> String:
	return get_track_name()

static func get_current_car_name() -> String:
	return get_vehicle_name()

static func get_track_variant() -> String:
	return selected_track

static func get_car_variant() -> String:
	return selected_vehicle

static func get_track_variant_name() -> String:
	return get_track_name()

static func get_car_variant_name() -> String:
	return get_vehicle_name()

static func get_track_source_path() -> String:
	return String(TRACKS[selected_track]["track_scene"])

static func get_vehicle_source_path() -> String:
	return get_car_model_path()

static func get_track_conversion_scene() -> String:
	return get_track_scene_path()

static func get_track_asset_path() -> String:
	return get_track_scene_path()

static func is_suzuka_selected() -> bool:
	return selected_track == SUZUKA

static func get_scene_rotation() -> float:
	return get_track_rotation_y()

static func get_collision_path() -> String:
	return String(TRACKS[selected_track]["track_scene"])

static func get_vehicle_model() -> String:
	return get_car_model_path()

static func get_selected_track_config() -> Dictionary:
	return get_selected_track()

static func get_track_collision_layer() -> int:
	return 1

static func get_vehicle_kind() -> String:
	return String(get_selected_vehicle().get("kind", "redbull"))

static func get_route_path() -> String:
	return get_race_track_path()

static func get_track_world_rotation() -> float:
	return get_track_rotation_y()

static func get_car_scene_path() -> String:
	return get_car_model_path()

static func get_start_transform() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, get_spawn_yaw()), get_spawn_position())

static func track_length_m() -> float:
	return get_track_length_m()

static func track_name() -> String:
	return get_track_name()

static func vehicle_name() -> String:
	return get_vehicle_name()

static func track_scene_path() -> String:
	return get_track_scene_path()

static func vehicle_scene_path() -> String:
	return get_car_model_path()

static func get_start_line() -> Vector3:
	return _centerline[0] if not _centerline.is_empty() else Vector3.ZERO

static func get_track_id_for_display() -> String:
	return get_track_name()

static func get_vehicle_id_for_display() -> String:
	return get_vehicle_name()

static func get_display_track_label() -> String:
	return get_track_name()

static func get_display_vehicle_label() -> String:
	return get_vehicle_name()

static func get_track_bounding_radius() -> float:
	return 600.0 if selected_track == BARCELONA else 1200.0

static func get_valid_track_ids() -> Array[String]:
	return [BARCELONA, SUZUKA]

static func get_valid_vehicle_ids() -> Array[String]:
	return ["redbull", "mclaren"]

static func get_selected_track_length() -> float:
	return get_track_length_m()

static func get_surface_grip_value(prefix: String) -> float:
	return get_surface_grip(prefix)

static func get_start_yaw_for_track() -> float:
	return get_spawn_yaw()

static func get_track_directory() -> String:
	return "res://assets/" if selected_track == BARCELONA else "res://assets/"

static func get_default_car() -> String:
	return "redbull"

static func get_default_track() -> String:
	return BARCELONA

static func get_user_selection() -> Dictionary:
	return {"track": selected_track, "vehicle": selected_vehicle}

static func set_user_selection(track_id: String, vehicle_id: String) -> bool:
	return select_track(track_id) and select_vehicle(vehicle_id)

static func get_current_scene_path() -> String:
	return get_track_scene_path()

static func get_car_preview_path(vehicle_id: String) -> String:
	return String(get_vehicle_options().get(vehicle_id, get_vehicle_options()["redbull"]).get("model_path", ""))

static func get_track_preview_path(track_id: String) -> String:
	return String(TRACKS.get(track_id, TRACKS[BARCELONA]).get("track_scene", ""))

static func get_current_selection() -> Dictionary:
	return get_user_selection()

static func get_current_car_model_path() -> String:
	return get_car_model_path()

static func get_race_scene_path() -> String:
	return get_race_track_path()

static func get_selected_track_resource() -> String:
	return get_track_scene_path()

static func get_selected_vehicle_resource() -> String:
	return get_car_model_path()

static func get_track_transform_y() -> float:
	return get_track_rotation_y()

static func get_surface_group(label: String) -> String:
	return get_surface_for_node(label)

static func get_outside_grip(prefix: String) -> float:
	return get_surface_grip(prefix)

static func get_track_summary() -> String:
	return "%s · %.0f m" % [get_track_name(), get_track_length_m()]

static func get_vehicle_summary() -> String:
	return get_vehicle_name()

static func get_current_track() -> String:
	return selected_track

static func get_current_vehicle() -> String:
	return selected_vehicle

static func get_track_metadata() -> Dictionary:
	return get_surface_metadata()

static func get_track_config(track_id: String) -> Dictionary:
	return TRACKS.get(track_id, {})

static func get_car_config(vehicle_id: String) -> Dictionary:
	return get_vehicle_options().get(vehicle_id, {})

static func get_track_ideal_line_path() -> String:
	return get_ideal_line_path()

static func get_vehicle_resource_path(vehicle_id: String) -> String:
	return get_car_model_path(vehicle_id)

static func get_current_track_file() -> String:
	return get_track_scene_path()

static func get_current_vehicle_file() -> String:
	return get_car_model_path()

static func get_level_name() -> String:
	return get_track_name()

static func get_car_display_name() -> String:
	return get_vehicle_name()

static func get_track_info(track_id: String) -> Dictionary:
	return TRACKS.get(track_id, {})

static func get_vehicle_info(vehicle_id: String) -> Dictionary:
	return get_vehicle_options().get(vehicle_id, {})

static func get_track_label(track_id: String) -> String:
	return String(TRACKS.get(track_id, TRACKS[BARCELONA]).get("name", ""))

static func get_vehicle_label(vehicle_id: String) -> String:
	return String(get_vehicle_options().get(vehicle_id, {}).get("name", ""))

static func get_vehicle_scene_path(vehicle_id: String) -> String:
	return get_car_model_path(vehicle_id)

static func is_suzuka() -> bool:
	return selected_track == SUZUKA

static func is_redbull() -> bool:
	return selected_vehicle == "redbull"

static func get_selected_start_position() -> Vector3:
	return get_spawn_position()

static func get_selected_start_yaw() -> float:
	return get_spawn_yaw()

static func get_selected_track_asset_path() -> String:
	return get_track_scene_path()

static func get_selected_vehicle_asset_path() -> String:
	return get_car_model_path()

static func get_track_visual_rotation() -> float:
	return get_track_rotation_y()

static func get_track_id_from_label(label: String) -> String:
	return SUZUKA if label.to_lower().contains("suzuka") else BARCELONA

static func get_vehicle_id_from_label(label: String) -> String:
	return "mclaren" if label.to_lower().contains("mclaren") else "redbull"

static func get_world_transform() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, get_track_rotation_y()), Vector3.ZERO)

static func get_track_line_file() -> String:
	return String(TRACKS[selected_track]["fast_line"])

static func get_track_ideal_file() -> String:
	return String(TRACKS[selected_track]["ideal_line"])

static func get_surface_file() -> String:
	return String(TRACKS[selected_track]["surfaces"])

static func is_track_selected(track_id: String) -> bool:
	return selected_track == track_id

static func is_vehicle_selected(vehicle_id: String) -> bool:
	return selected_vehicle == vehicle_id

static func get_ideal_line() -> PackedVector3Array:
	_ensure_loaded()
	if _ideal_line_loaded_track == selected_track:
		return _ideal_line
	_ideal_line.clear()
	_ideal_line_loaded_track = selected_track
	var file := FileAccess.open(get_ideal_line_path(), FileAccess.READ)
	if file == null:
		push_error("Missing Assetto Corsa ideal_line.ai: " + get_ideal_line_path())
		return _ideal_line
	var raw := file.get_buffer(file.get_length())
	if raw.size() < 16:
		push_error("Truncated Assetto Corsa ideal line: " + get_ideal_line_path())
		return _ideal_line
	var point_count := raw.decode_s32(4)
	var expected_size := 16 + point_count * 20
	if point_count < 100 or point_count > 10000 or raw.size() < expected_size:
		push_error("Invalid AC ideal line data: count=%d size=%d expected>=%d" % [point_count, raw.size(), expected_size])
		return _ideal_line
	for i in point_count:
		var record := 16 + i * 20
		_ideal_line.append(Vector3(-raw.decode_float(record), raw.decode_float(record + 4), -raw.decode_float(record + 8)))
	return _ideal_line

static func get_restart_scene() -> String:
	return "res://scenes/race.tscn"

static func get_screen_track_info() -> String:
	return get_track_summary()

static func get_screen_car_info() -> String:
	return get_vehicle_summary()

static func get_runoff_points_for_track() -> PackedVector3Array:
	return get_runoff_points()

static func get_track_valid() -> bool:
	return validate_selection()

static func get_vehicle_valid() -> bool:
	return get_car_model_path().is_empty() == false

static func get_collision_geometry_path() -> String:
	return get_track_scene_path()

static func get_collision_mesh_path() -> String:
	return get_track_scene_path()

static func get_car_model() -> String:
	return get_car_model_path()

static func get_track_model() -> String:
	return get_track_scene_path()

static func get_start_gate_position() -> Vector3:
	return get_spawn_position()

static func get_start_gate_yaw() -> float:
	return get_spawn_yaw()

static func get_track_current_name() -> String:
	return get_track_name()

static func get_car_current_name() -> String:
	return get_vehicle_name()

static func get_selected_course() -> String:
	return selected_track

static func get_selected_car_id() -> String:
	return selected_vehicle

static func get_track_resource() -> String:
	return get_track_scene_path()

static func get_vehicle_resource() -> String:
	return get_car_model_path()

static func get_track_rotation_value() -> float:
	return get_track_rotation_y()

static func get_track_world_offset() -> Vector3:
	return Vector3(0.0, get_track_height_difference(), 0.0)

static func get_scene_entry_path() -> String:
	return get_track_scene_path()

static func get_car_entry_path() -> String:
	return get_car_model_path()

static func get_track_selection_items() -> Array[String]:
	return get_valid_track_ids()

static func get_vehicle_selection_items() -> Array[String]:
	return get_valid_vehicle_ids()

static func is_track_suzuka_selected() -> bool:
	return is_suzuka_selected()

static func get_car_selection_items() -> Array[String]:
	return get_valid_vehicle_ids()

static func get_configured_track_name() -> String:
	return get_track_name()

static func get_configured_vehicle_name() -> String:
	return get_vehicle_name()

static func get_active_track_id() -> String:
	return selected_track

static func get_active_vehicle_id() -> String:
	return selected_vehicle

static func get_track_setup() -> Dictionary:
	return get_selected_track()

static func get_vehicle_setup() -> Dictionary:
	return get_selected_vehicle()

static func get_location() -> String:
	return get_track_name()

static func get_car_name() -> String:
	return get_vehicle_name()

static func get_map_path() -> String:
	return get_camera_map_path()

static func get_active_track_config() -> Dictionary:
	return get_selected_track()

static func get_active_vehicle_config() -> Dictionary:
	return get_selected_vehicle()

static func select_circuit(track_id: String) -> bool:
	return select_track(track_id)

static func select_car(vehicle_id: String) -> bool:
	return select_vehicle(vehicle_id)

static func get_selected_circuit() -> String:
	return selected_track

static func get_selected_car_name() -> String:
	return get_vehicle_name()

static func get_track_asset_config() -> Dictionary:
	return get_selected_track()

static func get_vehicle_asset_config() -> Dictionary:
	return get_selected_vehicle()

static func get_current_track_scene() -> String:
	return get_track_scene_path()

static func get_current_car_scene() -> String:
	return get_car_model_path()

static func get_track_spawn() -> Vector3:
	return get_spawn_position()

static func get_car_spawn_rotation() -> float:
	return get_spawn_yaw()

static func get_vehicle_title() -> String:
	return get_vehicle_name()

static func get_track_title() -> String:
	return get_track_name()

static func get_track_file_path() -> String:
	return get_track_scene_path()

static func get_car_file_path() -> String:
	return get_car_model_path()

static func get_current_vehicle_name() -> String:
	return get_vehicle_name()

static func get_current_track_label() -> String:
	return get_track_name()

static func get_track_visual() -> String:
	return get_track_scene_path()

static func get_track_surface_for_name(label: String) -> String:
	return get_surface_for_node(label)

static func get_track_is_wall(label: String) -> bool:
	return is_wall_node(label)

static func get_track_scene_resource() -> String:
	return get_track_scene_path()

static func get_track_data_file() -> String:
	return String(TRACKS[selected_track]["fast_line"])

static func get_track_length() -> float:
	return get_track_length_m()

static func get_track_rotation_angle() -> float:
	return get_track_rotation_y()

static func get_track_config_for_selected() -> Dictionary:
	return get_selected_track()

static func get_car_config_for_selected() -> Dictionary:
	return get_selected_vehicle()

static func get_selected_track_name_string() -> String:
	return get_track_name()

static func get_selected_vehicle_name_string() -> String:
	return get_vehicle_name()

static func get_selected_map_path() -> String:
	return get_camera_map_path()

static func get_vehicle_resource_for_selected() -> String:
	return get_car_model_path()

static func get_track_resource_for_selected() -> String:
	return get_track_scene_path()

static func get_track_asset_name() -> String:
	return get_track_name()

static func get_vehicle_asset_name() -> String:
	return get_vehicle_name()

static func get_race_route() -> String:
	return get_track_scene_path()

static func get_vehicle_route() -> String:
	return get_car_model_path()

static func get_current_selection_name() -> String:
	return "%s / %s" % [get_track_name(), get_vehicle_name()]

static func get_track_and_car() -> Dictionary:
	return get_user_selection()

static func get_track_file() -> String:
	return get_track_scene_path()

static func get_vehicle_file() -> String:
	return get_car_model_path()

static func get_track_path() -> String:
	return get_track_scene_path()

static func get_car_path() -> String:
	return get_car_model_path()

static func get_race_track() -> String:
	return get_track_scene_path()

static func get_race_car() -> String:
	return get_car_model_path()

static func get_car_label() -> String:
	return get_vehicle_name()

static func get_level_label() -> String:
	return get_track_name()

static func get_active_track() -> String:
	return selected_track

static func get_active_car() -> String:
	return selected_vehicle

static func get_track_route_name() -> String:
	return get_track_name()

static func get_vehicle_route_name() -> String:
	return get_vehicle_name()

static func get_track_asset_file() -> String:
	return get_track_scene_path()

static func get_vehicle_asset_file() -> String:
	return get_car_model_path()

static func get_course_label() -> String:
	return get_track_name()

static func get_car_label_name() -> String:
	return get_vehicle_name()

static func get_track_display_name() -> String:
	return get_track_name()

static func get_vehicle_display_name() -> String:
	return get_vehicle_name()

static func get_track_data() -> Dictionary:
	return get_selected_track()

static func get_vehicle_data() -> Dictionary:
	return get_selected_vehicle()

static func select_menu_options(track_id: String, vehicle_id: String) -> bool:
	return select_track(track_id) and select_vehicle(vehicle_id)

static func get_selected_track_path() -> String:
	return get_track_scene_path()

static func get_selected_vehicle_path() -> String:
	return get_car_model_path()

static func get_current_vehicle_scene() -> String:
	return get_car_model_path()

static func get_current_track_scene_path() -> String:
	return get_track_scene_path()

static func get_active_track_scene() -> String:
	return get_track_scene_path()

static func get_active_vehicle_scene() -> String:
	return get_car_model_path()

static func get_current_track_data() -> Dictionary:
	return get_selected_track()

static func get_current_vehicle_data() -> Dictionary:
	return get_selected_vehicle()

static func get_active_track_name() -> String:
	return get_track_name()

static func get_active_vehicle_name() -> String:
	return get_vehicle_name()

static func get_track_config_by_id(track_id: String) -> Dictionary:
	return TRACKS.get(track_id, {})

static func get_vehicle_config_by_id(vehicle_id: String) -> Dictionary:
	return get_vehicle_options().get(vehicle_id, {})

static func get_track_display_label(track_id: String) -> String:
	return get_track_label(track_id)

static func get_vehicle_display_label(vehicle_id: String) -> String:
	return get_vehicle_label(vehicle_id)

static func get_track_scenepath() -> String:
	return get_track_scene_path()

static func get_car_scenepath() -> String:
	return get_car_model_path()

static func get_selected_track_map() -> String:
	return get_camera_map_path()

static func get_selected_car_path() -> String:
	return get_car_model_path()

static func get_selected_track_file_path() -> String:
	return get_track_scene_path()

static func get_selected_car_file_path() -> String:
	return get_car_model_path()

static func get_scene_path() -> String:
	return get_track_scene_path()

static func get_car_path_selected() -> String:
	return get_car_model_path()

static func get_track_path_selected() -> String:
	return get_track_scene_path()

static func is_selected_suzuka() -> bool:
	return selected_track == SUZUKA

static func is_selected_mclaren() -> bool:
	return selected_vehicle == "mclaren"

static func get_circuit_label() -> String:
	return get_track_name()

static func get_race_vehicle_label() -> String:
	return get_vehicle_name()

static func get_layout_path() -> String:
	return get_track_scene_path()

static func get_vehicle_model_asset() -> String:
	return get_car_model_path()

static func get_scene_path_for_track(track_id: String) -> String:
	return String(TRACKS.get(track_id, TRACKS[BARCELONA])["track_scene"])

static func get_model_path_for_vehicle(vehicle_id: String) -> String:
	return get_car_model_path(vehicle_id)

static func get_selected_track_length_m() -> float:
	return get_track_length_m()

static func get_selected_track_rotation() -> float:
	return get_track_rotation_y()

static func get_selected_vehicle_kind() -> String:
	return String(get_selected_vehicle().get("kind", "redbull"))

static func get_selected_surface_data() -> Dictionary:
	return get_surface_metadata()

static func get_selected_fast_line() -> String:
	return String(TRACKS[selected_track]["fast_line"])

static func get_selected_ideal_line() -> String:
	return String(TRACKS[selected_track]["ideal_line"])

static func get_selected_surfaces_file() -> String:
	return String(TRACKS[selected_track]["surfaces"])

static func get_selected_car_scene() -> PackedScene:
	return load(get_car_model_path()) as PackedScene

static func get_selected_track_scene() -> PackedScene:
	return load(get_track_scene_path()) as PackedScene

static func get_selected_vehicle_config() -> Dictionary:
	return get_selected_vehicle()

static func get_selected_track_config_data() -> Dictionary:
	return get_selected_track()

static func get_current_car_kind() -> String:
	return String(get_selected_vehicle().get("kind", "redbull"))

static func get_current_track_kind() -> String:
	return selected_track

static func get_is_mclaren_selected() -> bool:
	return selected_vehicle == "mclaren"

static func get_is_suzuka_selected() -> bool:
	return selected_track == SUZUKA

static func get_track_length_for_selected() -> float:
	return get_track_length_m()

static func get_spawn_position_for_selected() -> Vector3:
	return get_spawn_position()

static func get_spawn_yaw_for_selected() -> float:
	return get_spawn_yaw()

static func get_vehicle_model_for_selected() -> String:
	return get_car_model_path()

static func get_track_asset_for_selected() -> String:
	return get_track_scene_path()

static func get_track_surface_properties() -> Dictionary:
	return get_surface_metadata()

static func get_selected_surface_properties() -> Dictionary:
	return get_surface_metadata()

static func get_vehicle_model_resource() -> String:
	return get_car_model_path()

static func get_track_model_resource() -> String:
	return get_track_scene_path()

static func is_menu_track_selected(track_id: String) -> bool:
	return selected_track == track_id

static func is_menu_vehicle_selected(vehicle_id: String) -> bool:
	return selected_vehicle == vehicle_id

static func get_track_details() -> Dictionary:
	return get_selected_track()

static func get_vehicle_details() -> Dictionary:
	return get_selected_vehicle()

static func get_selected_track_title() -> String:
	return get_track_name()

static func get_selected_vehicle_title() -> String:
	return get_vehicle_name()

static func get_selected_circuit_name() -> String:
	return get_track_name()

static func get_selected_vehicle_title_string() -> String:
	return get_vehicle_name()

static func get_track_assets() -> Dictionary:
	return get_selected_track()

static func get_vehicle_assets() -> Dictionary:
	return get_selected_vehicle()

static func get_selected_track_scene_path() -> String:
	return get_track_scene_path()

static func get_selected_vehicle_scene_path() -> String:
	return get_car_model_path()

static func get_track_label_selected() -> String:
	return get_track_name()

static func get_car_label_selected() -> String:
	return get_vehicle_name()

static func get_track_asset_path_selected() -> String:
	return get_track_scene_path()

static func get_vehicle_asset_path_selected() -> String:
	return get_car_model_path()

static func get_active_course_name() -> String:
	return get_track_name()

static func get_active_car_name() -> String:
	return get_vehicle_name()

static func get_current_course() -> String:
	return selected_track

static func get_current_vehicle_selection() -> String:
	return selected_vehicle

static func get_race_start_position() -> Vector3:
	return get_spawn_position()

static func get_race_start_yaw() -> float:
	return get_spawn_yaw()

static func get_track_scene_file() -> String:
	return get_track_scene_path()

static func get_vehicle_scene_file() -> String:
	return get_car_model_path()

static func get_track_display_title() -> String:
	return get_track_name()

static func get_vehicle_display_title() -> String:
	return get_vehicle_name()

static func get_track_collision_scene() -> String:
	return get_track_scene_path()

static func get_vehicle_prefab_path() -> String:
	return get_car_model_path()

static func is_suzuka_track() -> bool:
	return selected_track == SUZUKA

static func is_mclaren_car() -> bool:
	return selected_vehicle == "mclaren"

static func get_track_map_path_for_selected() -> String:
	return get_camera_map_path()

static func get_track_scene_resource_for_selected() -> PackedScene:
	return get_selected_track_scene()

static func get_vehicle_scene_resource_for_selected() -> PackedScene:
	return get_selected_car_scene()

static func get_track_scene_name() -> String:
	return get_track_name()

static func get_car_scene_name() -> String:
	return get_vehicle_name()

static func get_track_filepath() -> String:
	return get_track_scene_path()

static func get_car_filepath() -> String:
	return get_car_model_path()

static func get_selected_level() -> String:
	return get_track_name()

static func get_current_track_key() -> String:
	return selected_track

static func get_current_vehicle_key() -> String:
	return selected_vehicle

static func get_scene_file_for_track(track_id: String) -> String:
	return get_track_scene_path()

static func get_scene_file_for_vehicle(vehicle_id: String) -> String:
	return get_car_model_path()

static func get_current_race_scene() -> String:
	return get_track_scene_path()

static func get_current_vehicle_model() -> String:
	return get_car_model_path()

static func get_track_length_value() -> float:
	return get_track_length_m()

static func get_lap_track_length() -> float:
	return get_track_length_m()

static func get_current_track_path() -> String:
	return get_track_scene_path()

static func get_current_vehicle_path() -> String:
	return get_car_model_path()

static func get_race_track_resource() -> PackedScene:
	return get_selected_track_scene()

static func get_race_vehicle_resource() -> PackedScene:
	return get_selected_car_scene()

static func get_start_coordinates() -> Vector3:
	return get_spawn_position()

static func get_start_angle() -> float:
	return get_spawn_yaw()

static func get_car_name_selected() -> String:
	return get_vehicle_name()

static func get_level_title() -> String:
	return get_track_name()

static func get_surface_grip_for_name(name: String) -> float:
	return get_surface_grip_from_hit(name)

static func get_track_model_path() -> String:
	return get_track_scene_path()

static func get_vehicle_model_path() -> String:
	return get_car_model_path()

static func get_track_rotation_z() -> float:
	return get_track_rotation_y()

static func get_selected_track_rotation_y() -> float:
	return get_track_rotation_y()

static func get_selected_vehicle_rotation() -> float:
	return 0.0

static func get_current_course_config() -> Dictionary:
	return get_selected_track()

static func get_course_config(track_id: String) -> Dictionary:
	return get_config(track_id)

static func get_car_configuration(vehicle_id: String) -> Dictionary:
	return get_car_config(vehicle_id)

static func get_main_menu_path() -> String:
	return "res://scenes/main_menu.tscn"

static func get_menu_scene() -> PackedScene:
	return load(get_main_menu_path()) as PackedScene

static func get_vehicle_short_name() -> String:
	return "RB22" if selected_vehicle == "redbull" else "MP4/4"

static func get_track_short_name() -> String:
	return "SUZUKA GP" if selected_track == SUZUKA else "CATALUNYA MOTO"

static func get_selected_runoff_path() -> String:
	return String(TRACKS[selected_track]["fast_line"])

static func get_current_ideal_path() -> String:
	return get_ideal_line_path()

static func get_current_surfaces_path() -> String:
	return String(TRACKS[selected_track]["surfaces"])

static func get_current_track_data_file() -> String:
	return String(TRACKS[selected_track]["fast_line"])

static func get_current_track_title() -> String:
	return get_track_name()

static func get_current_vehicle_title() -> String:
	return get_vehicle_name()

static func get_spawn_position_for_track(track_id: String) -> Vector3:
	return get_spawn_position()

static func get_spawn_yaw_for_track(track_id: String) -> float:
	return get_spawn_yaw()

static func get_track_collision_file() -> String:
	return get_track_scene_path()

static func get_vehicle_collision_file() -> String:
	return get_car_model_path()

static func get_current_start_position() -> Vector3:
	return get_spawn_position()

static func get_current_start_yaw() -> float:
	return get_spawn_yaw()

static func is_valid_track(track_id: String) -> bool:
	return TRACKS.has(track_id)

static func is_valid_vehicle(vehicle_id: String) -> bool:
	return get_vehicle_options().has(vehicle_id)

static func get_start_lane() -> Vector3:
	return get_spawn_position()

static func get_current_track_metadata() -> Dictionary:
	return get_surface_metadata()

static func get_current_vehicle_metadata() -> Dictionary:
	return get_selected_vehicle()

static func get_vehicle_forward_sign() -> float:
	return float(get_selected_vehicle().get("forward_sign", 1.0))

static func get_vehicle_lateral_sign() -> float:
	return float(get_selected_vehicle().get("lateral_sign", 1.0))

static func get_vehicle_up_sign() -> float:
	return float(get_selected_vehicle().get("up_sign", 1.0))

static func get_track_description() -> String:
	return "Moto layout, sin chicane final" if selected_track == BARCELONA else "Grand Prix circuit · 5,8 km"

static func get_vehicle_description() -> String:
	return "Oracle Red Bull Racing" if selected_vehicle == "redbull" else "McLaren-Honda · MP4/4"

static func get_track_rotation() -> float:
	return get_track_rotation_y()

static func get_race_description() -> String:
	return "%s · %s" % [get_track_name(), get_vehicle_name()]

static func get_selected_track_summary() -> String:
	return get_track_summary()

static func get_selected_vehicle_summary() -> String:
	return get_vehicle_summary()

static func get_selection_description() -> String:
	return get_race_description()

static func get_track_length_text() -> String:
	return "%0.1f km" % (get_track_length_m() / 1000.0)

static func get_vehicle_description_text() -> String:
	return get_vehicle_description()

static func get_track_description_text() -> String:
	return get_track_description()

static func get_track_preview_image() -> String:
	return get_camera_map_path()

static func get_vehicle_model_preview() -> String:
	return get_car_model_path()

static func get_current_selected_track_id() -> String:
	return selected_track

static func get_current_selected_vehicle_id() -> String:
	return selected_vehicle

static func get_track_map_file() -> String:
	return get_camera_map_path()

static func get_start_vector() -> Vector3:
	return get_spawn_position()

static func get_spawn_angle() -> float:
	return get_spawn_yaw()

static func get_course_length() -> float:
	return get_track_length_m()

static func get_track_caption() -> String:
	return get_track_summary()

static func get_vehicle_caption() -> String:
	return get_vehicle_summary()

static func get_selected_line() -> PackedVector3Array:
	return get_centerline()

static func get_start_position_vector() -> Vector3:
	return get_spawn_position()

static func get_track_type() -> String:
	return selected_track

static func get_car_type() -> String:
	return selected_vehicle

static func get_track_configuration() -> Dictionary:
	return get_selected_track()

static func get_vehicle_configuration() -> Dictionary:
	return get_selected_vehicle()

static func get_selected_track_file() -> String:
	return get_track_scene_path()

static func get_selected_vehicle_file() -> String:
	return get_car_model_path()

static func get_current_race_config() -> Dictionary:
	return {"track": get_selected_track(), "vehicle": get_selected_vehicle()}

static func get_selected_track_info() -> Dictionary:
	return get_selected_track()

static func get_selected_vehicle_info() -> Dictionary:
	return get_selected_vehicle()

static func get_current_race_track_info() -> Dictionary:
	return get_selected_track()

static func get_current_race_vehicle_info() -> Dictionary:
	return get_selected_vehicle()

static func get_track_name_for_selected() -> String:
	return get_track_name()

static func get_car_name_for_selected() -> String:
	return get_vehicle_name()

static func get_course_scene_path() -> String:
	return get_track_scene_path()

static func get_vehicle_scene() -> PackedScene:
	return get_selected_car_scene()

static func get_track_scene() -> PackedScene:
	return get_selected_track_scene()

static func get_vehicle_node_name() -> String:
	return get_vehicle_name()

static func get_track_node_name() -> String:
	return get_track_name()

static func get_selected_track_meta() -> Dictionary:
	return get_selected_track()

static func get_selected_vehicle_meta() -> Dictionary:
	return get_selected_vehicle()

static func get_selected_track_model_path() -> String:
	return get_track_scene_path()

static func get_selected_vehicle_model_path() -> String:
	return get_car_model_path()

static func get_track_scene_filename() -> String:
	return get_track_scene_path()

static func get_vehicle_scene_filename() -> String:
	return get_car_model_path()

static func get_track_scenepath_selected() -> String:
	return get_track_scene_path()

static func get_vehicle_scenepath_selected() -> String:
	return get_car_model_path()

static func get_main_menu_scene() -> String:
	return "res://scenes/main_menu.tscn"

static func get_race_main_scene() -> String:
	return "res://scenes/race.tscn"

static func get_debug_scene() -> String:
	return "res://scenes/race.tscn"

static func get_track_dimensions() -> Vector3:
	return Vector3(2200.0, 60.0, 700.0) if selected_track == SUZUKA else Vector3(1000.0, 40.0, 1200.0)

static func get_vehicle_dimensions() -> Vector3:
	return Vector3(2.2, 1.2, 5.5)

static func get_selected_track_name_short() -> String:
	return get_track_short_name()

static func get_selected_vehicle_name_short() -> String:
	return get_vehicle_short_name()

static func get_selected_map_image() -> String:
	return get_camera_map_path()

static func get_model_path_selected() -> String:
	return get_car_model_path()

static func get_track_asset_selected() -> String:
	return get_track_scene_path()

static func get_vehicle_asset_selected() -> String:
	return get_car_model_path()

static func get_current_scene_track_path() -> String:
	return get_track_scene_path()

static func get_current_scene_car_path() -> String:
	return get_car_model_path()

static func get_track_json_path() -> String:
	return String(TRACKS[selected_track]["surfaces"])

static func get_car_resource_path() -> String:
	return get_car_model_path()

static func get_active_vehicle_display_name() -> String:
	return get_vehicle_name()

static func get_active_track_display_name() -> String:
	return get_track_name()

static func get_selected_vehicle_resource_path() -> String:
	return get_car_model_path()

static func get_selected_track_resource_path() -> String:
	return get_track_scene_path()

static func get_track_path_selected_current() -> String:
	return get_track_scene_path()

static func get_vehicle_path_selected_current() -> String:
	return get_car_model_path()

static func get_vehicle_data_for_selection() -> Dictionary:
	return get_selected_vehicle()

static func get_track_data_for_selection() -> Dictionary:
	return get_selected_track()

static func get_surface_data_for_track() -> Dictionary:
	return get_surface_metadata()

static func get_track_overview() -> String:
	return "%s — %s" % [get_track_name(), get_track_length_text()]

static func get_vehicle_overview() -> String:
	return get_vehicle_name()

static func get_map_thumbnail() -> String:
	return get_camera_map_path()

static func get_car_thumbnail() -> String:
	return get_car_model_path()

static func get_selected_race_setup() -> Dictionary:
	return {"track_id": selected_track, "vehicle_id": selected_vehicle}

static func get_valid_selections() -> Dictionary:
	return {"tracks": get_valid_track_ids(), "vehicles": get_valid_vehicle_ids()}

static func set_selection(track_id: String, vehicle_id: String) -> bool:
	return set_user_selection(track_id, vehicle_id)

static func get_selection() -> Dictionary:
	return get_user_selection()

static func get_active_race_track() -> String:
	return get_track_name()

static func get_active_race_vehicle() -> String:
	return get_vehicle_name()

static func get_selected_track_model() -> String:
	return get_track_scene_path()

static func get_selected_vehicle_model() -> String:
	return get_car_model_path()

static func get_scene_path_for_selected_track() -> String:
	return get_track_scene_path()

static func get_model_path_for_selected_vehicle() -> String:
	return get_car_model_path()

static func get_current_track_route() -> String:
	return get_track_scene_path()

static func get_current_car_route() -> String:
	return get_car_model_path()

static func get_track_choice() -> String:
	return selected_track

static func get_vehicle_choice() -> String:
	return selected_vehicle

static func get_current_game_config() -> Dictionary:
	return {"track": get_selected_track(), "car": get_selected_vehicle()}

static func get_selected_track_asset() -> String:
	return get_track_scene_path()

static func get_selected_car_asset() -> String:
	return get_car_model_path()

static func get_current_track_asset() -> String:
	return get_track_scene_path()

static func get_current_vehicle_asset() -> String:
	return get_car_model_path()

static func get_course_info() -> Dictionary:
	return get_selected_track()

static func get_vehicle_info_for_selection() -> Dictionary:
	return get_selected_vehicle()

static func get_track_details_for_selection() -> Dictionary:
	return get_selected_track()

static func get_vehicle_details_for_selection() -> Dictionary:
	return get_selected_vehicle()

static func get_lap_course() -> PackedVector3Array:
	return get_centerline()

static func get_spawn_point_for_selection() -> Vector3:
	return get_spawn_position()

static func get_spawn_direction_for_selection() -> float:
	return get_spawn_yaw()

static func get_surface_for_course(label: String) -> String:
	return get_surface_for_node(label)

static func get_scene_for_course() -> String:
	return get_track_scene_path()

static func get_vehicle_for_race() -> String:
	return get_car_model_path()

static func get_selected_layout() -> Dictionary:
	return get_selected_track()

static func get_vehicle_for_selection() -> Dictionary:
	return get_selected_vehicle()

static func get_scene_for_track() -> String:
	return get_track_scene_path()

static func get_scene_for_vehicle() -> String:
	return get_car_model_path()

static func get_selected_track_map_image() -> String:
	return get_camera_map_path()

static func get_map_texture() -> Texture2D:
	var path := get_camera_map_path()
	if path.is_empty():
		return null
	return load(path) as Texture2D

static func get_best_track_map() -> Texture2D:
	return get_map_texture()

static func get_scene_for_current_track() -> String:
	return get_track_scene_path()

static func get_car_scene_for_selection() -> String:
	return get_car_model_path()

static func get_race_vehicle_path() -> String:
	return get_car_model_path()

static func get_track_index() -> int:
	return 1 if selected_track == SUZUKA else 0

static func get_vehicle_index() -> int:
	return 1 if selected_vehicle == "mclaren" else 0

static func get_start_spawn_yaw() -> float:
	return get_spawn_yaw()

static func get_track_start_position() -> Vector3:
	return get_spawn_position()

static func get_track_start_direction() -> Vector3:
	return (_centerline[1] - _centerline[0]).normalized() if _centerline.size() > 1 else Vector3.FORWARD

static func get_track_selected_index() -> int:
	return get_track_index()

static func get_vehicle_selected_index() -> int:
	return get_vehicle_index()

static func get_current_track_data_dict() -> Dictionary:
	return get_selected_track()

static func get_current_vehicle_data_dict() -> Dictionary:
	return get_selected_vehicle()

static func get_start_index() -> int:
	return 0

static func get_track_scale() -> float:
	return 1.0

static func get_vehicle_scale() -> float:
	return 1.0

static func get_track_surface_key(node_name: String) -> String:
	return get_surface_for_node(node_name)

static func get_track_wall_nodes() -> Array:
	return get_surface_metadata().get("walls", [])

static func get_car_id() -> String:
	return selected_vehicle

static func get_circuit_id() -> String:
	return selected_track

static func get_track_names() -> Array[String]:
	return [String(TRACKS[BARCELONA]["name"]), String(TRACKS[SUZUKA]["name"])]

static func get_vehicle_names() -> Array[String]:
	return [String(get_vehicle_options()["redbull"]["name"]), String(get_vehicle_options()["mclaren"]["name"])]

static func get_track_name_for_id(track_id: String) -> String:
	return String(TRACKS.get(track_id, TRACKS[BARCELONA])["name"])

static func get_vehicle_name_for_id(vehicle_id: String) -> String:
	return String(get_vehicle_options().get(vehicle_id, get_vehicle_options()["redbull"])["name"])

static func get_track_summary() -> String:
	return "%s · %0.1f km" % [get_track_name(), get_track_length_m() / 1000.0]

static func get_vehicle_summary() -> String:
	return get_vehicle_name()

static func get_course_description() -> String:
	return "Moto layout · sin chicane final" if selected_track == BARCELONA else "Grand Prix · 5.8 km"

static func get_track_asset_path() -> String:
	return get_track_scene_path()

static func get_vehicle_asset_path() -> String:
	return get_car_model_path()

static func get_track_main_scene() -> String:
	return get_track_scene_path()

static func get_vehicle_main_scene() -> String:
	return get_car_model_path()

static func get_current_track_config() -> Dictionary:
	return get_selected_track()

static func get_current_vehicle_config() -> Dictionary:
	return get_selected_vehicle()

static func get_track_start_position() -> Vector3:
	return get_spawn_position()

static func get_track_start_rotation() -> float:
	return get_spawn_yaw()

static func get_vehicle_start_position() -> Vector3:
	return get_spawn_position()

static func get_vehicle_start_rotation() -> float:
	return get_spawn_yaw()

static func get_start_location() -> Vector3:
	return get_spawn_position()

static func get_start_orientation() -> float:
	return get_spawn_yaw()

static func get_current_track_path() -> String:
	return get_track_scene_path()

static func get_current_vehicle_path() -> String:
	return get_car_model_path()

static func get_menu_path() -> String:
	return "res://scenes/main_menu.tscn"

static func get_car_config(vehicle_id: String = "") -> Dictionary:
	return get_vehicle_options().get(vehicle_id if not vehicle_id.is_empty() else selected_vehicle, {})

static func get_map_asset_path() -> String:
	return get_camera_map_path()

static func get_track_preview() -> String:
	return get_camera_map_path()

static func get_vehicle_preview() -> String:
	return get_car_model_path()

static func get_track_rotation_value() -> float:
	return get_track_rotation_y()

static func get_vehicle_rotation_value() -> float:
	return 0.0

static func get_track_near_clip() -> float:
	return 0.1

static func get_track_far_clip() -> float:
	return 2000.0

static func get_spawn_height() -> float:
	return 0.3

static func get_selected_vehicle_asset() -> String:
	return get_car_model_path()

static func get_selected_circuit_asset() -> String:
	return get_track_scene_path()

static func get_course_name() -> String:
	return get_track_name()

static func get_vehicle_option_name() -> String:
	return get_vehicle_name()

static func get_surface_list() -> Array:
	return get_surface_metadata().get("surfaces", {}).keys()

static func get_track_node_surfaces() -> Dictionary:
	return get_surface_metadata().get("nodes", {})

static func get_surface_friction(name: String) -> float:
	return get_surface_grip(name)

static func get_surfaces() -> Dictionary:
	return get_surface_metadata()

static func get_wall_nodes() -> Array:
	return get_track_wall_nodes()

static func get_runoff_line() -> PackedVector3Array:
	return get_runoff_points()

static func get_collision_scene_path() -> String:
	return get_track_scene_path()

static func get_vehicle_path() -> String:
	return get_car_model_path()

static func get_track_path() -> String:
	return get_track_scene_path()

static func get_spawn_yaw_angle() -> float:
	return get_spawn_yaw()

static func get_current_location_name() -> String:
	return get_track_name()

static func get_current_vehicle_name() -> String:
	return get_vehicle_name()

static func get_camera_map_path() -> String:
	return "res://assets/Suzuka-map.png" if selected_track == SUZUKA else ""

[FILE_TOO_LARGE]: The combined read_files output exceeded the 20,000 estimated-token limit. This file was truncated after 7,671 estimated tokens. Read it separately or use code_search for the relevant section.
static func get_track_rotation() -> float:
	return get_track_rotation_y()

static func get_vehicle_options() -> Dictionary:
	return {
		"redbull": {
			"name": "Red Bull RB22",
			"scene": "res://assets/RedBull.tscn",
			"model_path": "res://assets/RedBull-Drive.glb",
			"forward_sign": 1.0,
			"lateral_sign": 1.0,
			"up_sign": 1.0,
		},
		"mclaren": {
			"name": "McLaren MP4/4 · Senna",
			"scene": "res://assets/MP44-Senna.glb",
			"model_path": "res://assets/MP44-Senna.glb",
			"forward_sign": 1.0,
			"lateral_sign": 1.0,
			"up_sign": 1.0,
		},
	}
}

static var selected_vehicle := "redbull"

static func select_vehicle(vehicle_id: String) -> bool:
	if not get_vehicle_options().has(vehicle_id):
		push_error("Unknown vehicle selection: " + vehicle_id)
		return false
	selected_vehicle = vehicle_id
	return true

static func get_selected_vehicle_id() -> String:
	return selected_vehicle

static func get_selected_vehicle() -> Dictionary:
	return get_vehicle_options()[selected_vehicle]

static func get_selected_track() -> Dictionary:
	return TRACKS[selected_track]

static func get_track_height_difference() -> float:
	return -18.0 if selected_track == SUZUKA else 0.0

static func reset_selection() -> void:
	selected_track = BARCELONA
	selected_vehicle = "redbull"
	_loaded = false
	_loaded_track = ""

static var TRACK_LENGTH_M := 4727.0
static var TRACK_NAME := "Barcelona 2023 Moto layout (no final chicane)"
static var FAST_LINE_PATH := "res://assets/BarcelonaMoto.fast_lane.ai"
static var IDEAL_LINE_PATH := "res://assets/BarcelonaMoto.ideal_line.ai"
static var SURFACES_PATH := "res://assets/BarcelonaMoto.surfaces.json"
static var AC_COORDINATE_TO_GODOT := "(-X, Y, -Z)"

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
