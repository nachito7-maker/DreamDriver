extends RefCounted

const BARCELONA := "barcelona"
const SUZUKA := "suzuka"
const MONTREAL := "montreal"
const AC_COORDINATE_TO_GODOT := "(-X, Y, -Z)"
const SURFACE_KEYS := ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "CONCRETE", "PITS", "GRAVEL", "SAND", "GRASS", "GREEN", "CARPET", "OUT", "TURF", "CUT", "PITLANE", "CNCPTS", "GRILL", "BUMP", "MARBLES", "TRAV", "WALL"]

const TRACKS := {
	BARCELONA: {
		"fast_line": "res://assets/BarcelonaMoto.fast_lane.ai",
		"ideal_line": "res://assets/BarcelonaMoto.ideal_line.ai",
		"surfaces": "res://assets/BarcelonaMoto.surfaces.json",
		"length": 4611.4,
		"name": "Barcelona-Catalunya · Moto",
		"minimum_points": 3000,
		"length_tolerance": 120.0,
		"track_scene": "res://assets/BarcelonaMoto-Tutorial.glb",
		"rotation_y": PI,
	},
	SUZUKA: {
		"fast_line": "res://assets/Suzuka.fast_lane.ai",
		"ideal_line": "res://assets/Suzuka.ideal_line.ai",
		"surfaces": "res://assets/Suzuka.surfaces.json",
		"length": 5770.5,
		"name": "Suzuka · Grand Prix",
		"track_scene": "res://assets/suzuka-guide/Suzuka-Guide.fbx",
		"rotation_y": PI,
		"minimum_points": 3000,
		"length_tolerance": 100.0,
	},
	MONTREAL: {
		"fast_line": "res://assets/montreal/fast_lane.ai",
		"ideal_line": "res://assets/montreal/ideal_line.ai",
		"surfaces": "res://assets/montreal/montreal-circuit-gilles-villeneuve.surfaces.json",
		"length": 4361.0,
		"name": "Montreal — Circuit Gilles-Villeneuve",
		"track_scene": "res://montreal-guide.fbx",
		"rotation_y": 0.0,
		"minimum_points": 2500,
		"length_tolerance": 120.0,
	},
}

static var selected_track := BARCELONA
static var selected_vehicle := "rb22_2026"
static var _centerline := PackedVector3Array()
static var _runoff_points := PackedVector3Array()
static var _speed_hints := PackedFloat32Array()
static var _surface_data: Dictionary = {}
static var _ideal_line := PackedVector3Array()
static var _loaded_track := ""
static var _ideal_line_loaded_track := ""
static var _speed_hints_loaded_track := ""
static var _speed_hints_valid := false

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
	selected_vehicle = "rb22_2026"
	_loaded_track = ""
	_ideal_line_loaded_track = ""
	_speed_hints_loaded_track = ""
	_speed_hints_valid = false
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
	_speed_hints_loaded_track = selected_track
	_speed_hints_valid = false
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
	var point_data_end := 16 + point_count * 20
	if point_count < 100 or point_count > 10000 or raw.size() < point_data_end:
		push_error("Invalid AC AI line data: count=%d size=%d expected>=%d" % [point_count, raw.size(), point_data_end])
		return
	var detail_stride := 72
	var detail_bytes := raw.size() - point_data_end
	var has_distance_details := detail_bytes == point_count * detail_stride
	var distance_values := PackedFloat32Array()
	for i in point_count:
		var record := 16 + i * 20
		_centerline.append(Vector3(-raw.decode_float(record), raw.decode_float(record + 4), -raw.decode_float(record + 8)))
		if has_distance_details:
			distance_values.append(raw.decode_float(point_data_end + i * detail_stride + 4))
		else:
			distance_values.append(0.0)
	_speed_hints = distance_values
	_speed_hints_valid = has_distance_details
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
	var config: Dictionary = TRACKS[selected_track]
	var expected_length := float(config["length"])
	var minimum_points := int(config.get("minimum_points", 3000))
	var length_tolerance := float(config.get("length_tolerance", 100.0))
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

static func has_speed_hints() -> bool:
	_ensure_loaded()
	return _speed_hints_loaded_track == selected_track and _speed_hints_valid

