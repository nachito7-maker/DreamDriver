extends SceneTree

const TrackScript = preload("res://scripts/track_data.gd")
const RaceScript = preload("res://scripts/race.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	TrackScript.select_track(TrackScript.MONTREAL)
	TrackScript.select_vehicle("rb22_2026")
	var race := Node3D.new()
	race.set_script(RaceScript)
	root.add_child(race)
	for _frame in 12:
		await physics_frame
	var space := race.get_world_3d().direct_space_state
	var points := TrackScript.get_centerline()
	for index in [0, 100, 500, 1000, 1800, 2500]:
		var p: Vector3 = points[index]
		var query := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 100.0, p - Vector3.UP * 100.0, 1)
		query.collide_with_areas = false
		var hit := space.intersect_ray(query)
		print("ROAD_HEIGHT_SAMPLE i=", index, " line=", p, " hit=", hit.get("position", Vector3.INF), " node=", hit.get("collider", null).name if hit.get("collider", null) != null else "none", " delta=", hit.get("position", Vector3.INF).y - p.y if hit else INF)
	for body in race.track_mesh.find_children("*", "StaticBody3D", true, false):
		var b := body as StaticBody3D
		var colliders := 0
		for child in b.get_children():
			if child is CollisionShape3D and child.shape != null:
				colliders += 1
		if colliders:
			print("RUNTIME_FBX_BODY name=", b.name, " layer=", b.collision_layer, " surface=", b.get_meta("ac_surface", ""), " shapes=", colliders)
	quit(0)
