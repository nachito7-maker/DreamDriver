extends SceneTree

const TrackScript := preload("res://scripts/track_data.gd")
const RaceScene := preload("res://scenes/race.tscn")
const OUT := "res://.tools/recovery/cockpit-structures-20261018/diagnostics/mclaren"
const CANDIDATES := ["wishbone_LF_2_001", "steering_arm_LF_001", "steering_arm_RF_001"]

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
	await _capture("visibility-before-nose")
	var saved_masks: Dictionary = {}
	for candidate_name in CANDIDATES:
		var found: Array[Node] = race.car.model_root.find_children(candidate_name, "MeshInstance3D", true, false)
		if found.is_empty(): continue
		var mesh := found[0] as MeshInstance3D
		saved_masks[mesh] = mesh.layers
		mesh.layers = 1
	print("VISIBILITY_TEST targeted=", saved_masks.size(), " camera_mask=", race.nose_camera.cull_mask, " chase_mask=", race.camera.cull_mask)
	for _i in 2: await process_frame
	await _capture("visibility-after-nose")
	race.set_camera_mode(0)
	race._update_chase_camera(1.0)
	race._apply_camera_mode(1.0)
	for _i in 3: await process_frame
	await _capture("visibility-after-exterior")
	for mesh in saved_masks:
		(mesh as MeshInstance3D).layers = int(saved_masks[mesh])
	print("VISIBILITY_RESTORED count=", saved_masks.size())
	race.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OUT + "/" + label + ".png"
	var err := root.get_texture().get_image().save_png(path)
	print("CAPTURE label=", label, " error=", err, " path=", path)
