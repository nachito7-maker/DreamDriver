extends SceneTree

# ============================================================================
# Sonda de la línea dinámica de asistencia (sin GPU).
#
# Comprueba las cuentas, no los píxeles (de los píxeles se encargan
# `.tools/recovery/linea/capturar.gd` y `.tools/recovery/linea/linea_pixeles.py`):
#
#   1. Velocidad ideal de cada punto: finita, dentro de sus topes y coherente con la
#      capacidad lateral MEDIDA del coche (sonda_direccion).
#   2. Envolventes de frenada: nunca por encima de la velocidad ideal, la suave nunca por
#      encima de la roja ni ésta por encima de la fuerte, y las tres realizables punto a
#      punto con su deceleración. La ROJA —la que dibuja el aviso— tiene que quedar por
#      debajo de la fuerte en todos los puntos: eso es exactamente "el rojo no llega
#      nunca más tarde que el punto de frenada de la física".
#   3. Punto de frenada. En cada curva significativa y para cada velocidad POR ENCIMA de
#      la de la curva (si el coche va más despacio que el vértice no hay frenada que
#      juzgar) se mide dónde empieza el tramo rojo y se comprueba que esté en la
#      distancia de frenada con la ANTELACIÓN declarada, (v² − v_curva²)/(2·a_roja), y
#      que nunca esté más cerca que la frenada de la física (v² − v_curva²)/(2·a_freno),
#      es decir que el aviso no llegue tarde ni pida más de lo que el coche frena. La
#      curva que manda se busca POR DELANTE del inicio del rojo, como el mínimo de
#      v_ideal(j)² + 2·a·(s_j − s_rojo): buscarla desde el coche devolvía la primera
#      ondulación de la velocidad ideal y la distancia salía negativa (medido: curva
#      1612, −1613 m/s²). Y la comparación se hace en DISTANCIA, no en deceleración
#      implícita: la distancia no puede ser más fina que el paso de la trazada (1,51 m),
#      así que dividir por ella inventaba desviaciones del 5000 % sobre frenadas cortas.
#      También se exige que el amarillo aparezca antes que el rojo, con un margen de
#      tiempo razonable.
#   4. Sin parpadeo: el estado de un punto es monótono con la velocidad (subir de
#      velocidad sólo puede convertir verde en amarillo y amarillo en rojo).
#   5. Prueba funcional: una vuelta conducida SÓLO con lo que dice la línea (frenar
#      cuando está rojo, levantar el pie cuando está amarillo, acelerar cuando está
#      verde) no se sale nunca del plan: ni supera la velocidad ideal, ni pisa más agarre
#      del que el coche tiene, y CADA frenada de la vuelta estaba anunciada por la línea
#      a una distancia entre la de frenada de referencia y la cómoda. Y el control
#      negativo —el mismo conductor ignorando la línea— sí se sale, que es lo que
#      demuestra que la prueba tiene dientes.
#   6. Geometría del listón: dos vértices por anillo a ± el ancho declarado y a la altura
#      declarada sobre la trazada, con el arco en la UV.
#   7. Continuidad de los estados a lo largo de la línea: escaneando la ventana visible
#      metro a metro, nunca se pasa de verde a rojo sin muestras amarillas en medio (el
#      amarillo no puede desaparecer, que es lo que dejaría el aviso sin transición).
#   8. Extremos y valores inválidos: en los bordes de la pista (arco 0, media vuelta,
#      último punto, y estaciones que se salen de la vuelta por los dos lados) y en las
#      velocidades extremas (0 y 720 km/h) el veredicto y las tres envolventes siguen
#      siendo finitos y coherentes: nada de NaN, de infinitos ni de ceros donde no toca.
#
# Uso:
#   "$GODOT" --headless --path . --script scripts/driving_line_probe.gd
# ============================================================================

const TrackScript = preload("res://scripts/track_data.gd")
const LineScript = preload("res://scripts/driving_line.gd")

const TICKS := 120.0
const SPEEDS_KPH := [120.0, 160.0, 200.0, 250.0, 300.0]
const CORNER_PROMINENCE_KPH := 15.0      # cuánto tiene que bajar la ideal para ser "curva"
const CORNER_APART_M := 150.0            # separación mínima entre curvas contadas
const PLACE_MIN_M := 120.0               # colocación del coche antes de cada curva
const PLACE_MAX_M := 700.0
const CORNER_MIN_APPROACH_M := 60.0      # colocación mínima para juzgar una aproximación
const TOLERANCE_RATIO := 0.05            # 5 % en la distancia de frenada
const BRAKING_MIN_M := 10.0              # por debajo de esto no hay frenada que medir
const BRAKING_MIN_CASES := 5             # casos obligatorios de frenada que medir
const MANEUVERS_MIN := 4                 # frenadas obligatorias dentro de la vuelta
const IDEAL_OVERSHOOT_MPS := 0.5         # la vuelta conducida no supera la ideal
const GRIP_TOLERANCE := 1.02             # 2 % de holgura sobre la capacidad medida
const RED_SEARCH_M := 400.0              # hasta dónde se busca el inicio del tramo rojo
const DRIVER_LOOKAHEAD_M := 8.0          # lo que mira por delante el conductor de la sonda
const YELLOW_GAIN := 2.0                 # 1/s: cuánto corrige al levantar el pie (proporcional)
const SCAN_M := 900.0                    # hasta dónde se sigue la banda y la curva que manda
const MANEUVER_BRAKE_RATIO := 0.99       # se considera frenada de verdad la de referencia

var linea = null
var points := PackedVector3Array()
var errores: Array[String] = []
var lineas_ok: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	points = TrackScript.get_centerline()
	linea = MeshInstance3D.new()
	linea.set_script(LineScript)
	linea.turn_median_half_window = 2
	linea.min_turn_deg_per_m = 0.02
	linea.construir(points)
	var count: int = points.size()

	_perfil(count)
	_envolventes(count)
	var curvas := _curvas(count)
	print("LINEA curvas significativas=%d índices=%s" % [curvas.size(), str(_indices(curvas))])
	_puntos_de_frenada(curvas)
	_monotonia(count)
	_continuidad(count)
	_extremos(count)
	_transiciones(count)
	_vuelta_conducida(count)
	_geometria(count)

	for texto in lineas_ok:
		print("LINEA PASS ", texto)
	for texto in errores:
		print("LINEA FAIL ", texto)
	print("LINEA %s comprobaciones=%d fallos=%d" % ["PASS" if errores.is_empty() else "FAIL",
		lineas_ok.size(), errores.size()])
	quit(1 if not errores.is_empty() else 0)

