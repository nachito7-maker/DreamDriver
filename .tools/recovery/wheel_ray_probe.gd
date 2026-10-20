extends SceneTree
const TD = preload("res://scripts/track_data.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	TD.reset_selection()
	TD.set_user_selection(TD.SUZUKA, "mclaren")
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 60: await physics_frame
	var car: CharacterBody3D = race.car
	print("ROOT ", car.global_transform, " contacts=", car.wheel_contacts, " sup=", car.suspension, " height=", car.suspension.height)
	for i in car._suspension_wheels.size():
		var wheel: Node3D = car._suspension_wheels[i]
		var h: Vector3 = car.global_transform.affine_inverse() * wheel.global_position
		var p: Vector3 = car.global_transform * Vector3(h.x, 0.0, h.z)
		for length in [1.7, 3.0, 5.0, 10.0, 20.0]:
			var qx: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(p+Vector3.UP*length*0.5,p-Vector3.UP*length*0.5,1)
			var hx: Dictionary = race.get_world_3d().direct_space_state.intersect_ray(qx)
			print("LEN i=",i," length=",length," hit=",hx.collider.name if not hx.is_empty() else "MISS"," y=",hx.position.y if not hx.is_empty() else NAN)
		var q1: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.8,p-Vector3.UP*0.9,1)
		var qinside: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.8,p-Vector3.UP*0.9,1)
		qinside.hit_from_inside = true
		var hin: Dictionary = race.get_world_3d().direct_space_state.intersect_ray(qinside)
		var exclude: Array[RID] = []
		for body in race.track_mesh.find_children("*", "StaticBody3D", true, false):
			if body.name != "1ROAD": exclude.append(body.get_rid())
		var qroad: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.8,p-Vector3.UP*0.9,1)
		qroad.exclude = exclude
		var hroad: Dictionary = race.get_world_3d().direct_space_state.intersect_ray(qroad)
		var q2: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(p+Vector3.UP*100,p-Vector3.UP*100,1)
		var a: Dictionary = race.get_world_3d().direct_space_state.intersect_ray(q1)
		q1.hit_back_faces = true
		var c: Dictionary = race.get_world_3d().direct_space_state.intersect_ray(q1)
		var b: Dictionary = race.get_world_3d().direct_space_state.intersect_ray(q2)
		print("RAY i=",i," wheel=",wheel.name," global=",wheel.global_position," carhub=",h," narrow=",a.collider.name if not a.is_empty() else "MISS", " y=",a.position.y if not a.is_empty() else NAN," len=5=",b.collider.name if not b.is_empty() else "MISS"," by=",b.position.y if not b.is_empty() else NAN)
	quit(0)
