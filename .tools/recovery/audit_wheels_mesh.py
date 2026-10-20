#!/usr/bin/env python3
"""Auditoría de la FORMA de las cuatro ruedas del Red Bull en el activo entregado.

Las sondas en ejecución (`car_wheel_probe.gd`) y `audit_delivery.py` auditan la
CAJA ENVOLVENTE de cada rueda: dónde está el pivote, cuánto mide el fondo, cuál es
el eje de giro. La caja no ve ninguna de las cosas que el ojo sí ve, y que son las
que describen una rueda «deformada» o «mal ensamblada»:

  * REDONDEZ — radio de la silueta por sector (72 sectores). Una rueda ovalada, con
    un plano o con un lóbulo sale aquí; la caja envolvente es idéntica.
  * DIÁMETROS — los dos diámetros radiales, que en una rueda tienen que coincidir.
  * CORONA — radio de la banda de rodadura a lo largo de la anchura. Un neumático
    de verdad NO es un cilindro: la corona es curva y el radio baja hacia los
    hombros. Se informa como medida y no como defecto (lo sería un ESCALÓN).
  * NORMALES — ángulo entre la normal ALMACENADA (la que usa el motor para
    sombrear) y la normal geométrica del triángulo. Si van del revés, la rueda se
    sombrea al revés y aparecen manchas y sombras que no corresponden a nada.
  * TALÓN — radio del BARRIL de la llanta (la superficie cilíndrica interior). Es
    la frontera física entre neumático y llanta: si el reparto de materiales no cae
    ahí, una banda del barril queda pintada de goma (o al revés) y la rueda parece
    mal ensamblada.
  * VOLUMEN FIRMADO — por pieza suelta: informa del enrollado de las caras. En
    este activo TODAS las piezas (chasis incluido) salen negativas, que es la
    convención del exportador con materiales de doble cara, así que no se usa como
    criterio: sirve para comparar piezas entre sí.
  * PIEZAS SUELTAS — componentes conexas de la malla, si alguna queda dentro de
    otra (geometría duplicada o interpenetrada) y cuánto abulta cada una.
  * PROTRUSIONES — geometría por fuera de la silueta del neumático.
  * REPARTO GOMA/LLANTA — rango radial de las caras de cada material, que es lo que
    decide si la rueda parece un neumático con llanta o un disco.
  * VISIBILIDAD — rayos desde fuera hacia el eje: la primera superficie que ve un
    rayo tiene que ser la GOMA en la banda de rodadura. Si ve la llanta, o si no ve
    nada, la goma tiene agujeros que se atraviesan y la rueda se ve como un tambor
    plateado. Es la única de estas medidas que ve ese defecto: la silueta, los
    diámetros, la corona y la cobertura angular lo dejan pasar (en la junta de dos
    gajos queda un resto de triángulo que llega a la banda, y la silueta sale bien
    aunque a la superficie le falte el trozo de en medio).

Uso:
    python3 .tools/recovery/audit_wheels_mesh.py [assets/RedBull-Drive.glb]

Informe: .tools/recovery/wheels_mesh_audit.json
Sale con código distinto de cero si alguna rueda incumple un criterio de forma.
"""
from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

import numpy as np

GLB = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/RedBull-Drive.glb")
OUT = Path(".tools/recovery/wheels_mesh_audit.json")

# --- criterios de forma (declarados; se aplican a las cuatro ruedas) -----------
REDONDEZ_MAX = 0.02          # dispersión del radio de la silueta, sobre el radio
DIAMETROS_MAX = 0.01         # diferencia entre los dos diámetros, sobre el radio
CORONA_MAX = 0.06            # curvatura de la corona admitida, sobre el radio
NORMALES_AL_REVES_MAX = 0.05  # fracción del ÁREA con la normal almacenada al revés
RAYOS_FUERA_DE_LA_GOMA_MAX = 0.0  # fracción de rayos que pueden ver algo que no sea goma
VOLUMEN_NEGATIVO_MAX = 1.0   # cm³ de volumen firmado negativo admitidos por pieza
SECTORES = 72
BANDA = 0.90                 # fracción del radio que define la banda de rodadura
ANGULOS_RAYOS = 720          # paso de 0,5° en el barrido de rayos
ALTURAS_RAYOS = 4            # planos axiales donde se disparan los rayos

COMPONENTES = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2), 5123: ("H", 2),
               5125: ("I", 4), 5126: ("f", 4)}