func ok(texto: String) -> void:
	lineas_ok.append(texto)

func fail(texto: String) -> void:
	errores.append(texto)

func _check(condition: bool, texto: String) -> void:
	if condition:
		ok(texto)
	else:
		fail(texto)

func _indices(curvas: Array) -> Array:
	var salida: Array = []
	for curva in curvas:
		salida.append(curva["indice"])
	return salida

# --- 1. velocidad ideal -------------------------------------------------------

func _perfil(count: int) -> void:
	var ideal: PackedFloat32Array = linea.speed_ideal
	var minimo := INF
	var maximo := -INF
	var total := 0.0
	var indice_minimo := 0
	var peor_agarre := 0.0
	var peor_en := 0
	for i in count:
		var v: float = ideal[i]
		if not is_finite(v) or v <= 0.0:
			fail("velocidad ideal no finita en %d: %s" % [i, str(v)])
			return
		if v < minimo:
			minimo = v
			indice_minimo = i
		maximo = maxf(maximo, v)
		total += v
		var giro := deg_to_rad(maxf(float(linea.turn[i]), 0.0001))
		var g := v * v * giro / 9.81
		var capacidad: float = linea.capacidad_lateral(v) / 9.81
		var ratio := g / maxf(capacidad, 0.001)
		if ratio > peor_agarre:
			peor_agarre = ratio
			peor_en = i
	print("LINEA perfil puntos=%d ideal_min=%.1f km/h (índice %d) ideal_max=%.1f km/h ideal_media=%.1f km/h" % [
		count, minimo * 3.6, indice_minimo, maximo * 3.6, total / float(count) * 3.6])
	var margen: float = linea.lateral_safety
	_check(maximo <= linea.top_speed_mps + 1e-3,
		"ninguna velocidad ideal supera el tope declarado (máx %.1f km/h de %.1f)" % [maximo * 3.6, linea.top_speed_mps * 3.6])
	_check(peor_agarre <= margen + 0.02,
		"el agarre que pide la velocidad ideal no pasa del margen declarado (peor %.3f en el índice %d, margen %.2f)" % [peor_agarre, peor_en, margen])
	_check(minimo > 30.0 / 3.6,
		"ninguna velocidad ideal es absurdamente baja (mínima %.1f km/h)" % (minimo * 3.6))

# --- 2. envolventes -----------------------------------------------------------

func _envolventes(count: int) -> void:
	var hard: PackedFloat32Array = linea.envelope_hard
	var soft: PackedFloat32Array = linea.envelope_soft
	var rojo: PackedFloat32Array = linea.envelope_rojo
	var deceleration: float = linea.brake_reference_m_s2
	var a_roja: float = linea.deceleracion_del_rojo()
	var fallos_de_ideal := 0
	var fallos_de_orden := 0
	var fallos_de_freno := 0
	var fallos_de_rojo := 0
	var fallos_de_orden_rojo := 0
	var fallos_rojo_tarde := 0
	for i in count:
		if hard[i] > float(linea.speed_ideal[i]) + 1e-3:
			fallos_de_ideal += 1
		if soft[i] > hard[i] + 1e-3:
			fallos_de_orden += 1
		if rojo[i] > hard[i] + 1e-3:
			fallos_rojo_tarde += 1
		if soft[i] > rojo[i] + 1e-3:
			fallos_de_orden_rojo += 1
		var next := (i + 1) % count
		var step: float = float(linea.step_next[i])
		var reachable := sqrt(hard[next] * hard[next] + 2.0 * deceleration * step)
		if hard[i] > reachable + 1e-3:
			fallos_de_freno += 1
		var reachable_rojo := sqrt(rojo[next] * rojo[next] + 2.0 * a_roja * step)
		if rojo[i] > reachable_rojo + 1e-3:
			fallos_de_rojo += 1
	_check(fallos_de_ideal == 0,
		"las envolventes nunca pasan de la velocidad ideal (%d incumplimientos)" % fallos_de_ideal)
	_check(fallos_de_orden == 0,
		"la envolvente suave nunca pasa de la fuerte (%d incumplimientos)" % fallos_de_orden)
	_check(fallos_de_orden_rojo == 0,
		"la envolvente del rojo nunca baja de la cómoda (%d incumplimientos)" % fallos_de_orden_rojo)
	_check(fallos_rojo_tarde == 0,
		"el aviso rojo nunca llega más tarde que la frenada de la física (%.1f m/s²): %d incumplimientos" % [deceleration, fallos_rojo_tarde])
	_check(fallos_de_freno == 0,
		"la envolvente fuerte es realizable punto a punto con %.1f m/s² (%d incumplimientos)" % [deceleration, fallos_de_freno])
	_check(fallos_de_rojo == 0,
		"la envolvente del rojo es realizable punto a punto con los %.1f m/s² de su antelación (%d incumplimientos)" % [a_roja, fallos_de_rojo])

# --- 3. curvas y puntos de frenada --------------------------------------------

# Mínimos locales de la velocidad ideal con prominencia suficiente, separados entre sí:
# son las curvas que obligan a frenar.
func _curvas(count: int) -> Array:
	var ideal: PackedFloat32Array = linea.speed_ideal
	var minimos: Array = []
	var i := 0
	while i < count:
		var v := ideal[i]
		var es_minimo := true
		for offset in range(-8, 9):
			if offset == 0:
				continue
			if ideal[(i + offset + count) % count] < v:
				es_minimo = false
				break
		if es_minimo:
			minimos.append(i)
		i += 4
	var curvas: Array = []
	for indice in minimos:
		var alto := _maximo_cerca(ideal, indice, count, 220.0)
		if alto * 3.6 - float(ideal[indice]) * 3.6 < CORNER_PROMINENCE_KPH:
			continue
		var aceptada := true
		for otra in curvas:
			if _distancia_arco(int(indice), int(otra["indice"])) < CORNER_APART_M:
				if float(ideal[indice]) < float(ideal[otra["indice"]]):
					otra["indice"] = indice
					otra["ideal"] = float(ideal[indice])
				aceptada = false
				break
		if aceptada:
			curvas.append({"indice": indice, "ideal": float(ideal[indice])})
	return curvas

