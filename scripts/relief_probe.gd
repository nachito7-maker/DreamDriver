extends SceneTree

# ¿Queda relieve invisible de la calzada por encima del asfalto?
#
# El circuito trae del original de Assetto Corsa una malla de física cuyos grupos no
# son suelo ni muro sino RELIEVE del suelo: la goma de las ruedas (MARBLES), las
# tiras de badenes (BUMP), las rejillas (GRILLE), los cruces (TRAV) y los escalones
# de hormigón (CNCPTS). En AC se rueda POR ENCIMA de ellos, porque su coche son
# cuatro rayos de rueda; aquí el coche es una caja rígida contra una malla trimesh,
# así que cualquier borde que sobresalga es un muro. Y como las mallas de física no
# se dibujan, el muro es INVISIBLE: eso era lo que clavaba el coche a 310 km/h
# sobre asfalto, sin nada dibujado delante.
#
# Esta sonda mide, cara a cara y en coordenadas del MUNDO, cuánto sobresale cada
# cara de relieve sobre la superficie que tiene debajo (la que de verdad pisa el
# coche: asfalto, bordillo, hierba...), excluyendo del rayo todas las caras de
# relieve y todos los muros para no medirse contra sí misma. A la vez comprueba que
# los muros y las superficies sigan donde estaban: vuelve a montar el circuito tal
# como viene del GLB, sin pasar por la escena de carrera, y compara cuerpo a cuerpo.
#
# Uso:
#   Godot --headless --path . --script res://scripts/relief_probe.gd
#   Godot --headless --path . --script res://scripts/relief_probe.gd -- --original
#
# Con `--original` mide la MISMA magnitud sobre la geometría tal como la entrega AC,
# sin el hundimiento del juego: es la medida "antes" de esta fase, hecha con el mismo
# instrumento, y entonces lo que se exige es lo contrario —que sí haya caras de
# relieve por encima de la calzada—, porque de ahí venía el bloqueo invisible.

const TrackScript = preload("res://scripts/track_data.gd")

const RELIEVE := ["MARBLES", "BUMP", "GRILLE", "GRILL", "CNCPTS", "TRAV"]
const ALTURA := 0.05          # m por encima del suelo que ya molesta al coche
const RELIEF_SINK_M := 1.5    # m que baja el relieve, igual que en la escena (race.gd)

var failures := 0
var solo_original := false
var space: PhysicsDirectSpaceState3D

func check(condition: bool, message: String) -> void:
	print("RELIEVE ", "PASS " if condition else "FAIL ", message)
	if not condition:
		failures += 1

func info(message: String) -> void:
	print("RELIEVE INFO ", message)

func _initialize() -> void:
	call_deferred("_run")

func _etiqueta(cuerpo: Node) -> String:
	# La escena de carrera anota la superficie original de AC en `ac_surface`; el
	# original montado a mano no la tiene, pero trae los extras del GLB, que es de
	# donde la saca la escena. Sin esto, el grupo MARBLES —cuyo cuerpo se llama
	# `OTHER` en la malla de AC— se quedaría sin medir.
	var extras: Dictionary = cuerpo.get_meta("extras", {})
	return (String(cuerpo.name) + " " + String(cuerpo.get_meta("ac_surface", "")) + " " + String(extras.get("ac_source_nodes", ""))).to_upper()

func _es_relieve(cuerpo: StaticBody3D) -> bool:
	# Mismo criterio que el juego: primero el grupo que el propio juego anotó al
	# montar la escena, y si no, el nombre y la superficie original de AC (que es lo
	# único que hay cuando se mide el original, sin pasar por la escena).
	var anotado := String(cuerpo.get_meta("ac_relief", ""))
	if anotado != "":
		return true
	var etiqueta := _etiqueta(cuerpo)
	for key in RELIEVE:
		if key in etiqueta:
			return true
	return false

func _extremos(caras: PackedVector3Array) -> Array:
	if caras.is_empty():
		return []
	var minimo := caras[0]
	var maximo := caras[0]
	for i in caras.size():
		minimo = minimo.min(caras[i])
		maximo = maximo.max(caras[i])
	return [minimo, maximo]

func _caras_en_el_mundo(cuerpo: StaticBody3D) -> PackedVector3Array:
	for hijo in cuerpo.get_children():
		var forma := hijo as CollisionShape3D
		if forma != null and forma.shape is ConcavePolygonShape3D:
			var locales := (forma.shape as ConcavePolygonShape3D).get_faces()
			var mundo := PackedVector3Array()
			mundo.resize(locales.size())
			for i in locales.size():
				mundo[i] = forma.global_transform * locales[i]
			return mundo
	return PackedVector3Array()

func _rayo(from: Vector3, to: Vector3, exclude: Array) -> float:
	var consulta := PhysicsRayQueryParameters3D.create(from, to, 1)
	consulta.exclude = exclude
	var golpe := space.intersect_ray(consulta)
	return INF if golpe.is_empty() else float(golpe.position.y)