TIPOS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def load_glb(path: Path):
    raw = path.read_bytes()
    magic, version, length = struct.unpack_from("<III", raw)
    assert magic == 0x46546C67 and version == 2, "no es un GLB 2"
    assert length == len(raw), (length, len(raw))
    size = struct.unpack_from("<I", raw, 12)[0]
    doc = json.loads(raw[20:20 + size])
    bin_size = struct.unpack_from("<I", raw, 20 + size)[0]
    return doc, raw[28 + size:28 + size + bin_size]


def accessor(doc: dict, blob: bytes, index: int) -> np.ndarray:
    acc = doc["accessors"][index]
    fmt, size = COMPONENTES[acc["componentType"]]
    components = TIPOS[acc["type"]]
    view = doc["bufferViews"][acc["bufferView"]]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride") or components * size
    if stride == components * size:
        flat = np.frombuffer(blob, dtype=np.dtype("<" + fmt), count=acc["count"] * components, offset=start)
        data = flat.reshape(acc["count"], components)
    else:  # bufferView intercalado
        data = np.vstack([np.frombuffer(blob, dtype=np.dtype("<" + fmt), count=components,
                                        offset=start + i * stride) for i in range(acc["count"])])
    return data.astype(np.float64 if fmt == "f" else np.int64)


def componentes(tri: np.ndarray, positions: np.ndarray, fusionado: np.ndarray) -> list:
    """Componentes conexas: los vértices que comparten posición (a 0,1 mm) se
    fusionan y después se unen por las aristas de los triángulos. Una pieza suelta
    (un muñón, una llanta duplicada, una lámina interior) sale como componente
    aparte aunque el exportador haya duplicado sus vértices."""
    parent = np.arange(int(fusionado.max()) + 1)
    raiz = np.array([int(v) for v in fusionado[tri.reshape(-1)]]).reshape(-1, 3)

    def find(a: int) -> int:
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for a, b, c in raiz:
        ra, rb, rc = find(a), find(b), find(c)
        if rb != ra:
            parent[rb] = ra
        if rc != ra:
            parent[rc] = ra
    representante = np.zeros((len(parent), 3))
    for i, m in enumerate(fusionado):
        representante[int(m)] = positions[i]
    grupos: dict = {}
    for m in range(len(parent)):
        grupos.setdefault(find(m), []).append(m)
    partes = []
    for vertices in grupos.values():
        partes.append({"vertices": len(vertices),
                       "posiciones": representante[np.array(vertices)]})
    partes.sort(key=lambda p: -p["vertices"])
    return partes


