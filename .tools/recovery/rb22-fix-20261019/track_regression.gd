extends SceneTree
const TD = preload("res://scripts/track_data.gd")
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, message: String) -> void:
	print("TRACK_CHECK ", "PASS " if ok else "FAIL ", message)
	if not ok: failures += 1
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var selected := TD.set_user_selection(args[0] if not args.is_empty() else TD.BARCELONA, args[1] if args.size() > 1 else "rb22_2026")
	if not selected:
		quit(2)
		return
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	for i in 120: await physics_frame
	var car: CharacterBody3D = race.car
	race.controls.set_process(false)
	var line := TD.get_centerline()
	var meshes := {}
	for wheel in car._suspension_wheels:
		var nodes: Array[Node] = wheel.find_children("*", "MeshInstance3D", true, false)
		if wheel is MeshInstance3D: nodes.append(wheel)
		for node in nodes:
			var mesh := node as MeshInstance3D
			# The RB22's wheel_* and Valkyrie's RIM_*/DISK_* meshes are not the tire tread.
			if TD.selected_vehicle in ["rb22_2026", "valkyrie"] and not String(mesh.name).to_lower().begins_with("tyre_"): continue
			var points := PackedVector3Array()
			for s in mesh.mesh.get_surface_count():
				points.append_array(mesh.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX])
			meshes[mesh] = points
	for start in ([0, 1300] if TD.selected_track == TD.SUZUKA else [0, 600]):
		var tangent := (line[(start + 4) % line.size()] - line[posmod(start - 4, line.size())]).normalized()
		car.set_meta("touch_throttle", 0.0)
		car.set_meta("touch_brake", 0.0)
		car.set_meta("touch_steer", 0.0)
		car.recover_to(line[start], atan2(-tangent.x, -tangent.z))
		for i in 120: await physics_frame
		var nearest: int = start
		var min_contacts := 4
		var worst_error := 0.0
		var worst_gap := 0.0
		var collisions := 0
		var speed_peak := 0.0
		var samples := 0
		var worst_detail := ""
		for tick in 720:
			var distance := INF
			for j in range(nearest - 25, nearest + 55):
				var idx := posmod(j, line.size())
				var p := line[idx] - car.global_position
				var d := Vector2(p.x, p.z).length_squared()
				if d < distance:
					distance = d
					nearest = idx
			var target := line[(nearest + 12) % line.size()]
			var local := car.to_local(target)
			var lookahead := maxf(Vector2(local.x, local.z).length(), 1.0)
			var angle := atan(2.0 * car.suspension.wheelbase_m * local.x / (lookahead * lookahead))
			car.set_meta("touch_steer", clampf(angle / maxf(car.debug_max_steer, 0.001), -1.0, 1.0))
			car.set_meta("touch_throttle", 0.8 if car.speed_kph < 75.0 else 0.0)
			car.set_meta("touch_brake", 0.12 if car.speed_kph > 80.0 else 0.0)
			await physics_frame
			min_contacts = mini(min_contacts, car.wheel_contacts)
			speed_peak = maxf(speed_peak, car.speed_kph)
			worst_error = maxf(worst_error, sqrt(distance))
			collisions += car.get_slide_collision_count()
			if tick % 30 != 0: continue
			# A tire has sidewall/rim submeshes above the tread. Measure the
			# lowest point of the whole wheel, not each decorative submesh.
			for wheel in car._suspension_wheels:
				var low := Vector3(0, INF, 0)
				for mesh in meshes:
					if mesh != wheel and not wheel.is_ancestor_of(mesh): continue
					for p in meshes[mesh]:
						var world: Vector3 = mesh.global_transform * p
						if world.y < low.y: low = world
				# Match the production sampler's vertical range: Suzuka's
				# concave triangles may be missed when the ray starts inside its AABB.
				var ray := PhysicsRayQueryParameters3D.create(low + Vector3.UP * 5.0, low - Vector3.UP * 5.0, 1)
				ray.exclude = car.ground_ray_exclude
				ray.hit_back_faces = true
				var hit := car.get_world_3d().direct_space_state.intersect_ray(ray)
				if not hit.is_empty():
					var gap: float = low.y - hit.position.y
					if absf(gap) > worst_gap:
						worst_detail = "tick=%d wheel=%s gap=%.4f low=%s hit=%s roads=%s offset=%s slopes=%.4f/%.4f model=%s" % [tick, wheel.name, gap, str(low), str(hit.position), str(car._wheel_road), str(car.suspension.offset), car.suspension.slope_x, car.suspension.slope_z, str(car.model_root.position)]
					worst_gap = maxf(worst_gap, absf(gap))
					samples += 1
		print("TRACK_RESULT track=%s vehicle=%s start=%d end=%d peak_kph=%.1f min_contacts=%d line_error=%.3f tire_gap=%.4f samples=%d collisions=%d" % [TD.selected_track, TD.selected_vehicle, start, nearest, speed_peak, min_contacts, worst_error, worst_gap, samples, collisions])
		print("TRACK_WORST ", worst_detail)
		check(speed_peak > 65.0, "accelerates beyond 65 km/h")
		check(min_contacts >= 2, "maintains road support")
		check(worst_error < 4.0, "follows actual circuit curves")
		check(samples > 40 and worst_gap < 0.020, "actual tire vertices stay within 20mm of road")
	meshes.clear()
	race.queue_free()
	await process_frame
	print("TRACK_RESULT failures=", failures)
	quit(1 if failures else 0)