# Suelo que hay debajo de una cara. Si no aparece ninguno (la cara está sobre un
# hueco o dentro de otra geometría, y el rayo no puede empezar dentro de un cuerpo),
# se busca la superficie que tiene POR ENCIMA: en una cara que se hundió, la
# calzada por la que rueda el coche está arriba.
func _suelo_debajo(point: Vector3, exclude: Array) -> float:
	var abajo := _rayo(point + Vector3.UP * 6.0, point - Vector3.UP * 6.0, exclude)
	if abajo != INF:
		return abajo
	return _rayo(point + Vector3.UP * 0.05, point + Vector3.UP * 8.0, exclude)

func _estacion_de(point: Vector3, line: PackedVector3Array) -> int:
	var mejor := 0
	var mejor_distancia := INF
	for i in line.size():
		var distancia := Vector2(point.x - line[i].x, point.z - line[i].z).length_squared()
		if distancia < mejor_distancia:
			mejor_distancia = distancia
			mejor = i
	return mejor

func _cuerpos_de_superficie(track: Node3D) -> Array[StaticBody3D]:
	var salida: Array[StaticBody3D] = []
	for nodo in track.find_children("*", "StaticBody3D", true, false):
		var cuerpo := nodo as StaticBody3D
		if cuerpo.collision_layer == 0 or _es_relieve(cuerpo) or "WALL" in _etiqueta(cuerpo):
			continue
		salida.append(cuerpo)
	return salida

