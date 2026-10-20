extends SceneTree

# Inventario de los cuerpos físicos del circuito: nombre, metadatos de origen,
# capa, tipo de forma y caja envolvente del cuerpo. Es la referencia para saber
# qué malla es cada cosa antes de tocar colisiones.
#
# Uso:  Godot --headless --path . --script res://scripts/collision_inventory_probe.gd

const GROUPS := ["TRM-BRC", "ROAD", "CURB", "KERB", "RUMBLE", "GRAVEL", "SAND", "GRASS", "GREEN",
	"OUT", "CONCRETE", "PITS", "CARPET", "WALL", "BARRIER", "RAIL", "FENCE"]

func _initialize() -> void:
	call_deferred("_run")

func _classify(label: String) -> String:
	var upper := label.to_upper()
	for key in GROUPS:
		if key in upper:
			return key
	return "OTHER"

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	var bodies: Array[Node] = race.track_mesh.find_children("*", "StaticBody3D", true, false)
	print("INVENTORY cuerpos=", bodies.size())
	var by_group := {}
	for node in bodies:
		var body := node as StaticBody3D
		var surface := String(body.get_meta("ac_surface", ""))
		var source := String(body.get_meta("ac_source", ""))
		var shape_text := "sin-forma"
		var faces := 0
		for child in body.get_children():
			var collision := child as CollisionShape3D
			if collision == null or collision.shape == null:
				continue
			var shape := collision.shape
			shape_text = shape.get_class()
			if shape is ConcavePolygonShape3D:
				faces = (shape as ConcavePolygonShape3D).get_faces().size() / 3
		var parent_mesh := body.get_parent() as MeshInstance3D
		var extent := Vector3.ZERO
		if parent_mesh != null and parent_mesh.mesh != null:
			extent = parent_mesh.mesh.get_aabb().size
		var group := _classify(String(body.name) + " " + surface + " " + source)
		by_group[group] = int(by_group.get(group, 0)) + 1
		print("BODY grupo=%s capa=%d caras=%d tam=%s nombre=%s origen=%s superficie=%s forma=%s" % [
			group, body.collision_layer, faces, str(extent.snapped(Vector3(0.1, 0.1, 0.1))),
			String(body.name), source, surface, shape_text])
	print("INVENTORY grupos=", by_group)
	race.queue_free()
	await process_frame
	quit(0)
