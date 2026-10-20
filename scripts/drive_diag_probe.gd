extends SceneTree

# Diagnóstico de la vuelta: qué entrada recibe el coche, a qué velocidad va y
# qué superficie pisa, medio segundo a medio segundo durante los primeros 40 s.
# Sirve para separar un fallo del coche de un fallo de la cadena de toques.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	for i in 120:
		await physics_frame
	var car: CharacterBody3D = race.car
	var ui: CanvasLayer = race.controls
	var line: PackedVector3Array = load("res://scripts/track_data.gd").get_centerline()
	var nearest := 0
	var steer_point: Vector2 = ui._steer_center
	var tr: Rect2 = ui._pedal_rects["throttle"]
	var br: Rect2 = ui._pedal_rects["brake"]
	var throttle_point := Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5, tr.position.y + tr.size.y * 0.05)
	var brake_point := Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5, br.end.y - 1.0)
	var steer_command := 0.0
	print("DIAG lienzo=", ui._viewport_size, " mando=", steer_point, " gas=", tr, " freno=", br)
	_press(ui, steer_point, throttle_point, brake_point)
	for step in 4800:
		await physics_frame
		_press(ui, steer_point, throttle_point, brake_point)
		var best := INF
		for offset in range(-12, 30):
			var idx := posmod(nearest + offset, line.size())
			var d := Vector2(car.global_position.x - line[idx].x, car.global_position.z - line[idx].z).length_squared()
			if d < best:
				best = d
				nearest = idx
		# Control Stanley: corrección suave por desviación lateral + error de rumbo,
		# con límite de mando y de velocidad de cambio. Con un coche que gira 1,1 g
		# un perseguidor puro se desestabiliza; éste es un lazo lento y estable.
		var tangent := (line[(nearest + 3) % line.size()] - line[(nearest - 3 + line.size()) % line.size()]).normalized()
		var lateral_axis := Vector3(tangent.z, 0.0, -tangent.x).normalized()
		var left_error := (car.global_position - line[nearest]).dot(lateral_axis)
		var forward_car := -car.global_basis.z
		var heading_term := forward_car.cross(tangent).y
		var demand := clampf(0.12 * left_error - 1.2 * heading_term, -0.35, 0.35)
		steer_command = clampf(demand, steer_command - 0.03, steer_command + 0.03)
		var raw: float = ui.steering_travel_for(steer_command)
		ui._handle_touch_motion(10, ui._steer_center + Vector2(raw * ui._steering_ring.size.x * 0.46, 0))
		# Velocidad fija y cómoda: 12 m/s (43 km/h) exige 0,3 g en la curva más
		# cerrada del trazado, así que el coche la sostiene sin acercarse al límite.
		var target_speed := 12.0
		var speed_error: float = target_speed - car.speed_mps
		var throttle := clampf(speed_error * 0.18 + 0.05, 0.0, 1.0)
		var brake := clampf(-speed_error * 0.12, 0.0, 0.65)
		var gas_point := Vector2(ui._throttle_pedal.position.x + ui._throttle_pedal.size.x * 0.5,
			pedal_point(ui, tr, maxf(0.45, throttle)).y)
		var brake_command_point := Vector2(ui._brake_pedal.position.x + ui._brake_pedal.size.x * 0.5,
			pedal_point(ui, br, brake).y)
		if throttle <= 0.03:
			gas_point.y = ui._throttle_pedal.position.y + ui._throttle_pedal.size.y + 4.0
		if brake <= 0.03:
			brake_command_point.y = ui._brake_pedal.position.y + ui._brake_pedal.size.y + 4.0
		ui._handle_touch_motion(11, gas_point)
		ui._handle_touch_motion(12, brake_command_point)
		ui._process(1.0 / 120.0)
		if step % 60 == 0:
			var hits := ""
			for c in car.get_slide_collision_count():
				var hit := car.get_slide_collision(c)
				hits += "%s(n=%.2f,%.2f,%.2f) " % [String(hit.get_collider().name).replace("barcelona_remastered_physics_obj__", ""),
					hit.get_normal().x, hit.get_normal().y, hit.get_normal().z]
			print("DIAG t=%.1f idx=%d error=%.1f vel=%.1f km/h gas=%.2f freno=%.2f direccion=%.2f mando=%.2f superficie=%s agarre=%.2f contacts=%d suelo=%s objetivo=%.1f m/s demanda=%.2f angulo=%.3f accel=%.2f marcha=%d normal=(%.2f,%.2f,%.2f) choques=%s" % [
				step / 120.0, nearest, sqrt(best), car.speed_kph, car.throttle_input, car.brake_input,
				car.steering_input, raw, car.ground_surface, car.surface_grip, car.wheel_contacts, str(car.is_on_floor()),
				target_speed, demand, car.steering_angle, car.acceleration_longitudinal, car.gear,
				car.ground_normal.x, car.ground_normal.y, car.ground_normal.z, hits])
			print("DIAG GEO t=%.1f desvio=%+.2f m rumbo=%.1f° rumbo_linea=%.1f° mando=%.2f paso=%d" % [
				step / 120.0, left_error, rad_to_deg(car.rotation.y), rad_to_deg(atan2(-tangent.x, -tangent.z)),
				steer_command, nearest])
	race.queue_free()
	await process_frame
	quit(0)

func _press(ui: CanvasLayer, steer: Vector2, throttle: Vector2, brake: Vector2) -> void:
	if ui._steer_touch_id < 0:
		ui._handle_touch_down(10, steer)
	if ui._throttle_touch_id < 0:
		ui._handle_touch_down(11, throttle)
	if ui._brake_touch_id < 0:
		ui._handle_touch_down(12, brake)

# El recorrido del dedo para pedir una demanda sale de la curva DECLARADA del pedal
# (`touch_controls.pedal_travel_for`), no de una copia de la rampa (la copia con el 0,8 de la
# rampa vieja pedía casi el doble de gas del que la sonda creía pedir).
func pedal_point(ui: CanvasLayer, rect: Rect2, demand: float) -> Vector2:
	return rect.position + rect.size * Vector2(0.5, 1.0 - ui.pedal_travel_for(demand))
