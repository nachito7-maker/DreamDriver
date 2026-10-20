extends SceneTree

const TrackScript := preload("res://scripts/track_data.gd")
const RaceScene := preload("res://scenes/race.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	TrackScript.set_user_selection(TrackScript.BARCELONA, "mclaren")
	var race: Node3D = RaceScene.instantiate()
	root.add_child(race)
	await process_frame
	race.set_physics_process(false)
	race.car.set_physics_process(false)
	race.set_camera_mode(1)
	race._update_nose_camera()
	race._apply_camera_mode(1.0)
	for _i in 3:
		await process_frame
	var camera: Camera3D = race.nose_camera
	var viewport: Vector2 = camera.get_viewport().get_visible_rect().size
	var left := Rect2(Vector2(0.33, 0.68) * viewport, Vector2(0.10, 0.19) * viewport)
	var right := Rect2(Vector2(0.57, 0.68) * viewport, Vector2(0.10, 0.19) * viewport)
	print("VIEWPORT=", viewport, " LEFT_TARGET=", left, " RIGHT_TARGET=", right)
	var found := 0
	for node in race.car.model_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null or not mesh.visible:
			continue
		var aabb: AABB = mesh.mesh.get_aabb()
		var minp := Vector2(INF, INF)
		var maxp := Vector2(-INF, -INF)
		for x in [aabb.position.x, aabb.end.x]:
			for y in [aabb.position.y, aabb.end.y]:
				for z in [aabb.position.z, aabb.end.z]:
					var point := camera.unproject_position(mesh.global_transform * Vector3(x, y, z))
					minp.x = minf(minp.x, point.x); minp.y = minf(minp.y, point.y)
					maxp.x = maxf(maxp.x, point.x); maxp.y = maxf(maxp.y, point.y)
		var rect := Rect2(minp, maxp - minp)
		if rect.intersects(left) or rect.intersects(right):
			found += 1
			print("CANDIDATE path=", mesh.get_path(), " rect=", rect, " local_aabb=", aabb, " material=", (mesh.get_active_material(0) as Material).resource_name if mesh.get_active_material(0) else "none")
	print("CANDIDATES_COUNT=", found)
	race.queue_free()
	await process_frame
	quit()
