extends SceneTree

# ============================================================================
# ¿QUÉ dibuja la franja azulada de la trazada?
#
# La fase anterior dedujo, mirando píxeles, que la franja gris-azulada del centro
# de la calzada era la GOMA del mod (`groove.png`, alfa parcial) y no un defecto de
# importación. Para corregirla hay que saber exactamente QUÉ malla la dibuja y de
# QUÉ material vive, porque los materiales del GLB están COMPARTIDOS entre mallas
# (glTF los referencia por índice) y tocar uno cambia todos sus usuarios.
#
# Esta sonda monta la escena de carrera como la monta el juego (race.tscn, con su
# `_build_world`) y publica, para cada malla cuyo material use una textura de goma
# (`groove`, `tyres_add2`):
#   * nombre y ruta del nodo, y el objeto fuente del KN5,
#   * la caja envolvente (una franja que recorre la trazada mide cientos de metros
#     de largo y poco más de un metro de ancho),
#   * nombre del material, textura base, modo de transparencia y umbral de recorte,
#   * media de color y de alfa de la PROPIA textura (de dónde sale el azul),
#   * si ese material lo comparten otras mallas de la escena.
#
# Necesita ventana: sin GPU las imágenes del GLB no se pueden leer.
#
# Uso:
#   "$GODOT" --path . --script .tools/recovery/linea/decal_probe.gd
# ============================================================================

const FRAME_W := 2400
const FRAME_H := 1080

var race: Node3D
var view: SubViewport

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	view = SubViewport.new()
	view.size = Vector2i(FRAME_W, FRAME_H)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	view.add_child(race)
	for i in 30:
		await physics_frame
	# --- inventario de mallas y de usuarios de cada material ------------------
	var meshes := race.find_children("*", "MeshInstance3D", true, false)
	print("DECAL mallas_visibles=%d" % meshes.size())
	var usuarios := {}                      # id de material -> [nombres de nodo]
	var candidatas: Array = []
	for node in meshes:
		var mesh := node as MeshInstance3D
		if not mesh.visible:
			continue
		var aabb: AABB = mesh.mesh.get_aabb()
		var fuente := String(mesh.get_meta("kn5_source_obj", ""))
		for i in mesh.mesh.get_surface_count():
			var mat := mesh.mesh.surface_get_material(i) as StandardMaterial3D
			if mat == null:
				continue
			usuarios.get_or_add(mat.get_instance_id(), []).append(String(mesh.name) + "#" + str(i))
			var tex := mat.albedo_texture
			var nombre_tex := "" if tex == null else String(tex.resource_path).get_file()
			if tex != null and nombre_tex == "" and tex is ImageTexture:
				nombre_tex = "<glb:%s>" % String(tex.get_name())
			var goma := "groove" in nombre_tex.to_lower() or "tyres_add2" in nombre_tex.to_lower() \
				or "groove" in String(mat.resource_name).to_lower() \
				or "groove" in String(mat.get_meta("extras", {}).get("ac_material", "")).to_lower()
			if not goma:
				continue
			candidatas.append({
				"nodo": String(mesh.name),
				"fuente": fuente,
				"superficie": i,
				"material": String(mat.resource_name),
				"textura": nombre_tex,
				"transparencia": mat.transparency,
				"umbral": mat.alpha_scissor_threshold,
				"albedo_color": str(mat.albedo_color),
				"aabb_tamano": str(aabb.size.snapped(Vector3(0.01, 0.01, 0.01))),
				"aabb_centro": str(aabb.get_center().snapped(Vector3(0.1, 0.1, 0.1))),
				"vertice": str(aabb.position.snapped(Vector3(0.1, 0.1, 0.1))),
				"material_id": mat.get_instance_id(),
			})
	# --- medidas de cada textura de goma --------------------------------------
	var medidas := {}
	for entrada in candidatas:
		var clave: String = entrada["textura"]
		if medidas.has(clave):
			continue
		var texto := _medir_textura(entrada)
		medidas[clave] = texto
	for entrada in candidatas:
		print("DECAL nodo=%s fuente=%s superficie=%d material=%s textura=%s transparencia=%d umbral=%.2f albedo_color=%s" % [
			entrada["nodo"], entrada["fuente"], entrada["superficie"], entrada["material"],
			entrada["textura"], entrada["transparencia"], entrada["umbral"], entrada["albedo_color"]])
		print("DECAL   aabb tamano=%s centro=%s esquina=%s compartido_por=%d" % [
			entrada["aabb_tamano"], entrada["aabb_centro"], entrada["vertice"],
			usuarios.get(entrada["material_id"], []).size()])
		print("DECAL   textura: %s" % medidas[entrada["textura"]])
	# --- resumen por material -------------------------------------------------
	for clave in usuarios:
		var lista: Array = usuarios[clave]
		if lista.size() > 1:
			print("DECAL material_compartido id=%s usuarios=%d %s" % [clave, lista.size(), str(lista.slice(0, 6))])
	quit(0)

# Media de color y de alfa de una textura, y su dominante (separación entre canales
# respecto al mayor, en %; 0 % es gris puro). Es de dónde sale el tinte azulado.
func _medir_textura(entrada: Dictionary) -> String:
	var mesh := _buscar(entrada["nodo"])
	if mesh == null:
		return "sin malla"
	var mat := mesh.mesh.surface_get_material(int(entrada["superficie"])) as StandardMaterial3D
	if mat == null or mat.albedo_texture == null:
		return "sin textura"
	var imagen := mat.albedo_texture.get_image()
	if imagen == null:
		return "textura ilegible"
	imagen.convert(Image.FORMAT_RGBA8)
	var ancho := imagen.get_width()
	var alto := imagen.get_height()
	var suma := Vector3.ZERO
	var suma_alfa := 0.0
	var cuentas := 0
	var alfas := PackedFloat32Array()
	for y in range(0, alto, maxi(1, alto / 64)):
		for x in range(0, ancho, maxi(1, ancho / 64)):
			var c := imagen.get_pixel(x, y)
			suma += Vector3(c.r, c.g, c.b)
			suma_alfa += c.a
			if alfas.size() < 4096:
				alfas.append(c.a)
			cuentas += 1
	if cuentas == 0:
		return "textura vacía"
	var media := suma / float(cuentas)
	var mayor := maxf(media.x, maxf(media.y, media.z))
	var menor := minf(media.x, minf(media.y, media.z))
	var desviacion := 0.0 if mayor <= 0.0 else (mayor - menor) / mayor * 100.0
	alfas.sort()
	var alfa_medio := sum(alfas) / maxf(1.0, alfas.size())
	var alfa_p90 := alfas[int(clampf(roundf(alfas.size() * 0.9), 0.0, alfas.size() - 1.0))] if alfas.size() > 0 else 0.0
	var alfa_max := alfas[alfas.size() - 1] if alfas.size() > 0 else 0.0
	return "tamano=%dx%d media_rgb=(%.0f,%.0f,%.0f) dominante=%.1f%% alfa_medio=%.0f alfa_p90=%.0f alfa_max=%.0f alfa_medio_global=%.0f" % [
		ancho, alto, media.x * 255.0, media.y * 255.0, media.z * 255.0, desviacion,
		alfa_medio * 255.0, alfa_p90 * 255.0, alfa_max * 255.0, suma_alfa / float(cuentas) * 255.0]

func sum(valores: PackedFloat32Array) -> float:
	var total := 0.0
	for v in valores:
		total += v
	return total

func _buscar(nombre: String) -> MeshInstance3D:
	for node in race.find_children("*", "MeshInstance3D", true, false):
		if String(node.name) == nombre:
			return node
	return null
