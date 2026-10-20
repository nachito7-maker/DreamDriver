extends SceneTree

# Mide, en el espacio LOCAL del coche (el del modelo), los hitos que necesita la
# cámara del morro: morro, punta del alerón, alto de los neumáticos delanteros,
# eje delantero, alto de la carrocería y mitad de vía. Sin dibujar: sólo cajas.
#
# Uso: "$GODOT" --headless --path . --script .tools/recovery/fase-fp/geometria_modelo.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 30:
		await physics_frame
	var car = race.car
	if car == null or car.model_root == null:
		print("GEOMETRIA no hay coche")
		quit(1)
		return
	var model: Node3D = car.model_root
	var inv: Transform3D = model.global_transform.affine_inverse()
	print("GEOMETRIA modelo=%s  pos_local=%s  escala=%s" % [
		model.name, _v(model.position), _v(model.global_basis.get_scale())])
	var piezas := {}
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = child.mesh
		var aabb: AABB = mesh.get_aabb()
		var box := AABB(inv * (child.global_transform * aabb.get_center()), Vector3.ZERO)
		var low := Vector3(INF, INF, INF)
		var high := Vector3(-INF, -INF, -INF)
		for cx in [aabb.position.x, aabb.end.x]:
			for cy in [aabb.position.y, aabb.end.y]:
				for cz in [aabb.position.z, aabb.end.z]:
					var point: Vector3 = inv * (child.global_transform * Vector3(cx, cy, cz))
					low = low.min(point)
					high = high.max(point)
		var size := high - low
		var nombre := String(child.name)
		piezas[nombre] = {"low": low, "high": high, "size": size}
		var etiqueta := "rueda" if nombre.to_lower().contains("wheel") else "carroceria"
		print("PIEZA %-34s %-11s x[%+7.3f %+7.3f] y[%+7.3f %+7.3f] z[%+7.3f %+7.3f]  centro=%s  tam=%s" % [
			nombre, etiqueta, low.x, high.x, low.y, high.y, low.z, high.z,
			_v(box.position), _v(size)])
	# Hitos derivados: todo lo que necesita la cámara sale de aquí.
	var cuerpo: Dictionary = piezas.get("Body", {}) if piezas.has("Body") else {}
	var delanteras := []
	var traseras := []
	for nombre in piezas:
		if not nombre.to_lower().contains("wheel"):
			continue
		var pieza: Dictionary = piezas[nombre]
		if float(pieza["low"].z) < 0.0:
			delanteras.append(pieza)
		else:
			traseras.append(pieza)
	if delanteras.is_empty() or traseras.is_empty() or cuerpo.is_empty():
		print("GEOMETRIA no se encontraron las piezas esperadas: %s" % [piezas.keys()])
		quit(1)
		return
	var delantera: Dictionary = delanteras[0]
	var trasera: Dictionary = traseras[0]
	var alto_rueda: float = delantera["high"].y
	var alto_rueda_trasera: float = trasera["high"].y
	var eje_delantero: float = (float(delantera["low"].z) + float(delantera["high"].z)) * 0.5
	var eje_trasero: float = (float(trasera["low"].z) + float(trasera["high"].z)) * 0.5
	var punta_aleron: float = cuerpo["low"].z
	var alto_carroceria: float = cuerpo["high"].y
	var radio: float = float(delantera["size"].y) * 0.5
	var media_via: float = absf((float(delantera["low"].x) + float(delantera["high"].x)) * 0.5)
	print("HITOS radio_delantero=%.3f  alto_neumatico=%.3f  alto_neumatico_trasero=%.3f" % [
		radio, alto_rueda, alto_rueda_trasera])
	print("HITOS eje_delantero_z=%+.3f  eje_trasero_z=%+.3f  batalla=%.3f  punta_aleron_z=%+.3f" % [
		eje_delantero, eje_trasero, eje_trasero - eje_delantero, punta_aleron])
	print("HITOS alto_carroceria=%.3f  ancho_carroceria=%.3f  largo_carroceria=%.3f  media_via=%.3f" % [
		alto_carroceria, float(cuerpo["size"].x), float(cuerpo["size"].z), media_via])
	print("HITOS aleron_por_delante_del_eje=%.3f  fondo_carroceria_y=%.3f" % [
		eje_delantero - punta_aleron, float(cuerpo["low"].y)])
	# Sección del morro: alto de la carrocería frente al eje delantero, para saber
	# a qué altura está el morro donde se pone la cámara.
	var perfil := []
	for z in [-2.8, -2.6, -2.4, -2.2, -2.0, -1.8, -1.6, -1.4, -1.2, -1.0]:
		var alto := -INF
		var bajo := INF
		for child in model.find_children("*", "MeshInstance3D", true, false):
			if String(child.name).to_lower().contains("wheel"):
				continue
			var aabb: AABB = child.mesh.get_aabb()
			var mesh := child.mesh as ArrayMesh
			if mesh == null:
				continue
			var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var stride: int = maxi(1, int(verts.size() / 20000.0))
			for i in range(0, verts.size(), stride):
				var point: Vector3 = inv * (child.global_transform * verts[i])
				if absf(point.z - z) < 0.06:
					alto = maxf(alto, point.y)
					bajo = minf(bajo, point.y)
		if alto > -INF:
			perfil.append([z, bajo, alto])
	print("PERFIL z, y_min, y_max de la carrocería en la zona del morro:")
	for entrada in perfil:
		print("   z=%+.2f  y=[%+.3f %+.3f]" % [entrada[0], entrada[1], entrada[2]])
	race.queue_free()
	await process_frame
	quit(0)

func _v(value: Vector3) -> String:
	return "(%.3f, %.3f, %.3f)" % [value.x, value.y, value.z]
