extends SceneTree
const TD = preload("res://scripts/track_data.gd")
const DT := 1.0 / 120.0
var failures := 0
var car: CharacterBody3D
var vertices := {}
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, text: String) -> void:
	print("RB_CHECK ", "PASS " if ok else "FAIL ", text)
	if not ok: failures += 1
func geometry(w: Node3D) -> Dictionary:
	var meshes: Array[Node] = w.find_children("*", "MeshInstance3D", true, false)
	if w is MeshInstance3D: meshes.append(w)
	var low := INF
	var high := -INF
	var box := AABB()
	var first := true
	for mesh in meshes:
		var mi := mesh as MeshInstance3D
		if not vertices.has(mi):
			var points := PackedVector3Array()
			for s in mi.mesh.get_surface_count():
				points.append_array(mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX])
			vertices[mi] = points
		for p in vertices[mi]:
			var wp: Vector3 = mi.global_transform * p
			low = minf(low, wp.y)
			high = maxf(high, wp.y)
			var lp: Vector3 = w.global_transform.affine_inverse() * wp
			if first:
				box = AABB(lp, Vector3.ZERO)
				first = false
			else: box = box.expand(lp)
	return {"low": low, "high": high, "box": box}
func _run() -> void:
	Engine.max_fps = 0
	TD.selected_vehicle = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "rb22_2026"
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 12: await physics_frame
	car = race.car
	race.controls.set_process(false)
	var pad := StaticBody3D.new()
	pad.name = "ROAD regression pad"
	pad.collision_layer = 1
	pad.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2000, 10, 2000)
	shape.shape = box
	pad.add_child(shape)
	pad.position.y = 995.0
	root.add_child(pad)
	car.recover_to(Vector3(0, 1000, 0), 0)
	for i in 180: await physics_frame
	print("GEOMETRY vehicle=", TD.selected_vehicle, " corners=", car.suspension.corner)
	for w in car._suspension_wheels:
		var g := geometry(w)
		print("WHEEL ", w.name, " local_box=", g.box, " pivot=", w.position, " rest=", car._wheel_rest[w], " gap=", g.low - 1000)
	# Exercise all spin phases on the actual tire vertices, not rotated AABB corners.
	car.set_physics_process(false)
	for phase in [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0]:
		car._wheel_spin = phase
		car._update_visuals(0.0)
		for w in car._suspension_wheels:
			var g := geometry(w)
			check(absf(g.low - 1000) < 0.012, "%s phase=%.1f tire_gap=%.4fm" % [w.name, phase, g.low - 1000])
	car.set_physics_process(true)
	# Small steering demand must follow R=L/tan(delta), with no hidden yaw loss.
	for kph in [10.0, 60.0, 120.0, 180.0]:
		car.recover_to(Vector3(0, 1000, 0), 0)
		car.set_meta("touch_steer", 0.0)
		for i in 100: await physics_frame
		car.set_meta("touch_steer", 0.5)
		var yaw_sum := 0.0
		var length_sum := 0.0
		var expected_sum := 0.0
		for i in 120:
			car.velocity = -car.global_basis.z * kph / 3.6
			var y0 := car.rotation.y
			await physics_frame
			if i > 60:
				yaw_sum += absf(wrapf(car.rotation.y - y0, -PI, PI))
				length_sum += kph / 3.6 * DT
				expected_sum += car.suspension.wheelbase_m / tan(absf(car.steering_angle))
		var radius := length_sum / maxf(yaw_sum, 0.00001)
		var expected := expected_sum / 59.0
		print("RADIUS kph=", kph, " real=", radius, " geometric=", expected)
		check(absf(radius / expected - 1.0) < 0.05, "radius agrees with geometry at %.0fkm/h" % kph)
	# Load-transfer direction must match physical front (-Z) and right (+X).
	check(car.suspension.corner[0].z < car.suspension.corner[2].z, "front axle is ahead of rear in physics frame")
	car.set_meta("touch_steer", 0.0)
	car.set_meta("touch_throttle", 1.0)
	car.recover_to(Vector3(0, 1000, 0), 0)
	for i in 180: await physics_frame
	check(car.suspension.pitch_relative > 0.0, "acceleration raises the nose")
	var min_kph := 25.0 if TD.selected_vehicle == "valkyrie" else 45.0
	check(car.speed_kph > min_kph, "accelerator drives the car from rest (%.1f > %.1f km/h)" % [car.speed_kph, min_kph])
	vertices.clear()
	race.queue_free()
	pad.queue_free()
	await process_frame
	print("RB_RESULT failures=", failures)
	quit(1 if failures else 0)