func _maximo_cerca(ideal: PackedFloat32Array, indice: int, count: int, metres: float) -> float:
	var pasos := int(maxf(1.0, metres / float(linea.step_m)))
	var maximo := 0.0
	for offset in range(-pasos, pasos + 1):
		maximo = maxf(maximo, float(ideal[(indice + offset + count) % count]))
	return maximo

func _distancia_arco(a: int, b: int) -> float:
	var largo: float = linea.track_length
	var d: float = absf(float(linea.arc[a]) - float(linea.arc[b]))
	return minf(d, largo - d)

# La estación más rápida entre `PLACE_MIN_M` y `PLACE_MAX_M` metros antes de la curva: es
# donde un coche llegaría lanzado, así que es donde tiene sentido medir la frenada.
func _colocacion(indice: int) -> int:
	var count: int = points.size()
	var mejor := indice
	var mejor_ideal := -1.0
	var recorrido := 0.0
	var i := indice
	while recorrido < PLACE_MAX_M:
		var anterior := (i - 1 + count) % count
		recorrido += float(linea.step_next[anterior])
		i = anterior
		if recorrido < PLACE_MIN_M:
			continue
		if float(linea.speed_ideal[i]) > mejor_ideal:
			mejor_ideal = float(linea.speed_ideal[i])
			mejor = i
	return mejor

# La curva que manda por delante de `desde_ds`: el mínimo de
# v_ideal(s + ds)² + 2·a·ds. Su `ds` es la distancia a la curva que obliga a frenar y su
# `ideal` la velocidad de ese vértice; si el mínimo cae en el propio `desde_ds` es que la
# envolvente no está limitada por ninguna curva de delante, sino por el límite del tramo.
func _curva_que_manda(car_s: float, desde_ds: float, hasta_ds: float, deceleration: float) -> Dictionary:
	var mejor := INF
	var mejor_ds := desde_ds
	var mejor_ideal: float = linea.limite_en(linea.speed_ideal, car_s, desde_ds)
	var ds := desde_ds
	while ds <= hasta_ds:
		var ideal: float = linea.limite_en(linea.speed_ideal, car_s, ds)
		var valor := ideal * ideal + 2.0 * deceleration * ds
		if valor < mejor:
			mejor = valor
			mejor_ds = ds
			mejor_ideal = ideal
		ds += 0.5
	return {"ds": mejor_ds, "ideal": mejor_ideal}

