extends SceneTree

const TrackScript := preload("res://scripts/track_data.gd")
const RaceScene := preload("res://scenes/race.tscn")
const MenuScene := preload("res://scenes/main_menu.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var menu := MenuScene.instantiate()
	root.add_child(menu)
	await process_frame
	var montreal_button := menu.find_child("Track montreal", true, false) as Button
	if montreal_button == null:
		push_error("Montreal button missing from the actual menu")
		quit(1)
		return
	montreal_button.pressed.emit()
	if menu._track_id != TrackScript.MONTREAL or String(menu._summary.text).find("Circuit Gilles-Villeneuve") < 0 or menu._map.texture == null or menu._map.texture.resource_path != "res://assets/montreal/preview.png":
		push_error("Montreal menu selection did not update its summary and authentic preview")
		quit(2)
		return
	print("MENU_PASS options=", menu._track_buttons.keys(), " selected=", menu._track_id, " summary=", menu._summary.text,
		" preview=", menu._map.texture.resource_path if menu._map.texture else "none")
	var start_button := menu.find_child("Start race", true, false) as Button
	if start_button == null:
		push_error("The normal menu launch button is missing")
		quit(14)
		return
	start_button.pressed.emit()
	for _frame in 10:
		await process_frame
	var launched_race := RaceScene.instantiate() as Node3D
	if launched_race == null or TrackScript.get_selected_track_id() != TrackScript.MONTREAL:
		push_error("Launching from the selected Montreal menu entry did not resolve the Montreal race scene")
		quit(15)
		return
	root.add_child(launched_race)
	for _frame in 10:
		await process_frame
	print("MENU_LAUNCH_PASS scene=", launched_race.scene_file_path, " selected=", TrackScript.get_selected_track_id())

	for vehicle_id in ["rb22_2026", "mclaren"]:
		if not TrackScript.set_user_selection(TrackScript.MONTREAL, vehicle_id):
			push_error("Could not select Montreal / " + vehicle_id)
			quit(3)
			return
		var race: Node3D
		if vehicle_id == "rb22_2026":
			race = launched_race
		else:
			race = RaceScene.instantiate()
			root.add_child(race)
		for _frame in 10:
			await process_frame
		if race.track_mesh == null or race.car == null or race.car.model_root == null:
			push_error("Montreal race did not instantiate for " + vehicle_id)
			race.queue_free()
			quit(4)
			return
		var meshes: Array[Node] = race.track_mesh.find_children("*", "MeshInstance3D", true, false)
		var visible_count := 0
		var physics_count := 0
		var road_count := 0
		var wall_count := 0
		var grass_count := 0
		for node in meshes:
			var mesh := node as MeshInstance3D
			if mesh.visible:
				visible_count += 1
		for node in race.track_mesh.find_children("*", "StaticBody3D", true, false):
			var body := node as StaticBody3D
			if body.collision_layer == 0:
				continue
			for shape in body.get_children():
				if shape is CollisionShape3D and shape.shape != null:
					physics_count += 1
					var label := String(body.name + " " + String(body.get_meta("ac_surface", ""))).to_upper()
					if "ROAD" in label: road_count += 1
					if "WALL" in label: wall_count += 1
					if "GRASS" in label or "SAND" in label: grass_count += 1
		var start := TrackScript.get_centerline()[0]
		var spawn: Vector3 = race.car.global_position
		var first_segment := TrackScript.get_centerline()[1] - start
		var right := Vector3(-first_segment.z, 0.0, first_segment.x).normalized()
		var lateral_offset := absf(Vector2(spawn.x - start.x, spawn.z - start.z).dot(Vector2(right.x, right.z)))
		var spawn_height_delta := absf((spawn.y - 0.5) - start.y)
		var heading: Vector3 = -race.car.global_basis.z.normalized()
		var tangent: Vector3 = (TrackScript.get_centerline()[1] - TrackScript.get_centerline()[0]).normalized()
		var forward_dot: float = heading.dot(tangent)
		var track_resource := TrackScript.get_track_scene_path()
		var model_resource := TrackScript.get_car_model_path()
		var lap_tracker: Node = race.car.lap_tracker
		print("MONTREAL vehicle=", vehicle_id, " track=", race.track_mesh.name,
			" resource=", track_resource, " model=", model_resource,
			" center_points=", TrackScript.get_centerline().size(), " ideal_points=", TrackScript.get_ideal_line().size(),
			" speed_hints=", TrackScript.has_speed_hints(), " spawn=", spawn, " start=", start,
			" forward_dot=", forward_dot, " lateral_offset_m=", lateral_offset, " spawn_height_delta_m=", spawn_height_delta,
			" meshes=", meshes.size(), " visible=", visible_count,
			" colliders=", physics_count, " road=", road_count, " walls=", wall_count, " grass=", grass_count,
			" lap_tracker=", lap_tracker != null, " hud=", race.hud != null, " controls=", race.controls != null,
			" cameras=", race.camera != null and race.nose_camera != null)
		if meshes.size() < 800 or visible_count < 800 or physics_count < 6 or road_count < 1 or wall_count < 1 or grass_count < 1:
			push_error("Montreal geometry/collision inventory incorrect")
			race.queue_free(); quit(5); return
		if lateral_offset > 2.0 or spawn_height_delta > 1.0 or forward_dot < 0.95:
			push_error("Montreal spawn is not on the start lane or facing along the AC line")
			race.queue_free(); quit(6); return
		if lap_tracker == null or race.hud == null or race.controls == null or race.camera == null or race.nose_camera == null or TrackScript.get_selected_track_id() == TrackScript.MONTREAL and not FileAccess.file_exists("res://assets/montreal/sections.json"):
			push_error("Montreal session is missing driving systems or its seven lap-timing sector gates")
			race.queue_free(); quit(7); return
		if not is_equal_approx(lap_tracker.lap_time, 0.0):
			push_error("Timer should start at 0")
			race.queue_free(); quit(9); return
		# Drive Montreal's complete lap with the same touch controls and racing line.
		# Keep the second vehicle as a quick control/timer smoke check.
		var initial: Vector3 = race.car.global_position
		race.car.set_physics_process(true)
		if vehicle_id == "rb22_2026":
			if not await _drive_montreal_lap(race):
				push_error("Montreal driving probe failed to complete a valid timed lap")
				race.queue_free(); quit(10); return
		else:
			race.controls._handle_touch_down(71, race.controls._throttle_pedal.position + race.controls._throttle_pedal.size * Vector2(0.5, 0.05))
			for _frame in 180:
				await process_frame
			race.controls._handle_touch_up(71)
		if race.car.global_position.distance_to(initial) < 0.5 or race.car.speed_mps < 1.0 or (vehicle_id != "rb22_2026" and lap_tracker.lap_time <= 0.0):
			push_error("Car did not respond to throttle or timer did not advance")
			race.queue_free(); quit(10); return
		print("DRIVING_PASS vehicle=", vehicle_id, " moved=", race.car.global_position.distance_to(initial), " speed=", race.car.speed_mps, " lap_time=", lap_tracker.lap_time, " completed_laps=", lap_tracker.laps, " best_lap=", lap_tracker.best_lap)
		race.queue_free()
		await process_frame

	# Loading the other track through the same catalog must clear Montreal's cached
	# line, surfaces and scene path; then validate a second transition to Suzuka.
	for track_id in [TrackScript.BARCELONA, TrackScript.SUZUKA, TrackScript.MONTREAL]:
		if not TrackScript.select_track(track_id):
			push_error("Track switch failed: " + track_id)
			quit(11); return
		var path := TrackScript.get_track_scene_path()
		var selected := load(path) as PackedScene
		var first_point: Vector3 = TrackScript.get_centerline()[0]
		var first_surface_key := String(TrackScript.get_surface_metadata().get("source", ""))
		var own_surface_path := String(TrackScript.TRACKS[track_id]["surfaces"])
		var surface_file := FileAccess.open(own_surface_path, FileAccess.READ)
		var own_surface_data: Variant = JSON.parse_string(surface_file.get_as_text()) if surface_file != null else null
		var own_surface_key := String(own_surface_data.get("source", "")) if own_surface_data is Dictionary else ""
		print("SWITCH_PASS id=", track_id, " name=", TrackScript.get_track_name(),
			" resource=", path, " center_points=", TrackScript.get_centerline().size(),
			" ideal_points=", TrackScript.get_ideal_line().size(), " surfaces=", first_surface_key,
			" own_surface_resource=", own_surface_path, " own_surface_source=", own_surface_key,
			" first_point=", first_point, " collision_scene_loaded=", selected != null)
		var minimum_points := 2500 if track_id == TrackScript.MONTREAL else int(TrackScript.TRACKS[track_id].get("minimum_points", 3000))
		var maximum_length_error := float(TrackScript.TRACKS[track_id].get("length_tolerance", 100.0))
		if selected == null or TrackScript.get_centerline().size() < minimum_points:
			push_error("Switch did not resolve the selected track's own resources")
			quit(12); return
		var line := TrackScript.get_centerline()
		var sampled_length := 0.0
		for point_index in line.size():
			sampled_length += line[point_index].distance_to(line[(point_index + 1) % line.size()])
		if absf(sampled_length - float(TrackScript.TRACKS[track_id]["length"])) > maximum_length_error or own_surface_data == null:
			push_error("Selected circuit's AI line or surface metadata do not match its own catalog resources")
			quit(13); return
	print("MONTREAL_SMOKE_PASS menu/race/driving/timer/cameras/controls/resources/track-switch")
	quit(0)

func _drive_montreal_lap(race: Node3D) -> bool:
	Engine.max_fps = 0
	var car: CharacterBody3D = race.car
	var ui: CanvasLayer = race.controls
	var line: PackedVector3Array = TrackScript.get_centerline()
	var track_transform := Basis(Vector3.UP, TrackScript.get_track_rotation_y())
	var world_line := PackedVector3Array()
	for source_point in line:
		world_line.append(track_transform * source_point)
	line = world_line
	if ui._viewport_size.x <= 0.0 or line.size() < 2500:
		return false
	var steer_point: Vector2 = ui._steer_center
	var throttle_rect: Rect2 = ui._pedal_rects["throttle"]
	var brake_rect: Rect2 = ui._pedal_rects["brake"]
	var steering_touch := 81
	var throttle_touch := 82
	var brake_touch := 83
	var throttle_point := Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5, throttle_rect.position.y + throttle_rect.size.y * 0.05)
	var brake_point := Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5, brake_rect.end.y - 1.0)
	ui._handle_touch_down(steering_touch, steer_point)
	ui._handle_touch_down(throttle_touch, throttle_point)
	ui._handle_touch_down(brake_touch, brake_point)
	for _warmup in 120:
		await physics_frame
	var nearest := 0
	var max_error := 0.0
	var wall_hits := 0
	for step in 120000:
		await physics_frame
		if ui._steer_touch_id < 0: ui._handle_touch_down(steering_touch, steer_point)
		if ui._throttle_touch_id < 0: ui._handle_touch_down(throttle_touch, throttle_point)
		if ui._brake_touch_id < 0: ui._handle_touch_down(brake_touch, brake_point)
		var best := INF
		var search_origin := nearest
		for offset in range(-12, 30):
			var point_index := posmod(search_origin + offset, line.size())
			var world_point: Vector3 = line[point_index]
			var distance_squared := Vector2(car.global_position.x - world_point.x, car.global_position.z - world_point.z).length_squared()
			if distance_squared < best:
				best = distance_squared
				nearest = point_index
		max_error = maxf(max_error, sqrt(best))
		var lookahead: float = 8.0 + car.speed_mps * 0.7
		var distance := 0.0
		var target_index := nearest
		while distance < lookahead:
			var next_index := (target_index + 1) % line.size()
			distance += line[target_index].distance_to(line[next_index])
			target_index = next_index
		var local := car.to_local(line[target_index])
		var alpha := atan2(local.x, -local.z)
		var wheel_angle := atan2(2.0 * car.wheelbase_m * sin(alpha), lookahead)
		var steering_max := lerpf(car.steering_at_low_speed_rad, car.steering_at_high_speed_rad, pow(clampf(car.speed_mps / 100.0, 0.0, 1.0), 0.68))
		var demand := clampf(wheel_angle / steering_max * 0.55, -1.0, 1.0)
		var raw: float = ui.steering_travel_for(demand)
		ui._handle_touch_motion(steering_touch, ui._steer_center + Vector2(raw * ui._steering_ring.size.x * 0.46, 0.0))
		var curvature: float = absf(wheel_angle) / car.wheelbase_m
		var target_speed := clampf(sqrt(1.0 / maxf(curvature, 0.001)), 6.0, 10.0)
		var speed_error: float = target_speed - car.speed_mps
		var throttle := clampf(speed_error * 0.18 + 0.05, 0.0, 1.0)
		var brake := clampf(-speed_error * 0.12, 0.0, 0.65)
		var gas_point := throttle_rect.position + throttle_rect.size * Vector2(0.5, 1.0 - ui.pedal_travel_for(maxf(0.45, throttle)))
		var brake_command_point := brake_rect.position + brake_rect.size * Vector2(0.5, 1.0 - ui.pedal_travel_for(brake))
		if throttle <= 0.03: gas_point.y = ui._throttle_pedal.position.y + ui._throttle_pedal.size.y + 4.0
		if brake <= 0.03: brake_command_point.y = ui._brake_pedal.position.y + ui._brake_pedal.size.y + 4.0
		ui._handle_touch_motion(throttle_touch, gas_point)
		ui._handle_touch_motion(brake_touch, brake_command_point)
		ui._process(1.0 / 120.0)
		for collision_index in car.get_slide_collision_count():
			if "WALL" in String(car.get_slide_collision(collision_index).get_collider().name):
				wall_hits += 1
		if step % 6000 == 0:
			print("MONTREAL_LAP_PROGRESS t=", step / 120.0, " speed=", car.speed_kph, " error_m=", sqrt(best), " sectors=", lap_tracker_next_sector(car), " laps=", car.lap_tracker.laps)
		if sqrt(best) > 25.0 or car.global_position.y < -60.0 or wall_hits > 0:
			break
		if car.lap_tracker.laps >= 1:
			break
	ui._handle_touch_up(steering_touch)
	ui._handle_touch_up(throttle_touch)
	ui._handle_touch_up(brake_touch)
	print("MONTREAL_FULL_LAP passed=", car.lap_tracker.laps == 1 and car.lap_tracker.previous_lap > 25.0 and car.lap_tracker.best_lap > 25.0 and max_error < 12.0 and wall_hits == 0,
		" laps=", car.lap_tracker.laps, " lap_s=", car.lap_tracker.previous_lap, " best_s=", car.lap_tracker.best_lap,
		" max_error_m=", max_error, " wall_hits=", wall_hits, " next_sector=", lap_tracker_next_sector(car))
	return car.lap_tracker.laps == 1 and car.lap_tracker.previous_lap > 25.0 and car.lap_tracker.best_lap > 25.0 and max_error < 12.0 and wall_hits == 0

func lap_tracker_next_sector(car: CharacterBody3D) -> int:
	return int(car.lap_tracker.next_sector)