def visibilidad(pos: np.ndarray, tri: np.ndarray, tri_mat: np.ndarray, indice_goma: int,
                eje: int, radial: list, r_max: float, mitad: float, centro: np.ndarray) -> dict:
    """Primera superficie que ve cada rayo lanzado desde fuera hacia el eje.

    Se disparan rayos desde fuera (a 3 R del eje) apuntando al eje, en cuatro
    planos axiales y 720 direcciones (una cada 0,5°). Por cada rayo se toma el
    primer triángulo que corta —Möller–Trumbore, el de `t` positivo más pequeño—
    y se mira QUÉ superficie es: goma en la banda (lo correcto), goma más
    adentro, la llanta, o nada (el rayo atraviesa la rueda y sigue de largo).
    Los tres últimos casos son agujeros en la goma.
    """
    caras = pos[tri]
    v0, v1, v2 = caras[:, 0], caras[:, 1], caras[:, 2]
    e1, e2 = v1 - v0, v2 - v0
    lejos = 3.0 * r_max
    resultado = {"goma_banda": 0, "goma_interior": 0, "llanta": 0, "nada": 0}
    ejemplos = []
    for fraccion in np.linspace(-0.75, 0.75, ALTURAS_RAYOS):
        x = centro[eje] + fraccion * mitad
        for k in range(ANGULOS_RAYOS):
            tita = 2.0 * np.pi * k / ANGULOS_RAYOS
            direccion = np.zeros(3)
            direccion[radial[0]] = -np.cos(tita)
            direccion[radial[1]] = -np.sin(tita)
            origen = np.zeros(3)
            origen[eje] = x
            origen[radial[0]] = centro[radial[0]] + np.cos(tita) * lejos
            origen[radial[1]] = centro[radial[1]] + np.sin(tita) * lejos
            pvec = np.cross(direccion, e2)
            det = np.einsum("ij,ij->i", e1, pvec)
            valido = np.abs(det) > 1e-12
            inv = np.zeros_like(det)
            inv[valido] = 1.0 / det[valido]
            tvec = origen - v0
            u = np.einsum("ij,ij->i", tvec, pvec) * inv
            qvec = np.cross(tvec, e1)
            v = np.einsum("j,ij->i", direccion, qvec) * inv
            t = np.einsum("ij,ij->i", e2, qvec) * inv
            golpea = valido & (u >= -1e-9) & (v >= -1e-9) & (u + v <= 1.0 + 1e-9) & (t > 1e-6)
            if not golpea.any():
                resultado["nada"] += 1
                continue
            candidatos = np.where(golpea)[0]
            elegido = int(candidatos[np.argmin(t[golpea])])
            punto = origen + direccion * t[elegido]
            radio = float(np.hypot(punto[radial[0]] - centro[radial[0]],
                                   punto[radial[1]] - centro[radial[1]]))
            if tri_mat[elegido] == indice_goma and radio >= 0.98 * r_max:
                resultado["goma_banda"] += 1
                continue
            resultado["goma_interior" if tri_mat[elegido] == indice_goma else "llanta"] += 1
            if len(ejemplos) < 6:
                ejemplos.append([round(float(np.degrees(tita)), 1),
                                 round(float(x) * 1000.0, 1), round(radio * 1000.0, 1)])
    resultado["total"] = int(sum(resultado.values()))
    resultado["fuera_de_la_goma"] = int(resultado["total"] - resultado["goma_banda"])
    resultado["fraccion_fuera_de_la_goma"] = round(
        resultado["fuera_de_la_goma"] / max(resultado["total"], 1), 4)
    resultado["ejemplos_angulo_x_radio_mm"] = ejemplos
    return resultado