func _puntos_de_frenada(curvas: Array) -> void:
	var a_freno: float = linea.brake_reference_m_s2
	var a_roja: float = linea.deceleracion_del_rojo()
	var paso: float = float(linea.step_m)
	var casos := 0
	var sin_rojo := 0
	var sin_amarillo := 0
	var amarillo_tarde := 0
	var margen_fuera := 0
	var casos_incomodos := 0
	var frenadas_cortas := 0
	var avisos_tarde := 0
	var pide_de_mas := 0
	var sin_amarillo_estrecho := 0
	var peor_desviacion := 0.0
	var tolerancia_del_peor := 0.0
	var peor_texto := ""
	for curva in curvas:
		var indice: int = curva["indice"]
		var colocacion := _colocacion(indice)
		var ideal_colocacion: float = linea.speed_ideal[colocacion]
		var s_car := float(linea.arc[colocacion])
		var d_curva := _distancia_arco(colocacion, indice)
		if d_curva < CORNER_MIN_APPROACH_M:
			continue
		for kph in SPEEDS_KPH:
			# Sólo se prueba por debajo de la ideal del punto de colocación: así el rojo
			# no puede venir de "ir por encima de la ideal", sino de la frenada.
			var v := minf(float(kph) / 3.6, ideal_colocacion * 0.95)
			if v <= 20.0:
				continue
			# Sólo cuentan las aproximaciones en las que HAY que frenar de verdad: si la
			# curva que manda por delante del coche está más cerca que una frenada, lo que
			# salga no es una frenada sino ir por encima del límite del propio tramo.
			var mando_del_coche := _curva_que_manda(s_car, 0.0, SCAN_M, a_freno)
			if float(mando_del_coche["ds"]) < BRAKING_MIN_M:
				continue
			# Sólo cuentan los casos que empiezan cómodos: si el coche ya está por encima
			# de la envolvente suave en su propio punto, el estado cercano es rojo por
			# definición y la secuencia verde→amarillo→rojo no aplica (se informa aparte).
			var comodo: bool = v <= linea.limite_en(linea.envelope_soft, s_car, 0.0) - 1e-6
			var ds_rojo := -1.0
			var ds_amarillo := -1.0
			# Paso fino (0,1 m): la banda amarilla puede ser estrecha donde la envolvente va
			# pegada a la velocidad ideal, y con 0,5 m se quedaba entre dos muestras.
			var ds := 0.0
			while ds <= SCAN_M:
				var estado: float = linea.verdict(v, s_car, ds)
				if estado <= -0.5 and ds_rojo < 0.0:
					ds_rojo = ds
				# El amarillo se busca SÓLO antes del rojo: el amarillo que reaparece a la
				# salida del vértice es otra cosa ("ya puedes acelerar") y no cuenta como
				# aviso de la frenada.
				if ds_rojo < 0.0 and absf(estado) <= 0.4 and ds_amarillo < 0.0:
					ds_amarillo = ds
				ds += 0.1
			if ds_rojo < 0.0:
				sin_rojo += 1
				print("LINEA DIAG sin_rojo curva=%d colocacion=%d velocidad=%.0f km/h" % [indice, colocacion, v * 3.6])
				continue
			if not comodo:
				casos_incomodos += 1
				continue
			if ds_amarillo < 0.0:
				# Sin amarillo delante del rojo: si la banda amarilla de ESE punto es más
				# estrecha que 1 km/h, no hay color que enseñar (la envolvente va pegada a la
				# velocidad ideal del propio tramo) y eso no es un defecto del aviso. Si la
				# banda tenía sitio, sí lo es.
				var estrecha := float(linea.limite_en(linea.envelope_rojo, s_car, ds_rojo)) \
					- float(linea.limite_en(linea.envelope_soft, s_car, ds_rojo))
				if estrecha <= 1.0 / 3.6:
					sin_amarillo_estrecho += 1
					print("LINEA DIAG sin_amarillo_estrecho curva=%d colocacion=%d velocidad=%.0f km/h d_rojo=%.1f m banda=%.2f m/s" % [
						indice, colocacion, v * 3.6, ds_rojo, estrecha])
				else:
					sin_amarillo += 1
					print("LINEA DIAG sin_amarillo curva=%d colocacion=%d velocidad=%.0f km/h d_rojo=%.1f m banda=%.2f m/s" % [
						indice, colocacion, v * 3.6, ds_rojo, estrecha])
				continue
			if ds_amarillo > ds_rojo:
				amarillo_tarde += 1
			# La curva que manda, buscada desde el INICIO DEL ROJO. Si el mínimo cae en el
			# propio inicio del rojo (distancia 0) es que el rojo no sale de una frenada
			# que venga de lejos, sino de ir por encima del límite de ese tramo.
			var mando := _curva_que_manda(s_car, ds_rojo, ds_rojo + SCAN_M, a_freno)
			var v_curva: float = mando["ideal"]
			var distancia := float(mando["ds"]) - ds_rojo
			# La distancia de frenada con la ANTELACIÓN declarada es la referencia contra la
			# que se mide dónde empieza el rojo; la de la física (a_freno) es el límite por el
			# que el aviso no puede quedarse corto.
			var esperada := (v * v - v_curva * v_curva) / (2.0 * a_freno)
			var esperada_roja := (v * v - v_curva * v_curva) / (2.0 * maxf(a_roja, 0.001))
			var margen_s := (ds_rojo - ds_amarillo) / maxf(v, 1.0)
			var necesaria := (v * v - v_curva * v_curva) / (2.0 * maxf(distancia, 0.5))
			print("LINEA FRENADA curva=%d colocación=%d vértice=%.1f km/h velocidad=%.0f km/h d_rojo=%.0f m d_amarillo=%.0f m margen=%.2f s frenada_medida=%.1f m frenada_de_la_física=%.1f m frenada_con_antelación=%.1f m pide_frenar=%.1f m/s² tipo=%s" % [
				indice, colocacion, v_curva * 3.6, v * 3.6, ds_rojo, ds_amarillo, margen_s,
				distancia, esperada, esperada_roja, necesaria, "frenada" if distancia >= BRAKING_MIN_M else "límite_del_tramo"])
			if distancia < BRAKING_MIN_M:
				frenadas_cortas += 1
				continue
			# Tolerancia: el 5 % de la frenada con antelación, y nunca menos de un paso de la
			# trazada, que es la resolución con la que se puede decir dónde empieza un tramo.
			var tolerancia := maxf(TOLERANCE_RATIO * esperada_roja, paso)
			casos += 1
			if margen_s < 0.08 or margen_s > 2.20:
				margen_fuera += 1
			# "Tarde" = el rojo empieza más cerca de la curva que la distancia de frenada de
			# la física: quien frenase al verlo no llegaría.
			if distancia < esperada - tolerancia:
				avisos_tarde += 1
			# Y "pide de más" = la deceleración que exigiría frenar desde el inicio del rojo
			# supera la capacidad de referencia del coche.
			if necesaria > a_freno * 1.02:
				pide_de_mas += 1
			if absf(distancia - esperada_roja) > peor_desviacion:
				peor_desviacion = absf(distancia - esperada_roja)
				tolerancia_del_peor = tolerancia
				peor_texto = "curva %d a %.0f km/h: el rojo empieza a %.0f m, la física pide %.0f m y con la antelación declarada %.0f m" % [
					indice, kph, distancia, esperada, esperada_roja]
	_check(casos > BRAKING_MIN_CASES, "hay casos de frenada que medir (%d, más %d de frenada corta descartados)" % [casos, frenadas_cortas])
	_check(sin_rojo == 0, "toda aproximación más rápida que su curva tiene tramo rojo (%d sin él)" % sin_rojo)
	_check(sin_amarillo == 0, "toda aproximación más rápida que su curva tiene tramo amarillo donde la banda tiene sitio (%d sin él, %d descartados por banda < 1 km/h)" % [sin_amarillo, sin_amarillo_estrecho])
	_check(amarillo_tarde == 0, "el amarillo aparece siempre ANTES del rojo (%d en contra)" % amarillo_tarde)
	_check(margen_fuera == 0, "el margen del amarillo está en un rango razonable (%d de %d fuera de 0,08-2,20 s)" % [margen_fuera, casos])
	_check(avisos_tarde == 0,
		"el tramo rojo nunca empieza más cerca de la curva que la distancia de frenada de la física "
		+ "(%.1f m/s²): %d avisos tarde" % [a_freno, avisos_tarde])
	_check(pide_de_mas == 0,
		"frenar al ver el rojo no pide más deceleración que la de referencia (%.2f m/s²): %d casos" % [a_freno, pide_de_mas])
	print("LINEA FRENADA resumen casos=%d incomodos_aparte=%d sin_rojo=%d sin_amarillo=%d tarde=%d pide_de_mas=%d antelacion=%.0f %% a_roja=%.1f m/s²" % [casos, casos_incomodos, sin_rojo, sin_amarillo, avisos_tarde, pide_de_mas, float(linea.frenada_antelacion) * 100.0, a_roja])
	_check(peor_desviacion <= tolerancia_del_peor,
		"el tramo rojo empieza a la distancia de frenada CON la antelación declarada (peor caso: %.1f m de desviación con %.1f m de tolerancia, %s)" % [
			peor_desviacion, tolerancia_del_peor, peor_texto])

