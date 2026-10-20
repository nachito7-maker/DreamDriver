extends SceneTree

const TrackScript := preload("res://scripts/track_data.gd")
const RaceScene := preload("res://scenes/race.tscn")
const OUT := "res://.tools/recovery/cockpit-structures-20261018/final"
const VEHICLES := ["mclaren", "rb22_2026"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var failures := 0
	for vehicle_id in VEHICLES:
		if not TrackScript.set_user_selection(TrackScript.BARCELONA, vehicle_id):
			push_error("Could not select vehicle " + vehicle_id)
			failures += 1
			continue
		var race: Node3D = RaceScene.instantiate()
		root.add_child(race)
		await process_frame
		await process_frame
		if race.car == null or race.car.model_root == null or race.nose_camera == null or race.camera == null:
			push_error("Race/car/cameras failed to load: " + vehicle_id)
			failures += 1
			race.queue_free()
			await process_frame
			continue
		race.set_physics_process(false)
		race.car.set_physics_process(false)
		var cockpit := race.nose_camera.get_node_or_null("Onboard cockpit details") as Node3D
		var unexpected := 0
		var actual_names: Array[String] = []
		if cockpit != null:
			for child in cockpit.get_children():
				if child is MeshInstance3D:
					actual_names.append(String(child.name))
					if String(child.name).to_lower().contains("halo") or String(child.name).to_lower().contains("support") or String(child.name).to_lower().contains("pillar"):
						unexpected += 1
		var wheel_paths := _wheel_nodes(race.car.model_root, vehicle_id)
		var visible_meshes := 0
		var material_surfaces := 0
		for node in race.car.model_root.find_children("*", "MeshInstance3D", true, false):
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh == null:
				continue
			if mesh_node.visible:
				visible_meshes += 1
			material_surfaces += mesh_node.mesh.get_surface_count()
		var halo_count := 0
		for node in race.car.model_root.find_children("*", "MeshInstance3D", true, false):
			if String(node.name).to_lower().begins_with("hal_"):
				halo_count += 1
		print("VERIFY vehicle=", vehicle_id, " cockpit_meshes=", actual_names,
			" unexpected_camera_supports=", unexpected, " rendered_wheel_meshes=", wheel_paths,
			" source_halo_meshes=", halo_count, " visible_model_meshes=", visible_meshes,
			" material_surfaces=", material_surfaces)
		if unexpected != 0 or wheel_paths.size() != 4 or visible_meshes == 0 or material_surfaces == 0:
			push_error("Vehicle structural verification failed: " + vehicle_id)
			failures += 1
		race.set_camera_mode(1)
		race._update_nose_camera()
		race._apply_camera_mode(1.0)
		for _i in 2:
			await process_frame
		failures += await _capture(vehicle_id + "-nose")
		race.set_camera_mode(0)
		race._update_chase_camera(1.0)
		race._apply_camera_mode(1.0)
		for _i in 2:
			await process_frame
		failures += await _capture(vehicle_id + "-exterior")
		race.queue_free()
		await process_frame
	print("FINAL_VERIFICATION failures=", failures, " output=", OUT)
	quit(0 if failures == 0 else 1)

func _wheel_nodes(model: Node3D, vehicle_id: String) -> Array[String]:
	var canonical_names := ["wheel_fl", "wheel_fr", "wheel_rl", "wheel_rr"]
	var paths: Array[String] = []
	for canonical in canonical_names:
		var search_name: String = canonical
		if vehicle_id == "rb22_2026" and canonical == "wheel_rl":
			search_name = "wheel_bl"
		elif vehicle_id == "rb22_2026" and canonical == "wheel_rr":
			search_name = "wheel_br"
		var found := model.find_children(search_name + "*", "MeshInstance3D", true, false)
		if not found.is_empty():
			paths.append(String(found[0].get_path()))
	return paths

func _capture(label: String) -> int:
	await RenderingServer.frame_post_draw
	var path: String = OUT + "/" + label + ".png"
	var error := root.get_texture().get_image().save_png(path)
	print("CAPTURE label=", label, " error=", error, " path=", path)
	if error != OK:
		push_error("Screenshot failed: " + label)
		return 1
	return 0
