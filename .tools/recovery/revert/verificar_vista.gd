extends SceneTree

# Diagnóstico fuera del juego: mide con números la vista que presenta la escena
# de carrera recuperada y guarda una captura. Comprueba lo que el jugador ve:
# dónde está la cámara respecto al coche, si el coche queda encuadrado y cómo se
# reparte el encuadre entre cielo y calzada (una vista de conducción tiene
# horizonte y asfalto por debajo; una vista aérea no).

const OUT_PNG := "res://.tools/recovery/revert/vista-juego-recuperada.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	for i in 240:
		await process_frame
	var car: CharacterBody3D = race.car
	var camera: Camera3D = race.camera
	var car_pos := car.global_position
	var cam_pos := camera.global_position
	var offset := cam_pos - car_pos
	var forward := -car.global_basis.z
	var viewport: Vector2 = root.get_visible_rect().size
	var p_center := camera.unproject_position(car_pos)
	var p_front := camera.unproject_position(car_pos + forward * 2.0)
	var p_back := camera.unproject_position(car_pos - forward * 2.0)
	var inside := Rect2(Vector2.ZERO, viewport).has_point(p_center) and Rect2(Vector2.ZERO, viewport).has_point(p_front) and Rect2(Vector2.ZERO, viewport).has_point(p_back)
	var pitch := rad_to_deg(asin(clampf(-offset.normalized().y, -1.0, 1.0)))
	print("VISTA coche=%s camara=%s" % [str(car_pos.snapped(Vector3(0.01, 0.01, 0.01))), str(cam_pos.snapped(Vector3(0.01, 0.01, 0.01)))])
	print("VISTA distancia=%.2f m  altura sobre el coche=%.2f m  detrás=%.2f m  inclinación=%.1f°" % [offset.length(), offset.y, offset.dot(forward), pitch])
	print("VISTA coche proyectado centro=(%.0f,%.0f) morro=(%.0f,%.0f) cola=(%.0f,%.0f) viewport=%s encuadrado=%s" % [
		p_center.x, p_center.y, p_front.x, p_front.y, p_back.x, p_back.y, str(viewport), str(inside)])
	var image: Image = root.get_texture().get_image()
	var error := image.save_png(OUT_PNG)
	var rows_deciels: Array = []
	for band in 10:
		var y0 := int(image.get_height() * band / 10.0)
		var y1 := int(image.get_height() * (band + 1) / 10.0)
		var total := Vector3.ZERO
		var grey := 0
		var count := 0
		for y in range(y0, y1, 2):
			for x in range(0, image.get_width(), 4):
				var c := image.get_pixel(x, y)
				total += Vector3(c.r, c.g, c.b)
				var top := maxf(c.r, maxf(c.g, c.b))
				var bottom := minf(c.r, minf(c.g, c.b))
				# Asfalto: gris (poca diferencia entre canales) y ni negro ni quemado.
				if top - bottom < 0.09 and top > 0.25 and top < 0.92:
					grey += 1
				count += 1
		total /= float(maxi(count, 1))
		rows_deciels.append({"banda": band, "medio": "%d,%d,%d" % [roundi(total.x * 255.0), roundi(total.y * 255.0), roundi(total.z * 255.0)], "gris": float(grey) / float(maxi(count, 1))})
	var sky_band: Dictionary = rows_deciels[0]
	var lower_grey := 0.0
	for band in range(5, 10):
		lower_grey = maxf(lower_grey, float(rows_deciels[band]["gris"]))
	var horizon_found := -1
	for band in 10:
		var entry: Dictionary = rows_deciels[band]
		if float(entry["gris"]) > 0.30:
			horizon_found = band
			break
	print("VISTA guardada=", error == OK, " ", OUT_PNG, " ", image.get_width(), "x", image.get_height())
	for entry in rows_deciels:
		print("VISTA banda=%d medio=(%s) gris=%.0f%%" % [entry["banda"], entry["medio"], float(entry["gris"]) * 100.0])
	print("VISTA cielo_arriba=%s asfalto_abajo=%.0f%% primera_banda_con_calzada=%d encuadrado=%s inclinacion=%.1f°" % [
		sky_band["medio"], lower_grey * 100.0, horizon_found, str(inside), pitch])
	var ok: bool = inside and error == OK and pitch < 25.0 and lower_grey > 0.10 and horizon_found > 0
	print("VISTA PASS=", ok)
	race.queue_free()
	await process_frame
	quit(0 if ok else 1)
