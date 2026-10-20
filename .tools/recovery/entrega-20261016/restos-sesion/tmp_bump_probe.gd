extends SceneTree

# SONDA TEMPORAL: traza la suspensión al pasar sobre el resalto de prueba de 30 mm (el
# mismo que monta `suspension_probe`) para localizar por qué una rueda atraviesa el
# asfalto. No forma parte de la entrega; se borra al terminar el diagnóstico.

const TrackScript = preload("res://scripts/track_data.gd")

var race: Node3D
var car
var puntos: PackedVector3Array
var bump: StaticBody3D


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
	puntos = TrackScript.get_centerline()
	var linea := _punto(330)
	car.recover_to(linea + Vector3.UP * 0.3, _rumbo(330))
	car.velocity = Vector3.ZERO
	_demand(0.0)
	for i in 240:
		await physics_frame
	_make_bump()
	for i in 40:
		_demand(0.35)
		await physics_frame
	print("    t  cmb   est   alturas(fl,fr,rl,rr)                suelo  carg  road_slope_x  slope_x   rel_x    altura    asf_plano  compr   offsets(fl,fr,rl,rr)")
	for i in 300:
		_demand(0.35 if not _alcanzado(i) else 0.25)
		await physics_frame
		var s = car.suspension
		if i % 3 != 0:
			continue
		var h := "%.3f %.3f %.3f %.3f" % [s.road[0], s.road[1], s.road[2], s.road[3]]
		var off := "%.1f %.1f %.1f %.1f" % [s.offset[0] * 1000.0, s.offset[1] * 1000.0, s.offset[2] * 1000.0, s.offset[3] * 1000.0]
		print("%5.2f %3d %5d  %s  %s %5d  %+.4f  %+.4f  %+.4f  %8.3f  %8.3f  %+6.1f  %s" % [
			i / 120.0, car.wheel_contacts, _nearest(),
			h, str(s.grounded), s.loaded_contacts, s.road_slope_x, s.slope_x, s.slope_x - s.road_slope_x,
			s.height, s.road_height, s.compression * 1000.0, off])
	bump.queue_free()
	await process_frame
	quit(0)


func _alcanzado(i: int) -> bool:
	return i > 150


func _demand(throttle: float) -> void:
	car.set_meta("touch_throttle", throttle)
	car.set_meta("touch_brake", 0.0)
	car.set_meta("touch_steer", 0.0)


func _punto(index: int) -> Vector3:
	return puntos[posmod(index, puntos.size())]


func _rumbo(index: int) -> float:
	var a := puntos[posmod(index - 4, puntos.size())]
	var b := puntos[posmod(index + 4, puntos.size())]
	return atan2(-(b.x - a.x), -(b.z - a.z))


func _nearest() -> int:
	var best := 0
	var dist := INF
	for i in puntos.size():
		var d := Vector2(car.global_position.x - puntos[i].x, car.global_position.z - puntos[i].z).length_squared()
		if d < dist:
			dist = d
			best = i
	return best


func _make_bump() -> void:
	var left: Vector3 = car.global_transform * Vector3(-0.93, 0.0, 0.0)
	var ground := _ground_below(left)
	var forward: Vector3 = -car.global_basis.z
	bump = StaticBody3D.new()
	bump.name = "Resalto de prueba 30 mm"
	bump.collision_layer = 1
	bump.collision_mask = 0
	bump.set_meta("ac_surface", "ASPHALT")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.34, 0.06, 4.0)
	shape.shape = box
	bump.add_child(shape)
	race.add_child(bump)
	bump.global_position = Vector3(left.x, ground, left.z) + forward * 12.0
	bump.global_rotation = Vector3(0.0, car.global_rotation.y, 0.0)
	print("resalto: suelo=%.3f pos=%s" % [ground, bump.global_position])


func _ground_below(point: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.5, point - Vector3.UP * 3.0, 1)
	var hit: Dictionary = root.world_3d.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return -999.0
	return (hit["position"] as Vector3).y
