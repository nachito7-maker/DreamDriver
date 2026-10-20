extends SceneTree

# SONDA TEMPORAL: traza fotograma a fotograma el coche sobre una losa inclinada para
# localizar de dónde sale la aceleración que no está en el balance de fuerzas. No forma
# parte de la entrega; se borra al terminar el diagnóstico.

const TICK := 1.0 / 120.0
const PAD_Y := 1500.0
const LADO := 2000.0
const V0 := 60.0

var race: Node3D
var car


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	for i in 120:
		await physics_frame
	car = race.car
	race.controls.set_process(false)
	var pad := _losa(3.0)
	for i in 4:
		await physics_frame
	var suelo := _suelo(0.0, 0.0)
	car.recover_to(Vector3(0.0, suelo + 0.4, 0.0), 0.0)
	car.velocity = Vector3.ZERO
	_demand(0.0)
	for i in 30:
		await physics_frame
	car.velocity = -car.global_transform.basis.z * V0
	for i in 30:
		_demand(1.0)
		await physics_frame
	print("     t   km/h    speed   |v|      vx     vy      vz      pos_y  plano   hueco  pie  choques  par     aire   rod   pide   gana   dy")
	for i in 120:
		_demand(1.0)
		var antes: float = car.speed_mps
		var pos_antes: Vector3 = car.global_position
		await physics_frame
		if i % 5 != 0:
			continue
		var v: Vector3 = car.velocity
		var plano: float = car.suspension.road_height if car.suspension != null else 0.0
		var caja: CollisionShape3D = null
		for child in car.get_children():
			if child is CollisionShape3D:
				caja = child
		var hueco := 0.0
		if caja != null:
			var abajo: Vector3 = caja.global_position - caja.global_transform.basis.y * 0.275
			hueco = abajo.y - plano
		var choques := ""
		for c in car.get_slide_collision_count():
			choques += String(car.get_slide_collision(c).get_collider().name).substr(0, 12) + ","
		print("%6.2f %6.1f %8.3f %8.3f %7.3f %7.3f %7.3f %8.3f %8.3f %6.3f %s %-14s %8.0f %8.0f %6.0f %8.2f %8.2f %+7.3f" % [
			i * TICK, car.speed_kph, car.speed_mps, v.length(), v.x, v.y, v.z,
			car.global_position.y, plano, hueco, str(car.is_on_floor()), choques,
			car.debug_engine_force_n, car.debug_drag_force_n, car.debug_roll_force_n,
			car.debug_longitudinal_accel, (car.speed_mps - antes) / TICK,
			car.global_position.y - pos_antes.y])
	pad.queue_free()
	await process_frame
	quit(0)


func _demand(throttle: float) -> void:
	car.set_meta("touch_throttle", throttle)
	car.set_meta("touch_brake", 0.0)
	car.set_meta("touch_steer", 0.0)


func _losa(grados: float) -> StaticBody3D:
	var pad := StaticBody3D.new()
	pad.name = "TRM-BRC banco"
	pad.collision_layer = 1
	pad.collision_mask = 0
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(LADO * 2.0, 40.0, LADO * 2.0)
	collision.shape = box
	pad.add_child(collision)
	race.add_child(pad)
	pad.rotation.x = deg_to_rad(grados)
	pad.global_position = Vector3(0.0, PAD_Y, 0.0) - pad.global_transform.basis.y * 20.0
	return pad


func _suelo(x: float, z: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, PAD_Y + 60.0, z), Vector3(x, PAD_Y - 60.0, z), 1)
	var hit: Dictionary = car.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return NAN
	return (hit["position"] as Vector3).y