func _run() -> void:
	var args: Array = OS.get_cmdline_user_args()
	solo_original = args.has("--original")
	var inicio := Time.get_ticks_msec()
	var raiz: Node3D
	if solo_original:
		raiz = (load("res://assets/BarcelonaMoto-Tutorial.glb") as PackedScene).instantiate() as Node3D
		raiz.rotation.y = PI   # el mismo giro que le da la escena de carrera
	else:
		raiz = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	root.add_child(raiz)
	await process_frame
	await physics_frame
	space = raiz.get_world_3d().direct_space_state
	Engine.max_fps = 0
	var track: Node3D = raiz if solo_original else raiz.track_mesh
	var line: PackedVector3Array = TrackScript.get_centerline()
	info("malla medida: %s" % ("la del original de AC (sin el hundimiento del juego)" if solo_original else "la que monta la escena de carrera"))

	var relieve: Array[StaticBody3D] = []
	var muros: Array[StaticBody3D] = []
	var superficies := 0
	for nodo in track.find_children("*", "StaticBody3D", true, false):
		var cuerpo := nodo as StaticBody3D
		if cuerpo.collision_layer == 0:
			continue
		if _es_relieve(cuerpo):
			relieve.append(cuerpo)
		elif "WALL" in _etiqueta(cuerpo):
			muros.append(cuerpo)
		else:
			superficies += 1
	# Nada de lo que se mide aquí puede estorbar a la medida: ni el relieve (que es
	# lo medido) ni los muros (que son verticales y taparían su propio suelo).
	var exclude: Array = []
	for cuerpo in relieve + muros:
		exclude.append(cuerpo.get_rid())
	info("cuerpos: %d de relieve, %d de muro, %d de superficie" % [relieve.size(), muros.size(), superficies])
	check(relieve.size() > 0 and muros.size() > 0,
		"la malla trae los dos grupos que hay que medir: %d de relieve y %d de muro" % [relieve.size(), muros.size()])

	# --- relieve: cuánto sobresale cada cara del suelo que tiene debajo ---------
	var caras := 0
	var sin_suelo := 0
	var encima := 0
	var peor := -INF
	var peor_medido := -INF
	var peor_punto := Vector3.ZERO
	var por_grupo := {}
	for cuerpo in relieve:
		var grupo := String(cuerpo.get_meta("ac_relief", ""))
		if grupo == "":
			var etiqueta := _etiqueta(cuerpo)
			for key in RELIEVE:
				if key in etiqueta:
					grupo = key
					break
		var caras_cuerpo := _caras_en_el_mundo(cuerpo)
		var alta := -INF
		var indice := 0
		while indice * 3 + 2 < caras_cuerpo.size():
			var centro := (caras_cuerpo[indice * 3] + caras_cuerpo[indice * 3 + 1] + caras_cuerpo[indice * 3 + 2]) / 3.0
			indice += 1
			caras += 1
			var suelo := _suelo_debajo(centro, exclude)
			if suelo == INF:
				sin_suelo += 1
				continue
			var relieve_m := centro.y - suelo
			alta = maxf(alta, relieve_m)
			if relieve_m > peor_medido:
				peor_medido = relieve_m
				peor_punto = centro
			if relieve_m > ALTURA:
				encima += 1
				peor = maxf(peor, relieve_m)
		var acumulado: Array = por_grupo.get(grupo, [0, -INF])
		por_grupo[grupo] = [int(acumulado[0]) + caras_cuerpo.size() / 3, maxf(float(acumulado[1]), alta)]
	for grupo in por_grupo.keys():
		var datos: Array = por_grupo[grupo]
		info("relieve grupo=%s caras=%d max_sobre_suelo=%+.2f m" % [grupo, datos[0], datos[1]])
	var estacion := _estacion_de(peor_punto, line)
	info("la cara de relieve más alta está en %s (estación %d, %.0f m de trazada)" % [
		str(peor_punto), estacion, estacion * 1.508])
	if solo_original:
		check(encima > 0,
			"el original de AC SÍ trae caras de relieve por encima de la calzada: %d de %d caras sobresalen más de %.2f m, la peor %+.2f m (sin suelo que medir: %d)" % [
				encima, caras, ALTURA, peor_medido, sin_suelo])
	else:
		check(encima == 0,
			"ninguna de las %d caras de relieve sobresale más de %.2f m del suelo que tiene debajo: por encima del tope hay %d, y la más alta de todas está %+.2f m por debajo (sin suelo que medir: %d)" % [
				caras, ALTURA, encima, peor_medido, sin_suelo])

	if solo_original:
		info("medido en %d ms" % (Time.get_ticks_msec() - inicio))
		raiz.queue_free()
		await process_frame
		quit(0 if failures == 0 else 1)
		return

	# --- lo demás no se ha movido: montado contra el original ------------------
	#
	# La corrección sólo puede haber bajado el relieve. Lo que lo demuestra sin
	# preguntarle al código que lo hizo es montar OTRA VEZ el circuito original tal
	# como viene del GLB —sin pasar por la escena de carrera— y comparar, cuerpo a
	# cuerpo y por su nombre, dónde estaba cada colisión y dónde está ahora: los
	# muros y las superficies tienen que estar exactamente donde estaban (0,00 m de
	# desplazamiento) y cada grupo de relieve exactamente `RELIEF_SINK_M` por debajo.
	var fuente := (load("res://assets/BarcelonaMoto-Tutorial.glb") as PackedScene).instantiate() as Node3D
	fuente.rotation.y = PI
	root.add_child(fuente)
	await process_frame
	var original := {}
	for nodo in fuente.find_children("*", "StaticBody3D", true, false):
		var cuerpo := nodo as StaticBody3D
		var extras: Dictionary = cuerpo.get_meta("extras", {})
		if extras.get("kn5_source_obj", "") == "4.obj":
			continue
		original[String(cuerpo.name)] = _extremos(_caras_en_el_mundo(cuerpo))
	fuente.queue_free()

	var intocados := 0
	var desviados := 0
	var peor_desvio := 0.0
	var peor_nombre := ""
	var hundidos_bien := 0
	var hundidos_mal := 0
	var candidatos: Array[StaticBody3D] = relieve + muros + _cuerpos_de_superficie(track)
	for cuerpo in candidatos:
		if not original.has(String(cuerpo.name)):
			continue
		var ahora: Array = _extremos(_caras_en_el_mundo(cuerpo))
		var antes: Array = original[String(cuerpo.name)]
		if ahora.is_empty() or antes.is_empty():
			continue
		var desplazamiento: float = ((ahora[1] as Vector3).y + (ahora[0] as Vector3).y) * 0.5 - ((antes[1] as Vector3).y + (antes[0] as Vector3).y) * 0.5
		var esperado := -RELIEF_SINK_M if _es_relieve(cuerpo) else 0.0
		if absf(desplazamiento - esperado) <= 0.01:
			if esperado == 0.0:
				intocados += 1
			else:
				hundidos_bien += 1
		else:
			if esperado == 0.0:
				desviados += 1
				if absf(desplazamiento) > absf(peor_desvio):
					peor_desvio = desplazamiento
					peor_nombre = String(cuerpo.name)
			else:
				hundidos_mal += 1
				info("relieve no hundido lo que toca: %s desplazamiento %+.2f m" % [cuerpo.name, desplazamiento])
	info("contra el original: %d cuerpos en su sitio, %d de relieve hundidos %.2f m, %d desviados, %d de relieve sin hundir" % [
		intocados, hundidos_bien, RELIEF_SINK_M, desviados, hundidos_mal])
	if desviados > 0:
		info("el peor desvío (%+.2f m) es %s" % [peor_desvio, peor_nombre])
	check(intocados > 0 and desviados == 0,
		"ni los muros ni las superficies se han movido: %d cuerpos sin tocar, %d con desplazamiento%s" % [
			intocados, desviados, "" if desviados == 0 else " (el peor %+.2f m en %s)" % [peor_desvio, peor_nombre]])
	check(hundidos_bien > 0 and hundidos_mal == 0,
		"el relieve sí: %d cuerpos hundidos exactamente %.2f m, %d sin hundir" % [hundidos_bien, RELIEF_SINK_M, hundidos_mal])

	info("medido en %d ms" % (Time.get_ticks_msec() - inicio))
	raiz.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
