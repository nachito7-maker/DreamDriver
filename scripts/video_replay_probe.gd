extends SceneTree

# Reproduce la conducción de cada vídeo dentro del juego.
#
# La velocidad medida en el vídeo (barra del HUD, 60 veces por segundo) es la
# consigna que persigue un controlador que pisa el pedal de verdad —el mismo
# camino de entrada que usa el jugador— y sin tocar la dirección, que es lo que
# hacen los dos vídeos del encargo. Al final queda, para cada vídeo, si el coche se
# clavó o no, dónde, sobre qué superficie y contra qué cuerpo.
#
# Criterio de aprobado: sobre la CALZADA el coche no puede quedarse clavado. Salirse
# por no girar y detenerse fuera de la calzada es conducción, no un fallo de
# colisiones, y se informa con el cuerpo que lo paró.
#
# Uso:  Godot --headless --path . --script res://scripts/video_replay_probe.gd -- 9880 9879

const Traces = preload("res://scripts/video_speed_traces.gd")
const TrackScript = preload("res://scripts/track_data.gd")

const TICKS := 120
const CALZADA := ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "CONCRETE", "PITS", "CARPET"]
const PARA_KMH := 20.0
const CORRIA_KMH := 100.0
const VIGILA_KMH := 60.0
const TRAS_PARAR_S := 3.0

var failures := 0
var line: PackedVector3Array

func check(condition: bool, message: String) -> void:
	print("REPLAY ", "PASS " if condition else "FAIL ", message)
	if not condition:
		failures += 1

func _initialize() -> void:
	call_deferred("_run")

func _group_of(body: Node) -> String:
	if body == null:
		return "NONE"
	var label := (String(body.name) + " " + String(body.get_meta("ac_surface", ""))).to_upper()
	for key in (CALZADA + ["GRAVEL", "SAND", "GRASS", "GREEN", "OUT", "GRILL", "WALL",
			"MARBLES", "BUMP", "CNCPTS", "TRAV"]):
		if key in label:
			return key
	return "OTHER"

func _choques(car: CharacterBody3D) -> String:
	var texto := ""
	for c in car.get_slide_collision_count():
		var choque := car.get_slide_collision(c)
		var cuerpo := choque.get_collider() as Node
		texto += "%s(%s) " % [String(cuerpo.name).replace("barcelona_remastered_physics_obj__", ""), _group_of(cuerpo)]
	if texto == "":
		return "(ninguno)"
	return texto

func _run() -> void:
	var videos: Array = OS.get_cmdline_user_args()
	if videos.is_empty():
		videos = ["9880", "9879"]
	for video in videos:
		await _reproducir(String(video))
	quit(0 if failures == 0 else 1)

