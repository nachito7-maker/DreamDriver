extends SceneTree

# Diagnóstico temporal: dónde queda cada pieza del coche respecto al asfalto.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 0
	for i in 120:
		await physics_frame
	var car: CharacterBody3D = race.car
	race.controls.set_process(false)
	car.set_meta("touch_throttle", 1.0)
	for i in 240:
		await physics_frame
	print("FRAME       car.y=%.4f ground=%.4f suspension.height=%.4f cruda=%.4f model_root.position.y=%.4f" % [
		car.global_position.y, car._ground_height, car.suspension.height,
		car.suspension.height - car.global_position.y, car.model_root.position.y])
	print("FRAME       model_root.global.y=%.4f body_node=%s body_node.global.y=%.4f" % [
		car.model_root.global_position.y, str(car._body_node.name), car._body_node.global_position.y])
	print("FRAME       wheel_rest_y=%s corners=%s" % [str(car._suspension_rest_y), str(car.suspension.corner)])
	print("FRAME       road[i]=%s offset[i]=%s load=%s" % [
		str(car.suspension.road), str(car.suspension.offset), str(car.suspension.load)])
	for i in car._suspension_wheels.size():
		var w: Node3D = car._suspension_wheels[i]
		var bottom := w.global_position.y - 0.374
		print("FRAME       rueda %d %s local_y=%.4f global_y=%.4f fondo=%.4f (asfalto %.4f) fila=%.4f" % [
			i, str(w.name), w.position.y, w.global_position.y,
			w.global_position.y - bottom,
			car.suspension.road[i], car.suspension.road[i] - bottom])
	print("FRAME       collision.y=%.4f box.size=%s" % [
		(car.get_child(0) as CollisionShape3D).position.y,
		str(((car.get_child(0) as CollisionShape3D).shape as BoxShape3D).size)])
	race.queue_free()
	await process_frame
	quit(0)
