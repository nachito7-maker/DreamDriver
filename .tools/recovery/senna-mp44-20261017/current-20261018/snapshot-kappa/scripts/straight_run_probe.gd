extends SceneTree

# Reproduce la conducción que se ve en los vídeos: acelerador a fondo desde la
# salida y ni un toque de dirección. Es la maniobra más simple de reproducir y la
# que deja al descubierto cualquier obstáculo que no esté dibujado, porque el
# coche no se aparta de su rumbo: lo que lo pare, ahí está.
#
# Se conduce con la interfaz de TOQUE real (los mismos `_handle_touch_*` que usa
# el jugador), no moviendo variables a mano, así que también prueba la cadena de
# entrada. Cada medio segundo queda una fila con la estación, el desvío lateral,
# la velocidad y la superficie; al detenerse el coche se imprime, del propio
# motor de física, con qué cuerpo chocó, dónde y con qué normal.
#
# Prueba de la CAUSA, en el mismo binario: con `--relieve-como-antes` se devuelve el
# relieve de la calzada a la altura que tenía en la malla original de AC (+1,50 m,
# exactamente lo que el juego le resta) y se exige lo contrario: que el coche SÍ se
# clave sobre el asfalto a fondo. Si con el relieve en su sitio se clava y con el
# relieve hundido no, la causa del bloqueo invisible queda probada, no argumentada.
#
# Uso:  Godot --path . --script res://scripts/straight_run_probe.gd [--relieve-como-antes]

const TrackScript = preload("res://scripts/track_data.gd")

const RELIEF_SINK_M := 1.5   # lo que la escena le resta al relieve (race.gd)
const SEGUNDOS := 30.0
const TICKS_POR_SEGUNDO := 120
const PARADO := 20.0          # km/h por debajo de los cuales el coche está detenido
const LANZADO := 150.0        # km/h que tiene que haber alcanzado antes de pararse
const TRAS_PARAR_S := 3.0     # se sigue pisando el acelerador para ver si se mueve

var failures := 0
var line: PackedVector3Array

func check(condition: bool, message: String) -> void:
	print("RECTO ", "PASS " if condition else "FAIL ", message)
	if not condition:
		failures += 1

func info(message: String) -> void:
	print("RECTO INFO ", message)

func _initialize() -> void:
	call_deferred("_run")

func _group_of(body: Node) -> String:
	if body == null:
		return "NONE"
	var label := (String(body.name) + " " + String(body.get_meta("ac_surface", ""))).to_upper()
	for key in ["TRM-BRC", "ROAD", "CURB", "KERB", "RUMBLE", "GRAVEL", "SAND", "GRASS",
			"GREEN", "OUT", "CONCRETE", "PITS", "CARPET", "GRILL", "WALL", "BUMP",
			"MARBLES", "CNCPTS", "TRAV"]:
		if key in label:
			return key
	return "OTHER"

