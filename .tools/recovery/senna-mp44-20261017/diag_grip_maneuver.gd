extends SceneTree

# Diagnóstico de la maniobra dinámica de `surface_grip_probe`: coloca el coche en
# la misma estación y rumbo, y traza posición, contactos y superficie para ver
# por qué la maniobra deja de tener ruedas sobre el suelo.
# Uso: Godot --headless --path . --script res://.tools/recovery/senna-mp44-20261017/diag_grip_maneuver.gd

const TrackScript = preload("res://scripts/track_data.gd")
const DRIVE_STATION := [2760, -1]
const WHEEL_POINTS := [Vector3(-0.85, 0, -1.5), Vector3(0.85, 0, -1.5), Vector3(-0.85, 0, 1.95), Vector3(0.85, 0, 1.95)]
const SURFACE_KEYS := ["TRM-BRC", "ROAD", "KERB", "CURB", "RUMBLE", "CONCRETE", "PITS",
	"GRAVEL", "SAND", "GRASS", "GREEN", "CARPET", "OUT"]

var line: PackedVector3Array
var space: PhysicsDirectSpaceState3D
var car: CharacterBody3D

func _initialize() -> void:
	call_deferred("_run")

func _group_of(body: Node) -> String:
	if body == null:
		return "NONE"
	var label := (String(body.name) + " " + String(body.get_meta("ac_surface", ""))).to_upper()
	for key in SURFACE_KEYS:
		if key in label:
			return key
	return "OTHER"

func _ray(point: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP, point - Vector3.UP * 1.2, 1)
	return space.intersect_ray(query)

func _wheel_surface() -> String:
	var votes := {}
	for offset in WHEEL_POINTS:
		var world: Vector3 = car.global_transform * offset
		var hit := _ray(world)
		if hit.is_empty():
			continue
		var group := _group_of(hit.collider as Node)
		if group == "OTHER" or group == "NONE":
			continue
		votes[group] = int(votes.get(group, 0)) + 1
	var best := ""
	var best_votes := 0
	for key in votes:
		if int(votes[key]) > best_votes:
			best_votes = int(votes[key])
			best = String(key)
	return best

func shape_probe(shape: Shape3D, at: Vector3, radius: float, label: String) -> void:
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis.IDENTITY, at)
	params.collision_mask = 0xFFFFFFFF
	var hits := space.intersect_shape(params, 16)
	print("DIAG esfera %s en %s: %d cuerpos" % [label, str(at), hits.size()])
	for h in hits:
		print("   -> %s" % String((h.collider as Node).name))

func _run() -> void:
	var race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	Engine.max_fps = 240
	for i in 120:
		await physics_frame
	car = race.car
	line = TrackScript.get_centerline()
	space = race.get_world_3d().direct_space_state

	var index: int = DRIVE_STATION[0]
	var side: int = DRIVE_STATION[1]
	var tangent := (line[(index + 4) % line.size()] - line[(index - 4 + line.size()) % line.size()]).normalized()
	var outward := Vector3(tangent.z, 0.0, -tangent.x).normalized() * float(side)
	var start := line[index] + Vector3.UP * 0.5
	print("DIAG estación=%d centro=%s tangente=%s salida=%s" % [index, str(line[index]), str(tangent), str(outward)])
	# Perfil del suelo a lo largo de la salida (perpendicular) y a lo largo de la pista.
	for d in [0.0, 2.0, 4.0, 8.0, 12.0, 20.0, 30.0, 45.0, 60.0]:
		var p: Vector3 = line[index] + outward * d
		var hit := _ray(p)
		if hit.is_empty():
			print("DIAG perfil d=%.0f SIN SUELO bajo y=%.2f" % [d, p.y])
		else:
			print("DIAG perfil d=%.0f suelo=%s y=%.2f collider=%s" % [d, str(hit.position.snapped(Vector3(0.01, 0.01, 0.01))), float(hit.position.y), String((hit.collider as Node).name)])
	car.recover_to(start, atan2(-outward.x, -outward.z))
	print("DIAG inmediato pos=%s vy=%.2f" % [str(car.global_position.snapped(Vector3(0.01, 0.01, 0.01))), car.velocity.y])
	var sphere := SphereShape3D.new()
	shape_probe(sphere, car.global_position + Vector3.UP * 0.3, 0.7, "cuerpo")
	for i in 40:
		await physics_frame
		if i < 24 or i % 8 == 0:
			var tocados := ""
			for c in car.get_slide_collision_count():
				var col := car.get_slide_collision(c)
				if col != null:
					tocados += String((col.get_collider() as Node).name) + " "
			print("DIAG f=%d pos=%s vy=%.2f ruedas=%d choques=%s" % [i, str(car.global_position.snapped(Vector3(0.01, 0.01, 0.01))), car.velocity.y, int(car.get("wheel_contacts")), tocados])
	print("DIAG tras colocar pos=%s ruedas=%d suelo=%s" % [str(car.global_position.snapped(Vector3(0.01, 0.01, 0.01))), int(car.get("wheel_contacts")), _wheel_surface()])
	Input.action_press("throttle")
	for tick in 400:
		await physics_frame
		if tick % 10 == 0:
			print("DIAG t=%d pos=%s kmh=%.1f vy=%.2f ruedas=%d superficie=%s suelo=%s" % [
				tick, str(car.global_position.snapped(Vector3(0.1, 0.1, 0.1))), float(car.get("speed_kph")),
				car.velocity.y, int(car.get("wheel_contacts")), _wheel_surface(), str(car.get("ground_surface"))])
	Input.action_release("throttle")
	race.queue_free()
	await process_frame
	quit(0)
