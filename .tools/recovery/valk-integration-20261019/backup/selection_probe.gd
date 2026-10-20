extends SceneTree

const TrackScript = preload("res://scripts/track_data.gd")
const RaceScript = preload("res://scripts/race.gd")
const MENU_SCRIPT = preload("res://scripts/main_menu.gd")
const MENU_SCENE = preload("res://scenes/main_menu.tscn")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	TrackScript.reset_selection()
	if TrackScript.get_selected_vehicle_id() != "rb22_2026":
		push_error("The new RB22 must be the default vehicle after reset")
		quit(8)
		return
	if TrackScript.set_user_selection(TrackScript.BARCELONA, "redbull"):
		push_error("The discarded Red Bull must not be selectable")
		quit(9)
		return
	if TrackScript.get_vehicle_name_for_id("redbull") != TrackScript.get_vehicle_name_for_id("rb22_2026") or TrackScript.get_car_model_path("redbull") != TrackScript.get_car_model_path("rb22_2026"):
		push_error("Legacy Red Bull references must resolve to the new RB22, never the discarded asset")
		quit(10)
		return
	for track_id in [TrackScript.BARCELONA, TrackScript.SUZUKA, TrackScript.MONTREAL]:
		for vehicle_id in ["mclaren", "rb22_2026"]:
			if not TrackScript.set_user_selection(track_id, vehicle_id):
				push_error("Selection rejected: %s / %s" % [track_id, vehicle_id])
				quit(1)
				return
			var centerline := TrackScript.get_centerline()
			var ideal_line := TrackScript.get_ideal_line()
			var track_scene := load(TrackScript.get_track_scene_path()) as PackedScene
			var vehicle_scene := load(TrackScript.get_car_model_path()) as PackedScene
			var minimum_points := int(TrackScript.TRACKS[track_id].get("minimum_points", 3000))
			var minimum_ideal_points := 2800 if track_id == TrackScript.BARCELONA else 2500 if track_id == TrackScript.MONTREAL else 3000
			if centerline.size() < minimum_points or ideal_line.size() < minimum_ideal_points or track_scene == null or vehicle_scene == null:
				push_error("Missing race resources: %s / %s | center=%d ideal=%d track=%s vehicle=%s" % [
					track_id, vehicle_id, centerline.size(), ideal_line.size(), track_scene != null, vehicle_scene != null])
				quit(2)
				return
			print("[selection probe] CONFIG track=%s car=%s center=%d ideal=%d scene=%s model=%s" % [
				track_id, vehicle_id, centerline.size(), ideal_line.size(),
				TrackScript.get_track_scene_path(), TrackScript.get_car_model_path()])
			var race := Node3D.new()
			race.set_script(RaceScript)
			root.add_child(race)
			for _frame in 8:
				await process_frame
			if race.track_mesh == null or race.car == null or race.car.model_root == null:
				push_error("Race did not construct track and vehicle: %s / %s" % [track_id, vehicle_id])
				race.queue_free()
				quit(3)
				return
			var expected_name := String(TrackScript.get_selected_vehicle().get("name", ""))
			var actual_name := expected_name.replace("/", "_")
			var wheel_count := 0
			for wheel_name in ["wheel_fl", "wheel_fr", "wheel_rl", "wheel_rr"]:
				if race.car.model_root.find_child(wheel_name, true, false) != null:
					wheel_count += 1
			if race.car.name != actual_name or wheel_count != 4:
				push_error("Vehicle mount check failed: name=%s expected=%s wheels=%d" % [race.car.name, actual_name, wheel_count])
				race.queue_free()
				quit(4)
				return
			var collider_count := 0
			var road_count := 0
			var wall_count := 0
			var offtrack_count := 0
			for node in race.track_mesh.find_children("*", "StaticBody3D", true, false):
				var body := node as StaticBody3D
				if body.collision_layer == 0:
					continue
				var has_shape := false
				for child in body.get_children():
					if child is CollisionShape3D and child.shape != null:
						has_shape = true
				if not has_shape:
					continue
				collider_count += 1
				var surface := String(body.get_meta("ac_surface", ""))
				var label := (String(body.name) + " " + surface).to_upper()
				if "ROAD" in label or "TRM-BRC" in label:
					road_count += 1
				if "WALL" in label:
					wall_count += 1
				if "GRASS" in label or "SAND" in label or "GRAVEL" in label or "OUT" in label:
					offtrack_count += 1
			var minimum_colliders := 6 if track_id == TrackScript.MONTREAL else 10
			if collider_count < minimum_colliders or road_count == 0 or wall_count == 0 or offtrack_count == 0:
				push_error("Track collider inventory failed: track=%s colliders=%d road=%d walls=%d offtrack=%d" % [
					track_id, collider_count, road_count, wall_count, offtrack_count])
				race.queue_free()
				quit(6)
				return
			print("[selection probe] PASS track=%s car=%s track_nodes=%d wheel_nodes=%d colliders=%d road=%d walls=%d offtrack=%d" % [
				track_id, vehicle_id, race.track_mesh.get_child_count(), wheel_count,
				collider_count, road_count, wall_count, offtrack_count])
			await process_frame
			race.queue_free()
			await process_frame
	var menu_scene := MENU_SCENE.instantiate()
	root.add_child(menu_scene)
	await process_frame
	var vehicle_options := TrackScript.get_vehicle_options()
	if vehicle_options.size() != 2 or vehicle_options.has("redbull"):
		push_error("Vehicle catalog must contain exactly McLaren and the new RB22: %s" % str(vehicle_options.keys()))
		quit(7)
		return
	if menu_scene.find_child("Track suzuka", true, false) == null or menu_scene.find_child("Track barcelona", true, false) == null or menu_scene.find_child("Track montreal", true, false) == null or menu_scene.find_child("Vehicle mclaren", true, false) == null or menu_scene.find_child("Vehicle rb22_2026", true, false) == null or menu_scene.find_child("Vehicle redbull", true, false) != null:
		push_error("Main menu must retain Barcelona/Suzuka and offer Montreal plus both existing vehicles")
		quit(5)
		return
	print("[selection probe] PASS menu retains Barcelona/Suzuka and offers Montreal plus both existing vehicles")
	quit()
