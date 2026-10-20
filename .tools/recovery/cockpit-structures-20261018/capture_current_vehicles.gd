extends SceneTree

const TrackScript := preload("res://scripts/track_data.gd")
const RaceScene := preload("res://scenes/race.tscn")
const OUT := "res://.tools/recovery/cockpit-structures-20261018/before"
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
		var race := RaceScene.instantiate()
		root.add_child(race)
		for _i in 12:
			await physics_frame
		var car: Node3D = race.car
		if car == null or car.model_root == null:
			push_error("Race car/model failed to load: " + vehicle_id)
			quit(2)
			return
		var path: String = OUT + "/" + vehicle_id + "-hierarchy.txt"
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_line("VEHICLE=" + vehicle_id + " MODEL=" + TrackScript.get_car_model_path(vehicle_id))
		for child in car.model_root.find_children("*", "MeshInstance3D", true, false):
			var mesh_node := child as MeshInstance3D
			if mesh_node.mesh == null:
				continue
			var label := String(mesh_node.name).to_lower()
			if not (label.contains("halo") or label.contains("hal_") or label.contains("cockpit") or
				label.contains("safetycell") or label.contains("steer") or label.contains("barra") or
				label.contains("mirror") or label.contains("wheel") or label.contains("suspension")):
				continue
			var bounds := mesh_node.mesh.get_aabb()
			var world_bounds := mesh_node.global_transform * bounds
			file.store_line("MESH path=%s class=%s local_pos=%s local_rot=%s local_scale=%s aabb_pos=%s aabb_size=%s world_origin=%s world_aabb_origin=%s world_aabb_size=%s vertices=%d surfaces=%d" % [
				String(mesh_node.get_path()), mesh_node.mesh.get_class(), str(mesh_node.position), str(mesh_node.rotation),
				str(mesh_node.scale), str(bounds.position), str(bounds.size), str(mesh_node.global_position),
				str(world_bounds.position), str(world_bounds.size), _vertex_count(mesh_node.mesh), mesh_node.mesh.get_surface_count()])
		file.close()
		print("HIERARCHY=", ProjectSettings.globalize_path(path))

		# Use actual production cameras and the normal view transition, then capture the
		# rendered frame after drawing rather than taking a synthetic editor preview.
		race.set_camera_mode(1)
		for _i in 12:
			await physics_frame
		await RenderingServer.frame_post_draw
		var nose_path: String = OUT + "/" + vehicle_id + "-nose.png"
		var nose_error := root.get_texture().get_image().save_png(nose_path)
		print("CAPTURE vehicle=", vehicle_id, " camera=nose path=", nose_path, " error=", nose_error)

		race.set_camera_mode(0)
		for _i in 12:
			await physics_frame
		await RenderingServer.frame_post_draw
		var exterior_path: String = OUT + "/" + vehicle_id + "-exterior.png"
		var exterior_error := root.get_texture().get_image().save_png(exterior_path)
		print("CAPTURE vehicle=", vehicle_id, " camera=exterior path=", exterior_path, " error=", exterior_error)
		if nose_error != OK or exterior_error != OK:
			push_error("Screenshot save failed for " + vehicle_id)
			quit(3)
			return
		race.queue_free()
		await process_frame
	quit(0)

func _vertex_count(mesh: Mesh) -> int:
	var count := 0
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		if arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:
			count += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return count
