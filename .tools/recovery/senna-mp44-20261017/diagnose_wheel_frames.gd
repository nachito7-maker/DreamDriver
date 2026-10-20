extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for _i in 180:
		await physics_frame
	var car: CharacterBody3D = race.car
	var s = car.suspension
	print("FRAME car=%s model=%s model_basis=%s corners=%s roads=%s" % [str(car.global_transform), str(car.model_root.global_transform), str(car.model_root.global_basis), str(s.corner), str(s.road)])
	for i in car._suspension_wheels.size():
		var wheel: MeshInstance3D = car._suspension_wheels[i]
		var car_local_hub: Vector3 = car.global_transform.affine_inverse() * wheel.global_position
		var node_local: Vector3 = wheel.position
		var legacy_ray: Vector3 = car.global_transform * Vector3(node_local.x, 0.0, node_local.z)
		var actual_ray: Vector3 = Vector3(wheel.global_position.x, car.global_position.y + 1.0, wheel.global_position.z)
		var query_actual := PhysicsRayQueryParameters3D.create(actual_ray, actual_ray - Vector3.UP * 3.0, 1)
		var actual_hit := root.world_3d.direct_space_state.intersect_ray(query_actual)
		var query_legacy := PhysicsRayQueryParameters3D.create(legacy_ray + Vector3.UP, legacy_ray - Vector3.UP * 2.0, 1)
		var legacy_hit := root.world_3d.direct_space_state.intersect_ray(query_legacy)
		var size: Vector3 = wheel.mesh.get_aabb().size
		var smallest := 0
		for axis in range(1, 3):
			if size[axis] < size[smallest]: smallest = axis
		var axes := [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
		var axle: Vector3 = (wheel.global_basis * axes[smallest]).normalized()
		var values := [size.x, size.y, size.z]
		var largest := 0
		for axis in range(1, 3):
			if axis != smallest and values[axis] > values[largest]: largest = axis
		var middle := 3 - smallest - largest
		var radius: float = size[largest] * 0.5
		var width: float = size[smallest]
		var bottom: float = wheel.global_position.y - width * 0.5 * absf(axle.y) - radius * sqrt(maxf(0.0, 1.0 - axle.y * axle.y))
		print("WHEEL i=%d name=%s node_local=%s car_local_hub=%s suspension_corner=%s wheel_world=%s ray_delta=%s legacy_hit=%s actual_hit=%s axle=%s radius=%.4f width=%.4f bottom=%.4f clearance_actual=%s" % [
			i, String(wheel.name), str(node_local), str(car_local_hub), str(s.corner[i]), str(wheel.global_position), str(car.to_local(wheel.global_position) - Vector3(node_local.x, node_local.y, node_local.z)),
			str(legacy_hit.get("position", Vector3.INF)), str(actual_hit.get("position", Vector3.INF)), str(axle), radius, width, bottom,
			"n/a" if actual_hit.is_empty() else str(bottom - float(actual_hit.position.y))])
	quit()
