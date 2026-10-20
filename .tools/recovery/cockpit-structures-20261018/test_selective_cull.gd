extends SceneTree

const TrackScript := preload("res://scripts/track_data.gd")
const RaceScene := preload("res://scenes/race.tscn")
const OUT := "res://.tools/recovery/cockpit-structures-20261018/diagnostics/mclaren"

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
	for _i in 3: await process_frame
	var candidates := ["wishbone_LF_2_001", "steering_arm_LF_001", "steering_arm_RF_001"]
	var changed := 0
	for candidate_name in candidates:
		var found: Array[Node] = race.car.model_root.find_children(candidate_name, "MeshInstance3D", true, false)
		if found.is_empty(): continue
		var mesh := found[0] as MeshInstance3D
		if mesh.layers != 1:
			mesh.layers = 1
			changed += 1
	print("SELECTIVE_CULL changed=", changed, " nose_mask=", race.nose_camera.cull_mask, " exterior_mask=", race.camera.cull_mask)
	await _capture("selective-cull-nose")
	race.set_camera_mode(0)
	race._update_chase_camera(1.0)
	race._apply_camera_mode(1.0)
	for _i in 3: await process_frame
	await _capture("selective-cull-exterior")
	print("SELECTIVE_CULL_PASS rendered_changes_only_in_nose_layers")
	race.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OUT + "/" + label + ".png"
	var error := root.get_texture().get_image().save_png(path)
	print("CAPTURE label=", label, " error=", error)
