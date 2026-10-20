extends SceneTree

# ============================================================================
# CALIBRACIÓN DE LA PINTURA DE LA LÍNEA DE ASISTENCIA
#
# La paleta de la línea NO se elige a ojo: se elige por el color que el motor PINTA
# en pantalla, con la luz, el material y el tonemap del juego por medio. Este script
# monta la escena de carrera en un SubViewport de 2400x1080 (el lienzo del teléfono),
# coloca el coche en la recta de salida, lo CONGELA —la pose, la cámara y la luz no
# cambian entre medidas, así que lo único que cambia es el color— y, para cada
# albedo candidato:
#
#   1. lo escribe en la paleta del estado que toca (verde, amarillo, rojo o goma),
#   2. fuerza la línea entera a ese color,
#   3. deja asentar el antialiasing temporal, y
#   4. guarda el fotograma en `disparos-calib/<etiqueta>.png`.
#
# Además guarda `mascara-linea.png` con la línea forzada a MAGENTA —un color que no
# existe en el circuito, así que los píxeles del listón se reconocen por su color y no
# por diferencias entre fotogramas—, `mascara-linea2.png` (el mismo estado otra vez, para
# comprobar que el lienzo se vuelve a dibujar sin moverse) y `mascara-base.png` (el
# mismo instante con el listón oculto, para medir el asfalto de al lado).
#
# El desgaste se apaga durante la medida (u_wear = 0): se calibra el color de la
# pintura, no su gasto.
#
# Uso:
#   "$GODOT" --path . --script res://.tools/recovery/linea-visual/calibrar.gd
# ============================================================================

const TrackScript = preload("res://scripts/track_data.gd")

const OUT_DIR := "res://.tools/recovery/linea-visual"
const SHOTS_DIR := "res://.tools/recovery/linea-visual/disparos-calib"
const FRAME_W := 2400
const FRAME_H := 1080
const ASENTAR_FOTOGRAMAS := 40

# Candidatos: [etiqueta, ranura, color sRGB del albedo]. La ranura 0/1/2 es
# verde/amarillo/rojo; la 3 es la GOMA (los tres colores al mismo gris, que es lo que
# pinta el borde de la pintura y con lo que se funde en el horizonte). Se prueban de
# oscuro a claro dentro de cada familia para poder elegir el que dé el color buscado.
var CANDIDATOS := [
	["goma-058", 3, Color(0.58, 0.58, 0.58)],
	["goma-063", 3, Color(0.63, 0.63, 0.63)],
	["goma-068", 3, Color(0.68, 0.68, 0.68)],
	["goma-073", 3, Color(0.73, 0.73, 0.73)],
	["verde-1", 0, Color(0.43, 0.50, 0.39)],
	["verde-2", 0, Color(0.47, 0.54, 0.43)],
	["verde-3", 0, Color(0.51, 0.58, 0.47)],
	["verde-4", 0, Color(0.55, 0.62, 0.51)],
	["amarillo-1", 1, Color(0.57, 0.52, 0.42)],
	["amarillo-2", 1, Color(0.61, 0.56, 0.46)],
	["amarillo-3", 1, Color(0.65, 0.60, 0.50)],
	["amarillo-4", 1, Color(0.69, 0.64, 0.54)],
	["rojo-1", 2, Color(0.56, 0.45, 0.42)],
	["rojo-2", 2, Color(0.60, 0.49, 0.46)],
	["rojo-3", 2, Color(0.64, 0.53, 0.50)],
	["rojo-4", 2, Color(0.68, 0.57, 0.54)],
]

