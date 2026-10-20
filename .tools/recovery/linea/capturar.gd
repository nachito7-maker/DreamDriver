extends SceneTree

# ============================================================================
# Capturas de la línea de asistencia para medirla EN PÍXELES.
#
# La sonda `scripts/driving_line_probe.gd` comprueba las cuentas sin GPU; ésta
# monta la escena de carrera de verdad (con su cámara, su luz y su tonemap), la
# sitúa en los casos que pide el encargo y guarda, por caso, DOS fotogramas que
# son el mismo instante:
#
#   <caso>-linea.png   con la línea de asistencia dibujada
#   <caso>-base.png    con la línea de asistencia oculta
#
# La diferencia de las dos imágenes son los píxeles de la línea de asistencia (sin
# depender de ningún color), y la segunda sirve para medir aparte la goma de la
# trazada que trae el circuito: su neutralidad (nada de azul) y que es algo más
# oscura que el asfalto de al lado.
#
# Además guarda, POR CASO, tres capturas de REFERENCIA —la misma pose y la misma
# velocidad con la línea forzada a verde, amarillo y rojo—: son los tres colores tal
# y como los pinta el motor ahí mismo (luz y tonemap incluidos), que es contra lo que
# hay que clasificar los píxeles de ese caso. La exposición no es igual en todas las
# poses (medido: el verde de la recta sale (31,96,41) y el rojo de la horquilla
# (2,84,12) sobre el mismo material), así que contrastar los píxeles de un caso
# contra una referencia tomada en otro sitio los clasificaba mal.
#
# Las estaciones y las velocidades de los casos NO están escritas a mano: salen de
# los datos de la propia línea (envolventes y veredicto) buscando, para cada
# patrón pedido, la estación que lo cumple Y cuya ventana se vea en pantalla (la
# línea puede cumplirse donde la trazada se sale del cuadro, p. ej. en una
# horquilla, y entonces no hay nada que medir). El registro que se guarda lleva, por
# caso, en qué punto de la pantalla cae cada estación de la ventana visible y qué
# estado dice la línea en ella: eso es lo que comprueba
# `.tools/recovery/linea/linea_pixeles.py` sobre los archivos.
#
# Necesita ventana (dibuja en un SubViewport de 2400x1080, el lienzo del teléfono).
#
# Uso:
#   "$GODOT" --path . --script .tools/recovery/linea/capturar.gd
#   "$GODOT" --path . --script .tools/recovery/linea/capturar.gd -- goma-como-antes
#
# La segunda forma es el ANTES de la goma (y de la línea): la escena se monta con
# `race.goma_sin_corregir` y con el material del GLB, así que las capturas se
# comparan con la misma cámara, la misma luz y la misma pose.
# ============================================================================

const TrackScript = preload("res://scripts/track_data.gd")

const OUT_DIR := "res://.tools/recovery/linea"
const SHOTS_DIR := "res://.tools/recovery/linea/disparos"
const FRAME_W := 2400
const FRAME_H := 1080
const TICKS := 120.0
const SAMPLE_STEP_M := 10.0              # paso con el que se muestrea la ventana visible
const SAMPLE_COUNT := 26                 # ds = 0, 10, ... 250 m
const OCCLUDED_DS_M := 10.0              # el coche tapa la línea más cerca que esto
# Hasta dónde la línea es MEDIBLE en píxeles: a más de esto, el listón de 0,46 m proyecta
# menos de un píxel y el filtrado de la textura lo mezcla con el asfalto, así que el color
# que se mide es el del suelo (medido: a 150 m, las tres capturas forzadas daban el mismo
# (143,152,159) lavado). Los recuentos que deciden si un caso vale son los de esta ventana.
const MEDIBLE_DS_M := 120.0
const LATERAL_HALF_M := 0.9              # media anchura del corte transversal medido
const LATERAL_STEP_M := 0.1
const CROSS_DS := [20.0, 60.0, 100.0, 140.0, 180.0, 220.0, 250.0]
const RED_BAND_MIN_M := 90.0             # el rojo, de lejos, para la captura de aproximación
const RED_BAND_MAX_M := 200.0
const FORCED_NAMES := ["verde", "amarillo", "rojo"]
# Casos buscados: (id, patrón, cuántas muestras de cada color tienen que verse). El
# patrón se comprueba sobre el veredicto real; la visibilidad, sobre la proyección.
const CASES := [
	{"id": "recta", "patron": "todo_verde", "requisitos": {"VERDE": 8}},
	{"id": "aproximacion", "patron": "rojo_lejos", "requisitos": {"ROJO": 3, "AMARILLO": 2}},
	{"id": "frenada", "patron": "rojo_cerca", "requisitos": {"ROJO": 5}, "muestras_minimas": 9, "velocidad_max_kph": 250.0},
	# Estos dos casos de frenada se capturan con un techo de velocidad para mantener la
	# sección crítica en el campo de visión cercano del parabrisas, en lugar del horizonte.
	# En salida se exigen tres muestras (el audit de color vuelve a medir al menos tres).
	{"id": "salida", "patron": "verde_detras", "requisitos": {"VERDE": 5, "ROJO": 2}, "muestras_minimas": 3, "velocidad_max_kph": 250.0},
]
const CANDIDATOS_MAX := 40
const VISIBLES_MIN := 10
const SAMPLE_SOLID_M := 15.0               # separación mínima a un cambio de estado
# Velocidades con las que se busca cada patrón (km/h).
const SEARCH_KPH := [120.0, 160.0, 200.0, 250.0, 300.0]

