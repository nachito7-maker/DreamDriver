extends SceneTree

# Mapa de materiales de las ruedas: pinta la superficie 0 (goma) de rojo y la 1
# (llanta) de azul, con material plano, para VER —no suponer— qué caras lleva
# cada material. Es la comprobación que usó el proyecto F1 anterior
# (`tools/render_wheel_mat.py --diag`), aquí sobre el modelo montado en el juego.

const OUT_DIR := "res://.tools/wheels/diag"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 120:
		await physics_frame
	var car: CharacterBody3D = race.car
	var surfaces := [Color(0.85, 0.12, 0.12), Color(0.15, 0.35, 0.9), Color(0.9, 0.85, 0.15)]
	for child in car.model_root.find_children("*", "MeshInstance3D", true, false):
		if not String(child.name).to_lower().contains("wheel"):
			continue
		var mesh: Mesh = child.mesh
		for surface in range(mesh.get_surface_count()):
			var flat := StandardMaterial3D.new()
			flat.albedo_color = surfaces[min(surface, surfaces.size() - 1)]
			flat.roughness = 1.0
			flat.metallic = 0.0
			child.set_surface_override_material(surface, flat)
		print("RUEDA %s superficies=%d" % [String(child.name), mesh.get_surface_count()])
	var camera: Camera3D = race.camera
	var pos: Vector3 = car.global_position
	var fwd: Vector3 = -car.global_basis.z
	var right: Vector3 = car.global_basis.x
	var rl: Vector3 = pos - fwd * 1.95 - right * 0.89
	var views := [
		["rueda_trasera", rl - right * 2.2 + Vector3.UP * 0.30, rl],
		["rueda_trasera_atras", rl - fwd * -2.2 + Vector3.UP * 0.30, rl],
		["trasera_baja", pos - fwd * 5.5 + Vector3.UP * 0.6, pos + Vector3.UP * 0.35],
		["lateral_baja", pos + right * 6.0 + Vector3.UP * 0.5, pos + Vector3.UP * 0.35],
	]
	for view in views:
		camera.global_position = view[1]
		camera.look_at(view[2], Vector3.UP)
		for i in 3:
			await process_frame
		var image: Image = root.get_texture().get_image()
		print("DIAG %s -> %s" % [view[0], image.save_png("%s/%s.png" % [OUT_DIR, view[0]])])
	race.queue_free()
	await process_frame
	quit(0)