func _reproducir(video: String) -> void:
	var datos: Dictionary = Traces.TRAZAS[video]
	var consigna: Array = datos["kmh"]
	var duracion: float = datos["duracion_s"]
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	for i in 120:
		await physics_frame
	var car: CharacterBody3D = race.car
	var ui: CanvasLayer = race.controls
	line = TrackScript.get_centerline()
	var gas_rect: Rect2 = ui._pedal_rects["throttle"]
	var freno_rect: Rect2 = ui._pedal_rects["brake"]
	var steer_point: Vector2 = ui._steer_center
	var station := 0
	var max_kph := 0.0
	var parada_en := -1
	var parada_station := 0
	var parada_desvio := 0.0
	var parada_superficie := ""
	var parada_choques := ""
	var parada_posicion := Vector3.ZERO
	var avance := 0.0
	var total := int(duracion * TICKS)
	print("REPLAY --- %s: %d fotogramas de consigna, %.1f s, sucesos del vídeo %s" % [
		video, consigna.size(), duracion, str(datos["sucesos"])])
	for tick in range(total):
		await physics_frame
		if ui._steer_touch_id < 0:
			ui._handle_touch_down(10, steer_point)
		if ui._throttle_touch_id < 0:
			ui._handle_touch_down(11, Vector2(gas_rect.position.x + gas_rect.size.x * 0.5, gas_rect.position.y + gas_rect.size.y * 0.2))
		if ui._brake_touch_id < 0:
			ui._handle_touch_down(12, Vector2(freno_rect.position.x + freno_rect.size.x * 0.5, freno_rect.end.y - 1.0))
		ui._handle_touch_motion(10, steer_point)
		var t := tick / float(TICKS)
		var indice := clampi(int(t * float(datos["fps"])), 0, consigna.size() - 1)
		var objetivo: float = float(consigna[indice])
		var error: float = objetivo / 3.6 - car.speed_mps
		var acelerador := clampf(error * 0.18 + 0.05, 0.0, 1.0)
		var freno := clampf(-error * 0.12, 0.0, 0.65)
		if acelerador > 0.03:
			ui._handle_touch_motion(11, Vector2(gas_rect.position.x + gas_rect.size.x * 0.5,
				gas_rect.position.y + gas_rect.size.y * (1.0 - clampf(acelerador, 0.05, 1.0) * 0.8)))
		else:
			ui._handle_touch_motion(11, Vector2(gas_rect.position.x + gas_rect.size.x * 0.5, gas_rect.end.y + 4.0))
		if freno > 0.03:
			ui._handle_touch_motion(12, Vector2(freno_rect.position.x + freno_rect.size.x * 0.5,
				freno_rect.position.y + freno_rect.size.y * (1.0 - clampf(freno, 0.05, 0.8))))
		else:
			ui._handle_touch_motion(12, Vector2(freno_rect.position.x + freno_rect.size.x * 0.5, freno_rect.end.y + 4.0))
		ui._process(1.0 / float(TICKS))

		station = _nearest(car.global_position, station)
		var tangent := (line[(station + 3) % line.size()] - line[(station - 3 + line.size()) % line.size()]).normalized()
		var desvio := (car.global_position - line[station]).dot(Vector3(tangent.z, 0.0, -tangent.x).normalized())
		max_kph = maxf(max_kph, car.speed_kph)
		if tick % 60 == 0:
			print("REPLAY t=%.1f consigna=%.0f real=%.1f estacion=%d desvio=%+.2f m superficie=%s ruedas=%d direccion=%.3f mando=%.3f gas=%.2f freno=%.2f choques=%s" % [
				t, objetivo, car.speed_kph, station, desvio, car.ground_surface,
				car.wheel_contacts, car.steering_input, ui._steer_value, car.throttle_input,
				car.brake_input, _choques(car)])
		if parada_en < 0 and car.speed_kph < PARA_KMH and max_kph >= CORRIA_KMH and objetivo >= VIGILA_KMH:
			parada_en = tick
			parada_station = station
			parada_desvio = desvio
			parada_superficie = car.ground_surface
			parada_choques = _choques(car)
			parada_posicion = car.global_position
			print("REPLAY PARADA t=%.2f estacion=%d desvio=%+.2f m real=%.1f km/h consigna=%.0f superficie=%s agarre=%.2f ruedas=%d posicion=%s choques=%s" % [
				t, station, desvio, car.speed_kph, objetivo, car.ground_surface,
				car.surface_grip, car.wheel_contacts, str(car.global_position), parada_choques])
		if parada_en >= 0 and tick == parada_en + int(TRAS_PARAR_S * TICKS):
			avance = car.global_position.distance_to(parada_posicion)
			print("REPLAY TRAS_PARAR %.1f s pisando el acelerador: avance=%.3f m real=%.1f km/h estacion=%d desvio=%+.2f m superficie=%s choques=%s" % [
				TRAS_PARAR_S, avance, car.speed_kph, station, desvio, car.ground_surface, _choques(car)])
			break
		if int(t) >= 1 and int(t) % 5 == 0 and tick % 60 == 0:
			pass
	print("REPLAY RESUMEN %s: maximo=%.1f km/h estacion_final=%d consigna_final=%.0f km/h parada=%s" % [
		video, max_kph, station, float(consigna[consigna.size() - 1]),
		"no" if parada_en < 0 else "estacion %d desvio %+.2f m superficie %s avance %.3f m" % [
			parada_station, parada_desvio, parada_superficie, avance]])
	if parada_en >= 0:
		check(not CALZADA.has(parada_superficie),
			"%s: sobre la calzada el coche no se clava (se paró en la estación %d, desvío %+.2f m, superficie %s, choques %s)" % [
				video, parada_station, parada_desvio, parada_superficie, parada_choques])
	race.queue_free()
	await process_frame

func _nearest(position: Vector3, desde: int) -> int:
	var mejor := desde
	var mejor_distancia := INF
	for offset in range(-80, 120):
		var indice := posmod(desde + offset, line.size())
		var distancia := Vector2(position.x - line[indice].x, position.z - line[indice].z).length_squared()
		if distancia < mejor_distancia:
			mejor_distancia = distancia
			mejor = indice
	return mejor