# Diferencia mínima por canal, sobre 255, para dar por DIBUJADA la línea en un píxel: se
# compara el fotograma con la línea contra el mismo instante con la línea oculta. Sirve
# para las muestras de la comprobación de píxeles, que no puede exigir un color donde el
# listón queda tapado por el terreno o por el propio coche.
const DIFERENCIA_LINEA := 10.0
# Y la diferencia a partir de la cual el píxel es de la LÍNEA y no una mezcla con el
# asfalto: con eso se eligen las muestras con las que se miden los tres colores de
# referencia (donde la línea es un par de píxeles y el color que se lee es el suyo).
# 30: el TAA mueve el fotograma unos 8-25 niveles por sí solo, así que 30 da margen; las
# capturas forzadas locales filtran además las superficies que no son la línea. 60 descartaba
# la salida de meta entera aunque el cambio fuera visible (típicamente 35-55 niveles).
const FUERTE_DIFERENCIA := 30.0
const FUERTES_MIN := 6
const GROOVE_MUESTRAS := 80                # puntos de la goma que se miden en píxeles
const GOMA_MUESTRAS_MIN := 12              # puntos de goma que tienen que verse para medirla
const GROOVE_PASO_VERTICES := 40
const GROOVE_RADIO_M := 160.0

var antes := false
var view: SubViewport
var race: Node3D
var car
var cam: Camera3D
var linea
var puntos := PackedVector3Array()
var shots := SHOTS_DIR
var errores: Array[String] = []
var registro: Dictionary = {"casos": [], "lienzo": [FRAME_W, FRAME_H]}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	antes = "goma-como-antes" in OS.get_cmdline_user_args()
	# `caso=<id>` captura sólo ese caso (para depurar una pose sin repetir las cuatro).
	var solo := ""
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("caso="):
			solo = String(arg).substr(5)
	shots = SHOTS_DIR + ("-antes" if antes else "")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(shots))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	view = SubViewport.new()
	view.name = "Lienzo de medida 2400x1080"
	view.size = Vector2i(FRAME_W, FRAME_H)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	race = (load("res://scenes/race.tscn") as PackedScene).instantiate()
	# El modo "antes" se activa ANTES de añadir la escena al árbol: la corrección de la
	# goma se hace en `_ready`.
	race.goma_sin_corregir = antes
	view.add_child(race)
	Engine.max_fps = 120
	for i in 240:
		await physics_frame
	car = race.car
	cam = race.camera
	linea = race.assistance_line
	puntos = TrackScript.get_centerline()
	registro["trazada_puntos"] = puntos.size()
	registro["goma"] = race.goma_corregida
	registro["color_goma_medido"] = _color_de_la_goma()
	registro["escala_de_grises"] = race.GOMA_EN_ESCALA_DE_GRISES
	registro["modo"] = "antes" if antes else "despues"
	DisplayServer.window_move_to_foreground()
	print("LINEA_PX lienzo=%dx%d trazada=%d puntos goma_en=%d mallas" % [
		FRAME_W, FRAME_H, puntos.size(), race.goma_corregida.size()])

	if not solo.is_empty():
		# La ejecución enfocada conserva los casos ya capturados, para que depurar una pose
		# no deje incompleto `capturas.json` (que consume la validación completa).
		var anterior_path := OUT_DIR + ("/capturas-antes.json" if antes else "/capturas.json")
		if FileAccess.file_exists(anterior_path):
			var anterior: Variant = JSON.parse_string(FileAccess.get_file_as_string(anterior_path))
			if anterior is Dictionary:
				for caso_previo in anterior.get("casos", []):
					if String(caso_previo.get("id", "")) != solo:
						registro["casos"].append(caso_previo)
	else:
		await _capturar_goma()
	for caso in CASES:
		if not solo.is_empty() and String(caso["id"]) != solo:
			continue
		await _capturar_caso(caso["id"], caso["patron"], caso["requisitos"], int(caso.get("muestras_minimas", FUERTES_MIN)))

	var ruta := OUT_DIR + ("/capturas-antes.json" if antes else "/capturas.json")
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	archivo.store_string(JSON.stringify(registro, "  "))
	archivo.close()
	print("LINEA_PX registro=%s" % ruta)
	for texto in errores:
		print("LINEA_PX FAIL ", texto)
	# Las referencias son POR CASO (cada pose tiene su exposición), así que se informe
	# cuántos casos las tienen completas, no un diccionario global que ya no existe.
	var con_referencias := 0
	for caso in registro["casos"]:
		if (caso.get("referencias") as Dictionary).size() == FORCED_NAMES.size():
			con_referencias += 1
	print("LINEA_PX %s casos=%d con_las_tres_referencias=%d" % [
		"PASS" if errores.is_empty() else "FAIL", registro["casos"].size(), con_referencias])
	quit(1 if not errores.is_empty() else 0)