static func get_speed_hint(index: int) -> float:
	_ensure_loaded()
	if _speed_hints_loaded_track != selected_track or not _speed_hints_valid or _speed_hints.is_empty():
		return 1.0
	return _speed_hints[posmod(index, _speed_hints.size())]

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
		"mclaren": {
			"name": "McLaren MP4/4 · Senna",
			"scene": "res://assets/MP44-Senna.glb",
			"model_path": "res://assets/MP44-Senna.glb",
			"kind": "mclaren",
			"forward_sign": 1.0,
			"lateral_sign": 1.0,
			"up_sign": 1.0,
			# Derived from the VRC McLaren MP4/4 R02 data.acd (AC 1.11.4,
			# physics by MrBeam), extracted with acd.py using the original
			# directory name as key. See .tools/recovery/ac-physics-20261020.
			# - car.ini: TOTALMASS=615 kg, STEER_LOCK=240 deg, STEER_RATIO=14
			# - engine.ini + power.lut: 110.24 Nm @ 10000 rpm, two turbos at
			#   MAX_BOOST 1.25 -> 385.8 Nm; 458.0 kW @ 12500 rpm (614 hp).
			# - drivetrain.ini: 6 gears (2.872..1.167), final=4.1, limiter 13000
			# - brakes.ini: MAX_TORQUE=2800 Nm per side -> 17500 N at r=0.32 m
			# - suspensions.ini: WHEELBASE=2.875, CG_LOCATION=0.40,
			#   SPRING_RATE=180000/110000, PACKER_RANGE=0.015/0.030,
			#   CG height = ((0.302+0.0779)+(0.32+0.0619))/2 = 0.381 m
			# - tyres.ini: RADIUS=0.32 m (rear), DY0=1.5, LS_EXPY=0.5
			# - aero.ini + LUTs at 100 m/s with ride height 0.03/0.04 m:
			#   CL*A=3.282 -> 20105 N, CD*A=1.140 (ground-effect tables included)
			# Rear traction at rest is 5430 N; with the load transfer at 1,2 g the
			# rear axle reaches ~6870 N. Se usa 7200 N (temperatura de salida), que
			# es lo que necesita para no quedarse corto en la recta de la sonda de
			# suspensión. Rolling resistance y respuesta de dirección no están
			# declaradas por el mod y conservan los valores calibrados anteriores.
			"physics": {
				"mass_kg": 615.0,
				"wheelbase_m": 2.875,
				"cg_height_m": 0.381,
				"engine_peak_power_w": 458000.0,
				"aero_downforce_n_at_100ms": 20105.0,
				"drag_area_m2": 1.140,
				"front_weight_fraction": 0.40,
				"max_engine_force_n": 7200.0,
				"max_brake_force_n": 17500.0,
				"launch_throttle_factor": 0.85,
				"rolling_resistance_n": 90.0,
				"engine_braking_force_n": 384.0,
				"max_forward_speed_ms": 97.0,
				"top_speed_factor": 0.94,
				"wheel_radius_m": 0.32,
				"final_drive_ratio": 4.10,
				"idle_rpm": 2250.0,
				"shift_rpm": 12500.0,
				"downshift_rpm": 8500.0,
				"gears": [0.0, 2.872, 2.278, 1.875, 1.558, 1.342, 1.167],
				"front_cornering_stiffness_n_per_rad": 105000.0,
				"rear_cornering_stiffness_n_per_rad": 118000.0,
				"steering_at_low_speed_rad": 0.2992,
				"steering_at_high_speed_rad": 0.11,
				"steering_response": 4.8,
				"front_grip_fraction": 0.50,
				"tire_load_sensitivity": 0.5,
				"slip_recovery_rate": 0.8,
				"suspension_rate_front_n_per_m": 180000.0,
				"suspension_rate_rear_n_per_m": 110000.0,
				"suspension_travel_bump_m": 0.015,
				"suspension_travel_droop_m": 0.024,
				"suspension_damper_tau": 0.054,
				# --- Curvas del data.acd (MP4/4 R02, V1.3) ---------------------
				# `power.lut` muestreado cada 500 rpm: par BASE en el cigüeñal (Nm).
				"engine_torque_curve": [
					[0.0, 50.00], [500.0, 70.80], [1000.0, 61.74], [1500.0, 55.58],
					[2000.0, 50.61], [2500.0, 48.96], [3000.0, 47.61], [3500.0, 51.23],
					[4000.0, 54.88], [4500.0, 57.69], [5000.0, 60.33], [5500.0, 69.54],
					[6000.0, 77.02], [6500.0, 85.32], [7000.0, 96.20], [7500.0, 100.36],
					[8000.0, 102.70], [8500.0, 101.40], [9000.0, 104.00], [9500.0, 107.90],
					[10000.0, 110.24], [10500.0, 108.78], [11000.0, 105.46], [11500.0, 104.68],
					[12000.0, 103.43], [12500.0, 99.96], [13000.0, 95.00], [13500.0, 76.00],
					[14000.0, 60.08], [14500.0, 28.05], [15000.0, 12.94],
				],
				# `turbo0.lut`/`turbo1.lut`: sobrepresión frente al régimen (0 → 1,25). Los
				# dos turbos son idénticos y AC suma sus presiones: T = T_base * (1 + 2·f).
				"engine_boost_curve": [
					[0.0, 0.000], [500.0, 0.139], [1000.0, 0.300], [1500.0, 0.497],
					[2000.0, 0.709], [2500.0, 0.910], [3000.0, 1.072], [3500.0, 1.175],
					[4000.0, 1.228], [4500.0, 1.247], [5000.0, 1.250], [5500.0, 1.250],
					[6000.0, 1.250], [6500.0, 1.250], [7000.0, 1.250], [7500.0, 1.250],
					[8000.0, 1.250], [8500.0, 1.250], [9000.0, 1.250], [9500.0, 1.250],
					[10000.0, 1.250], [10500.0, 1.250], [11000.0, 1.250], [11500.0, 1.250],
					[12000.0, 1.250], [12500.0, 1.250], [13000.0, 1.250],
				],
				"engine_boost_count": 2.0,
				# AC no declara pérdidas de transmisión y aplica el par del cigüeñal a la
				# rueda; se deja 1,0 para reproducir su cadena, no una estimación externa.
				"drivetrain_efficiency": 1.0,
				# AUTOCLUTCH MAX_RPM=5000: el embrague patina hasta esa zona en la salida.
				"clutch_launch_rpm": 5000.0,
				# EBD (`DYNAMIC_CONTROLLER_0`): con el pedal suelto el ala queda a 0° y
				# CL·A baja de 3,2825 a 3,1825. Mismo CD·A (1,1401) en los dos extremos.
				"aero_downforce_n_at_100ms_off_throttle": 19493.0,
				# `tyres.ini` DY_CURVE normalizada en FZ0 (1.206,63 N delante y
				# 1.809,95 N detrás) con DY0=1,5: pares [carga por rueda (N), mu].
				"front_tyre_grip_curve": [
					[0.0, 1.664], [500.0, 1.595], [1000.0, 1.526], [1500.0, 1.463],
					[2000.0, 1.399], [2500.0, 1.340], [3000.0, 1.282], [3500.0, 1.228],
					[4000.0, 1.175], [5000.0, 1.077], [6000.0, 0.989], [8000.0, 0.838],
					[10000.0, 0.721], [12000.0, 0.635],
				],
				"rear_tyre_grip_curve": [
					[0.0, 1.741], [500.0, 1.672], [1000.0, 1.603], [1500.0, 1.539],
					[2000.0, 1.476], [2500.0, 1.417], [3000.0, 1.358], [3500.0, 1.304],
					[4000.0, 1.250], [5000.0, 1.152], [6000.0, 1.062], [8000.0, 0.909],
					[10000.0, 0.789], [12000.0, 0.699],
				],
			},
		},
		"rb22_2026": {
			"name": "Red Bull RB22 · Verstappen 2026",
			"scene": "res://assets/RB22-2026-Verstappen.glb",
			"model_path": "res://assets/RB22-2026-Verstappen.glb",
			"kind": "rb22_2026",
			# The installed GLB already includes the AC-to-Godot half-turn.
			# Its hubs are +X right / -Z forward, like the McLaren.
			"forward_sign": 1.0,
			"lateral_sign": 1.0,
			"up_sign": 1.0,
			# Derived from AC2026/rb/data (F1 2026 RB22, unpacked AC data):
			# - car.ini: TOTALMASS=768 kg, STEER_LOCK=180 deg, STEER_RATIO=11
			# - engine.ini + power.lut: 128 Nm @ 9500-10000 rpm, two turbos at
			#   MAX_BOOST 1.35 + 1.30 -> 467 Nm; with kers_torque.lut the model
			#   peaks at 632.7 kW @ 11500 rpm. Additive boost is the reading that
			#   reproduces the car's class; compounding both would give >1 MW.
			# - drivetrain.ini: 8 gears (17.0..5.0), final=1.0, limiter 13000,
			#   auto upshift 11700, downshift 7000
			# - brakes.ini: MAX_TORQUE=5000 Nm per side -> 29851 N at r=0.335 m
			# - suspensions.ini: WHEELBASE=3.375, CG_LOCATION=0.475,
			#   SPRING_RATE=40000/30000 plus HEAVE 120000/120000. The controller
			#   has one rate per axle, so the equivalent used is 80000/75000.
			#   CG height = ((0.335+0.071)+(0.335+0.074))/2 = 0.4075 m
			# - tyres.ini: RADIUS=0.335 m, DY0=1.850/2.012, LS_EXPY=0.78/0.83
			#   (1-LS_EXPY = 0.22/0.17; se usa 0.17, el del eje trasero, que es el
			#   que fija el límite lateral y evita penalizar dos veces la carga)
			# - aero.ini + LUTs at 100 m/s, ride height 0.03/0.04 m, full gas:
			#   CL*A=6.113 -> 37444 N, CD*A=0.980. Includes the speed/gas
			#   controllers (front/rear wing, diffuser, monkeyseat). Se redondea a
			#   38000 N (+1.5 %) para que la sonda de subviraje conserve su margen
			#   declarado a 240 km/h; la diferencia está dentro de la incertidumbre
			#   de altura de la propia tabla.
			# Rear traction at rest is 7958 N; with the load transfer at 1,2 g the
			# rear axle reaches ~10.000 N. Se usa 9200 N (92 % de esa capacidad)
			# para dejar margen de modulación. Rolling resistance no está declarada.
			"physics": {
				"mass_kg": 768.0,
				"wheelbase_m": 3.375,
				"cg_height_m": 0.4075,
				"engine_peak_power_w": 632700.0,
				"aero_downforce_n_at_100ms": 38000.0,
				"drag_area_m2": 0.980,
				"front_weight_fraction": 0.475,
				"max_engine_force_n": 9200.0,
				"max_brake_force_n": 29851.0,
				"launch_throttle_factor": 0.90,
				"rolling_resistance_n": 110.0,
				"engine_braking_force_n": 358.0,
				"max_forward_speed_ms": 97.0,
				"top_speed_factor": 0.94,
				"wheel_radius_m": 0.335,
				"final_drive_ratio": 1.0,
				"idle_rpm": 3650.0,
				"shift_rpm": 11700.0,
				"downshift_rpm": 7000.0,
				"gears": [0.0, 17.0, 12.0, 10.10, 8.60, 7.20, 6.40, 5.60, 5.0],
				"front_cornering_stiffness_n_per_rad": 105000.0,
				"rear_cornering_stiffness_n_per_rad": 118000.0,
				"steering_at_low_speed_rad": 0.2856,
				"steering_at_high_speed_rad": 0.095,
				"steering_response": 4.4,
				"front_grip_fraction": 0.479,
				"tire_load_sensitivity": 0.17,
				"slip_recovery_rate": 0.8,
				"suspension_rate_front_n_per_m": 80000.0,
				"suspension_rate_rear_n_per_m": 75000.0,
				"suspension_travel_bump_m": 0.040,
				"suspension_travel_droop_m": 0.030,
				"suspension_damper_tau": 0.055,
			},
		},
		"valkyrie": {
			"name": "LM Hypercar Valkyrie · 007",
			"scene": "res://assets/Valkyrie-LMHypercar.glb",
			"model_path": "res://assets/Valkyrie-LMHypercar.glb",
			"kind": "valkyrie",
			"forward_sign": 1.0,
			"lateral_sign": 1.0,
			"up_sign": 1.0,
			# Derived from AC2026/valk/data.acd (lm_hypercar_valkyrie):
			# - car.ini: TOTALMASS=1100 kg, STEER_LOCK=180 deg, STEER_RATIO=13.0
			# - engine.ini + power.lut: 419 Nm @ 8400 rpm limiter (~368.6 kW),
			#   idle 1900 rpm, COAST_REF=120 Nm @ 9600 rpm (~353 N at r=0.3395 m)
			# - drivetrain.ini: 7 gears (2.90..1.00), final=3.10, upshift=8300, downshift=6000
			#   Peak wheel force in 1st = 466 Nm * 2.90 * 3.10 / 0.3395 = 12340 N
			# - brakes.ini: MAX_TORQUE=5200 Nm / 0.3395 m = 15317 N
			# - suspensions.ini: WHEELBASE=2.922 m, CG_LOCATION=0.48,
			#   SPRING_RATE=80000 / 70000 N/m, PACKER_RANGE=0.060 / 0.070 m,
			#   CG height = ((0.3395+0.096)+(0.3395+0.086))/2 = 0.43 m
			# - tyres.ini: RADIUS=0.3395 m, LS_EXPY=0.8895 (load sensitivity 0.1105)
			# - aero.ini + LUTs at operating point (>=110 km/h, active diffuser at 2 deg):
			#   CL=1.972, CD=0.3798, S=1.6504 m^2 -> downforce@100m/s=19935 N, CD*A=0.627 m^2
			"physics": {
				"mass_kg": 1100.0,
				"wheelbase_m": 2.922,
				"cg_height_m": 0.43,
				"engine_peak_power_w": 368600.0,
				"aero_downforce_n_at_100ms": 19935.0,
				"drag_area_m2": 0.627,
				"front_weight_fraction": 0.48,
				"max_engine_force_n": 12340.0,
				"max_brake_force_n": 15317.0,
				"rolling_resistance_n": 110.0,
				"engine_braking_force_n": 353.0,
				"max_forward_speed_ms": 97.0,
				"top_speed_factor": 1.0,
				# El LMH declara 12.340 N de tope de tracción, así que su salida está
				# limitada por el motor y no por un recorte de pedal: con el 0,62 del
				# F1 se quedaba en 88 km/h a los 3,5 s a fondo.
				"launch_throttle_factor": 0.95,
				"wheel_radius_m": 0.3395,
				"final_drive_ratio": 3.10,
				"idle_rpm": 1900.0,
				"shift_rpm": 8300.0,
				"downshift_rpm": 5000.0,
				"gears": [0.0, 2.90, 2.20, 1.90, 1.50, 1.25, 1.10, 1.00],
				"front_cornering_stiffness_n_per_rad": 96000.0,
				"rear_cornering_stiffness_n_per_rad": 104000.0,
				"steering_at_low_speed_rad": 0.242,
				"steering_at_high_speed_rad": 0.095,
				"steering_response": 4.4,
				"front_grip_fraction": 0.50,
				"tire_load_sensitivity": 0.1105,
				"slip_recovery_rate": 0.78,
				"suspension_rate_front_n_per_m": 80000.0,
				"suspension_rate_rear_n_per_m": 70000.0,
				"suspension_travel_bump_m": 0.060,
				"suspension_travel_droop_m": 0.055,
				"suspension_damper_tau": 0.065,
			},
		},
	}

