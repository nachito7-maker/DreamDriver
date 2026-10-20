extends SceneTree

# Trazador de la recomendación: dónde empieza cada banda y qué dicen las envolventes.
#
# Uso:
#   "$GODOT" --headless --path . --script .tools/recovery/linea/depurar_perfil.gd -- 792 120

const TrackScript = preload("res://scripts/track_data.gd")
const LineScript = preload("res://scripts/driving_line.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var points := TrackScript.get_centerline()
	var linea = MeshInstance3D.new()
	linea.set_script(LineScript)
	linea.construir(points)
	var args := OS.get_cmdline_user_args()
	var indice := int(args[0]) if args.size() > 0 else 792
	var kph := float(args[1]) if args.size() > 1 else 200.0
	var colocacion := _colocacion(linea, indice)
	var v := kph / 3.6
	var s_car := float(linea.arc[colocacion])
	var largo: float = linea.track_length
	var mando := _manda(linea, s_car, 0.0, 900.0)
	print("DEPURA curva=%d ideal_curva=%.1f km/h colocacion=%d ideal_colocacion=%.1f km/h velocidad=%.0f km/h distancia_a_curva=%.0f m curva_que_manda=%.0f m vértice=%.1f km/h" % [
		indice, float(linea.speed_ideal[indice]) * 3.6, colocacion, float(linea.speed_ideal[colocacion]) * 3.6, kph,
		_distancia_arco(linea, colocacion, indice), float(mando["ds"]), float(mando["ideal"]) * 3.6])
	var ds := 0.0
	var ds_rojo := -1.0
	var ds_amarillo := -1.0
	print("DEPURA umbral_amarillo=v-%.2f m/s umbral_rojo=v+%.2f m/s v=%.2f m/s" % [
		float(linea.deceleracion_comoda()) * float(linea.hold_lead_s), float(linea.brake_reference_m_s2) * float(linea.red_margin_s), v])
	while ds <= 160.0:
		var i: int = int(linea._indice_de_arco(fposmod(s_car + ds, largo)))
		var estado: float = linea.verdict(v, s_car, ds)
		if estado <= -0.5 and ds_rojo < 0.0:
			ds_rojo = ds
		if absf(estado) <= 0.4 and ds_amarillo < 0.0:
			ds_amarillo = ds
		if fmod(ds, 4.0) == 0.0 or (ds > 40.0 and ds < 80.0):
			print("DEPURA ds=%6.1f indice=%4d ideal=%6.1f env_fuerte=%6.1f env_suave=%6.1f estado=%2.0f" % [
				ds, i, float(linea.speed_ideal[i]) * 3.6, float(linea.envelope_hard[i]) * 3.6,
				float(linea.envelope_soft[i]) * 3.6, estado])
		ds += 1.0
	print("DEPURA ds_rojo=%.1f ds_amarillo=%.1f" % [ds_rojo, ds_amarillo])
	quit(0)

func _manda(linea, car_s: float, desde_ds: float, hasta_ds: float) -> Dictionary:
	var mejor := INF
	var mejor_ds := desde_ds
	var mejor_ideal: float = linea.limite_en(linea.speed_ideal, car_s, desde_ds)
	var ds := desde_ds
	while ds <= hasta_ds:
		var ideal: float = linea.limite_en(linea.speed_ideal, car_s, ds)
		var valor := ideal * ideal + 2.0 * float(linea.brake_reference_m_s2) * ds
		if valor < mejor:
			mejor = valor
			mejor_ds = ds
			mejor_ideal = ideal
		ds += 0.5
	return {"ds": mejor_ds, "ideal": mejor_ideal}

func _colocacion(linea, indice: int) -> int:
	var count: int = linea.points.size()
	var mejor := indice
	var mejor_ideal := -1.0
	var recorrido := 0.0
	var i := indice
	while recorrido < 700.0:
		var anterior := (i - 1 + count) % count
		recorrido += float(linea.step_next[anterior])
		i = anterior
		if recorrido < 120.0:
			continue
		if float(linea.speed_ideal[i]) > mejor_ideal:
			mejor_ideal = float(linea.speed_ideal[i])
			mejor = i
	return mejor

func _distancia_arco(linea, a: int, b: int) -> float:
	var largo: float = linea.track_length
	var d: float = absf(float(linea.arc[a]) - float(linea.arc[b]))
	return minf(d, largo - d)
