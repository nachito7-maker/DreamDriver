extends SceneTree

# Barrido de la cámara del morro: dibuja el mismo instante con varias
# combinaciones de punto de vista, campo de visión e inclinación, y guarda una
# captura de cada una con sus medidas de composición. Sirve para ELEGIR los
# parámetros mirándolos, en vez de deducirlos a mano, y para dejar la evidencia
# de la elección en el informe.
#
# Uso: "$GODOT" --path . --script .tools/recovery/fase-fp/barrido_morro.gd

const OUT_DIR := "res://.tools/recovery/fase-fp/barrido"
const FRAME_W := 2400
const FRAME_H := 1080
const TrackScript = preload("res://scripts/track_data.gd")

# z_adelante_del_eje (m), sobre el neumático (m), fov vertical (º), inclinación (º)
const COMBOS := [
	[-0.18, 0.20, 74.0, 17.0],
	[0.45, 0.24, 74.0, 12.0],
	[0.55, 0.24, 60.0, 10.0],
	[0.55, 0.24, 50.0, 8.0],
	[0.55, 0.30, 50.0, 10.0],
	[0.65, 0.26, 55.0, 9.0],
	[0.40, 0.22, 45.0, 7.0],
	[0.30, 0.18, 40.0, 6.0],
]

var race: Node3D
var car: CharacterBody3D
var nose: Camera3D
var view: SubViewport
var line: PackedVector3Array

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	view = SubViewport.new()
	view.size = Vector2i(FRAME_W, FRAME_H)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	view.add_child(race)
	Engine.max_fps = 120
	for i in 240:
		await physics_frame
	car = race.car
	nose = race.nose_camera
	line = TrackScript.get_centerline()
	race.set_camera_mode(1)
	# Sobre la recta principal, parado: la composición se mide sin cabeceo.
	var index := _index_at_distance(60.0)
	var tangent := (line[(index + 1) % line.size()] - line[index]).normalized()
	car.recover_to(line[index] + Vector3.UP * 0.2, atan2(-tangent.x, -tangent.z))
	for i in 40:
		await physics_frame
	var indice := 0
	for combo in COMBOS:
		race.nose_behind_axle_m = combo[0]
		race.nose_above_wheels_m = combo[1]
		race.nose_pitch_down_deg = combo[2]
		nose.fov = combo[3]
		race._measure_nose_offset()
		race._update_nose_camera()
		for i in 6:
			await physics_frame
		race._update_nose_camera()
		nose.global_position = race._nose_eye
		nose.look_at(race._nose_target, race._nose_up)
		nose.current = true
		await process_frame
		var medida := _composicion()
		var nombre := "combo-%02d-z%+.2f-y%+.2f-fov%02.0f-pitch%02.0f" % [
			indice, combo[0], combo[1], combo[2], combo[3]]
		var imagen: Image = view.get_texture().get_image()
		print("BARRIDO %s  franja=%.2f ancho=%.2f horizonte=%.2f  neumaticos=%.2f/%.2f  holgura=%.3f  -> %d" % [
			nombre, medida["franja"], medida["ancho"], medida["horizonte"],
			medida["tire_a"], medida["tire_b"], medida["holgura"], imagen.save_png(
				"%s/%s.png" % [OUT_DIR, nombre])])
		indice += 1
	race.queue_free()
	await process_frame
	quit(0)

func _composicion() -> Dictionary:
	var puntos: Array = []
	var ruedas: Array = []
	var inv: Transform3D = car.global_transform.affine_inverse()
	for child in car.model_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := child.mesh as ArrayMesh
		if mesh == null:
			continue
		var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var rueda := String(child.name).to_lower().contains("wheel")
		var stride: int = maxi(1, int(verts.size() / (400.0 if rueda else 4000.0)))
		var propios: Array = []
		for i in range(0, verts.size(), stride):
			var mundo: Vector3 = child.global_transform * verts[i]
			puntos.append(mundo)
			if rueda and (inv * mundo).z < 0.0:
				propios.append(mundo)
		if not propios.is_empty():
			ruedas.append(propios)
	var rect := _rect(puntos)
	var franja := clampf((float(FRAME_H) - rect.position.y) / float(FRAME_H), 0.0, 1.0)
	var base := nose.global_transform
	var adelante := -base.basis.z
	var horizonte := 0.5 + rad_to_deg(asin(clampf(adelante.y, -1.0, 1.0))) / nose.fov
	var visibles := []
	for propios in ruedas:
		visibles.append(_visible(propios))
	while visibles.size() < 2:
		visibles.append(0.0)
	var local := car.global_transform.affine_inverse() * nose.global_position
	return {"franja": franja, "ancho": rect.size.x / float(FRAME_W), "horizonte": horizonte,
		"tire_a": visibles[0], "tire_b": visibles[1],
		"holgura": local.y - _techo_chasis(local.z)}

func _rect(puntos: Array) -> Rect2:
	var rect := Rect2()
	var first := true
	for punto in puntos:
		if nose.is_position_behind(punto):
			continue
		var pantalla: Vector2 = nose.unproject_position(punto)
		if first:
			rect = Rect2(pantalla, Vector2.ZERO)
			first = false
		else:
			rect = rect.expand(pantalla)
	return rect

func _visible(puntos: Array) -> float:
	var rect := _rect(puntos)
	if rect.size.x < 0.5 or rect.size.y < 0.5:
		return 0.0
	var dentro := Rect2(Vector2.ZERO, Vector2(FRAME_W, FRAME_H)).intersection(rect)
	return clampf((dentro.size.x * dentro.size.y) / (rect.size.x * rect.size.y), 0.0, 1.0)

func _index_at_distance(distance: float) -> int:
	var travelled := 0.0
	var i := 0
	while travelled < distance and i < line.size() - 1:
		travelled += line[i].distance_to(line[i + 1])
		i += 1
	return i

# Techo del chasis en la vertical de la cámara, medido en vivo sobre los
# vértices de la malla (no contra una cota escrita a mano).
func _techo_chasis(z: float) -> float:
	var alto := -INF
	var inv: Transform3D = car.global_transform.affine_inverse()
	for child in car.model_root.find_children("*", "MeshInstance3D", true, false):
		if String(child.name).to_lower().contains("wheel"):
			continue
		var mesh := child.mesh as ArrayMesh
		if mesh == null:
			continue
		var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var stride: int = maxi(1, int(verts.size() / 60000.0))
		for i in range(0, verts.size(), stride):
			var punto: Vector3 = inv * (child.global_transform * verts[i])
			if absf(punto.z - z) <= 0.12:
				alto = maxf(alto, punto.y)
	return alto