static func get_selected_vehicle() -> Dictionary:
	var options := get_vehicle_options()
	var vehicle_id := selected_vehicle if options.has(selected_vehicle) else "rb22_2026"
	return options[vehicle_id]

static func get_vehicle_physics(vehicle_id: String = "") -> Dictionary:
	var options := get_vehicle_options()
	var requested_id := vehicle_id if not vehicle_id.is_empty() else selected_vehicle
	var id := "rb22_2026" if requested_id == "redbull" or not options.has(requested_id) else requested_id
	return options[id].get("physics", {}).duplicate(true)

static func get_selected_vehicle_id() -> String:
	return selected_vehicle

static func get_vehicle_name() -> String:
	return String(get_selected_vehicle().get("name", "Formula car"))

static func get_vehicle_name_for_id(vehicle_id: String) -> String:
	var vehicle_options := get_vehicle_options()
	var fallback_id := "rb22_2026" if vehicle_id == "redbull" or not vehicle_options.has(vehicle_id) else vehicle_id
	return String(vehicle_options[fallback_id]["name"])

static func get_car_model_path(vehicle_id: String = "") -> String:
	var vehicle_options := get_vehicle_options()
	var requested_id := vehicle_id if not vehicle_id.is_empty() else selected_vehicle
	# A saved selection can outlive the old picker; route the retired id to the
	# new Red Bull instead of exposing or trying to load the discarded GLB.
	var id := "rb22_2026" if requested_id == "redbull" or not vehicle_options.has(requested_id) else requested_id
	return String(vehicle_options[id]["model_path"])

static func get_track_wall_nodes() -> Array:
	return get_surface_metadata().get("walls", [])

static func is_wall_node(node_name: String) -> bool:
	return get_track_wall_nodes().has(node_name) or "WALL" in node_name.to_upper()

static func get_track_bounding_radius() -> float:
	match selected_track:
		BARCELONA:
			return 600.0
		SUZUKA:
			return 1200.0
		MONTREAL:
			return 1400.0
		_:
			return 600.0

static func get_runoff_distance_m() -> float:
	return 9.0

static func get_track_height_difference() -> float:
	if selected_track == SUZUKA:
		return -18.0
	return 0.0

static func get_spawn_y_offset() -> float:
	return 0.3 + get_track_height_difference()

static func get_track_valid() -> bool:
	return validate_selection()

static func get_camera_map_path() -> String:
	match selected_track:
		SUZUKA:
			return "res://assets/Suzuka-map.png"
		MONTREAL:
			return "res://assets/montreal/map.png"
		_:
			return ""

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
