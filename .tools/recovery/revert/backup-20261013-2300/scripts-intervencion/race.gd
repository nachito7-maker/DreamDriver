extends Node3D

const CarScript = preload("res://scripts/car_controller.gd")
const HudScript = preload("res://scripts/race_hud.gd")
const TouchScript = preload("res://scripts/touch_controls.gd")
const TrackScript = preload("res://scripts/track_data.gd")
const CAR_MODEL: PackedScene = preload("res://assets/RedBull.tscn")
const TRACK_SCENE_PATH := "res://assets/BarcelonaMoto-Tutorial.glb"

var car: CharacterBody3D
var hud: CanvasLayer
var controls: CanvasLayer
var camera: Camera3D
var start_gate: Area3D
var track_mesh: Node3D
var spawn_position := Vector3.ZERO

func _ready() -> void:
	Engine.max_fps = 60
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_world()
	_build_car()
	_build_camera()
	_build_lap_gate()
	hud = CanvasLayer.new()
	hud.name = "Race telemetry"
	hud.set_script(HudScript)
	add_child(hud)
	controls = CanvasLayer.new()
	controls.name = "Touch controls"
	controls.set_script(TouchScript)
	controls.car = car
	add_child(controls)
	if OS.get_name() == "Android":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

func _physics_process(delta: float) -> void:
	if car == null:
		return
	if car.global_position.y < -80.0 or Input.is_action_just_pressed("reset_car"):
		var points := TrackScript.get_centerline()
		var nearest := 0
		var distance := INF
		for i in points.size():
			var d := car.global_position.distance_squared_to(points[i])
			if d < distance:
				distance = d
				nearest = i
		var tangent := points[(nearest + 5) % points.size()] - points[nearest]
		car.recover_to(points[nearest] + Vector3.UP * 0.2, atan2(-tangent.x, -tangent.z))
	car.lap_tracker.advance(delta, car)
	var local := start_gate.to_local(car.global_position)
	if car.previous_gate_local_z > 0.0 and local.z <= 0.0 and absf(local.x) < 9.0 and absf(local.y) < 4.0:
		car.register_line_crossing(car.previous_gate_local_z, local.z)
	car.previous_gate_local_z = local.z

