extends SceneTree

const TrackScript = preload("res://scripts/track_data.gd")
var race: Node3D
var car: CharacterBody3D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 180:
		await physics_frame
	car = race.car
	_dump("initial")
	# Controlled straight acceleration through the existing action input.
	Input.action_press("throttle", 0.55)
	for i in 180:
		await physics_frame
	_dump("straight")
	Input.action_release("throttle")
	for i in 30:
		await physics_frame
	race.queue_free()
	await process_frame
	quit()

func _dump(tag: String) -> void:
	var s = car.suspension
	var rates := PackedFloat32Array()
	rates.resize(car._suspension_wheels.size())
	for i in rates.size(): rates[i] = s.rate_front_n_per_m if i < 2 else s.rate_rear_n_per_m
	print("DIAGSOLVE raw_road=%s corners=%s roads=%s ground=%s contacts=%d loaded=%d" % [str(s._solve_plane(rates, s.road, 0.0, 0.0, 0.0, 0.0)), str(s.corner), str(s.road), str(s.grounded), s.contacts, s.loaded_contacts])
	var up: Vector3 = car.model_root.global_basis.y.normalized()
	print("DIAG %s car=%s speed=%.2f contacts=%d loaded=%d modelUp=%s roadSlopes=(%.5f,%.5f) slopes=(%.5f,%.5f) H=%.4f RH=%.4f groundN=%s" % [tag, str(car.global_position), car.speed_mps, s.contacts, s.loaded_contacts, str(up), s.road_slope_x, s.road_slope_z, s.slope_x, s.slope_z, s.height, s.road_height, str(car.ground_normal)])
	for i in car._suspension_wheels.size():
		var w: Node3D = car._suspension_wheels[i]
		print("DIAGW %s %s pos=%s restY=%.5f offset=%.5f road=%.5f ground=%d load=%.1f localBasisY=%s globalBasisY=%s globalOrigin=%s meshCenter=%s meshSize=%s" % [tag, String(w.name), str(w.position), car._suspension_rest_y[i], s.offset[i], s.road[i], s.grounded[i], s.load[i], str(w.basis.y), str(w.global_basis.y), str(w.global_position), str(w.mesh.get_aabb().get_center()), str(w.mesh.get_aabb().size)])
	for n in [Vector3(-0.85,0,-1.5), Vector3(0.85,0,-1.5), Vector3(-0.85,0,1.95), Vector3(0.85,0,1.95)]:
		var p: Vector3 = car.global_transform * n
		var q := PhysicsRayQueryParameters3D.create(p+Vector3.UP, p-Vector3.UP*1.2,1)
		var h := root.world_3d.direct_space_state.intersect_ray(q)
		if not h.is_empty(): print("DIAGP %s point=%s hit=%s n=%s" % [tag,str(p),str(h.position),str(h.normal)])