# --- elección de los casos ----------------------------------------------------

# Estado de la línea en la estación `ds` metros por delante, con la velocidad dada.
func _estado_en(car_s: float, ds: float, speed: float) -> float:
	return linea.verdict(speed, car_s, ds)

# Perfil de la ventana visible: el estado en cada muestra.
func _perfil(car_s: float, speed: float) -> Array:
	var salida: Array = []
	for k in SAMPLE_COUNT:
		salida.append(_estado_en(car_s, k * SAMPLE_STEP_M, speed))
	return salida

# ¿Cumple el perfil el patrón pedido?
func _cumple(perfil: Array, patron: String) -> bool:
	var rojo := -1
	for k in perfil.size():
		if float(perfil[k]) <= -0.5 and rojo < 0:
			rojo = k
	match patron:
		"todo_verde":
			# Toda la ventana visible en verde: sólo se acelera.
			for estado in perfil:
				if float(estado) < 0.5:
					return false
			return true
		"rojo_lejos":
			# El rojo aparece de lejos (90-200 m), con amarillo por delante de él.
			if rojo < 0:
				return false
			var ds := rojo * SAMPLE_STEP_M
			if ds < RED_BAND_MIN_M or ds > RED_BAND_MAX_M:
				return false
			var amarillo := false
			for k in rojo:
				if absf(float(perfil[k])) <= 0.4:
					amarillo = true
			return amarillo and float(perfil[0]) > -0.5
		"rojo_cerca":
			# Frenando ya: el rojo empieza a menos de 30 m (o el propio punto es rojo).
			return rojo >= 0 and rojo * float(SAMPLE_STEP_M) <= 30.0
		"verde_detras":
			# Salida de curva: cerca todavía amarillo o rojo, y verde más adelante.
			if float(perfil[0]) >= 0.5 or float(perfil[1]) >= 0.5:
				return false
			var verdes := 0
			for k in perfil.size():
				if k * SAMPLE_STEP_M >= 60.0 and float(perfil[k]) >= 0.5:
					verdes += 1
			return verdes >= 6
	return false

# Todas las estaciones y velocidades que cumplen el patrón, de la más rápida a la
# más lenta (la más exigente para la línea: bandas más largas). Se recorre la vuelta
# entera cada 5 puntos y, para cada estación, las velocidades de la lista.
func _candidatos(patron: String, velocidad_max_kph: float = 9999.0) -> Array:
	var lista: Array = []
	for indice in range(0, puntos.size(), 5):
		var car_s := float(linea.arc[indice])
		for kph in SEARCH_KPH:
			if float(kph) > velocidad_max_kph:
				continue
			var speed: float = float(kph) / 3.6
			if not _cumple(_perfil(car_s, speed), patron):
				continue
			var puntos_caso := 0
			for k in SAMPLE_COUNT:
				if absf(_estado_en(car_s, k * SAMPLE_STEP_M, speed)) <= 0.4:
					puntos_caso += 1
			lista.append({"indice": indice, "kph": kph, "puntos": puntos_caso})
	lista.sort_custom(func(a, b):
		if absf(float(a["kph"]) - float(b["kph"])) > 0.5:
			return float(a["kph"]) > float(b["kph"])
		return int(a["indice"]) < int(b["indice"]))
	return lista.slice(0, CANDIDATOS_MAX)

