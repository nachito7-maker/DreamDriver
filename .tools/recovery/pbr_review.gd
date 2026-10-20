extends SceneTree

# Render del host para comparar materiales, no para juzgarlos de oído.
#
# Monta la misma escena que `race.gd` (mismo cielo, misma luz ambiental neutra y
# mismo sol, mismo tratamiento de filtros y transparencias) sobre el GLB que se
# le pase, coloca la cámara de persecución en la parrilla de salida y guarda un
# PNG. Con `PBR_OVERRIDE` se puede forzar la rugosidad de materiales concretos
# para comparar dos interpretaciones de los mismos datos originales.
#
#   TRACK_GLB=res://assets/BarcelonaMoto-Tutorial.glb \
#   OUT_PNG=.tools/recovery/pbr/render-a.png \
#   PBR_OVERRIDE="asph=0.189" godot --path . --script .tools/recovery/pbr_review.gd

const TrackScript = preload("res://scripts/track_data.gd")
const WARMUP := 90

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := OS.get_environment("TRACK_GLB")
	if path.is_empty():
		path = "res://assets/BarcelonaMoto-Tutorial.glb"
	var out := OS.get_environment("OUT_PNG")
	if out.is_empty():
		out = ".tools/recovery/pbr/render.png"
	var override := OS.get_environment("PBR_OVERRIDE")

	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#4e85b5")
	sky_mat.sky_horizon_color = Color("#b7d3e4")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.76, 0.78)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -24.0, 0.0)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	root.add_child(sun)

	var packed := load(path) as PackedScene
	if packed == null:
		print("REVIEW cargar_glb=false path=", path)
		quit(1)
		return
	var track: Node3D = packed.instantiate()
	track.rotation.y = PI
	root.add_child(track)

	var forced := {}
	for pair in override.split(",", false):
		if not pair.is_empty():
			var parts := pair.split("=")
			forced[parts[0]] = float(parts[1])

	var surfaces := 0
	var touched := 0
	for node in track.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var physics: bool = bool(mesh.get_meta("ac_physics", false)) or String(mesh.name).ends_with("-colonly")
		if physics:
			mesh.visible = false
			continue
		for i in mesh.mesh.get_surface_count():
			var mat := mesh.mesh.surface_get_material(i) as StandardMaterial3D
			if mat == null:
				continue
			surfaces += 1
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			var extras: Dictionary = mat.get_meta("extras", {})
			var metadata: Dictionary = JSON.parse_string(String(extras.get("ac_material", "{}")))
			if metadata.get("alpha_tested", false) or metadata.get("alpha_blend", false) or "Alpha" in String(metadata.get("shader", "")):
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				mat.alpha_scissor_threshold = 0.35
			for key in forced:
				# "*" fuerza la rugosidad de todo el circuito: es la forma de
				# reproducir el aspecto anterior (0,85 uniforme) con la misma
				# geometria y la misma camara, y asi comparar solo el material.
				if key == "*" or str(metadata.get("name", "")).begins_with(key):
					mat.roughness = forced[key]
					mat.roughness_texture = null
					mat.metallic_texture = null
					touched += 1

	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 72.0
	camera.near = 0.1
	camera.far = 2000.0
	var spawn: Vector3 = TrackScript.get_spawn_position()
	var yaw: float = TrackScript.get_spawn_yaw()
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	camera.position = spawn + Vector3.UP * 3.7 - forward * 9.0
	root.add_child(camera)
	camera.look_at(spawn + forward * 24.0 + Vector3.UP * 0.8, Vector3.UP)

	for i in WARMUP:
		await process_frame
	var image: Image = root.get_texture().get_image()
	var error := image.save_png(out)
	var bands := {
		"izquierda": Rect2(0.18, 0.72, 0.10, 0.16),
		"centro": Rect2(0.44, 0.76, 0.10, 0.14),
		"derecha": Rect2(0.70, 0.72, 0.10, 0.16),
	}
	var worst := 0.0
	var line := []
	for band in bands:
		var m := _measure(image, bands[band])
		worst = maxf(worst, float(m["spread"]))
		line.append("%s=(%s) desv=%.1f%% recorte=%.0f%% lum=%.3f" % [band, m["mean"], float(m["spread"]) * 100.0, float(m["clipped"]) * 100.0, float(m["luma"])])
	print("REVIEW path=", path, " guardado=", error == OK, " out=", out, " superficies=", surfaces, " forzados=", touched)
	print("REVIEW ", " | ".join(line))
	print("REVIEW asfalto_neutro=", worst < 0.08, " peor_desviacion=%.1f%%" % (worst * 100.0))
	quit(0 if error == OK else 1)

func _measure(image: Image, band: Rect2) -> Dictionary:
	var x0 := int(image.get_width() * band.position.x)
	var y0 := int(image.get_height() * band.position.y)
	var w := maxi(int(image.get_width() * band.size.x), 1)
	var h := maxi(int(image.get_height() * band.size.y), 1)
	var r := 0.0
	var g := 0.0
	var b := 0.0
	var n := 0
	var clipped := 0
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			var c := image.get_pixel(x, y)
			r += c.r
			g += c.g
			b += c.b
			n += 1
			if maxf(c.r, maxf(c.g, c.b)) > 0.995 and minf(c.r, minf(c.g, c.b)) < 0.85:
				clipped += 1
	r /= n
	g /= n
	b /= n
	var top := maxf(r, maxf(g, b))
	return {
		"clipped": float(clipped) / float(n),
		"spread": (top - minf(r, minf(g, b))) / maxf(top, 0.0001),
		"luma": 0.2126 * r + 0.7152 * g + 0.0722 * b,
		"mean": "%d,%d,%d" % [roundi(r * 255.0), roundi(g * 255.0), roundi(b * 255.0)],
	}
