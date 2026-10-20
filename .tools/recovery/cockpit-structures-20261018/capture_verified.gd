extends SceneTree

const TrackScript := preload("res://scripts/track_data.gd")
const RaceScene := preload("res://scenes/race.tscn")
const OUT := "res://.tools/recovery/cockpit-structures-20261018/verified"
const VEHICLES := ["mclaren", "rb22_2026"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for vehicle_id in VEHICLES:
		if not TrackScript.set_user_selection(TrackScript.BARCELONA, vehicle_id):
			push_error("Could not select vehicle " + vehicle_id)
			quit(1)
			return
		var race: Node3D = RaceScene.instantiate()
		root.add_child(race)
		await process_frame
		if race.car == null or race.car.model_root == null:
			push_error("Race car/model failed to load: " + vehicle_id)
			quit(2)
			return
		# Hold the exact same car pose while rendering both variants. This prevents
		# speed/camera movement from contaminating the visual A/B comparison.
		race.car.set_physics_process(false)
		race.set_camera_mode(1)
		race._update_nose_camera()
		race._apply_camera_mode(1.0)
		await process_frame
		var supports: Array[MeshInstance3D] = _add_reference_supports(race.nose_camera)
		await _capture(vehicle_id + "-nose-before")
		for node in supports:
			node.queue_free()
		for _i in 2:
			await process_frame
		await _capture(vehicle_id + "-nose-after")

		race.set_camera_mode(0)
		race._update_chase_camera(1.0)
		race._apply_camera_mode(1.0)
		await process_frame
		await _capture(vehicle_id + "-exterior-before")
		await _capture(vehicle_id + "-exterior-after")
		race.queue_free()
		await process_frame
	quit()

func _add_reference_supports(camera: Camera3D) -> Array[MeshInstance3D]:
	var cockpit := camera.get_node("Onboard cockpit details") as Node3D
	var carbon := StandardMaterial3D.new()
	carbon.albedo_color = Color(0.025, 0.035, 0.045)
	carbon.metallic = 0.22
	carbon.roughness = 0.72
	var result: Array[MeshInstance3D] = []
	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		rail.name = "Reference synthetic halo side support"
		var box := BoxMesh.new()
		box.size = Vector3(0.055, 0.38, 0.06)
		rail.mesh = box
		rail.position = Vector3(side * 0.40, -0.41, -1.18)
		rail.rotation.z = -side * deg_to_rad(26.0)
		rail.material_override = carbon
		rail.layers = 2
		cockpit.add_child(rail)
		result.append(rail)
	var pillar := MeshInstance3D.new()
	pillar.name = "Reference synthetic halo center pillar"
	var pillar_box := BoxMesh.new()
	pillar_box.size = Vector3(0.032, 0.24, 0.045)
	pillar.mesh = pillar_box
	pillar.position = Vector3(0.0, -0.30, -1.15)
	pillar.material_override = carbon
	pillar.layers = 2
	cockpit.add_child(pillar)
	result.append(pillar)
	return result

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path: String = OUT + "/" + label + ".png"
	var error := root.get_texture().get_image().save_png(path)
	print("CAPTURE label=", label, " path=", path, " error=", error)
	if error != OK:
		push_error("Screenshot save failed: " + label)
