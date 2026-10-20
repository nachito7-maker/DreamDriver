extends SceneTree

# Auditoría de materiales DENTRO del juego, no en el fichero.
#
# Godot carga `metallicRoughnessTexture` en dos ranuras: `roughness_texture`
# (canal G) y `metallic_texture` (canal B), y deja los factores en 1,0 porque
# glTF multiplica factor por textura. Leer `mat.roughness` a secas devuelve ese
# 1,0 y no dice nada: lo que hay que medir es el valor EFECTIVO.
#
#   rugosidad efectiva   = mat.roughness * (canal G de la textura, si la hay)
#   metalicidad efectiva = mat.metallic  * (canal B de la textura, si la hay)
#
# Los canales se leen de la textura que el juego tiene cargada y se comparan con
# los PNG generados desde los `*_MAP.dds` originales
# (.tools/recovery/pbr/roughness_manifest.json): la comprobación va de punta a
# punta, del DDS de Assetto Corsa al material que ve el motor.

const MANIFEST := ".tools/recovery/pbr/roughness_manifest.json"
const TOLERANCE := 4.0 / 255.0
const SAMPLE := ["asph", "asph-dark", "curb b", "slow-curb", "grass", "walls1", "sand-main", "grandstand-roof"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(race)
	await process_frame
	await process_frame

	var expected := {}
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for key in manifest["mapas"]:
		var stats: Dictionary = manifest["mapas"][key]
		var png: String = str(stats["png"])
		expected[png.get_file()] = float(stats["rugosidad"]["media"]) / 255.0

	var surfaces := 0
	var with_map := 0
	var map_checks := 0
	var map_errors := []
	var scalar_values := {}
	var metallic_errors := []
	var effective_samples := {}
	var channel_pairs := {}
	var outside_scope := 0

	for node in race.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var physics: bool = bool(mesh.get_meta("ac_physics", false)) or str(mesh.name).ends_with("-colonly")
		if physics:
			continue
		for i in mesh.mesh.get_surface_count():
			var mat := mesh.mesh.surface_get_material(i) as StandardMaterial3D
			if mat == null:
				continue
			surfaces += 1
			var extras: Dictionary = mat.get_meta("extras", {})
			var metadata: Dictionary = JSON.parse_string(str(extras.get("ac_material", "{}")))
			var name := str(metadata.get("name", mat.resource_name))
			var pbr: Dictionary = metadata.get("pbr", {})
			if pbr.is_empty():
				# Material ajeno a la pista (el coche trae su propio metallicRoughness
				# original): fuera del alcance de esta auditoria, pero se cuenta.
				outside_scope += 1
				continue
			var declared_map := str(pbr.get("roughness_map", ""))
			var declared_rough := float(pbr.get("roughness", -1.0))

			var metal := mat.metallic
			if mat.metallic_texture != null:
				var mimg: Image = mat.metallic_texture.get_image()
				var metal_sum := 0.0
				var metal_samples := 0.0
				var blue_max := 0
				var step_y := maxi(mimg.get_height() / 32, 1)
				var step_x := maxi(mimg.get_width() / 32, 1)
				for y in range(0, mimg.get_height(), step_y):
					for x in range(0, mimg.get_width(), step_x):
						var pixel := mimg.get_pixel(x, y)
						metal_sum += pixel.b
						metal_samples += 1.0
						blue_max = maxi(blue_max, roundi(pixel.b * 255.0))
				metal *= metal_sum / maxf(metal_samples, 1.0)
				if blue_max != 0:
					metallic_errors.append("%s canal B max=%d" % [name, blue_max])
			if metal > 0.002:
				metallic_errors.append("%s metal efectiva=%.4f" % [name, metal])

			if mat.roughness_texture != null:
				with_map += 1
				var image: Image = mat.roughness_texture.get_image()
				var green_sum := 0.0
				var green_samples := 0.0
				var step_gy := maxi(image.get_height() / 64, 1)
				var step_gx := maxi(image.get_width() / 64, 1)
				for y in range(0, image.get_height(), step_gy):
					for x in range(0, image.get_width(), step_gx):
						green_sum += image.get_pixel(x, y).g
						green_samples += 1.0
				var green := green_sum / maxf(green_samples, 1.0)
				var want := float(expected.get(declared_map, -1.0))
				map_checks += 1
				if absf(mat.roughness - 1.0) > 0.001:
					map_errors.append("%s factor=%.3f con textura" % [name, mat.roughness])
				if want < 0.0:
					map_errors.append("%s declara un mapa desconocido: %s" % [name, declared_map])
				elif absf(green - want) > TOLERANCE:
					map_errors.append("%s canal G=%.4f esperado=%.4f" % [name, green, want])
				channel_pairs["%d/%d" % [mat.roughness_texture_channel, mat.metallic_texture_channel]] = 1
				effective_samples[name] = green
			else:
				if absf(mat.roughness - declared_rough) > 0.0001:
					map_errors.append("%s rugosidad=%.4f declarada=%.4f" % [name, mat.roughness, declared_rough])
				var key := snappedf(mat.roughness, 0.001)
				scalar_values[key] = int(scalar_values.get(key, 0)) + 1

	var distinct := 0
	for value in scalar_values:
		if value > 0.0 and value < 1.0:
			distinct += 1
	print("PBR superficies=", surfaces, " con_textura_de_rugosidad=", with_map, " sin_textura=", surfaces - with_map)
	print("PBR valores_de_rugosidad_escalar_distintos=", distinct, " canales_rugosidad/metal=", channel_pairs)
	for want in SAMPLE:
		for key in effective_samples:
			if key.begins_with(want):
				print("PBR %-24s rugosidad_efectiva=%.3f" % [key, effective_samples[key]])
	print("PBR comprobaciones_de_mapa=", map_checks, " errores=", map_errors.size())
	for error in map_errors.slice(0, 10):
		print("PBR   ! ", error)
	print("PBR metalicidad_no_neutra=", metallic_errors.size())
	for error in metallic_errors.slice(0, 5):
		print("PBR   ! ", error)
	var passed: bool = surfaces > 100 and with_map >= 30 and distinct >= 10 and map_errors.is_empty() and metallic_errors.is_empty()
	print("PBR materiales_fuera_de_alcance=", outside_scope)
	print("PBR PASS=", passed)
	race.queue_free()
	await process_frame
	quit(0 if passed else 1)