# --- 4. monotonía con la velocidad (antiparpadeo) ------------------------------

func _monotonia(count: int) -> void:
	var violaciones := 0
	var peor := ""
	var estaciones := [0, 300, 900, 1500, 2100, 2306, 2700, 3000]
	for estacion in estaciones:
		var s_car := float(linea.arc[estacion])
		for ds in [10.0, 40.0, 90.0, 160.0, 240.0]:
			var anterior := 2.0
			var v := 8.0
			while v <= 100.0:
				var estado: float = linea.verdict(v, s_car, ds)
				if estado > anterior + 1e-6:
					violaciones += 1
					peor = "estación %d a %.0f m: %.0f km/h" % [estacion, ds, v * 3.6]
					break
				anterior = estado
				v += 0.5
	_check(violaciones == 0,
		"el estado no retrocede al subir la velocidad (0 violaciones esperadas; %d%s)" % [
			violaciones, "" if peor == "" else ", p. ej. " + peor])

# --- 4b. continuidad de los estados a lo largo de la línea ----------------------

# Muestra a muestra (0,5 m) sobre la ventana visible, se cuentan los saltos DIRECTOS de
# verde a rojo. Sólo cuentan como fallo los que ocurren donde la banda amarilla TENDRÍA
# sitio: si en ese punto la envolvente del rojo y la cómoda valen lo mismo, no existe
# ninguna velocidad que caiga entre las dos y el amarillo no puede dibujarse ahí (es el
# caso de ir por encima del límite del propio tramo, donde la recomendación es roja por
# definición). Se recorren estaciones de toda la vuelta y varios múltiplos de la
# velocidad ideal del propio punto.
func _continuidad(count: int) -> void:
	var saltos := 0
	var sin_sitio := 0
	var transiciones := 0
	var texto := ""
	# Sólo la ventana que se DIBUJA: más allá de `visible_window_m` la línea no llega a la
	# pantalla (el shader la descarta) y lo que pase allí no lo ve nadie.
	var limite_ds := float(linea.visible_window_m)
	for estacion in range(0, count, 37):
		var s_car := float(linea.arc[estacion])
		for factor in [1.0, 1.15, 1.35, 1.6, 2.0]:
			var speed: float = maxf(float(linea.limite_en(linea.speed_ideal, s_car, 0.0)) * float(factor), 6.0)
			var anterior := 2.0
			var ds := 0.0
			while ds <= limite_ds:
				var estado: float = linea.verdict(speed, s_car, ds)
				if estado != anterior:
					transiciones += 1
					if anterior == 1.0 and estado == -1.0:
						var suave := float(linea.limite_en(linea.envelope_soft, s_car, ds))
						var roja := float(linea.limite_en(linea.envelope_rojo, s_car, ds))
						if roja - suave > 1.0 / 3.6:
							saltos += 1
							if texto == "":
								texto = "estación %d a %.0f km/h, en ds=%.1f m (cómoda %.1f m/s, roja %.1f m/s)" % [
									estacion, speed * 3.6, ds, suave, roja]
						else:
							sin_sitio += 1
					anterior = estado
				ds += 0.25
	_check(saltos == 0,
		"dentro de la ventana dibujada no hay saltos de verde a rojo donde quepa el amarillo "
		+ "(%d de %d transiciones, más %d con la banda amarilla por debajo de 1 km/h%s)" % [
			saltos, transiciones, sin_sitio, "" if texto == "" else ", p. ej. " + texto])

# --- 4c. extremos: bordes de la pista y velocidades imposibles ------------------

# La tabla de arcos tiene que ser finita, creciente y sin tramos nulos, y el veredicto y
# las tres envolventes tienen que seguir siendo finitos y positivos en los bordes de la
# vuelta (arco 0, media vuelta, último punto, justo por encima del cierre) y con los `ds`
# que se salen de la vuelta por los dos lados (la cola por detrás del coche y una ventana
# mayor que la vuelta). Y en las velocidades extremas el veredicto tiene que ser el que
# toca: parado, verde en todas partes; a 720 km/h, rojo en el propio punto.
func _extremos(count: int) -> void:
	_check(float(linea.track_length) > 4000.0 and float(linea.track_length) < 5200.0,
		"la longitud de la vuelta es la del circuito (%.1f m)" % float(linea.track_length))
	var malos := 0
	var arco := -1.0
	for i in count:
		if not is_finite(float(linea.arc[i])) or float(linea.arc[i]) < arco - 1e-6:
			malos += 1
		arco = float(linea.arc[i])
		if not is_finite(float(linea.step_next[i])) or float(linea.step_next[i]) <= 0.0:
			malos += 1
	_check(malos == 0,
		"la tabla de arcos es finita y creciente y ningún tramo mide cero (%d fallos)" % malos)
	var largo := float(linea.track_length)
	var bordes := [0.0, largo * 0.5, largo - 0.5, largo - 1e-3, largo, -1e-3]
	var malos_veredicto := 0
	var malos_envolvente := 0
	var texto := ""
	var verdes_a_cero := 0
	var rojos_a_tope := 0
	var casos_cero := 0
	var casos_tope := 0
	for s_car in bordes:
		for ds in [-float(linea.visible_tail_m), 0.0, 1e-6, largo - 1.0, largo, largo + 10.0, float(linea.visible_window_m)]:
			for speed in [0.0, 6.0, 83.333, 200.0]:
				var estado: float = linea.verdict(speed, s_car, ds)
				if not is_finite(estado) or (absf(estado) != 1.0 and estado != 0.0):
					malos_veredicto += 1
				if speed == 0.0:
					casos_cero += 1
					if estado >= 0.5:
						verdes_a_cero += 1
				if speed == 200.0:
					casos_tope += 1
					if estado <= -0.5:
						rojos_a_tope += 1
				for envolvente in [linea.envelope_rojo, linea.envelope_hard, linea.envelope_soft]:
					var limite: float = linea.limite_en(envolvente, s_car, ds)
					if not is_finite(limite) or limite <= 0.0:
						malos_envolvente += 1
						if texto == "":
							texto = "s_car=%.1f ds=%.1f → %s" % [s_car, ds, str(limite)]
	_check(malos_veredicto == 0,
		"en los bordes de la vuelta el veredicto sigue siendo verde, amarillo o rojo (%d fallos)" % malos_veredicto)
	_check(malos_envolvente == 0,
		"en los bordes de la vuelta las tres envolventes siguen siendo finitas y positivas (%d fallos%s)" % [
			malos_envolvente, "" if texto == "" else ", p. ej. " + texto])
	_check(verdes_a_cero == casos_cero,
		"parado, la línea recomienda acelerar en todos los puntos (%d de %d)" % [verdes_a_cero, casos_cero])
	_check(rojos_a_tope == casos_tope,
		"a 720 km/h, la línea recomienda frenar en todos los puntos (%d de %d)" % [rojos_a_tope, casos_tope])

