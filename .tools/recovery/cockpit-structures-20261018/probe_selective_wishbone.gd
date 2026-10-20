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
	var path := "res://McLaren MP4_4 · Senna/McLaren MP4_4 · Senna production model"
	var model: Node3D = race.car.model_root
	var candidates: Array[Node] = model.find_children("wishbone_LF_2_001", "MeshInstance3D", true, false)
	if candidates.is_empty():
		push_error("Imported node wishbone_LF_2_001 not found")
		quit(1)
		return
	var part := candidates[0] as MeshInstance3D
	print("TARGET path=", part.get_path(), " layers_before=", part.layers, " camera_masks nose=", race.nose_camera.cull_mask, " chase=", race.camera.cull_mask, " aabb=", part.mesh.get_aabb())
	await _capture("wishbone-before-nose")
	# Render layer 3 (value 4): excluded from the nose camera mask 3, explicitly
	# included in the exterior mask 5. Mesh, material, transform and physics remain.
	part.layers = 4
	race.camera.cull_mask = 5
	race.nose_camera.cull_mask = 3
	for _i in 3: await process_frame
	await _capture("wishbone-hidden-nose")
	race.set_camera_mode(0)
	race._update_chase_camera(1.0)
	race._apply_camera_mode(1.0)
	for _i in 3: await process_frame
	await _capture("wishbone-visible-exterior")
	print("RESULT targeted_nodes=1 layer_after=", part.layers, " nose_mask=", race.nose_camera.cull_mask, " exterior_mask=", race.camera.cull_mask)
	race.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var file := ProjectSettings.globalize_path(OUT + "/" + label + ".png")
	var error := root.get_texture().get_image().save_png(file)
	print("CAPTURE label=", label, " error=", error)