func _visible_ok(caso: Dictionary, requisitos: Dictionary) -> bool:
	if int(caso["visibles"]) < VISIBLES_MIN:
		return false
	var cuenta: Dictionary = caso["visibles_por_estado"]
	for clave in requisitos:
		if int(cuenta.get(clave, 0)) < int(requisitos[clave]):
			return false
	return true

# Un caso se acepta cuando, además de cumplir el patrón con la ventana en pantalla y de
# dejar el coche congelado (el registro y las capturas tienen que ser el MISMO instante: a
# 300 km/h el coche avanza 0,7 m por fotograma y entre proyectar la trazada y guardar el
# PNG el muestreo caía en asfalto), la
# línea SE VE lo bastante en esa pose como para medirla en píxeles: al menos FUERTES_MIN
# muestras cambian el píxel más de FUERTE_DIFERENCIA al ocultarla (a más de 120 m el listón
# proyecta menos de un píxel y el filtrado de la textura lo mezcla con el asfalto, así que
# ahí el color medido es el del suelo). Si la pose elegida no sirve se prueba la siguiente
# candidata del patrón: elegir la primera que "se vea" y medirla daba referencias lavadas
# (medido: (143,152,159) para los tres colores forzados de la salida de la horquilla).
func _capturar_caso(id: String, patron: String, requisitos: Dictionary, muestras_minimas: int) -> void:
	var descartadas := 0
	var velocidad_max := 9999.0
	for definicion in CASES:
		if String(definicion["id"]) == id:
			velocidad_max = float(definicion.get("velocidad_max_kph", velocidad_max))
	var candidatos := _candidatos(patron, velocidad_max)
	for candidato in candidatos:
		await _colocar(int(candidato["indice"]), float(candidato["kph"]))
		await _congelar()
		var caso := _registro_del_caso("", patron, int(candidato["indice"]), float(candidato["kph"]))
		if not _visible_ok(caso, requisitos):
			_descongelar()
			continue
		caso["id"] = id
		# Los dos fotogramas del MISMO instante se guardan en disco y se devuelven: la
		# diferencia entre ellos dice dónde se está viendo de verdad la línea.
		var con_linea: Image = await _grabar(shots + "/%s-linea.png" % id)
		linea.visible = false
		# La visibilidad afecta al historial del TAA: esperar a que se asiente antes de
		# comparar, o el ruido temporal del fotograma se confunde con la línea.
		for i in ASENTAR_FOTOGRAMAS:
			await process_frame
		var sin_linea: Image = await _grabar(shots + "/%s-base.png" % id)
		linea.visible = true
		for i in ASENTAR_FOTOGRAMAS:
			await process_frame
		# El mismo instante con el material de goma del GLB: la diferencia entre este
		# fotograma y el anterior ES la franja de goma de esta pose, sin depender de que
		# dos ejecuciones distintas hayan quedado con la misma cámara y la misma luz.
		await _grabar_goma_original(shots + "/%s-base-original.png" % id)
		if con_linea == null or sin_linea == null:
			errores.append("no se pudieron capturar los dos fotogramas del caso %s" % id)
			_descongelar()
			return
		var muestras := _puntos_con_linea_a_la_vista(caso, con_linea, sin_linea)
		if muestras.size() < muestras_minimas:
			descartadas += 1
			_descongelar()
			continue
		await _referencias_del_caso(id, caso, muestras)
		_descongelar()
		registro["casos"].append(caso)
		print("LINEA_PX caso=%s patrón=%s índice=%d velocidad=%.0f km/h verdes=%d amarillos=%d rojos=%d muestras_visibles=%d medibles=%d descartadas=%d visibles_por_estado=%s" % [
			id, patron, caso["indice"], caso["velocidad_kph"], caso["verdes"], caso["amarillos"], caso["rojos"],
			caso["visibles"], muestras.size(), descartadas, str(caso["visibles_por_estado"])])
		return
	errores.append("no se encontró ningún caso con el patrón %s cuya línea se vea lo bastante para medirla en píxeles (mínimo %d muestras, %d poses descartadas)" % [patron, muestras_minimas, descartadas])

# Las muestras del caso en las que la línea se VE: el píxel cambia al ocultarla. Se piden
# FUERTES_MIN para poder medir el color, y son los puntos donde después se miden los tres
# colores de referencia y donde la comprobación de píxeles exige el color que toca.
func _puntos_con_linea_a_la_vista(caso: Dictionary, con_linea: Image, sin_linea: Image) -> Array:
	var muestras: Array = []
	for muestra in caso["muestras"]:
		if muestra["ocluido"] or not _en_cuadro(muestra["punto"]):
			continue
		var con := _pixel_de(con_linea, muestra["punto"], 1)
		var sin := _pixel_de(sin_linea, muestra["punto"], 1)
		if con == Vector3.INF or sin == Vector3.INF:
			continue
		var delta := maxf(absf(con.x - sin.x), maxf(absf(con.y - sin.y), absf(con.z - sin.z)))
		if delta <= FUERTE_DIFERENCIA:
			continue
		muestras.append(muestra["punto"])
	return muestras

