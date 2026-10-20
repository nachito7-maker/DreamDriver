extends SceneTree

const TrackScript := preload("res://scripts/track_data.gd")
const RaceScene := preload("res://scenes/race.tscn")
const OUT := "res://.tools/recovery/cockpit-structures-20261018/isolation"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for vehicle_id in ["mclaren", "rb22_2026"]:
		TrackScript.set_user_selection(TrackScript.BARCELONA, vehicle_id)
		var race := RaceScene.instantiate()
		root.add_child(race)
		for _i in 240:
			await physics_frame
		race.set_camera_mode(1)
		for _i in 60:
			await physics_frame
		var details: Node = race.nose_camera.get_node_or_null("Onboard cockpit details")
		var car: Node3D = race.car.model_root
		print("ISOLATE VEHICLE=", vehicle_id)
		for child in details.get_children():
			if child is MeshInstance3D:
				var mesh := child as MeshInstance3D
				print("SYNTH name=", mesh.name, " type=", mesh.mesh.get_class(), " dims=", (mesh.mesh.get_aabb().size), " pos=", mesh.position, " rot=", mesh.rotation, " scale=", mesh.scale, " layers=", mesh.layers, " visible=", mesh.visible)
		await _capture(race, vehicle_id + "-base")
		for child in details.get_children():
			if not child is MeshInstance3D or not String(child.name).contains("Halo"):
				continue
			var mesh := child as MeshInstance3D
			mesh.visible = false
			await process_frame
			await RenderingServer.frame_post_draw
			await _capture(race, vehicle_id + "-hide-" + mesh.name.to_lower().replace(" ", "-"))
			mesh.visible = true
		# Camera-local support structure as a whole versus model geometry alone.
		var saved: Array[Node] = []
		for child in details.get_children():
			if child is MeshInstance3D and String(child.name).contains("Halo"):
				child.visible = false
				saved.append(child)
		await process_frame
		await RenderingServer.frame_post_draw
		await _capture(race, vehicle_id + "-model-only")
		for child in saved:
			child.visible = true

		# RB source halo pieces, if present, are disabled one exact imported mesh at
		# a time and then as a family; all other imported surfaces remain visible.
		if vehicle_id == "rb22_2026":
			var halo_nodes: Array[MeshInstance3D] = []
			for node in car.find_children("*", "MeshInstance3D", true, false):
				if String(node.name).to_lower().begins_with("hal_"):
					halo_nodes.append(node)
					print("SOURCE_HALO node=", node.get_path(), " mesh=", node.mesh.get_class(), " bounds=", node.mesh.get_aabb(), " pos=", node.position, " rot=", node.rotation, " scale=", node.scale)
			for node in halo_nodes:
				node.visible = false
				await process_frame
				await RenderingServer.frame_post_draw
				await _capture(race, "rb22-hide-source-" + String(node.name).to_lower().replace("_", "-"))
				node.visible = true
			for node in halo_nodes:
				node.visible = false
			await process_frame
			await RenderingServer.frame_post_draw
			await _capture(race, "rb22-no-source-halo")
			for node in halo_nodes:
				node.visible = true

		# The red-colored line on the track is the intentional racing aid. Keep its
		# visual effect distinguishable from any geometry in the cockpit.
		if race.assistance_line is MeshInstance3D:
			var assist := race.assistance_line as MeshInstance3D
			print("ASSISTANCE_LINE mesh=", assist.mesh.get_class() if assist.mesh else "none", " surfaces=", assist.mesh.get_surface_count() if assist.mesh else 0, " visible=", assist.visible, " node=", assist.get_path())
			race.set_camera_mode(0)
			for _i in 60: await physics_frame
			await _capture(race, vehicle_id + "-exterior-line-on")
			assist.visible = false
			await process_frame
			await RenderingServer.frame_post_draw
			await _capture(race, vehicle_id + "-exterior-line-off-diagnostic")
		race.queue_free()
		await process_frame
	quit()

func _capture(race: Node, label: String) -> void:
	var path: String = OUT + "/" + label + ".png"
	var image: Image = root.get_texture().get_image()
	var err := image.save_png(path)
	print("ISOLATION_CAPTURE label=", label, " path=", path, " error=", err)