# --- 4d. el perfil dibujado no tiene escalones de color -------------------------

# Lo que de verdad se ve es la TEXTURA de estado, texel a texel. Se pide a la propia línea
# el perfil que escribe (`perfil_de_colores`, la misma función que usa `actualizar_estado`)
# para estaciones y velocidades de toda la vuelta y se comprueban dos cosas:
#  * que dos texeles vecinos nunca salten del color de acelerar al de frenar sin texeles de
#    mezcla en medio: es lo que garantiza el suavizado a lo largo de la línea, y lo que se
#    rompería si alguien lo quitara o lo dejara más corto que una banda;
#  * que el escalón más grande entre texeles vecinos se queda en una fracción pequeña de
#    la distancia entre colores (un quinto), es decir, que ningún borde de banda se ve
#    como un corte.
func _transiciones(count: int) -> void:
	var saltos := 0
	var peor := 0.0
	var peor_fraccion := 0.0
	var mezclas := 0
	var peor_texto := ""
	var distancia_entre_colores := 0.0
	var paleta := [linea._color_accelerate_linear, linea._color_hold_linear, linea._color_brake_linear]
	for i in paleta.size():
		for j in range(i + 1, paleta.size()):
			distancia_entre_colores = maxf(distancia_entre_colores, (paleta[i] - paleta[j]).length())
	for estacion in range(0, count, 41):
		var s_car := float(linea.arc[estacion])
		for factor in [0.7, 1.0, 1.2, 1.5]:
			var speed: float = maxf(float(linea.limite_en(linea.speed_ideal, s_car, 0.0)) * float(factor), 5.0)
			var perfil: Dictionary = linea.perfil_de_colores(speed, s_car)
			var colores: PackedVector3Array = perfil["colores"]
			if colores.size() < 8:
				continue
			for k in colores.size() - 1:
				var paso := (colores[k + 1] - colores[k]).length()
				if paso > peor:
					peor = paso
					peor_fraccion = paso / maxf(distancia_entre_colores, 0.0001)
					peor_texto = "estación %d a %.0f km/h, texel %d del perfil" % [estacion, speed * 3.6, k]
				var a: Vector3 = colores[k]
				var b: Vector3 = colores[k + 1]
				var es_verde := a.distance_to(paleta[0]) < 1e-5 or b.distance_to(paleta[0]) < 1e-5
				var es_rojo := a.distance_to(paleta[2]) < 1e-5 or b.distance_to(paleta[2]) < 1e-5
				if es_verde and es_rojo:
					saltos += 1
				if a.distance_to(paleta[0]) >= 1e-5 and a.distance_to(paleta[2]) >= 1e-5:
					mezclas += 1
	_check(saltos == 0,
		"el perfil dibujado no tiene ningún salto de un texel verde a uno rojo: siempre hay mezcla en medio (%d saltos)" % saltos)
	_check(mezclas > 0, "el perfil dibujado tiene texeles de mezcla entre colores (%d)" % mezclas)
	# Criterio: un cuarto de la distancia más grande entre los tres colores. Es la cuenta
	# del propio suavizado: un filtro de `2·half+1` = 7 texeles no puede dar un escalón
	# mayor que la distancia entre colores partido por el tamaño de su ventana, y en los
	# extremos del perfil —donde la ventana se recorta a 4— el tope sube a 1/4. Medido, el
	# peor escalón es exactamente ése (0,200 en el último texel del perfil). Un borde duro
	# —sin suavizado— daría 1,000, así que la prueba tiene dientes: si alguien quitara el
	# suavizado (`color_smooth_texels = 0`), este criterio lo caza.
	_check(peor_fraccion <= 0.25,
		"el escalón más grande entre texeles vecinos es una fracción pequeña de la distancia entre colores "
		+ "(%.3f del máximo %.1f, en %s)" % [peor_fraccion, distancia_entre_colores, peor_texto])

# --- 5. prueba funcional: una vuelta conducida con la línea --------------------