def auditar(doc: dict, blob: bytes) -> dict:
    informe = {"activo": str(GLB), "umbrales": {
        "redondez_sobre_R": REDONDEZ_MAX, "diametros_sobre_R": DIAMETROS_MAX,
        "corona_sobre_R": CORONA_MAX, "area_con_normal_al_reves": NORMALES_AL_REVES_MAX,
        "rayos_fuera_de_la_goma": RAYOS_FUERA_DE_LA_GOMA_MAX},
        "ruedas": {}, "materiales": [m.get("name") for m in doc.get("materials", [])],
        "problemas": []}
    for nodo in doc["nodes"]:
        if "mesh" not in nodo or not nodo["name"].startswith("wheel_"):
            continue
        nombre = nodo["name"]
        posiciones, normales, indices, materiales = [], [], [], []
        for prim in doc["meshes"][nodo["mesh"]]["primitives"]:
            attr = prim["attributes"]
            posiciones.append(accessor(doc, blob, attr["POSITION"]))
            if "NORMAL" in attr:
                normales.append(accessor(doc, blob, attr["NORMAL"]))
            indices.append(accessor(doc, blob, prim["indices"]).reshape(-1))
        base = 0
        for i in range(len(posiciones)):
            indices[i] = indices[i] + base
            base += len(posiciones[i])
        pos = np.vstack(posiciones)
        nrm = np.vstack(normales)
        tri = np.concatenate(indices).reshape(-1, 3)
        tri_mat = np.concatenate([np.full(len(i) // 3, p.get("material", -1))
                                  for i, p in zip(indices, doc["meshes"][nodo["mesh"]]["primitives"])])
        lo, hi = pos.min(axis=0), pos.max(axis=0)
        tam = hi - lo
        eje = int(np.argmin(tam))
        radial = [i for i in range(3) if i != eje]
        centro = (lo + hi) * 0.5
        local = pos - centro
        r = np.hypot(local[:, radial[0]], local[:, radial[1]])
        a = np.arctan2(local[:, radial[1]], local[:, radial[0]])
        w = local[:, eje]
        r_max = float(r.max())
        mitad = float(tam[eje]) * 0.5

        # --- normales: la almacenada (la que sombrea el motor) contra la geométrica
        caras = pos[tri]
        bruto = np.cross(caras[:, 1] - caras[:, 0], caras[:, 2] - caras[:, 0])
        area = np.linalg.norm(bruto, axis=1) * 0.5
        geo = bruto / np.where(area[:, None] < 1e-12, 1.0, area[:, None] * 2.0)
        centroide = caras.mean(axis=1)
        almacenada = nrm[tri].mean(axis=1)
        almacenada = almacenada / np.maximum(np.linalg.norm(almacenada, axis=1, keepdims=True), 1e-9)
        coseno = np.clip(np.einsum("ij,ij->i", geo, almacenada), -1.0, 1.0)
        angulo = np.degrees(np.arccos(coseno))
        area_reves = float(area[coseno < 0.0].sum())
        area_total = float(area.sum())
        fraccion_reves = area_reves / max(area_total, 1e-12)

        # --- redondez: radio de la silueta por sector ---------------------------
        sectores = ((a + np.pi) / (2 * np.pi) * SECTORES).astype(int) % SECTORES
        silueta = np.full(SECTORES, np.nan)
        for s in range(SECTORES):
            valores = r[sectores == s]
            if valores.size:
                silueta[s] = valores.max()
        validos = silueta[~np.isnan(silueta)]
        redondez = float(validos.max() - validos.min())
        # Silueta sólo de la BANDA de rodadura (sin flancos ni piezas interiores):
        # es la que define el contorno del neumático.
        banda = r >= BANDA * r_max
        silueta_banda = np.full(SECTORES, np.nan)
        for s in range(SECTORES):
            valores = r[banda & (sectores == s)]
            if valores.size:
                silueta_banda[s] = valores.max()
        validos_banda = silueta_banda[~np.isnan(silueta_banda)]
        redondez_banda = float(validos_banda.max() - validos_banda.min()) if validos_banda.size else 0.0

        # --- cilindricidad: radio de la banda a lo largo de la anchura ----------
        decima = np.clip(((w[banda] + mitad) / max(tam[eje], 1e-9) * 10).astype(int), 0, 9)
        radios_decima = [float(r[banda][decima == c].max()) for c in range(10) if (decima == c).any()]
        cilindro = float(max(radios_decima) - min(radios_decima)) if radios_decima else 0.0

        diam_a = float(local[:, radial[0]].max() - local[:, radial[0]].min())
        diam_b = float(local[:, radial[1]].max() - local[:, radial[1]].min())

        # --- piezas sueltas: volumen firmado, anidamiento y tamaño --------------
        clave = np.round(pos * 10000.0).astype(np.int64)
        _, fusionado = np.unique(clave, axis=0, return_inverse=True)
        parent = np.arange(int(fusionado.max()) + 1)
        raiz = np.array([int(v) for v in fusionado[tri.reshape(-1)]]).reshape(-1, 3)

        def find(x: int) -> int:
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x

        for x, y, z in raiz:
            rx, ry, rz = find(x), find(y), find(z)
            if ry != rx:
                parent[ry] = rx
            if rz != rx:
                parent[rz] = rx
        raices = np.array([find(int(v)) for v in fusionado])
        unicas = list(dict.fromkeys(raices.tolist()))
        detalle = []
        for numero, raiz_id in enumerate(unicas):
            mascara = raices[tri.reshape(-1)].reshape(-1, 3)
            miembros = np.isin(mascara[:, 0], [raiz_id])
            vertices_parte = np.unique(tri[miembros])
            p = pos[vertices_parte]
            c = p.mean(axis=0)
            bruto_parte = bruto[miembros]
            area_parte = area[miembros]
            volumen_firmado = float(np.einsum("ij,ij->i", centroide[miembros] - c,
                                              bruto_parte / 2.0).sum() / 3.0)
            hacia_dentro = float(area_parte[(np.einsum("ij,ij->i", geo[miembros],
                                                       centroide[miembros] - c) < 0.0)].sum())
            caja = p.max(axis=0) - p.min(axis=0)
            detalle.append({
                "vertices": int(len(vertices_parte)),
                "caras": int(miembros.sum()),
                "radio_max_mm": round(float(np.hypot(p[:, radial[0]], p[:, radial[1]]).max()) * 1000, 2),
                "radius_min_mm": round(float(np.hypot(p[:, radial[0]], p[:, radial[1]]).min()) * 1000, 2),
                "anchura_mm": round(float(caja[eje]) * 1000, 2),
                "centro_local_mm": [round(float(v) * 1000, 2) for v in c],
                "volumen_firmado_cm3": round(volumen_firmado * 1e6, 2),
                "relacion_volumen_caja": round(abs(volumen_firmado) * 6.0 /
                                              max(float(np.prod(np.maximum(caja, 1e-9))), 1e-12), 3),
                "area_que_mira_hacia_dentro_sobre_total": round(hacia_dentro / max(float(area_parte.sum()), 1e-12), 3),
                "caja_mm": [round(float(v) * 1000, 1) for v in caja],
            })
        detalle.sort(key=lambda p: -p["vertices"])
        # Anidamiento: la caja de una pieza dentro de la de otra.
        for i, uno in enumerate(detalle):
            for j, otro in enumerate(detalle):
                if i == j:
                    continue
                caja_uno = np.array(uno["caja_mm"])
                caja_otro = np.array(otro["caja_mm"])
                centro_uno = np.array(uno["centro_local_mm"])
                centro_otro = np.array(otro["centro_local_mm"])
                if np.all(np.abs(centro_uno - centro_otro) * 2 + caja_uno <= caja_otro + 1.0):
                    uno["dentro_de"] = j
                    break

        # --- protrusiones y reparto de materiales -------------------------------
        fuera_radio = int((r > r_max * 1.005).sum())
        fuera_ancho = int((np.abs(w) > mitad * 1.01).sum())
        materiales = {}
        r_c = np.hypot(centroide[:, radial[0]], centroide[:, radial[1]])
        for mat in sorted(set(tri_mat.tolist())):
            seleccion = tri_mat == mat
            if not seleccion.any():
                continue
            materiales[str(mat)] = {
                "caras": int(seleccion.sum()),
                "nombre": (doc["materials"][mat].get("name") if 0 <= mat < len(doc.get("materials", [])) else None),
                "radio_min_sobre_R": round(float(r_c[seleccion].min()) / r_max, 4),
                "radio_max_sobre_R": round(float(r_c[seleccion].max()) / r_max, 4),
                "radio_medio_sobre_R": round(float(r_c[seleccion].mean()) / r_max, 4),
                "caras_con_normal_al_reves": int((coseno[seleccion] < 0.0).sum()),
            }

        # --- TALÓN: radio del barril de la llanta --------------------------------
        # El barril es la superficie CILÍNDRICA interior de la llanta: caras con la
        # normal radial, como la banda de rodadura, pero a radio menor. Es la
        # frontera FÍSICA entre neumático y llanta y no depende de ningún
        # heurístico: se busca la banda de radio con más caras de normal radial por
        # debajo de 0,85 R. El neumático cubre desde ahí hacia fuera.
        radial_unit = np.zeros_like(centroide)
        con_r = np.maximum(np.hypot(centroide[:, radial[0]], centroide[:, radial[1]]), 1e-9)
        radial_unit[:, radial[0]] = centroide[:, radial[0]] / con_r
        radial_unit[:, radial[1]] = centroide[:, radial[1]] / con_r
        normal_radial = np.abs(np.einsum("ij,ij->i", geo, radial_unit))
        candidatos = normal_radial > 0.70
        barril = None
        mejor = (0, 0.0)
        bordes = np.linspace(0.0, r_max, 200)
        for i in range(199):
            seleccion = candidatos & (r_c >= bordes[i]) & (r_c < bordes[i + 1]) & (r_c < 0.85 * r_max)
            if int(seleccion.sum()) >= 50 and int(seleccion.sum()) > mejor[0]:
                mejor = (int(seleccion.sum()), (bordes[i] + bordes[i + 1]) * 0.5)
        if mejor[0]:
            barril = float(min(0.70 * r_max, max(0.40 * r_max, mejor[1])))
        # Radio en el que está el reparto actual, según las caras de cada material.
        nombre_material = {i: m.get("name") for i, m in enumerate(doc.get("materials", []))}
        reparto_goma = None
        reparto_llanta = None
        for indice, medida in materiales.items():
            if nombre_material.get(int(indice)) == "mat_fleet_tire":
                reparto_goma = medida["radio_min_sobre_R"] * r_max
            if nombre_material.get(int(indice)) == "mat_fleet_rim":
                reparto_llanta = medida["radio_max_sobre_R"] * r_max

        # --- visibilidad: ¿se ve la llanta a través de la goma? ------------------
        indice_goma = next((i for i, m in enumerate(doc.get("materials", []))
                            if m.get("name") == "mat_fleet_tire"), None)
        visibilidad_medida = None
        if indice_goma is not None:
            visibilidad_medida = visibilidad(pos, tri, tri_mat, indice_goma, eje, radial,
                                            r_max, mitad, centro)

        problemas = []
        if redondez_banda > REDONDEZ_MAX * r_max:
            problemas.append("silueta del neumático con %.1f mm de dispersión (máx %.1f)"
                             % (redondez_banda * 1000, REDONDEZ_MAX * r_max * 1000))
        if abs(diam_a - diam_b) > DIAMETROS_MAX * r_max:
            problemas.append("diámetros desiguales: %.1f y %.1f mm (diferencia %.1f)"
                             % (diam_a * 1000, diam_b * 1000, abs(diam_a - diam_b) * 1000))
        if cilindro > CORONA_MAX * r_max:
            problemas.append("corona con un escalón de %.1f mm (máx %.1f)"
                             % (cilindro * 1000, CORONA_MAX * r_max * 1000))
        if fraccion_reves > NORMALES_AL_REVES_MAX:
            problemas.append("%.1f %% del área con la normal almacenada al revés"
                             % (fraccion_reves * 100))
        for pieza in detalle:
            if "dentro_de" in pieza and pieza["caras"] > 20:
                problemas.append("pieza de %d caras metida dentro de otra (geometría duplicada)"
                                 % pieza["caras"])
        if fuera_radio:
            problemas.append("%d vértices más allá del radio máximo" % fuera_radio)
        if fuera_ancho:
            problemas.append("%d vértices más allá de la anchura" % fuera_ancho)
        # El reparto goma/llanta tiene que caer en el barril: si la llanta acaba
        # antes, una banda del propio barril queda pintada de goma (y al revés).
        desvio_talon = None
        if barril and reparto_goma is not None:
            desvio_talon = reparto_goma - barril
        if abs(desvio_talon) > 0.005:
            problemas.append("el reparto goma/llanta está a %.1f mm del barril (%.1f mm): "
                             "la llanta acaba %s del neumático"
                             % (desvio_talon * 1000, barril * 1000,
                                "por dentro" if desvio_talon > 0 else "por fuera"))
        if (visibilidad_medida and
                visibilidad_medida["fraccion_fuera_de_la_goma"] > RAYOS_FUERA_DE_LA_GOMA_MAX):
            problemas.append("desde fuera se ve la llanta (o el fondo) a través de la goma en "
                             "%d de %d direcciones (%.1f %%): a la goma le faltan trozos "
                             "(banda %d · goma por dentro %d · llanta %d · nada %d)"
                             % (visibilidad_medida["fuera_de_la_goma"], visibilidad_medida["total"],
                                100.0 * visibilidad_medida["fraccion_fuera_de_la_goma"],
                                visibilidad_medida["goma_banda"], visibilidad_medida["goma_interior"],
                                visibilidad_medida["llanta"], visibilidad_medida["nada"]))

        informe["ruedas"][nombre] = {
            "talon_barril_sobre_R": round(barril / r_max, 4) if barril else None,
            "talon_barril_mm": round(barril * 1000, 2) if barril else None,
            "caras_barril": mejor[0],
            "reparto_actual_goma_mm": round(reparto_goma * 1000, 2) if reparto_goma else None,
            "reparto_actual_llanta_mm": round(reparto_llanta * 1000, 2) if reparto_llanta else None,
            "desvio_del_reparto_al_barril_mm": round(desvio_talon * 1000, 2) if desvio_talon is not None else None,
            "caras": int(len(tri)),
            "eje_giro": "xyz"[eje],
            "radio_max_mm": round(r_max * 1000, 2),
            "anchura_mm": round(float(tam[eje]) * 1000, 2),
            "diametro_radial_a_mm": round(diam_a * 1000, 2),
            "diametro_radial_b_mm": round(diam_b * 1000, 2),
            "silueta_neumatico_dispersion_mm": round(redondez_banda * 1000, 2),
            "silueta_completa_dispersion_mm": round(redondez * 1000, 2),
            "silueta_por_sector_mm": [None if np.isnan(v) else round(v * 1000, 2) for v in silueta_banda],
            "corona_mm": round(cilindro * 1000, 2),
            "radios_banda_por_decima_mm": [round(v * 1000, 2) for v in radios_decima],
            "area_total_m2": round(area_total, 4),
            "area_con_normal_al_reves_m2": round(area_reves, 4),
            "fraccion_area_con_normal_al_reves": round(fraccion_reves, 4),
            "angulo_normal_almacenada_vs_geometrica_grados": {
                "p10": round(float(np.percentile(angulo, 10)), 2),
                "mediana": round(float(np.median(angulo)), 2),
                "p90": round(float(np.percentile(angulo, 90)), 2)},
            "piezas_sueltas": len(detalle),
            "piezas": detalle[:8],
            "vertices_fuera_de_radio": fuera_radio,
            "vertices_fuera_de_anchura": fuera_ancho,
            "materiales": materiales,
            "visibilidad": visibilidad_medida,
            "problemas": problemas,
        }
        informe["problemas"].extend(["%s: %s" % (nombre, p) for p in problemas])
    return informe


def main() -> int:
    doc, blob = load_glb(GLB)
    informe = auditar(doc, blob)
    print("ACTIVO %s" % GLB)
    print("%-10s %8s %8s %10s %10s %9s %7s %8s %8s %7s" % (
        "rueda", "R mm", "ancho", "diám.A", "diám.B", "silueta", "corona", "área↻", "talón", "piezas"))
    for nombre, d in informe["ruedas"].items():
        print("%-10s %8.2f %8.2f %10.2f %10.2f %9.2f %7.2f %7.1f%% %8s %7d" % (
            nombre, d["radio_max_mm"], d["anchura_mm"], d["diametro_radial_a_mm"],
            d["diametro_radial_b_mm"], d["silueta_neumatico_dispersion_mm"],
            d["corona_mm"], d["fraccion_area_con_normal_al_reves"] * 100,
            ("%.2f R" % d["talon_barril_sobre_R"]) if d["talon_barril_sobre_R"] else "?",
            d["piezas_sueltas"]))
    for nombre, d in informe["ruedas"].items():
        print("%-10s normal almacenada vs geométrica: p10 %.1f° · mediana %.1f° · p90 %.1f°"
              % (nombre, d["angulo_normal_almacenada_vs_geometrica_grados"]["p10"],
                 d["angulo_normal_almacenada_vs_geometrica_grados"]["mediana"],
                 d["angulo_normal_almacenada_vs_geometrica_grados"]["p90"]))
    for nombre, d in informe["ruedas"].items():
        print("%-10s materiales: %s" % (nombre, " · ".join(
            "%s %d caras %.2f-%.2f R (%d al revés)" % (m["nombre"], m["caras"], m["radio_min_sobre_R"],
                                                       m["radio_max_sobre_R"], m["caras_con_normal_al_reves"])
            for m in d["materiales"].values())))
    for nombre, d in informe["ruedas"].items():
        v = d.get("visibilidad")
        if v:
            print("%-10s visibilidad: goma en la banda %d/%d (%.2f %%) · goma por dentro %d · "
                  "llanta %d · nada %d -> %s"
                  % (nombre, v["goma_banda"], v["total"],
                     100.0 * v["goma_banda"] / max(v["total"], 1), v["goma_interior"],
                     v["llanta"], v["nada"],
                     "ok" if not v["fuera_de_la_goma"] else "DEFECTO: %d direcciones ven algo que no es goma"
                     % v["fuera_de_la_goma"]))
    for nombre, d in informe["ruedas"].items():
        for pieza in d["piezas"]:
            print("%-10s pieza %5d v %5d caras  R≤%7.1f mm  ancho %7.1f mm  vol %9.2f cm³ (%.2f caja) %.0f%% hacia dentro%s"
                  % (nombre, pieza["vertices"], pieza["caras"], pieza["radio_max_mm"], pieza["anchura_mm"],
                     pieza["volumen_firmado_cm3"], pieza["relacion_volumen_caja"],
                     pieza["area_que_mira_hacia_dentro_sobre_total"] * 100,
                     " [DENTRO DE OTRA]" if "dentro_de" in pieza else ""))
    if informe["problemas"]:
        print("\nPROBLEMAS (%d):" % len(informe["problemas"]))
        for problema in informe["problemas"]:
            print("  -", problema)
    else:
        print("\nFORMAS OK: las cuatro ruedas pasan los criterios de forma")
    OUT.write_text(json.dumps(informe, indent=1, ensure_ascii=False))
    print("informe: %s" % OUT)
    return 1 if informe["problemas"] else 0


if __name__ == "__main__":
    sys.exit(main())