# Los tres colores de referencia de ESTE caso. Se miden sobre la MISMA pose y a la
# MISMA velocidad con la línea forzada a un solo color, en los píxeles exactos en los
# que el caso tiene sus muestras: así la comparación no depende de que la luz o el
# tonemap pinten igual en dos sitios distintos de la vuelta.
func _referencias_del_caso(id: String, caso: Dictionary, muestras: Array) -> void:
	var referencias: Dictionary = {}
	for k in FORCED_NAMES.size():
			# La fila UV del listón se deriva de la posición del coche; congelar su _process
		# evita que la textura forzada se desplace bajo las muestras mientras se captura.
		linea.set_process(false)
		linea.forzar_estado(k)
		for i in ASENTAR_FOTOGRAMAS:
			await process_frame
		var imagen: Image = await _grabar(shots + "/%s-forzado-%s.png" % [id, FORCED_NAMES[k]])
		linea.soltar_estado()
		linea.set_process(true)
		if imagen == null:
			continue
		var colores: Array = []
		for punto in muestras:
			var color := _pixel_de(imagen, punto, 1)
			if color != Vector3.INF:
				colores.append(color)
		var media := Vector3.ZERO
		for color in colores:
			media += color
		media /= maxf(1.0, float(colores.size()))
		referencias[FORCED_NAMES[k]] = {"rgb": [media.x, media.y, media.z], "n": colores.size()}
		print("LINEA_PX caso=%s referencia=%s rgb=(%.0f,%.0f,%.0f) n=%d" % [
			id, FORCED_NAMES[k], media.x, media.y, media.z, colores.size()])
	caso["referencias"] = referencias

# Deja el coche quieto (sin apagar la física de la escena, que la cámara y la línea
# siguen viviendo de ella) para que las proyecciones y las capturas sean del MISMO
# instante. A 300 km/h el coche avanza 0,7 m por fotograma y entre proyectar la
# trazada y guardar el PNG se movía lo suficiente para que los píxeles pautados ya
# no fueran los de la línea.
func _congelar() -> void:
	car.set_physics_process(false)
	for i in 10:
		await physics_frame
	DisplayServer.window_move_to_foreground()

func _descongelar() -> void:
	car.set_physics_process(true)

# Guarda un fotograma con la goma en el material del GLB y devuelve la goma al material
# corregido. Es lo que da el "antes" de la franja en el MISMO instante (y en la misma
# pose) que el "después": lo único que cambia entre los dos PNG es el material de la
# goma. En modo `goma-como-antes` no hay nada corregido que quitar, así que no se
# guarda nada (y la comprobación independiente lo sabe, porque tampoco hay `-original`).
#
# Los `ASENTAR` fotogramas de espera no son adorno: el antialiasing temporal mezcla cada
# fotograma con su historial (~90 % de lo anterior), así que el material nuevo tarda
# decenas de fotogramas en verse entero. Medido: esperando 3 fotogramas, el "antes" de la
# franja salía (142,155,164) —una mezcla del material corregido y del del GLB, con la
# mitad del azul— en vez de los (143,158,193) que mide la ejecución con la corrección
# apagada. Con 45 la mezcla es del 1 %.
const ASENTAR_FOTOGRAMAS := 45

func _grabar_goma_original(ruta: String) -> Image:
	if race.goma_corregida.is_empty():
		return null
	print("LINEA_PX goma pasa al material del GLB en %d superficies" % race.goma_modo(true))
	for i in ASENTAR_FOTOGRAMAS:
		await process_frame
	var imagen: Image = await _grabar(ruta)
	race.goma_modo(false)
	for i in ASENTAR_FOTOGRAMAS:
		await process_frame
	return imagen

# Color medio de un cuadradito de píxeles; Vector3.INF si cae fuera del lienzo.
func _pixel_de(imagen: Image, punto: Dictionary, radio: int) -> Vector3:
	if bool(punto.get("detras", true)):
		return Vector3.INF
	var x := int(round(float(punto["x"])))
	var y := int(round(float(punto["y"])))
	if x < radio or y < radio or x >= imagen.get_width() - radio or y >= imagen.get_height() - radio:
		return Vector3.INF
	var suma := Vector3.ZERO
	var cuenta := 0
	for dx in range(-radio, radio + 1):
		for dy in range(-radio, radio + 1):
			var color := imagen.get_pixel(x + dx, y + dy)
			suma += Vector3(color.r, color.g, color.b)
			cuenta += 1
	return suma / maxf(1.0, float(cuenta)) * 255.0