var view: SubViewport
var race: Node3D
var car
var cam: Camera3D
var linea
var puntos := PackedVector3Array()
var errores: Array[String] = []
var registro := {"lienzo": [FRAME_W, FRAME_H], "candidatos": []}
var _imagen_anterior: Image = null

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOTS_DIR))
	view = SubViewport.new()
	view.name = "Lienzo de calibración 2400x1080"
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
	cam = race.camera
	linea = race.assistance_line
	puntos = TrackScript.get_centerline()
	await _colocar(0, 300.0)
	# La pose se congela: sin esto el coche sigue avanzando entre candidatos y cada
	# medida caería en un sitio distinto de la vuelta (y con otra luz).
	car.set_physics_process(false)
	for i in 40:
		await physics_frame
	DisplayServer.window_move_to_foreground()
	print("LINEA_CAL lienzo=%dx%d candidatos=%d color_actual=(%.2f,%.2f,%.2f)" % [
		FRAME_W, FRAME_H, CANDIDATOS.size(), linea.color_accelerate.r,
		linea.color_accelerate.g, linea.color_accelerate.b])
	linea.material_override.set_shader_parameter("u_wear", 0.0)

	# La máscara: el listón forzado a MAGENTA (un color que no está en el circuito),
	# repetido para comprobar que el lienzo se vuelve a dibujar igual, y el mismo
	# instante con el listón oculto.
	linea.color_accelerate = Color(1.0, 0.0, 1.0)
	linea.actualizar_paleta()
	linea.forzar_estado(0)
	await _asentar()
	await _grabar(SHOTS_DIR + "/mascara-linea.png")
	await _grabar(SHOTS_DIR + "/mascara-linea2.png")
	linea.visible = false
	await _asentar()
	await _grabar(SHOTS_DIR + "/mascara-base.png")
	linea.visible = true
	linea.soltar_estado()

	for candidato in CANDIDATOS:
		await _medir(String(candidato[0]), int(candidato[1]), candidato[2])

	var ruta := OUT_DIR + "/calibracion.json"
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	archivo.store_string(JSON.stringify(registro, "  "))
	archivo.close()
	print("LINEA_CAL registro=%s" % ruta)
	for texto in errores:
		print("LINEA_CAL FAIL ", texto)
	print("LINEA_CAL %s candidatos=%d" % ["PASS" if errores.is_empty() else "FAIL", registro["candidatos"].size()])
	quit(1 if not errores.is_empty() else 0)

# Un candidato: a la paleta del estado que toca, forzado en toda la línea, asentado y
# guardado. La medida la hace `calibrar.py` sobre el PNG.
func _medir(etiqueta: String, ranura: int, color: Color) -> void:
	if ranura == 3:
		# La goma: los tres colores al mismo gris, así el núcleo del listón ES la goma.
		linea.color_accelerate = color
		linea.color_hold = color
		linea.color_brake = color
		linea.actualizar_paleta()
		linea.forzar_estado(0)
	else:
		if ranura == 0:
			linea.color_accelerate = color
		elif ranura == 1:
			linea.color_hold = color
		else:
			linea.color_brake = color
		linea.actualizar_paleta()
		linea.forzar_estado(ranura)
	await _asentar()
	var imagen: Image = await _grabar(SHOTS_DIR + "/%s.png" % etiqueta)
	linea.soltar_estado()
	if imagen == null:
		errores.append("no se pudo capturar el candidato %s" % etiqueta)
		return
	registro["candidatos"].append({
		"etiqueta": etiqueta,
		"ranura": ranura,
		"albedo": [color.r, color.g, color.b],
		"archivo": "%s.png" % etiqueta,
	})
	print("LINEA_CAL %-12s ranura=%d albedo=(%.2f, %.2f, %.2f)" % [
		etiqueta, ranura, color.r, color.g, color.b])

func _asentar() -> void:
	for i in ASENTAR_FOTOGRAMAS:
		await process_frame

# Coloca el coche en la trazada con la velocidad dada (la misma colocación que usa
# `.tools/recovery/linea/capturar.gd`, para que la pose sea la de las capturas).
func _colocar(indice: int, kph: float) -> void:
	var tangente := (puntos[(indice + 1) % puntos.size()] - puntos[indice]).normalized()
	car.recover_to(puntos[indice] + Vector3.UP * 0.2, atan2(-tangente.x, -tangente.z))
	car.velocity = tangente * (kph / 3.6)
	for i in 90:
		Input.action_release("throttle")
		Input.action_release("brake")
		car.velocity = tangente * (kph / 3.6)
		await physics_frame
	for i in 40:
		await physics_frame

# Guarda el fotograma y lo devuelve (null si no se pudo). Igual que en `capturar.gd`:
# `force_draw` obliga a dibujar aunque el gestor de ventanas tape la ventana, y si la
# textura no cambia entre intentos la captura se da por perdida.
func _grabar(ruta: String) -> Image:
	for intento in 6:
		RenderingServer.force_draw(false)
		for i in 2:
			await process_frame
		var imagen: Image = view.get_texture().get_image()
		if _imagen_anterior == null or _diferencia(imagen, _imagen_anterior) > 0.0:
			_imagen_anterior = imagen
			var error := imagen.save_png(ruta)
			if error != OK:
				errores.append("no se pudo guardar %s (error %d)" % [ruta, error])
				return null
			return imagen
		if intento < 5:
			DisplayServer.window_move_to_foreground()
			await create_timer(0.15).timeout
	errores.append("el lienzo no se vuelve a dibujar: %s se queda con el fotograma anterior" % ruta)
	return null

func _diferencia(a: Image, b: Image) -> float:
	if a == null or b == null or a.get_size() != b.get_size():
		return 1.0
	var metricas := a.compute_image_metrics(b, false)
	return float(metricas.get("max", 1.0))
