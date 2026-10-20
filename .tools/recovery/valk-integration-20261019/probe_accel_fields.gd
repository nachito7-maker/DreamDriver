extends SceneTree

# Desglose de la cadena de fuerza longitudinal al acelerar a fondo desde parado.
# Sirve para saber si la lentitud de salida viene del motor, del recorte de
# pedal, del agarre o de la integración del movimiento.
# Uso: Godot --headless --path . --script .tools/recovery/valk-integration-20261019/probe_accel_fields.gd -- valkyrie

const TrackScript = preload("res://scripts/track_data.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var vehicle := String(args[0]) if not args.is_empty() else "valkyrie"
	TrackScript.selected_vehicle = vehicle
	TrackScript.selected_track = TrackScript.BARCELONA
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 180:
		await physics_frame
	var car: CharacterBody3D = race.car
	print("== %s masa=%.0f tope_fuerza=%.0f kW=%.0f lanzamiento=%.2f" % [
		vehicle, car.mass_kg, car.max_engine_force_n, car.engine_peak_power_w / 1000.0, car.launch_throttle_factor])
	Input.action_press("throttle")
	Input.action_release("brake")
	for i in 480:
		await physics_frame
		if i % 30 == 29:
			print("  t=%.1fs kmh=%.1f pedal=%.2f recorte=%.2f fuerza_motor=%.0f freno=%.0f arrastre=%.0f rodadura=%.0f pendiente=%.0f total=%.0f a_pedida=%.2f a_medida=%.2f" % [
				(i + 1) / 120.0, car.speed_kph, car.throttle_input, car.debug_actual_throttle,
				car.debug_engine_force_n, car.debug_brake_force_n, car.debug_drag_force_n, car.debug_roll_force_n,
				car.debug_longitudinal_force_n - car.debug_engine_force_n + car.debug_brake_force_n + car.debug_drag_force_n + car.debug_roll_force_n,
				car.debug_longitudinal_force_n, car.debug_longitudinal_accel, car.acceleration_longitudinal])
	Input.action_release("throttle")
	race.queue_free()
	for i in 20:
		await process_frame
	quit()