func _vuelta_conducida(count: int) -> void:
	var resultado := _conducir(true)
	var control := _conducir(false)
	print("LINEA VUELTA exceso_en=%d velocidad=%.1f km/h ideal=%.1f km/h" % [
		resultado["exceso_en"], resultado["exceso_velocidad"] * 3.6, resultado["exceso_ideal"] * 3.6])
	print("LINEA VUELTA tiempo=%.1f s velocidad_max=%.1f km/h exceso_sobre_ideal_max=%.2f m/s agarre_max=%.2f g frenada_max=%.1f m/s² tramos_rojos=%d tics_verde=%d tics_amarillo=%d tics_rojo=%d" % [
		resultado["tiempo"], resultado["velocidad_max"] * 3.6, resultado["exceso"], resultado["agarre"],
		resultado["frenada"], resultado["rojos"], resultado["verde"], resultado["amarillo"], resultado["rojo"]])
	print("LINEA VUELTA_CONTROL (sin mirar la línea) exceso_sobre_ideal_max=%.1f m/s agarre_max=%.2f g" % [
		control["exceso"], control["agarre"]])
	_check(resultado["completa"], "la vuelta conducida sólo con la línea se completa (%.1f s)" % resultado["tiempo"])
	_check(resultado["exceso"] <= IDEAL_OVERSHOOT_MPS,
		"conduciendo con la línea no se supera la velocidad ideal (exceso máximo %.2f m/s)" % resultado["exceso"])
	var capacidad_maxima: float = linea.capacidad_lateral(resultado["velocidad_max"]) / 9.81
	_check(resultado["agarre"] <= capacidad_maxima * GRIP_TOLERANCE,
		"conduciendo con la línea no se pisa más agarre del medido (%.2f g de %.2f g)" % [resultado["agarre"], capacidad_maxima])
	_check(resultado["frenada"] <= float(linea.brake_reference_m_s2) * 1.02,
		"la frenada que pide la línea no pasa de la referencia (%.1f m/s² de %.1f)" % [resultado["frenada"], linea.brake_reference_m_s2])
	_check(control["agarre"] > capacidad_maxima,
		"el control negativo sin mirar la línea sí se sale del agarre (%.2f g de %.2f g): la prueba tiene dientes" % [control["agarre"], capacidad_maxima])
	# Cada frenada de la vuelta: la línea tiene que haberla anunciado antes (tramo rojo por
	# delante en el momento de pisar el freno) y a una distancia entre la de frenada de
	# referencia y la cómoda: ni tarde (no se llega) ni absurdamente pronto.
	var paso: float = float(linea.step_m)
	var eventos: Array = resultado["frenadas"]
	var anunciadas := 0
	var tardias := 0
	var tempranas := 0
	var peor := 0.0
	var peor_texto := ""
	for evento in eventos:
		var v: float = evento["velocidad"]
		var esperada: float = evento["esperada"]
		var esperada_roja: float = evento["esperada_roja"]
		var comoda: float = evento["comoda"]
		var distancia: float = evento["distancia"]
		var tolerancia := maxf(TOLERANCE_RATIO * esperada, paso)
		print("LINEA FRENADA_VUELTA índice=%d velocidad=%.1f km/h vértice=%.1f km/h distancia=%.0f m frenada_de_la_física=%.0f m frenada_con_antelación=%.0f m cómoda=%.0f m rojo_por_delante=%.0f m pide_frenar=%.1f m/s²" % [
			evento["indice"], v * 3.6, float(evento["ideal_curva"]) * 3.6, distancia, esperada, esperada_roja, comoda,
			float(evento["banda"]), float(evento["pide_frenar"])])
		if float(evento["banda"]) < 0.0:
			continue
		anunciadas += 1
		if distancia < esperada - tolerancia:
			tardias += 1
		# El conductor de la sonda pisa el freno en cuanto la banda roja entra en lo que
		# mira por delante, así que lo más pronto que puede empezar una frenada es
		# `DRIVER_LOOKAHEAD_M` metros antes del inicio del rojo CON la antelación declarada.
		if distancia > esperada_roja + DRIVER_LOOKAHEAD_M + tolerancia:
			tempranas += 1
		var desviacion := absf(distancia - esperada_roja)
		if desviacion > peor:
			peor = desviacion
			peor_texto = "índice %d a %.1f km/h: %.0f m medidos contra %.0f m con antelación (%.0f m de la física)" % [
				evento["indice"], v * 3.6, distancia, esperada_roja, esperada]
	_check(eventos.size() >= MANEUVERS_MIN,
		"la vuelta registra frenadas que medir (%d)" % eventos.size())
	_check(anunciadas == eventos.size(),
		"toda frenada de la vuelta estaba anunciada por el tramo rojo antes de pisar el freno (%d de %d)" % [anunciadas, eventos.size()])
	_check(tardias == 0,
		"ninguna frenada de la vuelta empieza más tarde de la distancia de frenada de la física (%d tarde)" % tardias)
	_check(tempranas == 0,
		"ninguna frenada empieza antes del inicio del rojo con la antelación declarada más lo que mira el conductor (%d tempranas)" % tempranas)
	print("LINEA FRENADA_VUELTA resumen frenadas=%d anunciadas=%d peor_desviacion=%.1f m (%s)" % [
		eventos.size(), anunciadas, peor, peor_texto])
	_check(resultado["rojos"] > 0, "la vuelta con la línea produce tramos rojos (%d)" % resultado["rojos"])
	_check(resultado["verde"] > 0 and resultado["amarillo"] > 0,
		"la vuelta con la línea pasa por los tres estados (verde %d, amarillo %d, rojo %d tics)" % [
			resultado["verde"], resultado["amarillo"], resultado["rojo"]])

