extends SceneTree

# Renderiza el Red Bull por piezas para localizar geometría anómala: primero con
# el chasis solo (ruedas ocultas) y después con las ruedas solas (chasis
# oculto), desde varias vistas. Además imprime la caja de cada pieza.

const OUT_DIR := "res://.tools/wheels/parts"

var race: Node3D
var car: CharacterBody3D
var body: Array[MeshInstance3D] = []
var wheels: Array[MeshInstance3D] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 120:
		await physics_frame
	car = race.car
	for child in car.model_root.find_children("*", "MeshInstance3D", true, false):
		if String(child.name).to_lower().contains("wheel"):
			wheels.append(child)
		else:
			body.append(child)
	for part in body:
		var aabb: AABB = part.mesh.get_aabb()
		print("PIEZA %-8s caja_local pos=%s tam=%s  mundo_centro=%s" % [
			String(part.name), _v(aabb.position), _v(aabb.size),
			_v(part.global_transform * aabb.get_center())])
	# 1. chasis solo
	_set_visible(wheels, false)
	await _views("solo_chasis")
	# 2. ruedas solas
	_set_visible(wheels, true)
	_set_visible(body, false)
	await _views("solo_ruedas")
	# 3. todo
	_set_visible(body, true)
	await _views("todo")
	# 4. primeros planos de cada rueda
	await _close_ups("material")
	# 5. barrido de arcilla: material plano y neutro para juzgar la GEOMETRÍA sin
	#    que la textura de la librea (o su metalicidad) esconda la forma.
	var clay := StandardMaterial3D.new()
	clay.albedo_color = Color(0.72, 0.72, 0.75)
	clay.roughness = 0.6
	clay.metallic = 0.0
	for part in body:
		part.material_override = clay
	for part in wheels:
		part.material_override = clay
	await _views("arcilla")
	await _close_ups("arcilla")
	race.queue_free()
	await process_frame
	quit(0)

func _set_visible(parts: Array[MeshInstance3D], state: bool) -> void:
	for part in parts:
		part.visible = state

func _views(tag: String) -> void:
	var camera: Camera3D = race.camera
	var pos: Vector3 = car.global_position
	var fwd: Vector3 = -car.global_basis.z
	var right: Vector3 = car.global_basis.x
	var views := [
		["trasera_baja", pos - fwd * 5.5 + Vector3.UP * 0.6],
		["lateral_baja", pos + right * 6.0 + Vector3.UP * 0.5],
		["tres_cuartos", pos - fwd * 4.5 + right * 3.5 + Vector3.UP * 1.6],
		["planta", pos + Vector3.UP * 8.0],
	]
	for view in views:
		camera.global_position = view[1]
		camera.look_at(pos + Vector3.UP * 0.35, fwd if view[0] == "planta" else Vector3.UP)
		for i in 3:
			await process_frame
		var image: Image = root.get_texture().get_image()
		var path := "%s/%s-%s.png" % [OUT_DIR, tag, view[0]]
		print("VISTA %s -> %s error=%d" % [view[0], path, image.save_png(path)])

func _close_ups(prefix: String) -> void:
	var camera: Camera3D = race.camera
	var pos: Vector3 = car.global_position
	var fwd: Vector3 = -car.global_basis.z
	var right: Vector3 = car.global_basis.x
	var wheels := {
		"rueda_trasera_izq": pos - fwd * 1.95 - right * 0.89,
		"rueda_delantera_izq": pos + fwd * 1.51 - right * 0.93,
	}
	for key in wheels:
		var hub: Vector3 = wheels[key]
		for side in [["lado", -2.2], ["detras", -2.2], ["delante", 2.2]]:
			var offset: Vector3 = (right * float(side[1]) if side[0] == "lado"
				else (fwd * float(side[1])))
			camera.global_position = hub + offset + Vector3.UP * 0.35
			camera.look_at(hub, Vector3.UP)
			for i in 3:
				await process_frame
			var image: Image = root.get_texture().get_image()
			print("DETALLE %s %s -> %s" % [prefix, side[0], image.save_png("%s/%s-%s_%s.png" % [OUT_DIR, prefix, key, side[0]])])

func _v(value: Vector3) -> String:
	return "(%.3f, %.3f, %.3f)" % [value.x, value.y, value.z]
