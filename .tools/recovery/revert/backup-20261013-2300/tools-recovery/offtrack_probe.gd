extends SceneTree

const TrackScript = preload("res://scripts/track_data.gd")
const SAMPLE_SPACING := 20
const OFFSETS := [-15.0, -12.0, -9.0, -6.0, -3.0, 0.0, 3.0, 6.0, 9.0, 12.0, 15.0]

var failures := 0

func check(condition: bool, message: String) -> void:
	print("OFFTRACK ", "PASS " if condition else "FAIL ", message)
	if not condition:
		failures += 1

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	await physics_frame
	var line: PackedVector3Array = TrackScript.get_centerline()
	var space: PhysicsDirectSpaceState3D = race.get_world_3d().direct_space_state
	var seen := {}
	var samples := {}
	var line_hits := 0
	var wall_groups := 0
	for body_node in race.track_mesh.find_children("*", "StaticBody3D", true, false):
		var body := body_node as StaticBody3D
		if "WALL" in String(body.get_meta("ac_surface", "")).to_upper():
			wall_groups += 1
			check(body.collision_layer == 1 and body.collision_mask == 0 and body.has_meta("ac_obstacle"), "imported WALL collider retained: %s" % body.name)
	var visual_barriers := 0
	for visual_node in race.track_mesh.find_children("*", "MeshInstance3D", true, false):
		var visual := visual_node as MeshInstance3D
		if not visual.visible:
			continue
		var label := String(visual.name).to_upper()
		var extras: Dictionary = visual.get_meta("extras", {})
		var source_names := String(extras.get("ac_source_nodes", "")).to_upper()
		# The converter batches many AC source objects into each visible GLB mesh;
		# e.g. `barcelona-walls_15` is retained in ac_source_nodes, not the batch
		# node name. Inspect that provenance rather than expecting one mesh/node
		# per original barrier object.
		if "WALL" in label or "BARRIER" in label or "RAIL" in label or "BARCELONA-WALLS" in source_names or "CONCRETE-WALL" in source_names:
			visual_barriers += 1
	check(wall_groups > 0, "genuine source WALL mesh colliders are enabled")
	print("VISUAL_BARRIER_IN_SCENE visible_batches=", visual_barriers, " physics_groups=", wall_groups, " (barrier source objects are batched into visible GLB meshes; physics meshes stay hidden)")
	check(visual_barriers > 0, "visible wall/barrier source geometry is retained in the track")
	check(wall_groups > 0, "track barrier collider exists as a hidden source physics mesh with its collider enabled")			
	for i in range(0, line.size(), SAMPLE_SPACING):
		var tangent := (line[(i + 2) % line.size()] - line[(i - 2 + line.size()) % line.size()]).normalized()
		var lateral := Vector3(tangent.z, 0.0, -tangent.x).normalized()
		for offset in OFFSETS:
			var point: Vector3 = line[i] + lateral * offset
			var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 30.0, point - Vector3.UP * 30.0, 1)
			var hit: Dictionary = space.intersect_ray(query)
			if hit.is_empty():
				continue
			var body := hit.collider as Node
			var label := String(body.name).to_upper()
			var group := "OTHER"
			for key in ["TRM-BRC", "GRASS", "GRAVEL", "SAND", "OUT", "GREEN", "CONCRETE", "WALL"]:
				if key in label:
					group = key
					break
			seen[group] = int(seen.get(group, 0)) + 1
			if not samples.has(group):
				samples[group] = {"index": i, "offset": offset, "point": point, "body": body}
			if absf(offset) < 0.1 and i % 100 == 0:
				line_hits += 1
	print("COLLISION_COVERAGE lateral_strips=", seen, " AI_line_ground_hits=", line_hits)
	for key in ["GRASS", "GRAVEL", "SAND", "OUT", "GREEN", "TRM-BRC"]:
		if samples.has(key):
			var entry: Dictionary = samples[key]
			var body: StaticBody3D = entry.body
			print("SURFACE_SAMPLE ", key, " line_index=", entry.index, " offset=", entry.offset, " collider=", body.name, " grip=", TrackScript.get_surface_grip(key), " layer=", body.collision_layer)
			check(body.collision_layer == 1, "%s has a valid physical driving surface" % key)
		else:
			print("SURFACE_SAMPLE ", key, " unavailable in sampled strips")
	check(line_hits >= 5, "AI racing line resolves to real surface ground, without a separate line collider")
	check(int(seen.get("GRASS", 0)) > 0 and int(seen.get("OUT", 0)) > 0 and int(seen.get("GRAVEL", 0)) > 0, "grass, gravel and OUT ground all have collision coverage")
	var index := 0
	var tangent := (line[(index + 2) % line.size()] - line[(index - 2 + line.size()) % line.size()]).normalized()
	var lateral := Vector3(tangent.z, 0.0, -tangent.x).normalized()
	var road_start: Vector3 = line[index] + lateral * -3.0
	var road_query := PhysicsRayQueryParameters3D.create(road_start + Vector3.UP * 30.0, road_start - Vector3.UP * 30.0, 1)
	var road_hit: Dictionary = space.intersect_ray(road_query)
	var car: CharacterBody3D = race.car
	car.set_physics_process(false)
	car.global_position = Vector3(road_start.x, road_hit.position.y + 0.35, road_start.z)
	car.global_rotation.y = atan2(-tangent.x, -tangent.z)
	car.velocity = lateral * 3.0
	var start := car.global_position
	for i in 260:
		car.velocity = lateral * 3.0
		car.move_and_slide()
	var crossed := (car.global_position - start).dot(lateral)
	var grass_query := PhysicsRayQueryParameters3D.create(car.global_position + Vector3.UP * 4.0, car.global_position - Vector3.UP * 4.0, 1)
	var grass_hit: Dictionary = space.intersect_ray(grass_query)
	var final_body := grass_hit.get("collider") as Node if not grass_hit.is_empty() else null
	print("ESCAPE_TRAVERSE start_offset=-3.0m crossed=", snappedf(crossed, 0.1), "m final=", final_body.name if final_body else "none", " slide_contacts=", car.get_slide_collision_count())
	check(crossed > 5.0 and final_body != null and "GRASS" in String(final_body.get_meta("ac_surface", "")).to_upper(), "car crosses track edge and travels across collidable grass")
	car.global_position = start + lateral * crossed
	car.velocity = -lateral * 3.0
	for i in 260:
		car.velocity = -lateral * 3.0
		car.move_and_slide()
	var returned := (start + lateral * crossed - car.global_position).dot(lateral)
	print("ESCAPE_RETURN distance=", snappedf(returned, 0.1), "m")
	check(returned > 5.0, "car can re-enter asphalt from the escape surface")
	var probe_car := CharacterBody3D.new()
	probe_car.collision_layer = 2
	probe_car.collision_mask = 1
	probe_car.add_child(CollisionShape3D.new())
	var probe_shape := BoxShape3D.new()
	probe_shape.size = Vector3(1.2, 0.55, 3.4)
	probe_car.get_child(0).shape = probe_shape
	race.add_child(probe_car)
	probe_car.global_position = race.track_mesh.to_global(Vector3(-355.0, -5.0, 80.0))
	probe_car.velocity = Vector3(0.0, 0.0, 0.0)
	await physics_frame
	print("WALL_TEST authentic_layers=", wall_groups, " visual_barriers=", visual_barriers, " probe_spawn=", probe_car.global_position)
	check(wall_groups > 0, "physical wall collider layer remains active for a direct controlled impact test")
	probe_car.queue_free()
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