func _nearest_station(position: Vector3, desde: int) -> int:
	var mejor := desde
	var mejor_distancia := INF
	for offset in range(-40, 60):
		var indice := posmod(desde + offset, line.size())
		var distancia := Vector2(position.x - line[indice].x, position.z - line[indice].z).length_squared()
		if distancia < mejor_distancia:
			mejor_distancia = distancia
			mejor = indice
	return mejor

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	for i in 120:
		await physics_frame
	# Experimento de aislamiento: con `--sin-relieve` se apagan SÓLO los cuerpos de
	# los grupos que en Assetto Corsa son relieve de calzada, para comprobar si el
	# coche deja de detenerse. Es una prueba de diagnóstico, no un cambio del juego:
	# se hace aquí, en la sonda, y se informa en el registro.
	var args: Array = OS.get_cmdline_user_args()
	var relieve_como_antes: bool = args.has("--relieve-como-antes")
	if relieve_como_antes:
		var devueltos: Array = []
		for nodo in race.track_mesh.find_children("*", "StaticBody3D", true, false):
			var cuerpo := nodo as StaticBody3D
			if String(cuerpo.get_meta("ac_relief", "")) == "":
				continue
			for hijo in cuerpo.get_children():
				var forma := hijo as CollisionShape3D
				if forma != null:
					forma.position.y += RELIEF_SINK_M
			devueltos.append(String(cuerpo.name))
		print("RECTO CAUSA relieve devuelto a su altura original (+%.2f m): %s" % [RELIEF_SINK_M, str(devueltos)])
	if OS.get_cmdline_user_args().has("--sin-relieve"):
		var apagados: Array = []
		for nodo in race.track_mesh.find_children("*", "StaticBody3D", true, false):
			var cuerpo := nodo as StaticBody3D
			var etiqueta := (String(cuerpo.name) + " " + String(cuerpo.get_meta("ac_surface", ""))).to_upper()
			if "MARBLES" in etiqueta or "BUMP" in etiqueta or "GRILL" in etiqueta or "TRAV" in etiqueta or "CNCPTS" in etiqueta:
				cuerpo.collision_layer = 0
				apagados.append(String(cuerpo.name))
		print("RECTO AISLAMIENTO apagados=", apagados)
	var car: CharacterBody3D = race.car
	var ui: CanvasLayer = race.controls
	line = TrackScript.get_centerline()
	var gas_rect: Rect2 = ui._pedal_rects["throttle"]
	# A fondo: el pedal es analógico y su valor sale de `smoothstep(0, 0.8, y)`,
	# así que el máximo está al 20 % del alto del panel desde arriba.
	var gas_point := Vector2(gas_rect.position.x + gas_rect.size.x * 0.5,
		gas_rect.position.y + gas_rect.size.y * 0.2)
	var steer_point: Vector2 = ui._steer_center
	var station := 0
	var arranque := car.global_position
	var max_kph := 0.0
	var parado_en := -1
	var parado_station := 0
	var parado_desvio := 0.0
	var parado_posicion := Vector3.ZERO
	var parado_superficie := ""
	var parado_choques := ""
	var parado_avance := 0.0
	var total_ticks := int(SEGUNDOS * TICKS_POR_SEGUNDO)

	for tick in range(total_ticks):
		await physics_frame
		if ui._steer_touch_id < 0:
			ui._handle_touch_down(10, steer_point)
		if ui._throttle_touch_id < 0:
			ui._handle_touch_down(11, gas_point)
		ui._handle_touch_motion(10, steer_point)
		ui._handle_touch_motion(11, gas_point)
		ui._process(1.0 / float(TICKS_POR_SEGUNDO))

		station = _nearest_station(car.global_position, station)
		var tangent := (line[(station + 3) % line.size()] - line[(station - 3 + line.size()) % line.size()]).normalized()
		var lateral := Vector3(tangent.z, 0.0, -tangent.x).normalized()
		var desvio := (car.global_position - line[station]).dot(lateral)
		max_kph = maxf(max_kph, car.speed_kph)

		if tick % 60 == 0:
			print("RECTO t=%.2f estacion=%d desvio=%+.2f m %.1f km/h superficie=%s agarre=%.2f ruedas=%d suelo=%s gas=%.2f choques=%s" % [
				tick / float(TICKS_POR_SEGUNDO), station, desvio, car.speed_kph,
				car.ground_surface, car.surface_grip, car.wheel_contacts, str(car.is_on_floor()),
				car.throttle_input, _choques(car, true)])

		if car.speed_kph < PARADO and max_kph >= LANZADO and parado_en < 0:
			parado_en = tick
			parado_station = station
			parado_desvio = desvio
			parado_posicion = car.global_position
		parado_superficie = car.ground_surface
		parado_choques = _choques(car, false)
		if relieve_como_antes:
			print("RECTO CAUSA con el relieve original el choque es %s" % parado_choques)
			print("RECTO PARADA t=%.2f estacion=%d desvio=%+.2f m velocidad=%.1f km/h superficie=%s agarre=%.2f ruedas=%d suelo=%s posicion=%s" % [
				tick / float(TICKS_POR_SEGUNDO), station, desvio, car.speed_kph,
				car.ground_surface, car.surface_grip, car.wheel_contacts,
				str(car.is_on_floor()), str(car.global_position)])
			print("RECTO PARADA CHOQUES %s" % parado_choques)
			print("RECTO PARADA NORMAL suelo=(%.3f, %.3f, %.3f) velocidad=(%.2f, %.2f, %.2f)" % [
				car.ground_normal.x, car.ground_normal.y, car.ground_normal.z,
				car.velocity.x, car.velocity.y, car.velocity.z])
		if parado_en >= 0 and tick == parado_en + int(TRAS_PARAR_S * TICKS_POR_SEGUNDO):
			parado_avance = car.global_position.distance_to(parado_posicion)
			print("RECTO TRAS_PARAR %.1f s con el acelerador a fondo: avance=%.3f m velocidad=%.1f km/h estacion=%d desvio=%+.2f m gas=%.2f choques=%s" % [
				TRAS_PARAR_S, parado_avance, car.speed_kph, station, desvio,
				car.throttle_input, _choques(car, true)])
			break

	info("máximo alcanzado %.1f km/h; estación final %d; desvío final %+.2f m" % [
		max_kph, station, (car.global_position - line[station]).dot(
			Vector3((line[(station + 3) % line.size()] - line[(station - 3 + line.size()) % line.size()]).normalized().z, 0.0,
				-(line[(station + 3) % line.size()] - line[(station - 3 + line.size()) % line.size()]).normalized().x))])
	info("arranque=%s final=%s" % [str(arranque), str(car.global_position)])
	if parado_en >= 0:
		print("RECTO RESUMEN parada_en_estacion=%d desvio=%+.2f m superficie=%s avance_con_gas=%.3f m" % [
			parado_station, parado_desvio, parado_superficie, parado_avance])
	var calzada: Array = ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "CONCRETE", "PITS", "CARPET"]
	var en_calzada := parado_en >= 0 and calzada.has(parado_superficie)
	if relieve_como_antes:
		check(en_calzada, "con el relieve a su altura original el coche SÍ se clava sobre el asfalto (se detuvo en la estación %d, desvío %+.2f m, %.1f km/h alcanzados, superficie %s, avance con gas %.3f m)" % [
			parado_station, parado_desvio, max_kph, parado_superficie, parado_avance])
	else:
		check(not en_calzada, "sobre la calzada el coche no se queda clavado (se detuvo en la estación %d, desvío %+.2f m, superficie %s, avance con gas %.3f m)" % [
			parado_station, parado_desvio, parado_superficie, parado_avance])
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _choques(car: CharacterBody3D, resumido: bool) -> String:
	var texto := ""
	for c in car.get_slide_collision_count():
		var choque := car.get_slide_collision(c)
		var cuerpo := choque.get_collider() as Node
		var nombre := String(cuerpo.name).replace("barcelona_remastered_physics_obj__", "").replace("barcelona_remastered_physics_moto_obj__", "moto:")
		if resumido:
			texto += "%s(%s) " % [nombre, _group_of(cuerpo)]
		else:
			texto += "%s grupo=%s capa=%d punto=%s normal=(%.2f, %.2f, %.2f) " % [
				nombre, _group_of(cuerpo), cuerpo.collision_layer, str(choque.get_position()),
				choque.get_normal().x, choque.get_normal().y, choque.get_normal().z]
	if texto == "":
		return "(ninguno)"
	return texto
