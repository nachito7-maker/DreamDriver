extends SceneTree

# Comprueba que el McLaren monta las curvas del `data.acd` (par, turbos, aero con EBD y
# neumático) y mide con ellas la punta real en una losa plana y sin muros.
#
# Uso: Godot --headless --path . --script res://.tools/recovery/mclaren-20261020/mclaren_curves_probe.gd

const TrackScript = preload("res://scripts/track_data.gd")
const PAD_HEIGHT := 1500.0
const PAD_HALF := 30000.0

var race
var car
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	print("CURVAS ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func _demand(throttle: float, brake: float, steer: float) -> void:
	car.set_meta("touch_throttle", throttle)
	car.set_meta("touch_brake", brake)
	car.set_meta("touch_steer", steer)

func _build_pad() -> void:
	var pad := StaticBody3D.new()
	pad.name = "TRM-BRC banco de curvas"
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
	if not TrackScript.select_vehicle("mclaren"):
		push_error("No se pudo seleccionar el McLaren")
		quit(2)
		return
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	for _i in 120:
		await physics_frame
	car = race.car
	race.controls.set_process(false)
	_build_pad()
	car.recover_to(Vector3(0.0, PAD_HEIGHT + 0.4, 0.0), 0.0)
	for _i in 90:
		await physics_frame

	# 1. Las tablas están montadas y no son las del coche anterior.
	_check(car.engine_torque_curve.size() == 31, "curva de par montada con %d puntos (power.lut 0..15000 rpm cada 500)" % car.engine_torque_curve.size())
	_check(car.engine_boost_curve.size() == 27, "curva de sobrepresión montada con %d puntos (turbo*.lut 0..13000 rpm)" % car.engine_boost_curve.size())
	_check(is_equal_approx(car.engine_boost_count, 2.0), "dos turbos sumados (engine_boost_count=%.1f)" % car.engine_boost_count)
	_check(car.front_tyre_grip_curve.size() == 14 and car.rear_tyre_grip_curve.size() == 14, "curvas DY_CURVE montadas en los dos ejes")
	_check(is_equal_approx(car.aero_downforce_n_at_100ms_off_throttle, 19493.0), "aero con EBD montada (gas=0: %.0f N)" % car.aero_downforce_n_at_100ms_off_throttle)

	# 2. Par en el cigüeñal en los regímenes declarados por el mod.
	var torque_cases := [[5000.0, 211.2], [10000.0, 385.8], [12500.0, 349.9], [13000.0, 332.5]]
	for c in torque_cases:
		var measured: float = car._engine_torque_nm(c[0])
		_check(absf(measured - float(c[1])) <= 0.6, "par a %.0f rpm = %.2f Nm (base × (1 + 2·boost) = %.1f)" % [c[0], measured, c[1]])

	# 3. Fuerza en rueda por marcha a par máximo (sin recortes de agarre).
	var ratios: PackedFloat32Array = car.gears
	for g in range(1, ratios.size()):
		var force: float = car._engine_torque_nm(10000.0) * ratios[g] * car.final_drive_ratio * car.drivetrain_efficiency / car.wheel_radius_m
		print("CURVAS MARCHA %d relacion=%.3f par=%.1f Nm fuerza=%.0f N tope=%.0f N" % [
			g, ratios[g], car._engine_torque_nm(10000.0), force, car.max_engine_force_n])

	# 4. Punta real: 120 s a fondo en la losa.
	var start: Vector3 = car.global_position
	var last_report := 0.0
	var max_kph := 0.0
	for i in 10800:  # 90 s a 120 Hz
		_demand(1.0, 0.0, 0.0)
		await physics_frame
		max_kph = maxf(max_kph, car.speed_kph)
		var t := i / 120.0
		if t - last_report >= 10.0:
			last_report = t
			print("CURVAS t=%5.1f marcha=%d rpm=%5.0f par=%6.1f Nm fuerza=%6.0f N %.1f km/h aero=%.0f N" % [
				t, car.gear, car.engine_rpm, car.debug_engine_torque_nm, car.debug_engine_force_n,
				car.speed_kph, car.downforce_n])
	print("CURVAS PUNTA %.1f km/h en %d m" % [max_kph, int((car.global_position - start).length())])
	_check(max_kph > 250.0, "punta %.1f km/h (mínimo 250, el mismo umbral que la sonda de físicas)" % max_kph)
	_check(car.gear == car.gears.size() - 1, "la punta se hace en la última marcha (marcha %d)" % car.gear)

	print("CURVAS RESUMEN fallos=%d" % failures)
	race.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