func _registro_del_caso(id: String, patron: String, indice: int, kph: float) -> Dictionary:
	var car_s := float(linea.arc[indice])
	var speed := kph / 3.6
	var muestras: Array = []
	var cuenta := [0, 0, 0]
	for k in SAMPLE_COUNT:
		var ds := k * SAMPLE_STEP_M
		var estado := _estado_en(car_s, ds, speed)
		# Muestra "mixta": a menos de SAMPLE_SOLID_M de un cambio de estado el píxel
		# mezcla dos colores (la transición no es instantánea en pantalla), así que no
		# vale para exigirle un color concreto. Se marca y la comprobación la salta.
		var mixta := false
		for delta in [SAMPLE_SOLID_M, -SAMPLE_SOLID_M]:
			var vecino := ds + float(delta)
			if vecino < 0.0 or vecino > float(SAMPLE_COUNT - 1) * SAMPLE_STEP_M:
				continue
			if absf(_estado_en(car_s, vecino, speed) - estado) > 0.25:
				mixta = true
		if estado >= 0.5:
			cuenta[0] += 1
		elif estado <= -0.5:
			cuenta[2] += 1
		else:
			cuenta[1] += 1
		var muestra := {
			"ds": ds,
			"estado": linea.state_name(estado),
			"ocluido": ds < OCCLUDED_DS_M,
			"mixta": mixta,
			"punto": _proyectar(_punto_en(car_s, ds)),
		}
		# El corte transversal sólo se guarda donde la línea es medible: a más de 120 m el
		# listón proyecta menos de un píxel y el corte mediría asfalto (y la comprobación de
		# "dentro del listón no asoma el asfalto" fallaría por eso, no por la línea).
		if CROSS_DS.has(ds) and ds <= MEDIBLE_DS_M:
			muestra["cruce"] = _corte(car_s, ds)
		muestras.append(muestra)
	var visibles := 0
	var por_estado := {"VERDE": 0, "AMARILLO": 0, "ROJO": 0}
	for muestra in muestras:
		if muestra["ocluido"] or not _en_cuadro(muestra["punto"]):
			continue
		visibles += 1
		por_estado[muestra["estado"]] = int(por_estado.get(muestra["estado"], 0)) + 1
	return {
		"id": id, "patron": patron, "indice": indice, "velocidad_kph": kph,
		"arco_m": car_s, "muestras": muestras,
		"verdes": cuenta[0], "amarillos": cuenta[1], "rojos": cuenta[2], "visibles": visibles,
		"visibles_por_estado": por_estado,
	}

# ¿Cae el punto proyectado dentro del lienzo, con dos píxeles de margen?
func _en_cuadro(punto: Dictionary) -> bool:
	if bool(punto.get("detras", true)):
		return false
	return float(punto["x"]) >= 2.0 and float(punto["y"]) >= 2.0 and float(punto["x"]) < FRAME_W - 2.0 and float(punto["y"]) < FRAME_H - 2.0

func _punto_en(car_s: float, ds: float) -> Vector3:
	var largo: float = linea.track_length
	var s := fposmod(car_s + ds, largo)
	return puntos[int(linea._indice_de_arco(s))]

func _tangente_en(car_s: float, ds: float) -> Vector3:
	var largo: float = linea.track_length
	var s := fposmod(car_s + ds, largo)
	var i: int = int(linea._indice_de_arco(s))
	var after := puntos[(i + 1) % puntos.size()]
	return (after - puntos[i]).normalized()

# Corte transversal del punto: la recta que cruza la calzada, proyectada a pantalla
# metro a metro de lado a lado. Es lo que permite medir anchuras en píxeles.
func _corte(car_s: float, ds: float) -> Array:
	var centro := _punto_en(car_s, ds)
	var tangente := _tangente_en(car_s, ds)
	var derecha := Vector3(-tangente.z, 0.0, tangente.x).normalized()
	var salida: Array = []
	var offset := -LATERAL_HALF_M
	while offset <= LATERAL_HALF_M + 1e-6:
		var punto := centro + derecha * offset
		salida.append({"lado": offset, "punto": _proyectar(punto)})
		offset += LATERAL_STEP_M
	return salida

func _proyectar(punto: Vector3) -> Dictionary:
	var detras := cam.is_position_behind(punto)
	var pantalla := cam.unproject_position(punto)
	return {"x": pantalla.x, "y": pantalla.y, "detras": detras}

