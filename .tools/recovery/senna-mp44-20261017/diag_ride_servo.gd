extends SceneTree

# Diagnóstico del servosistema de altura (`_apoyar_sobre_la_calzada`) al colocar el
# coche con `recover_to`: traza por fotograma la altura del cuerpo, la referencia del
# servo, la altura de apoyo de la suspensión, el error y los contactos, para ver por qué
# el coche rebota en vez de asentarse.
# Uso: Godot --headless --path . --script res://.tools/recovery/senna-mp44-20261017/diag_ride_servo.gd

const TrackScript = preload("res://scripts/track_data.gd")
const STATION := 2760

var line: PackedVector3Array
var car: CharacterBody3D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 120:
		await physics_frame
	car = race.car
	line = TrackScript.get_centerline()
	print("DIAG posición de reposo pos=%s vy=%.2f contactos=%d altura_susp=%.3f ref=%.3f listo=%s" % [
		str(car.global_position.snapped(Vector3(0.01, 0.01, 0.01))), car.velocity.y,
		int(car.get("wheel_contacts")), float(car.suspension.height),
		float(car.get("_ride_reference")), str(car.get("_ride_ready"))])
	var index := STATION
	var tangent := (line[(index + 4) % line.size()] - line[(index - 4 + line.size()) % line.size()]).normalized()
	var outward := Vector3(tangent.z, 0.0, -tangent.x).normalized() * -1.0
	var start: Vector3 = line[index] + Vector3.UP * 0.5
	print("DIAG estación centro=%s salida=%s" % [str(line[index]), str(start)])
	car.recover_to(start, atan2(-outward.x, -outward.z))
	print("DIAG justo tras recover_to pos=%s vy=%.2f ref=%.3f listo=%s" % [
		str(car.global_position.snapped(Vector3(0.01, 0.01, 0.01))), car.velocity.y,
		float(car.get("_ride_reference")), str(car.get("_ride_ready"))])
	for i in 90:
		await physics_frame
		var tocados := ""
		for c in car.get_slide_collision_count():
			var col := car.get_slide_collision(c)
			if col != null:
				tocados += String((col.get_collider() as Node).name) + ","
		print("DIAG f=%02d y=%.3f vy=%+.2f contactos=%d susp=%.3f ref=%.3f listo=%s choques=%s" % [
			i, car.global_position.y, car.velocity.y, int(car.get("wheel_contacts")),
			float(car.suspension.height), float(car.get("_ride_reference")),
			str(car.get("_ride_ready")), tocados])
	race.queue_free()
	await process_frame
	quit(0)
