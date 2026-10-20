extends SceneTree

# Compara, sobre la escena de carrera real, el Red Bull y el McLaren:
#   * altura del cuerpo y del modelo respecto al asfalto (levitación)
#   * contacto de las cuatro ruedas y radio/batalla medidas
#   * aceleración a fondo en recta (5 s)
#   * giro con mando a tope a 100 km/h sostenidos (radio real)
#
# Uso: Godot --headless --path . --script .tools/recovery/rb22-fix-20261019/probe_compare.gd

const TrackScript = preload("res://scripts/track_data.gd")
const WheelNames := ["wheel_fl", "wheel_fr", "wheel_rl", "wheel_rr"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	TrackScript.selected_track = TrackScript.BARCELONA
	for id in ["rb22_2026", "mclaren", "valkyrie"]:
		await _measure(id)
	quit()

func _road_under(car: Node3D, at: Vector3) -> float:
	var space := car.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 4.0, at - Vector3.UP * 6.0, 1)
	q.exclude = [car.get_rid()]
	var hit := space.intersect_ray(q)
	return float(hit.get("position", Vector3(0, NAN, 0)).y) if not hit.is_empty() else NAN

func _wheel_bottom(car: Node3D, wheel: Node3D) -> float:
	var bottom := INF
	var meshes: Array[Node] = []
	if wheel is MeshInstance3D:
		meshes.append(wheel)
	meshes.append_array(wheel.find_children("*", "MeshInstance3D", true, false))
	for node in meshes:
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		var box: AABB = mi.global_transform * mi.mesh.get_aabb()
		bottom = minf(bottom, box.position.y)
	return bottom

func _measure(vehicle_id: String) -> void:
	TrackScript.selected_vehicle = vehicle_id
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 240:
		await physics_frame
	var car: CharacterBody3D = race.car
	var suspension: RefCounted = car.suspension
	print("== %s ==" % vehicle_id)
	print("  batalla=%.3f vias=%.3f/%.3f masa=%.0f" % [suspension.wheelbase_m, suspension.track_front_m, suspension.track_rear_m, car.mass_kg])
	print("  model_basis=", car.model_root.basis, " corners=", suspension.corner)
	print("  embedded bodies=", car.model_root.find_children("*", "CollisionObject3D", true, false).map(func(n): return str(n.get_path())))
	for i in car._suspension_wheels.size():
		var w: Node3D = car._suspension_wheels[i]
		var road := _road_under(car, w.global_position)
		print("  %s pos=%s pivot_y=%.3f fondo=%.3f asfalto=%.3f aire=%+.3f is_front=%d grounded=%d load=%.0fN" % [
			w.name, str(w.global_position.snapped(Vector3(0.01, 0.01, 0.01))),
			car._suspension_rest_y[i], _wheel_bottom(car, w), road,
			_wheel_bottom(car, w) - road if not is_nan(road) else NAN,
			suspension.is_front[i], suspension.grounded[i], suspension.load[i]])
	print("  cuerpo_y=%.3f plano=%.3f modelo_y=%.3f (modelo-plano=%+.3f) suelo=%.3f contactos=%d" % [
		car.global_position.y, suspension.height, car.model_root.global_position.y,
		car.model_root.global_position.y - suspension.height, suspension.road_height, car.wheel_contacts])
	var lowest := INF
	for node in car.model_root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		lowest = minf(lowest, (mi.global_transform * mi.mesh.get_aabb()).position.y)
	print("  punto_mas_bajo_modelo=%.3f (sobre asfalto %+.3f)" % [lowest, lowest - suspension.road_height])

	# Aceleración en recta, 5 s a fondo desde parado.
	Input.action_press("throttle")
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	Input.action_release("brake")
	var start := car.global_position
	var samples := []
	for i in 600:
		await physics_frame
		if i % 120 == 119:
			samples.append("%.0f" % car.speed_kph)
			for w in car._suspension_wheels:
				print("  moving ", w.name, " aire=", _wheel_bottom(car, w) - _road_under(car, w.global_position))
	var travelled := Vector2(car.global_position.x - start.x, car.global_position.z - start.z).length()
	print("  recta 5s: kmh=%s avance=%.1fm contactos=%d y=%.2f plano=%.2f" % [",".join(samples), travelled, car.wheel_contacts, car.global_position.y, suspension.height])

	# Giro a tope a 100 km/h sostenidos, 2 s. Fuerza la velocidad para aislar el radio.
	Input.action_release("throttle")
	Input.action_press("steer_right")
	var yaw0: float = car.rotation.y
	var max_g := 0.0
	for i in 240:
		var fwd := -car.global_basis.z
		car.velocity = fwd * 27.78
		await physics_frame
		max_g = maxf(max_g, absf(car.acceleration_lateral) / 9.81)
	var yaw_delta := wrapf(car.rotation.y - yaw0, -PI, PI)
	var omega := absf(yaw_delta) / 2.0
	print("  giro 100km/h: mando=%+.2f rueda=%.1f° guiñada=%.0f° omega=%.2f rad/s radio=%.1fm lateral_max=%.2fg contactos=%d" % [
		car.steering_input, rad_to_deg(car.steering_angle), rad_to_deg(yaw_delta), omega,
		27.78 / maxf(omega, 0.0001), max_g, car.wheel_contacts])
	Input.action_release("steer_right")
	race.queue_free()
	for i in 30:
		await process_frame