# --- la goma de la trazada: dónde cae en la pantalla -------------------------
#
# La goma que trae el circuito NO está en el centro de la calzada —sigue la línea
# del mod, que va por donde va—, así que muestrear la trazada no la mide. Lo que
# se hace aquí es buscar los vértices de la propia malla de la goma que están
# cerca del coche y por delante, proyectarlos y guardar también los píxeles de
# lado a lado: el centro es la goma y los lados, el asfalto con el que compararla.
func _capturar_goma() -> void:
	var eleccion := {}
	var muestras: Array = []
	for candidato in _candidatos("todo_verde"):
		await _colocar(int(candidato["indice"]), float(candidato["kph"]))
		await _congelar()
		muestras = _puntos_goma()
		if muestras.size() >= GOMA_MUESTRAS_MIN:
			eleccion = candidato
			break
		_descongelar()
	if eleccion.is_empty():
		errores.append("no se encontró una recta en verde con la goma a la vista para medir")
		return
	await _grabar(shots + "/goma-linea.png")
	linea.visible = false
	await _grabar(shots + "/goma-base.png")
	# Y el mismo sitio con el material de goma del GLB, puesto en caliente: sirve de
	# comprobación de que el material se puede poner y quitar sin reabrir la escena (y de
	# que el de la otra ejecución —la que se captura con la corrección apagada— es el mismo).
	# La MEDIDA de la franja no sale de aquí: comparando dos fotogramas de la misma ejecución,
	# el antialiasing temporal deja un ruido de fondo de cientos de miles de píxeles que
	# falsea el contraste; sale de comparar la tanda corregida con la del GLB, que es una
	# ejecución entera aparte con la misma pose (el asfalto sale idéntico, comprobado en
	# `linea_pixeles.py`).
	await _grabar_goma_original(shots + "/goma-original.png")
	registro["goma_sin_linea"] = true
	linea.visible = true
	registro["goma_muestras"] = muestras
	registro["goma_indice"] = int(eleccion["indice"])
	registro["goma_velocidad_kph"] = float(eleccion["kph"])
	_descongelar()
	print("LINEA_PX goma muestras_en_pantalla=%d (índice %d a %.0f km/h); la franja se mide en "
		% [muestras.size(), eleccion["indice"], eleccion["kph"]] + "linea_pixeles.py, sobre los PNG 'goma-base' de las dos tandas")

func _puntos_goma() -> Array:
	var salida: Array = []
	for nodo in race.find_children("*", "MeshInstance3D", true, false):
		if salida.size() >= GROOVE_MUESTRAS:
			break
		var mesh := nodo as MeshInstance3D
		if mesh.mesh == null or not mesh.visible:
			continue
		for superficie in mesh.mesh.get_surface_count():
			if not _es_goma(mesh.mesh.surface_get_material(superficie)):
				continue
			var arrays := mesh.mesh.surface_get_arrays(superficie)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var total := vertices.size() if indices.is_empty() else indices.size()
			var k := 0
			while k < total and salida.size() < GROOVE_MUESTRAS:
				var local := vertices[indices[k] if not indices.is_empty() else k]
				k += GROOVE_PASO_VERTICES
				var punto: Vector3 = mesh.global_transform * local
				if absf(punto.y - car.global_position.y) > 3.0:
					continue
				if punto.distance_to(car.global_position) > GROOVE_RADIO_M:
					continue
				if cam.is_position_behind(punto):
					continue
				var muestra := _muestra_de_goma(punto)
				if not muestra.is_empty():
					salida.append(muestra)
	return salida

func _es_goma(mat: Material) -> bool:
	var estandar := mat as StandardMaterial3D
	if estandar == null or estandar.albedo_texture == null:
		return false
	var etiqueta := ("%s %s" % [String(estandar.resource_name), String(estandar.albedo_texture.resource_path)]).to_lower()
	return "groove" in etiqueta or "tyres_add2" in etiqueta

# Un punto de goma y sus vecinos de lado a lado, todo proyectado a pantalla.
func _muestra_de_goma(punto: Vector3) -> Dictionary:
	var cercano := _centro_mas_cercano(punto)
	var tangente := _tangente_en(float(linea.arc[cercano]), 0.0)
	var derecha := Vector3(-tangente.z, 0.0, tangente.x).normalized()
	var vecinos: Array = []
	for lado in [-1.4, -1.0, 1.0, 1.4]:
		vecinos.append({"lado": lado, "punto": _proyectar(punto + derecha * float(lado))})
	return {"punto": _proyectar(punto + Vector3.UP * 0.02), "vecinos": vecinos, "lado_trazada": punto.distance_to(puntos[cercano])}