func _process(delta: float) -> void:
	if hud != null and car != null:
		hud.update_telemetry(car)
	if camera != null and car != null:
		var forward := -car.global_basis.z
		var target := car.global_position + Vector3.UP * 3.4 - forward * 9.0
		camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-delta * 6.0))
		camera.look_at(car.global_position + forward * (12.0 + car.speed_mps * 0.15) + Vector3.UP * 0.8, Vector3.UP)

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#4e85b5")
	sky_mat.sky_horizon_color = Color("#b7d3e4")
	sky.sky_material = sky_mat
	env.sky = sky
	# Con AMBIENT_SOURCE_SKY a 0.65 el cielo azul teñia toda la escena: el asfalto
	# de AC, de albedo neutro (asph_updt (80,80,80)), salia (146,180,202) y el
	# canal azul de las lineas blancas se recortaba a 255. El cielo se mantiene
	# como fondo, pero la luz ambiental pasa a ser neutra y el sol lleva el peso,
	# que es lo que hace que el circuito se parezca al original.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.76, 0.78)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -24.0, 0.0)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)
	var packed := load(TRACK_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Tutorial circuit import cannot load.")
		return
	track_mesh = packed.instantiate()
	track_mesh.name = "Barcelona Moto original AC track"
	# AC AI uses (-X,Y,-Z). The Blender Y-up export preserves AC coordinates.
	track_mesh.rotation.y = PI
	add_child(track_mesh)
	var collision_count := 0
	var native_wall_groups := 0
	for node in track_mesh.find_children("*", "StaticBody3D", true, false):
		var body := node as StaticBody3D
		var extras: Dictionary = body.get_meta("extras", {})
		var source := String(extras.get("kn5_source_obj", ""))
		var surface_names := String(extras.get("ac_source_nodes", body.name)).to_upper()
		var collider_name := String(body.name).to_upper()
		# 4.obj carries AC_START/AC_TIME marker boxes and no driving obstacles;
		# keep the exception scoped to that metadata-only source, not the track.
		if source == "4.obj":
			body.collision_layer = 0
			continue
		var wall_group := "WALL" in surface_names or "WALL" in collider_name or "BARRIER" in collider_name or "RAIL" in collider_name
		if wall_group:
			native_wall_groups += 1
		# Imported named wall/barrier bodies are present in the scene and are never
		# excluded by this runtime filter; scenery remains visual-only where source says so.
		# The legacy physics mesh includes three distant debris/marble triangles
		# marked OTHER. They remain harmless on its own broad ground mesh. Actual
		# AC WALL, ROAD, GRASS, GRAVEL, OUT and other physics layers stay enabled.
		body.collision_layer = 1
		body.collision_mask = 0
		body.set_meta("ac_surface", extras.get("ac_source_nodes", body.name))
		body.set_meta("ac_source", source)
		if wall_group:
			body.set_meta("ac_obstacle", true)
		collision_count += 1
	var meshes := track_mesh.find_children("*", "MeshInstance3D", true, false)
	for node in meshes:
		var mesh := node as MeshInstance3D
		var physics: bool = bool(mesh.get_meta("ac_physics", false)) or String(mesh.name).ends_with("-colonly")
		if physics:
			mesh.visible = false
			# AC_START/AC_TIME marker boxes are metadata, not road obstacles.
			if String(mesh.get_meta("kn5_source_obj", "")) == "4.obj":
				continue
			# Runtime glTF generation does not process editor import suffixes.
			var body := StaticBody3D.new()
			body.name = "AC physics " + mesh.name
			var sources := String(mesh.get_meta("kn5_source_obj", ""))
			body.set_meta("ac_surface", String(mesh.get_meta("ac_source_nodes", mesh.name)))
			body.set_meta("ac_source", sources)
			body.collision_layer = 1
			body.collision_mask = 0
			if "WALL" in String(body.get_meta("ac_surface", "")).to_upper():
				body.set_meta("ac_obstacle", true)
				if body.collision_layer != 0:
					native_wall_groups += 1
			mesh.add_child(body)
			var shape := CollisionShape3D.new()
			shape.shape = mesh.mesh.create_trimesh_shape()
			body.add_child(shape)
			collision_count += 1
		else:
			for i in mesh.mesh.get_surface_count():
				var mat := mesh.mesh.surface_get_material(i) as StandardMaterial3D
				if mat != null:
					mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
					var material_extras: Dictionary = mat.get_meta("extras", {})
					var metadata: Dictionary = JSON.parse_string(String(material_extras.get("ac_material", "{}")))
					if metadata.get("alpha_tested", false) or metadata.get("alpha_blend", false) or "Alpha" in String(metadata.get("shader", "")):
						mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
						mat.alpha_scissor_threshold = 0.35
	print("[track] tutorial mesh batches=", meshes.size(), " original hidden collision batches=", collision_count,
		" imported native WALL collider groups=", native_wall_groups)

func _build_car() -> void:
	spawn_position = TrackScript.get_spawn_position() + Vector3.UP * 0.3
	car = CharacterBody3D.new()
	car.name = "Red Bull Racing RB"
	car.set_script(CarScript)
	car.position = spawn_position
	car.rotation.y = TrackScript.get_spawn_yaw()
	car.collision_layer = 2
	car.collision_mask = 1
	car.safe_margin = 0.005
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# Central chassis collider excludes wheels/overhang: no broad box snagging kerbs.
	box.size = Vector3(1.2, 0.55, 3.4)
	collision.shape = box
	collision.position.y = 0.29
	car.add_child(collision)
	var model := CAR_MODEL.instantiate() as Node3D
	model.name = "RedBull production model"
	car.add_child(model)
	car.model_root = model
	add_child(car)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Chase camera"
	camera.current = true
	camera.fov = 72.0
	camera.near = 0.1
	camera.far = 2000.0
	camera.position = car.global_position + Vector3.UP * 3.4 + car.global_basis.z * 9.0
	add_child(camera)
	camera.look_at(car.global_position - car.global_basis.z * 12.0, Vector3.UP)

func _build_lap_gate() -> void:
	var points := TrackScript.get_centerline()
	var tangent := (points[1] - points[0]).normalized()
	start_gate = Area3D.new()
	start_gate.name = "Finish and start line"
	start_gate.position = points[0] + Vector3.UP
	start_gate.rotation.y = atan2(-tangent.x, -tangent.z)
	start_gate.collision_layer = 0
	start_gate.collision_mask = 0
	add_child(start_gate)
	var tracker := LapTracker.new()
	tracker.name = "Lap tracker"
	add_child(tracker)
	tracker.set_course(points)
	car.lap_tracker = tracker
	car.previous_gate_local_z = start_gate.to_local(car.global_position).z

class LapTracker extends Node:
	var lap_time := 0.0
	var previous_lap := -1.0
	var best_lap := -1.0
	var laps := 0
	var valid_lap := true
	var last_progress := 0.0
	var armed := false
	var course := PackedVector3Array()
	var accumulated_distance := PackedFloat32Array()
	var total_distance := 0.0
	var next_sector := 1
	var _scan_time := 0.0

	func set_course(points: PackedVector3Array) -> void:
		course = points
		total_distance = 0.0
		accumulated_distance.resize(points.size() + 1)
		accumulated_distance[0] = 0.0
		for i in points.size():
			total_distance += points[i].distance_to(points[(i + 1) % points.size()])
			accumulated_distance[i + 1] = total_distance

	func advance(delta: float, vehicle: CharacterBody3D) -> void:
		if armed:
			lap_time += delta
		_scan_time -= delta
		if _scan_time > 0.0:
			return
		_scan_time = 0.1
		var progress := _nearest_progress(vehicle.global_position)
		if _distance_to_track(vehicle.global_position) > 14.0:
			valid_lap = false
		if armed:
			var sector := int(progress / total_distance * 8.0)
			if sector == next_sector and next_sector <= 7:
				next_sector += 1
			if progress < last_progress - 50.0 and not (last_progress > total_distance * 0.9 and progress < 50.0):
				valid_lap = false
		last_progress = progress

	func register_crossing(previous_z: float, current_z: float) -> void:
		if previous_z <= 0.0 or current_z > 0.0:
			return
		if not armed:
			armed = true
			lap_time = 0.0
			valid_lap = true
			next_sector = 1
			return
		if lap_time < 25.0 or next_sector < 8:
			return
		previous_lap = lap_time
		laps += 1
		if valid_lap and (best_lap < 0.0 or previous_lap < best_lap):
			best_lap = previous_lap
		valid_lap = true
		lap_time = 0.0
		next_sector = 1
		last_progress = 0.0

	func _nearest_progress(position: Vector3) -> float:
		var best := INF
		var result := 0.0
		for i in range(0, course.size(), 3):
			var j := (i + 3) % course.size()
			var ab := course[j] - course[i]
			var t := clampf((position - course[i]).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
			var d := position.distance_squared_to(course[i] + ab * t)
			if d < best:
				best = d
				result = accumulated_distance[i] + ab.length() * t
		return result

	func _distance_to_track(position: Vector3) -> float:
		var best := INF
		for i in range(0, course.size(), 4):
			best = minf(best, Vector2(course[i].x - position.x, course[i].z - position.z).length())
		return best