# Conductor de prueba: un punto material que recorre la trazada. Con `mirando` frena
# cuando el tramo cercano está rojo, levanta el pie cuando está amarillo y acelera cuando
# está verde, con histéresis (una vez que frena, sigue frenando hasta la velocidad
# cómoda). Sin mirar, acelera siempre: control negativo.
func _conducir(mirando: bool) -> Dictionary:
	var largo: float = linea.track_length
	var a_freno: float = linea.brake_reference_m_s2
	var a_acelerar: float = float(linea.accel_m_s2)
	var dt := 1.0 / TICKS
	var s := 0.0
	var v := 30.0
	var t := 0.0
	var vuelta := 0.0
	var exceso := 0.0
	var agarre := 0.0
	var frenada := 0.0
	var velocidad_max := 0.0
	var rojos := 0
	var tics := [0, 0, 0]
	var exceso_en := -1
	var exceso_velocidad := 0.0
	var exceso_ideal := 0.0
	var frenando := false
	var en_rojo := false
	var completas := false
	var frenadas: Array = []
	var frenada_en_curso := false
	while t < 600.0:
		var a := -0.5
		if mirando:
			var rojo := false
			for ds in [0.0, 4.0, DRIVER_LOOKAHEAD_M]:
				if linea.verdict(v, s, ds) <= -0.5:
					rojo = true
					break
			# Se frena mientras la línea diga que hay que frenar por delante, y se deja de
			# frenar cuando deja de decirlo: es lo que hace quien mira la línea. Cancelar
			# la frenada en cuanto el coche baja del límite de su propio punto dejaba sin
			# frenar justo donde la banda de delante ya está en rojo (medido: 1,16 m/s de
			# exceso sobre el plan en el vértice siguiente).
			frenando = rojo
			if frenando:
				a = -a_freno
			elif linea.verdict(v, s, 0.0) < 0.5:
				# En amarillo el conductor de referencia levanta el pie y MODULA: baja al ritmo
				# cómodo —el del que está hecha la banda— y cierra lo que le sobra con un término
				# proporcional, que es lo que hace quien conduce cuando ve que se queda largo. Sin
				# ese término la sonda mediría el propio escalón del plan (los 1,51 m de la
				# trazada) en vez de la recomendación.
				var plan: float = linea.limite_en(linea.envelope_soft, s, 0.0)
				a = -clampf(linea.deceleracion_comoda() + (v - plan) * YELLOW_GAIN, 0.0, a_freno)
			else:
				a = a_acelerar
		else:
			a = a_acelerar
		# Maniobra de frenada: el momento en que se pisa el freno de verdad después de no
		# estar frenando. Ahí se mide lo que la línea tenía que haber avisado.
		var frenando_ahora := mirando and a <= -a_freno * MANEUVER_BRAKE_RATIO
		if frenando_ahora and not frenada_en_curso:
			var mando := _curva_que_manda(s, 0.0, PLACE_MAX_M + 200.0, a_freno)
			var distancia: float = float(mando["ds"])
			if distancia >= BRAKING_MIN_M:
				var v_curva: float = mando["ideal"]
				frenadas.append({
					"indice": int(linea._indice_de_arco(s)),
					"velocidad": v,
					"ideal_curva": v_curva,
					"distancia": distancia,
					"esperada": (v * v - v_curva * v_curva) / (2.0 * a_freno),
					"esperada_roja": (v * v - v_curva * v_curva) / (2.0 * linea.deceleracion_del_rojo()),
					"comoda": (v * v - v_curva * v_curva) / (2.0 * linea.deceleracion_comoda()),
					"banda": _inicio_del_rojo(s, v),
					"pide_frenar": (v * v - v_curva * v_curva) / (2.0 * maxf(distancia, 0.5)),
				})
		frenada_en_curso = frenando_ahora
		var v_nueva := maxf(8.0, v + a * dt)
		frenada = maxf(frenada, (v - v_nueva) / dt)
		v = v_nueva
		s = fposmod(s + v * dt, largo)
		vuelta += v * dt
		t += dt
		velocidad_max = maxf(velocidad_max, v)
		var indice: int = int(linea._indice_de_arco(s))
		# El exceso se mide contra la velocidad ideal EN LA ESTACIÓN DEL COCHE, interpolada
		# como la dibuja la línea: tomar el valor del punto más cercano de la trazada metía
		# en la medida el escalón de 1,51 m de la propia malla (0,75 m/s de un punto al
		# siguiente en la entrada de un vértice).
		var exceso_aqui: float = v - linea.limite_en(linea.speed_ideal, s, 0.0)
		if exceso_aqui > exceso:
			exceso = exceso_aqui
			exceso_en = indice
			exceso_velocidad = v
			exceso_ideal = float(linea.speed_ideal[indice])
		agarre = maxf(agarre, v * v * deg_to_rad(maxf(float(linea.turn[indice]), 0.0)) / 9.81)
		var estado: float = linea.verdict(v, s, 0.0)
		if estado <= -0.5:
			tics[2] += 1
		elif estado >= 0.5:
			tics[0] += 1
		else:
			tics[1] += 1
		if estado <= -0.5 and not en_rojo:
			rojos += 1
		en_rojo = estado <= -0.5
		if vuelta >= largo:
			completas = true
			break
	return {
		"tiempo": t,
		"completa": completas,
		"exceso": exceso,
		"exceso_en": exceso_en,
		"exceso_velocidad": exceso_velocidad,
		"exceso_ideal": exceso_ideal,
		"agarre": agarre,
		"frenada": frenada,
		"velocidad_max": velocidad_max,
		"rojos": rojos,
		"verde": tics[0],
		"amarillo": tics[1],
		"rojo": tics[2],
		"frenadas": frenadas,
	}

# Dónde empieza el tramo rojo por delante del coche, en metros. −1 si no hay ninguno.
func _inicio_del_rojo(car_s: float, speed: float) -> float:
	var ds := 0.0
	while ds <= RED_SEARCH_M:
		if linea.verdict(speed, car_s, ds) <= -0.5:
			return ds
		ds += 0.5
	return -1.0

# --- 6. geometría -------------------------------------------------------------

func _geometria(count: int) -> void:
	linea._construir_malla()
	var mesh: ArrayMesh = linea.mesh
	if mesh == null or mesh.get_surface_count() != 1:
		fail("el listón no tiene una sola superficie")
		return
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	_check(vertices.size() == count * 2,
		"el listón tiene dos vértices por punto de la trazada (%d de %d)" % [vertices.size(), count * 2])
	_check(indices.size() == (count - 1) * 6,
		"el listón tiene dos triángulos por tramo y no cierra la vuelta (%d índices)" % indices.size())
	var peor_ancho := 0.0
	var peor_alto := 0.0
	var peor_arco := 0.0
	for i in count:
		var centro := points[i]
		var izquierda := vertices[i * 2]
		var derecha := vertices[i * 2 + 1]
		peor_ancho = maxf(peor_ancho, absf((derecha - izquierda).length() * 0.5 - float(linea.line_half_width_m)))
		peor_alto = maxf(peor_alto, absf((izquierda + derecha).y * 0.5 - centro.y - float(linea.line_lift_m)))
		peor_arco = maxf(peor_arco, absf(uvs[i * 2].x - float(linea.arc[i])))
		peor_arco = maxf(peor_arco, absf(uvs[i * 2 + 1].x - float(linea.arc[i])))
	_check(peor_ancho < 0.001, "el ancho del listón es el declarado (%.4f m de error)" % peor_ancho)
	_check(peor_alto < 0.001, "el listón va a la altura declarada sobre la trazada (%.4f m de error)" % peor_alto)
	_check(peor_arco < 0.001, "la coordenada de arco viaja en la UV de cada vértice (%.4f m de error)" % peor_arco)
