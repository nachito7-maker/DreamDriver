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
	for _frame in 10:
		await physics_frame
	var points := TrackScript.get_centerline()
	var transforms := {
		"identity": func(p: Vector3) -> Vector3: return p,
		"rotate_180": func(p: Vector3) -> Vector3: return Vector3(-p.x, p.y, -p.z),
		"mirror_x": func(p: Vector3) -> Vector3: return Vector3(-p.x, p.y, p.z),
		"mirror_z": func(p: Vector3) -> Vector3: return Vector3(p.x, p.y, -p.z),
	}
	for key in transforms:
		var hits := 0
		var asphalt := 0
		var average_delta := 0.0
		var max_dist := 0.0
		for index in range(0, points.size(), 20):
			var p: Vector3 = transforms[key].call(points[index])
			var query := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 120.0, p - Vector3.UP * 120.0, 1)
			var hit := race.get_world_3d().direct_space_state.intersect_ray(query)
			if hit:
				hits += 1
				var collider := hit.collider as Node
				if collider.name == "Asphalt": asphalt += 1
				average_delta += absf(float(hit.position.y) - p.y)
				max_dist = maxf(max_dist, absf(float(hit.position.y) - p.y))
		print("AXIS_PROBE candidate=", key, " samples=", ceili(points.size() / 20.0), " hits=", hits, " asphalt=", asphalt, " mean_abs_y_delta=", average_delta / maxf(hits,1), " max_y_delta=", max_dist)
	quit(0)
