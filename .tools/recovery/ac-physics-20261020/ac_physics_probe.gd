extends SceneTree

# Sonda de validación de la receta de físicas derivada de los INI/LUT de AC.
# Mide, sobre una losa plana de asfalto y sin muros, aceleración, punta y frenada
# de un coche concreto. No escribe artefactos ni toca la selección guardada.
#
# Uso: Godot --headless --path . --script res://.tools/recovery/ac-physics-20261020/ac_physics_probe.gd -- <vehicle_id>

const TrackScript = preload("res://scripts/track_data.gd")
const PAD_HEIGHT := 1500.0
const PAD_HALF := 4000.0

var race
var car
var ui
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	print("PHYS ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func _demand(throttle: float, brake: float, steer: float) -> void:
	car.set_meta("touch_throttle", throttle)
	car.set_meta("touch_brake", brake)
	car.set_meta("touch_steer", steer)

func _build_pad() -> void:
	var pad := StaticBody3D.new()
	pad.name = "TRM-BRC banco de físicas"
	pad.collision_layer = 1
	pad.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(PAD_HALF * 2.0, 40.0, PAD_HALF * 2.0)
	shape.shape = box
	pad.add_child(shape)
	pad.position = Vector3(0.0, PAD_HEIGHT - 20.0, 0.0)
	race.add_child(pad)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var vehicle := String(args[0]) if not args.is_empty() else TrackScript.get_selected_vehicle_id()
	if not TrackScript.select_vehicle(vehicle):
		push_error("Unknown vehicle: " + vehicle)
		quit(2)
		return
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	for _i in 120:
		await physics_frame
	car = race.car
	ui = race.controls
	ui.set_process(false)
	_build_pad()
	car.recover_to(Vector3(0.0, PAD_HEIGHT + 0.4, 0.0), 0.0)
	for _i in 90:
		await physics_frame

	var config: Dictionary = TrackScript.get_vehicle_physics(vehicle)
	print("PHYS INFO vehicle=%s mass=%.1f/%.1f power=%.0f/%.0f aero=%.0f/%.0f drag=%.3f/%.3f wheelbase=%.3f/%.3f gears=%d" % [
		vehicle, car.mass_kg, float(config["mass_kg"]), car.engine_peak_power_w, float(config["engine_peak_power_w"]),
		car.aero_downforce_n_at_100ms, float(config["aero_downforce_n_at_100ms"]),
		car.drag_area_m2, float(config["drag_area_m2"]), car.wheelbase_m, float(config["wheelbase_m"]), car.gears.size()])
	_check(is_equal_approx(car.mass_kg, float(config["mass_kg"])), "la masa montada coincide con la receta")
	_check(is_equal_approx(car.engine_peak_power_w, float(config["engine_peak_power_w"])), "la potencia montada coincide con la receta")

	var start: Vector3 = car.global_position
	var t100 := -1.0
	var t200 := -1.0
	var max_kph := 0.0
	var max_downforce := 0.0
	var steps := 0
	for i in 1800:  # 15 s a 120 Hz
		_demand(1.0, 0.0, 0.0)
		await physics_frame
		steps += 1
		if t100 < 0.0 and car.speed_kph >= 100.0:
			t100 = steps / 120.0
		if t200 < 0.0 and car.speed_kph >= 200.0:
			t200 = steps / 120.0
		max_kph = maxf(max_kph, car.speed_kph)
		max_downforce = maxf(max_downforce, car.downforce_n)
	var accel_distance: float = (car.global_position - start).length()
	print("PHYS ACCEL vehicle=%s t100=%.2f t200=%.2f vmax=%.1f km/h distance=%.1f m downforce_max=%.0f N" % [
		vehicle, t100, t200, max_kph, accel_distance, max_downforce])
	_check(t100 > 0.0 and t100 < 6.0, "0-100 km/h en %.2f s (tope 6 s)" % t100)
	_check(max_kph > 250.0, "velocidad máxima %.1f km/h (mínimo 250)" % max_kph)

	var brake_start: Vector3 = car.global_position
	var brake_speed: float = car.speed_mps
	var max_decel := 0.0
	var stop_steps := 0
	var stopped := false
	for i in 900:  # 7,5 s de frenada
		_demand(0.0, 1.0, 0.0)
		await physics_frame
		stop_steps += 1
		max_decel = minf(max_decel, car.acceleration_longitudinal)
		if car.speed_kph < 5.0:
			stopped = true
			break
	var brake_distance: float = (car.global_position - brake_start).length()
	print("PHYS BRAKE vehicle=%s from=%.1f km/h decel_max=%.2f m/s2 (%.2f g) distance=%.1f m stopped=%s" % [
		vehicle, brake_speed * 3.6, -max_decel, -max_decel / 9.81, brake_distance, str(stopped)])
	_check(max_decel < -15.0, "frenada máxima %.2f m/s2 (mínimo 15)" % -max_decel)
	_check(stopped, "el coche se detuvo en la losa")

	for target_kph in [120.0, 240.0]:
		car.recover_to(Vector3(0.0, PAD_HEIGHT + 0.4, 0.0), 0.0)
		for _i in 60:
			await physics_frame
		var target: float = target_kph / 3.6
		var reached := false
		for _i in 1800:
			_demand(1.0, 0.0, 0.0)
			await physics_frame
			if car.speed_mps >= target:
				reached = true
				break
		var best_g := 0.0
		var steer_sum := 0.0
		var samples := 0
		for _i in 360:  # 3 s de curva sostenida
			var error: float = target - car.speed_mps
			var throttle := clampf(error * 0.4 + 0.2, 0.0, 1.0)
			var brake := clampf(-error * 0.3, 0.0, 1.0)
			_demand(throttle, brake, 0.7)
			await physics_frame
			best_g = maxf(best_g, absf(car.acceleration_lateral) / 9.81)
			steer_sum += absf(car.steering_angle)
			samples += 1
		print("PHYS CORNER vehicle=%s target=%.0f km/h speed=%.1f km/h g_max=%.2f g steer=%.2f deg contacts=%d reached=%s" % [
			vehicle, target_kph, car.speed_kph, best_g, rad_to_deg(steer_sum / maxf(samples, 1)), car.wheel_contacts, str(reached)])
		_check(reached, "alcanzó %.0f km/h en el banco" % target_kph)
		_check(best_g > 0.8, "sostiene %.2f g a %.0f km/h" % [best_g, target_kph])

	print("PHYS RESUMEN vehicle=%s fallos=%d" % [vehicle, failures])
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