func _centro_mas_cercano(punto: Vector3) -> int:
	var mejor := 0
	var mejor_distancia := INF
	for i in range(0, puntos.size(), 2):
		var d := Vector2(punto.x - puntos[i].x, punto.z - puntos[i].z).length_squared()
		if d < mejor_distancia:
			mejor_distancia = d
			mejor = i
	return mejor

# --- colocación del coche y captura ------------------------------------------

func _colocar(indice: int, kph: float) -> void:
	var tangente := (puntos[(indice + 1) % puntos.size()] - puntos[indice]).normalized()
	var derecha := Vector3(-tangente.z, 0.0, tangente.x).normalized()
	car.recover_to(puntos[indice] + derecha * 0.0 + Vector3.UP * 0.2, atan2(-tangente.x, -tangente.z))
	car.velocity = tangente * (kph / 3.6)
	car.speed_mps = kph / 3.6
	car.speed_kph = kph
	for i in 90:
		Input.action_release("throttle")
		Input.action_release("brake")
		car.velocity = tangente * (kph / 3.6)
		await physics_frame
	# La línea tiene su propio filtro de velocidad (τ = 0,15 s): se le da tiempo a
	# asentarse antes de dibujar, igual que la cámara.
	for i in 40:
		await physics_frame

# Guarda el fotograma y DEVUELVE la imagen guardada (null si no se pudo). Devolverla es
# importante: el que llama mide sobre ESTE fotograma y no sobre el que el lienzo tenga
# cuando vuelva a mirarlo. Medido: leyendo `view.get_texture()` después de guardar, las
# capturas forzadas de la salida de la horquilla devolvían el fotograma NORMAL (la línea ya
# sin forzar, porque entre guardar y leer entraba otro fotograma) y los tres colores de
# referencia salían casi iguales —(134,144,150), (137,145,151), (138,147,155)—, que no
# distingue nada.
func _grabar(ruta: String) -> Image:
	# El lienzo del anfitrión puede dejar de volverse a dibujar si el gestor de
	# ventanas lo tapa: se trae al frente y se comprueba que la textura cambie. Si no
	# cambia en seis intentos, la captura se da por perdida (mejor un fallo claro que
	# dos fotogramas idénticos midiendo cosas distintas).
	for intento in 6:
		# `force_draw` obliga al motor a dibujar el fotograma aunque el gestor de ventanas
		# no componga la ventana (máquina ocupada, ventana tapada).
		RenderingServer.force_draw(false)
		for i in 2:
			await process_frame
		var imagen: Image = view.get_texture().get_image()
		if _imagen_anterior == null or _diferencia(imagen, _imagen_anterior) > 0.0:
			_imagen_anterior = imagen
			var error := imagen.save_png(ruta)
			if error != OK:
				errores.append("no se pudo guardar %s (error %d)" % [ruta, error])
				return null
			return imagen
		if intento < 5:
			DisplayServer.window_move_to_foreground()
			await create_timer(0.15).timeout
	errores.append("el lienzo no se vuelve a dibujar: %s se queda con el fotograma anterior" % ruta)
	return null

# El fotograma anterior del mismo lienzo: la guarda de "se ha vuelto a dibujar" compara
# con el ENTERO, píxel a píxel, y no con una rejilla de muestreo. Con la rejilla (cada 7
# píxeles) la línea —un listón de un píxel de ancho— podía encenderse y apagarse sin tocar
# ningún punto de la rejilla, y el fotograma se daba por repetido sin serlo (medido: la
# salida de la horquilla, con la línea cambiando y 11 muestras en pantalla).
var _imagen_anterior: Image = null

# Diferencia máxima por canal entre dos fotogramas del mismo lienzo (0 = idénticos).
func _diferencia(a: Image, b: Image) -> float:
	if a == null or b == null or a.get_size() != b.get_size():
		return 1.0
	# `use_luma = false`: se compara canal a canal (la línea verde sobre el asfalto cambia
	# poco en luminancia y mucho en el canal rojo).
	var metricas := a.compute_image_metrics(b, false)
	return float(metricas.get("max", 1.0))

# --- goma de la trazada: medida del material y modo "como antes" ---------------

func _color_de_la_goma() -> Array:
	var colores: Array = []
	for entrada in race.goma_corregida:
		colores.append({
			"nodo": entrada.get("nodo", ""),
			"albedo": [entrada["albedo"].r, entrada["albedo"].g, entrada["albedo"].b],
			"media": [entrada["media"].x, entrada["media"].y, entrada["media"].z],
			"escala_de_grises": bool(entrada.get("escala_de_grises", false)),
		})
	return colores
