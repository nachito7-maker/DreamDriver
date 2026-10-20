extends SceneTree

const TrackData = preload("res://scripts/track_data.gd")
const START_INDEX := 1300
const END_INDEX := 1540
const MODEL_SPACE := false
const FORWARD_OFFSET := 20
const LOOKAHEAD_SECONDS := 1.1
const INPUT_SCALE := 0.45
const SPEED_LIMIT_MS := 25.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	TrackData.reset_selection()
	TrackData.select_track(TrackData.SUZUKA)
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	Engine.physics_ticks_per_second = 60
	var car: CharacterBody3D = race.car
	var line: PackedVector3Array = TrackData.get_centerline()
	car.set_physics_process(false)
	car.set_process(false)
	car.collision_mask = 0
	car.collision_layer = 0
	var initial_position: Vector3 = car.global_position
	if race.assistance_line != null:
		race.assistance_line.set_process(false)
	if race.hud != null:
		race.hud.set_process(false)
	if race.controls != null:
		race.controls.set_process(false)
	for frame in 120:
		await physics_frame
		race.set_physics_process(false)
		race.set_process(false)
	var track := race.track_mesh as Node3D
	var road_bodies: Array[StaticBody3D] = []
	for node in track.find_children("*", "StaticBody3D", true, false):
		var body := node as StaticBody3D
		if body.name.to_upper().contains("1ROAD"):
			body.collision_layer = 1
			body.collision_mask = 0
			road_bodies.append(body)
	if road_bodies.is_empty():
		push_error("Missing converted Suzuka road collision")
		race.queue_free()
		await process_frame
		quit(2)
		return
	if MODEL_SPACE:
		for i in line.size():
			line[i] = track.global_transform * line[i]
	# Race._ready positions its initial chassis at the stale startup height because
	# the scene root itself is attached to the tree only after _ready. Restore that
	# checkpoint and force only the road ray sampler, not broad chassis collisions.
	car.global_position = initial_position
	car.recover_to(line[START_INDEX], _yaw_at(line, START_INDEX))
	car.collision_mask = 0
	car.collision_layer = 0
	car.set_physics_process(true)
	car.set_meta("touch_throttle", 0.0)
	car.set_meta("touch_brake", 0.0)
	car.set_meta("touch_steer", 0.0)
	for frame in 90:
		await physics_frame
	var settled_position: Vector3 = car.global_position
	var settled_yaw: float = car.rotation.y
	print("SUZUKA_PROBE_START index=%d pos=%s speed=%.1f contacts=%d seated=%s" % [
		START_INDEX, str(settled_position), car.speed_kph, car.wheel_contacts, str(car.suspension.seated)])
	car.set_meta("touch_throttle", 0.55)
	var max_error := 0.0
	var minimum_contacts := 4
	var unsupported_ticks := 0
	var max_vertical_speed := 0.0
	var max_height_step := 0.0
	var previous_height: float = car.suspension.height
	var reached_end := false
	var steps := 0
	for step in 6000:
		await physics_frame
		steps = step + 1
		var nearest := _nearest(line, car.global_position, START_INDEX, END_INDEX)
		var distance_to_line := Vector2(line[nearest].x - car.global_position.x, line[nearest].z - car.global_position.z).length()
		max_error = maxf(max_error, distance_to_line)
		minimum_contacts = mini(minimum_contacts, car.wheel_contacts)
		if car.wheel_contacts == 0:
			unsupported_ticks += 1
		max_vertical_speed = maxf(max_vertical_speed, absf(car.velocity.y))
		max_height_step = maxf(max_height_step, absf(car.suspension.height - previous_height))
		previous_height = car.suspension.height
		var target_index := mini(nearest + FORWARD_OFFSET, END_INDEX)
		var local := car.to_local(line[target_index])
		var lookahead: float = maxf(14.0, car.speed_mps * LOOKAHEAD_SECONDS)
		var alpha := atan2(local.x, -local.z)
		var angle := atan2(2.0 * car.wheelbase_m * sin(alpha), lookahead)
		var demand := clampf(angle / maxf(car.debug_max_steer, 0.1), -1.0, 1.0)
		car.set_meta("touch_steer", demand * INPUT_SCALE)
		var target_speed := minf(SPEED_LIMIT_MS, maxf(16.0, sqrt(1.4 * lookahead)))
		var speed_error: float = target_speed - car.speed_mps
		car.set_meta("touch_throttle", clampf(0.52 + speed_error * 0.025, 0.2, 0.75))
		car.set_meta("touch_brake", clampf(-speed_error * 0.04, 0.0, 0.3))
		if step % 300 == 0:
			print("SUZUKA_PROBE_STEP frame=%d nearest=%d err=%.2f speed=%.1f y=%.2f contacts=%d vy=%.2f steer=%.2f" % [
				step, nearest, distance_to_line, car.speed_kph, car.global_position.y, car.wheel_contacts, car.velocity.y, car.steering_input])
		if nearest >= END_INDEX:
			reached_end = true
			break
		if car.global_position.y < -60.0 or distance_to_line > 20.0:
			break
	var passed := reached_end and minimum_contacts >= 2 and unsupported_ticks < 60 and max_error < 8.0 and max_vertical_speed < 6.0 and max_height_step < 0.08
	print("SUZUKA_DOWNHILL passed=%s reached=%s steps=%d index=%d min_contacts=%d unsupported_ticks=%d max_error=%.2f max_abs_vy=%.2f max_height_step=%.3f position=%s" % [
		str(passed), str(reached_end), steps, _nearest(line, car.global_position, START_INDEX, END_INDEX), minimum_contacts,
		unsupported_ticks, max_error, max_vertical_speed, max_height_step, str(car.global_position)])
	race.queue_free()
	await process_frame
	quit(0 if passed else 1)

func _nearest(line: PackedVector3Array, position: Vector3, from: int, to: int) -> int:
	var best := from
	var best_distance := INF
	for index in range(from, to + 1):
		var distance := Vector2(line[index].x - position.x, line[index].z - position.z).length_squared()
		if distance < best_distance:
			best_distance = distance
			best = index
	return best

func _yaw_at(line: PackedVector3Array, index: int) -> float:
	var tangent: Vector3 = line[(index + 6) % line.size()] - line[(index - 6 + line.size()) % line.size()]
	return atan2(-tangent.x, -tangent.z)
