extends SceneTree
const RaceScript = preload("res://scripts/race.gd")
var failures := 0
func check(value: bool, message: String) -> void:
	print("LAP ", "PASS " if value else "FAIL ", message)
	if not value: failures += 1
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var lap := RaceScript.LapTracker.new()
	root.add_child(lap)
	lap.set_course(load("res://scripts/track_data.gd").get_centerline())
	lap.register_crossing(-1, 1)
	check(not lap.armed, "reverse crossing ignored")
	lap.register_crossing(1, -1)
	check(lap.armed and lap.laps == 0, "first forward crossing starts timer")
	lap.lap_time = 95.25
	lap.register_crossing(1, -1)
	check(lap.laps == 0, "finish recross without sectors cannot count a lap")
	lap.next_sector = 8
	lap.register_crossing(1, -1)
	check(lap.laps == 1 and is_equal_approx(lap.best_lap, 95.25), "ordered lap records previous and best")
	lap.lap_time = 94.0
	lap.next_sector = 8
	lap.register_crossing(1, -1)
	check(lap.laps == 2 and is_equal_approx(lap.previous_lap, 94.0) and is_equal_approx(lap.best_lap, 94.0), "faster valid lap replaces best")
	lap.lap_time = 90.0
	lap.next_sector = 8
	lap.valid_lap = false
	lap.register_crossing(1, -1)
	check(lap.laps == 3 and is_equal_approx(lap.best_lap, 94.0), "invalid lap cannot replace best")
	lap.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
