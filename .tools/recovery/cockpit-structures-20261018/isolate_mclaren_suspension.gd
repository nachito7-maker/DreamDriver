extends SceneTree

const TrackScript := preload("res://scripts/track_data.gd")
const RaceScene := preload("res://scenes/race.tscn")
const OUT := "res://.tools/recovery/cockpit-structures-20261018/diagnostics/mclaren"
const CANDIDATES := [
	"steering_arm_LF_001", "steering_arm_RF_001",
	"Barra_Direccion_Left_001", "Barra_Direccion_Right_001",
	"Barra_Direccion__Left_Tornillos_001", "Barra_Direccion__Right_Tornillos_001",
	"wishbone_LF_1_001", "wishbone_LF_2_001", "wishbone_LF_3_001",
	"wishbone_RF_1_001", "wishbone_RF_2_001", "wishbone_RF_4_001",
	"WING_FRONT_LEFT_SUB0_001", "WING_FRONT_RIGHT_SUB0_001",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	TrackScript.set_user_selection(TrackScript.BARCELONA, "mclaren")
	var race: Node3D = RaceScene.instantiate()
	root.add_child(race)
	await process_frame
	if race.car == null or race.car.model_root == null:
		push_error("McLaren failed to load")
		quit(1)
		return
	race.set_physics_process(false)
	race.car.set_physics_process(false)
	race.set_camera_mode(1)
	race._update_nose_camera()
	race._apply_camera_mode(1.0)
	for _i in 3:
		await process_frame
	await _capture("baseline")
	for candidate_name in CANDIDATES:
		var found: Array[Node] = race.car.model_root.find_children(candidate_name, "MeshInstance3D", true, false)
		if found.is_empty():
			print("CANDIDATE missing=", candidate_name)
			continue
		for candidate in found:
			var mesh := candidate as MeshInstance3D
			print("ISOLATE name=", mesh.name, " path=", mesh.get_path(), " mesh=", mesh.mesh.get_class() if mesh.mesh else "null",
				" local_pos=", mesh.position, " local_rot=", mesh.rotation, " scale=", mesh.scale,
				" aabb=", mesh.mesh.get_aabb() if mesh.mesh else "null")
			mesh.visible = false
			for _i in 2:
				await process_frame
			await _capture(candidate_name.to_lower().replace("/", "-"))
			mesh.visible = true
			await process_frame
	race.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = OUT + "/" + label + ".png"
	var error := image.save_png(path)
	print("CAPTURE label=", label, " size=", image.get_size(), " error=", error)
