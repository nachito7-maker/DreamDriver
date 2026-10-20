#!/usr/bin/env python3
"""Mide el tamaño del coche EN PÍXELES sobre las capturas de la cámara.

Es la comprobación independiente de la medida geométrica de
`scripts/camera_probe.gd`: aquélla proyecta la caja del modelo con la cámara,
ésta cuenta los píxeles que de verdad cambia el coche en la imagen. Si las dos
coinciden, el coche ocupa lo que dicen las dos cuentas; si la geometría
estuviera mal, los píxeles no la acompañarían.

Tres modos:

  medida  <dir>          Sobre las capturas de la sonda: cada caso deja
                         `<caso>-coche.png` y `<caso>-fondo.png`, el MISMO
                         fotograma con el modelo visible y oculto. La silueta
                         es la diferencia de las dos imágenes: no depende de
                         ningún color ni de ninguna suposición.

  dispositivo <dir>      Sobre capturas del teléfono, donde no hay fotograma de
                         fondo: la silueta se saca con el clasificador de librea
                         (saturado u oscuro) dentro de la ventana inferior
                         central, y la velocidad se lee de la barra del HUD
                         (relleno #58ddad sobre 360 km/h). El clasificador se
                         valida antes contra la diferencia real en las capturas
                         del anfitrión (modo `medida`).

                         La mancha que se mide no es la MÁS GRANDE: es la que
                         contiene más librea azul oscura del coche (ver
                         `_componente_del_coche`). Medir la más grande se rompió
                         en `disp-006`: el césped de la izquierda encuadra como
                         saturado y sumó 15 077 px contra los 14 945 del coche,
                         así que la "silueta" saltó a 417 px de alto a 101 km/h y
                         la serie dejó de ser monótona. El azul oscuro de la
                         librea sí es exclusivo del coche.

  valida  <dir>          Sólo la comparación entre las dos formas de medir.

Sale con código distinto de cero si el coche no crece con la velocidad, si
alguna silueta toca el borde del cuadro o si la medida de píxeles y la
geométrica no describen lo mismo.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

try:
    from scipy import ndimage
except ImportError:  # pragma: no cover - sólo afecta al modo dispositivo
    ndimage = None

# --- criterios ---------------------------------------------------------------
DIFF_THRESHOLD = 14          # cambio mínimo por canal para contar un píxel
SIZE_GROWTH_MIN = 1.03       # cada escalón de velocidad, al menos un 3 % más
SIZE_TOTAL_MIN = 1.45        # y de parado a 200 km/h, un 45 % más
FRAME_MARGIN_MIN = 8         # píxeles libres entre la silueta y el borde
MIN_COMPONENTE_PX = 100      # mancha mínima de la diferencia que se considera coche
# Semilla de librea: el azul oscuro del chasis del Red Bull (medido en las
# capturas: (60, 70, 100) en el dispositivo y (50, 60, 78) en el anfitrión). Se
# pide luminancia baja y azul claramente dominante sobre rojo y verde, que es lo
# que lo separa del asfalto (45, 53, 59) —también oscuro, pero casi neutro, con
# b − r = 14—, del césped (197, 206, 127) y de los bordillos rojos (96, 53, 53).
SEMILLA_LUM_MAX = 120.0
SEMILLA_B_R_MIN = 22.0
SEMILLA_B_G_MIN = 10.0
AGREEMENT_MIN = 0.55         # la silueta debe ser al menos el 55 % de la caja
AGREEMENT_MAX = 1.35         # ... y no más de un 135 % (la caja es una cota)
ORDEN = ["parado", "50", "100", "150", "200"]
ORDEN_DISPOSITIVO = [0.0, 50.0, 100.0, 150.0, 200.0]

# El HUD ancla la telemetría arriba a la izquierda y escala con la ALTURA
# (`clamp(alto/900, 0,68 · 1,32)`, en `scripts/race_hud.gd`). La barra de
# velocidad está en (26, 91) dentro del panel de (24, 20) y mide 302 × 8 px
# antes de escalar, con un máximo de 360 km/h y relleno #58ddad.
BARRA = {"panel": (24.0, 20.0), "pos": (26.0, 91.0), "tam": (302.0, 8.0), "max_kmh": 360.0}
RELLENO = np.array([0x58, 0xDD, 0xAD], dtype=np.int16)

# Ventana inferior central: donde vive el coche y donde no hay HUD (la
# telemetría está arriba a la izquierda, el cronómetro arriba al centro, el
# mando abajo a la izquierda y los pedales a la derecha).
VENTANA = (0.28, 0.72, 0.42, 0.995)


def silueta_por_diferencia(coche: Path, fondo: Path) -> dict:
    """Silueta del coche = lo que cambia entre el fotograma con y sin modelo.

    De la diferencia se quedan las manchas CON TAMAÑO y se tira el ruido suelto:
    entre los dos fotogramas cambia el coche, pero también algún píxel aislado del
    HUD o del sombreado, y una caja que envuelva esos píxeles sueltos diría que el
    coche mide 279 px cuando mide 155 (medido: un píxel a y=495 estiraba la caja de
    la captura `frenado-final` desde y=618 hasta y=773).
    """
    a = np.asarray(Image.open(coche).convert("RGB")).astype(np.int16)
    b = np.asarray(Image.open(fondo).convert("RGB")).astype(np.int16)
    if a.shape != b.shape:
        raise ValueError(f"{coche.name} y {fondo.name} tienen tamaños distintos")
    alto, ancho = a.shape[0], a.shape[1]
    mascara = np.abs(a - b).max(axis=2) > DIFF_THRESHOLD
    if ndimage is not None and mascara.any():
        etiquetas, cuantas = ndimage.label(mascara)
        tamanos = ndimage.sum(mascara, etiquetas, range(1, cuantas + 1))
        mayor = float(tamanos.max())
        minimo = max(MIN_COMPONENTE_PX, mayor * 0.05)
        mascara = np.isin(etiquetas, [i + 1 for i, tamano in enumerate(tamanos) if tamano >= minimo])
    return _caja(mascara, alto, ancho)


def silueta_por_clasificador(png: Path, ventana=VENTANA) -> dict:
    """Silueta aproximada sin fondo de referencia: librea saturada u oscura.

    La máscara ancha (saturado u oscuro) captura el coche entero, neumáticos
    incluidos; la SELECCIÓN de la mancha es la que lleva la semilla de librea,
    porque el mundo también encuadra: el césped es saturado y los bordillos
    rojos lo son aún más. Ver `_componente_del_coche`.
    """
    a = np.asarray(Image.open(png).convert("RGB")).astype(np.int16)
    alto, ancho = a.shape[0], a.shape[1]
    rojo, verde, azul = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    saturacion = (a.max(axis=2) - a.min(axis=2)) / np.maximum(a.max(axis=2), 1)
    luminancia = a.mean(axis=2)
    librea = (saturacion > 0.28) | (luminancia < 58)
    semilla = ((luminancia < SEMILLA_LUM_MAX)
               & ((azul - rojo) >= SEMILLA_B_R_MIN)
               & ((azul - verde) >= SEMILLA_B_G_MIN))
    x0, x1 = int(ancho * ventana[0]), int(ancho * ventana[1])
    y0, y1 = int(alto * ventana[2]), int(alto * ventana[3])
    region = np.zeros((alto, ancho), bool)
    region[y0:y1, x0:x1] = True
    mascara = librea & region
    semilla = semilla & region
    if ndimage is None or not mascara.any():
        return _caja(mascara, alto, ancho)
    componentes = _componente_del_coche(mascara, semilla, region)
    if componentes is None:
        return _caja(mascara, alto, ancho)
    return _caja(componentes[0], alto, ancho, semilla_px=componentes[1])


def _componente_del_coche(mascara: np.ndarray, semilla: np.ndarray, region: np.ndarray):
    """Mancha del coche dentro de `mascara`: la que más semilla de librea tiene.

    Elegir la mancha MÁS GRANDE es lo que falló en el dispositivo: en `disp-006`
    el césped de la izquierda (saturado) encuadra y gana por 132 px, así que la
    silueta medida trepó a 417 px de alto a 101 km/h y la serie de aceleración
    dejó de crecer. Con la semilla de librea la mancha elegida es la del coche en
    las 15 capturas del teléfono y en las 12 del anfitrión (donde ya era la más
    grande, y por eso la validación no se mueve: 3,4 % de peor desvío).

    `disp-009` (192,7 km/h, batería del 15 de octubre) enseñó el segundo modo de
    fallo del mismo tipo: una banda de asfalto en sombra que cruza la pista, con
    semilla de azul oscuro (58 016 px: la sombra tira a azul) que supera a la del
    coche (12 885 px). La mancha elegida medía 1 067 px de ancho —toda la
    ventana— y tocaba TRES de sus cuatro bordes, mientras el coche estaba medido
    en la misma captura con 218 px de alto (entre los 191 de 152 km/h y los 244
    de 229 km/h, como toca). Por eso se descartan los candidatos que ATRAVIESAN
    LA VENTANA, entendido como tocar dos o más de sus bordes: el suelo y su
    sombra la atraviesan de lado a lado (tres bordes en `disp-009`), mientras el
    coche, medido, no toca ninguno en las 12 capturas del anfitrión y en 15 de
    las 16 del teléfono, y en la que toca (el coche recortado por la derecha a
    150 km/h en el anfitrión) toca uno solo: un objeto puede rozar un borde, pero
    no puede estar cortado por dos a la vez y seguir siendo un objeto. La regla
    sale de los bordes de `VENTANA`, que ya estaba declarada, y no de un umbral
    nuevo: el único número que elige es "dos", y sale de la definición de
    atravesar (un lado es rozar, dos es cruzar). Se descarta sólo si queda algún
    candidato que no la atraviese, y si no queda se mide el que la atraviesa y el
    informe lo enseña en la columna del margen.

    Devuelve `(mascara_de_la_mancha, semilla_dentro, area)` o `None` si no hay
    ninguna mancha.
    """
    etiquetas, cuantas = ndimage.label(mascara)
    if cuantas == 0:
        return None
    pegadas = _atraviesan_la_ventana(etiquetas, cuantas, region)
    if semilla.any():
        valores, cuentas = np.unique(etiquetas[semilla], return_counts=True)
        candidatos = {int(v): int(c) for v, c in zip(valores, cuentas) if v > 0}
    else:
        candidatos = {}
    enteras = {k: c for k, c in candidatos.items() if k not in pegadas}
    if enteras:
        elegida = max(enteras, key=lambda k: enteras[k])
        return etiquetas == elegida, enteras[elegida], int((etiquetas == elegida).sum())
    if candidatos:
        elegida = max(candidatos, key=lambda k: candidatos[k])
        return etiquetas == elegida, candidatos[elegida], int((etiquetas == elegida).sum())
    # Sin librea a la vista, se cae a la mancha más grande que quepa entera en la
    # ventana: peor medida, pero no una medida inventada, y el informe lo dice.
    tamanos = ndimage.sum(mascara, etiquetas, range(1, cuantas + 1))
    orden = sorted(range(1, cuantas + 1), key=lambda k: -tamanos[k - 1])
    mayor = next((k for k in orden if k not in pegadas), orden[0])
    return etiquetas == mayor, 0, int(tamanos[mayor - 1])


def _atraviesan_la_ventana(etiquetas: np.ndarray, cuantas: int, region: np.ndarray) -> set:
    """Componentes que tocan dos o más bordes de la ventana de búsqueda.

    Los bordes salen de `region`, que es la ventana ya declarada en `VENTANA`; el
    recuadro de cada componente lo da `ndimage.find_objects`, que es exacto. No
    hay ningún umbral de color que ajustar: es geometría de la ventana.
    """
    filas = np.nonzero(region.any(axis=1))[0]
    columnas = np.nonzero(region.any(axis=0))[0]
    if len(filas) == 0 or len(columnas) == 0:
        return set()
    arriba, abajo = int(filas.min()), int(filas.max())
    izquierda, derecha = int(columnas.min()), int(columnas.max())
    atravesadas = set()
    for indice, recorte in enumerate(ndimage.find_objects(etiquetas, max_label=cuantas),
                                    start=1):
        if recorte is None:
            continue
        renglones, columnas_del_recorte = recorte
        lados = ((renglones.start <= arriba) + (renglones.stop - 1 >= abajo)
                 + (columnas_del_recorte.start <= izquierda)
                 + (columnas_del_recorte.stop - 1 >= derecha))
        if lados >= 2:
            atravesadas.add(indice)
    return atravesadas


def _caja(mascara: np.ndarray, alto: int, ancho: int, semilla_px: int = 0) -> dict:
    ys, xs = np.nonzero(mascara)
    if len(xs) == 0:
        return {"pixeles": 0, "ancho_px": 0, "alto_px": 0, "alto_fraccion": 0.0,
                "margen_min_px": 0, "caja": None, "semilla_px": semilla_px}
    x0, x1 = int(xs.min()), int(xs.max())
    y0, y1 = int(ys.min()), int(ys.max())
    margenes = [x0, y0, ancho - 1 - x1, alto - 1 - y1]
    return {
        "pixeles": int(len(xs)),
        "semilla_px": semilla_px,
        "ancho_px": x1 - x0 + 1,
        "alto_px": y1 - y0 + 1,
        "alto_fraccion": (y1 - y0 + 1) / alto,
        "ancho_fraccion": (x1 - x0 + 1) / ancho,
        "margen_min_px": int(min(margenes)),
        "caja": [x0, y0, x1, y1],
    }


def velocidad_de_barra(png: Path) -> dict:
    """Velocidad leída de la barra del HUD (relleno #58ddad sobre 360 km/h).

    La barra se dibuja con las esquinas redondeadas, así que sus filas no miden
    lo mismo: las de arriba y abajo pierden el arranque redondeado (en una
    captura de 1080 de alto, ~11 px por extremo) y la del medio es la que mide
    el relleno de verdad. Se recorre la banda entera de la barra y se toma el
    tramo más largo que ARRANQUE en el borde izquierdo de la barra: eso deja
    fuera cualquier franja verde del mundo y mide lo que el juego pinta.
    """
    imagen = np.asarray(Image.open(png).convert("RGB")).astype(np.int16)
    alto, ancho = imagen.shape[0], imagen.shape[1]
    escala = min(max(alto / 900.0, 0.68), 1.32)
    x_ini = int(round((BARRA["panel"][0] + BARRA["pos"][0]) * escala))
    ancho_barra = BARRA["tam"][0] * escala
    y_arriba = (BARRA["panel"][1] + BARRA["pos"][1]) * escala
    y_abajo = y_arriba + BARRA["tam"][1] * escala
    y0 = max(0, int(round(y_arriba)) - 3)
    y1 = min(alto, int(round(y_abajo)) + 4)
    x1 = min(ancho, int(round(x_ini + ancho_barra)) + 5)
    x0 = max(0, x_ini - 5)
    if y1 <= y0 or x1 <= x0:
        return {"kmh": None, "motivo": "la barra cae fuera del lienzo"}
    banda = imagen[y0:y1, x0:x1, :]
    coincide = np.abs(banda - RELLENO).sum(axis=2) < 45
    relleno = 0
    fila_ganadora = None
    for indice_fila in range(coincide.shape[0]):
        fila = coincide[indice_fila]
        arranques = np.nonzero(fila)[0]
        for arranque in arranques:
            if not (0 <= arranque <= 9):      # el relleno nace en el borde izquierdo
                continue
            largo = 0
            while arranque + largo < fila.shape[0] and fila[arranque + largo]:
                largo += 1
            if largo > relleno:
                relleno = largo
                fila_ganadora = y0 + indice_fila
            break
    kmh = relleno / ancho_barra * BARRA["max_kmh"]
    return {"kmh": round(kmh, 1), "relleno_px": relleno, "ancho_barra_px": round(ancho_barra, 1),
            "fila": fila_ganadora, "x_ini": x_ini}


# --- modos -------------------------------------------------------------------

def modo_medida(directorio: Path) -> int:
    datos = json.loads((directorio / "medidas.json").read_text())
    casos = {c["id"]: c for c in datos["casos"]}
    modo = datos.get("modo", "nueva")
    salida: dict = {"modo": modo, "lienzo": datos["lienzo"], "casos": {}, "errores": []}
    filas = []
    for identificador in [c["id"] for c in datos["casos"]]:
        coche = directorio / "capturas" / f"{identificador}-coche.png"
        fondo = directorio / "capturas" / f"{identificador}-fondo.png"
        if not coche.exists() or not fondo.exists():
            continue
        silueta = silueta_por_diferencia(coche, fondo)
        clasificador = silueta_por_clasificador(coche)
        geometrico = casos[identificador]
        salida["casos"][identificador] = {
            "pixeles": silueta, "clasificador": clasificador,
            "geometrico_px": [geometrico["ancho_px"], geometrico["alto_px"]],
            "geometrico_fraccion": geometrico["alto_fraccion"],
            "velocidad_kph": geometrico["velocidad_kph"],
            "acuerdo_alto": silueta["alto_px"] / max(float(geometrico["alto_px"]), 1.0),
            "acuerdo_ancho": silueta["ancho_px"] / max(float(geometrico["ancho_px"]), 1.0),
        }
        filas.append((identificador, geometrico["velocidad_kph"], silueta, geometrico))
    # Criterios
    ordenados = [f for f in filas if f[0] in ORDEN]
    ordenados.sort(key=lambda f: ORDEN.index(f[0]))
    for identificador, kph, silueta, geometrico in filas:
        if silueta["pixeles"] == 0:
            salida["errores"].append(f"{identificador}: no se ve ninguna silueta")
            continue
        if silueta["margen_min_px"] < FRAME_MARGIN_MIN:
            salida["errores"].append(
                f"{identificador}: la silueta toca el borde (margen {silueta['margen_min_px']} px)")
        acuerdo = silueta["alto_px"] / max(float(geometrico["alto_px"]), 1.0)
        if not (AGREEMENT_MIN <= acuerdo <= AGREEMENT_MAX):
            salida["errores"].append(
                f"{identificador}: la silueta ({silueta['alto_px']} px) y la caja geométrica "
                f"({float(geometrico['alto_px']):.0f} px) no describen lo mismo ({acuerdo:.2f})")
    for i in range(1, len(ordenados)):
        anterior = ordenados[i - 1][2]["alto_fraccion"]
        actual = ordenados[i][2]["alto_fraccion"]
        if modo == "anterior":
            if actual > anterior / SIZE_GROWTH_MIN:
                salida["errores"].append(
                    f"anterior: de {ordenados[i-1][0]} a {ordenados[i][0]} km/h los píxeles "
                    f"no encogen ({anterior:.3f} → {actual:.3f})")
        elif actual < anterior * SIZE_GROWTH_MIN:
            salida["errores"].append(
                f"de {ordenados[i-1][0]} a {ordenados[i][0]} km/h los píxeles "
                f"no crecen ({anterior:.3f} → {actual:.3f})")
    if ordenados:
        factor = ordenados[-1][2]["alto_fraccion"] / max(ordenados[0][2]["alto_fraccion"], 1e-6)
        salida["factor_pixeles"] = factor
        if modo != "anterior" and factor < SIZE_TOTAL_MIN:
            salida["errores"].append(
                f"de parado a 200 km/h los píxeles sólo crecen un {(factor - 1) * 100:.0f} %")
    salida["filas"] = [
        {"id": i, "velocidad_kph": k, "pixel_alto_px": s["alto_px"], "pixel_ancho_px": s["ancho_px"],
         "pixel_alto_fraccion": s["alto_fraccion"], "geometrico_alto_px": g["alto_px"],
         "geometrico_alto_fraccion": g["alto_fraccion"], "margen_min_px": s["margen_min_px"],
         "acuerdo": s["alto_px"] / max(float(g["alto_px"]), 1.0)}
        for i, k, s, g in filas
    ]
    salida["passed"] = not salida["errores"]
    destino = directorio / "pixeles.json"
    destino.write_text(json.dumps(salida, indent=2))
    print(f"PIXELES modo={modo} lienzo={datos['lienzo']} capturas={len(filas)}")
    print(f"{'caso':<16}{'km/h':>7}{'píxeles alto':>14}{'% alto':>9}{'geométrico':>12}{'acuerdo':>9}{'margen':>8}")
    for fila in salida["filas"]:
        print(f"{fila['id']:<16}{fila['velocidad_kph']:>7.1f}{fila['pixel_alto_px']:>14}"
              f"{fila['pixel_alto_fraccion'] * 100:>8.2f}%{fila['geometrico_alto_px']:>12.0f}"
              f"{fila['acuerdo']:>9.2f}{fila['margen_min_px']:>8}")
    for error in salida["errores"]:
        print(f"  ERROR {error}")
    print(f"PIXELES factor={salida.get('factor_pixeles', 0.0):.2f} informe={destino} "
          f"passed={salida['passed']} errores={len(salida['errores'])}")
    return 0 if salida["passed"] else 1


def modo_dispositivo(directorio: Path) -> int:
    """Silueta y velocidad de las capturas del teléfono, sin fondo de referencia.

    En el dispositivo no hay fotograma sin coche, así que la silueta la saca el
    clasificador de librea, que antes se valida contra la diferencia real en las
    capturas del anfitrión (modo `valida`).

    La comprobación de que el coche crece con la velocidad sólo tiene sentido
    dentro de una MANIOBRA: `capturar_dispositivo.py` deja en `capturas.json` la
    fase de cada captura, y aquí se separan la aceleración (el coche tiene que
    crecer al subir de velocidad) de la frenada (tiene que encoger al bajarla).
    Mezclarlas compara peras con manzanas: una captura frenando fuerte mide más
    que una acelerando a la misma velocidad, porque el coche va de morro bajo.
    Sin ese fichero, sólo se comprueba la tendencia de conjunto y se dice.
    """
    imagenes = sorted(directorio.glob("*.png"))
    if not imagenes:
        print(f"DISPOSITIVO no hay capturas en {directorio}")
        return 1
    fases: dict[str, str] = {}
    fichas = directorio / "capturas.json"
    if fichas.exists():
        for ficha in json.loads(fichas.read_text()).get("capturas", []):
            fases[ficha["archivo"]] = ficha.get("fase", "")
    filas = []
    for png in imagenes:
        silueta = silueta_por_clasificador(png)
        barra = velocidad_de_barra(png)
        filas.append({"archivo": png.name, "kmh": barra["kmh"], "barra": barra,
                      "fase": fases.get(png.name, ""),
                      "alto_px": silueta["alto_px"], "ancho_px": silueta["ancho_px"],
                      "alto_fraccion": silueta["alto_fraccion"],
                      "margen_min_px": silueta["margen_min_px"], "pixeles": silueta["pixeles"],
                      "semilla_px": silueta.get("semilla_px", 0)})
    conocidas = [f for f in filas if f["kmh"] is not None and f["alto_px"] > 0]
    conocidas.sort(key=lambda f: f["kmh"])
    salida: dict = {"capturas": filas, "errores": []}
    print(f"{'captura':<20}{'km/h':>7}{'alto px':>9}{'% alto':>9}{'ancho px':>10}{'margen':>8}")
    for fila in conocidas:
        print(f"{fila['archivo']:<20}{fila['kmh']:>7.1f}{fila['alto_px']:>9}"
              f"{fila['alto_fraccion'] * 100:>8.2f}%{fila['ancho_px']:>10}{fila['margen_min_px']:>8}")
    if len(conocidas) < 3:
        salida["errores"].append("menos de tres capturas con velocidad legible")
        salida["passed"] = False
    else:
        mas_rapida = conocidas[-1]["kmh"]
        # Velocidades equivalentes a las de la sonda. La más alta que el coche
        # haya alcanzado en la recta del dispositivo: si no llega a 200, ese
        # caso queda cubierto por la medida del anfitrión, que usa el MISMO
        # lienzo (2400x1080 en el SubViewport, 2424x1080 el aparato y el HUD
        # escalando con la altura), y así se declara.
        aceleracion = [f for f in conocidas if f["fase"] in ("reposo", "aceleracion")]
        frenada = [f for f in conocidas if f["fase"] in ("frenada", "parado-final")]
        if not aceleracion:
            aceleracion = conocidas
        objetivos = [o for o in ORDEN_DISPOSITIVO if o <= mas_rapida + 10.0]
        elegidas = []
        for objetivo in objetivos:
            distancia, fila = min(((abs(f["kmh"] - objetivo), f) for f in aceleracion),
                                  key=lambda par: par[0])
            elegidas.append({"objetivo_kph": objetivo, "archivo": fila["archivo"],
                             "kmh": fila["kmh"], "desvio_kph": round(distancia, 1),
                             "alto_px": fila["alto_px"], "alto_fraccion": fila["alto_fraccion"],
                             "margen_min_px": fila["margen_min_px"],
                             "semilla_px": fila["semilla_px"]})
        salida["equivalencias"] = elegidas
        salida["velocidad_maxima_kph"] = mas_rapida
        for anterior, actual in zip(elegidas, elegidas[1:]):
            if actual["alto_fraccion"] < anterior["alto_fraccion"] * SIZE_GROWTH_MIN:
                salida["errores"].append(
                    f"en el dispositivo, de {anterior['kmh']:.0f} a {actual['kmh']:.0f} km/h "
                    f"el coche no crece ({anterior['alto_px']} → {actual['alto_px']} px)")
        if elegidas:
            factor = elegidas[-1]["alto_fraccion"] / max(elegidas[0]["alto_fraccion"], 1e-6)
            salida["factor"] = factor
            if factor < SIZE_TOTAL_MIN:
                salida["errores"].append(
                    f"en el dispositivo el coche sólo crece un {(factor - 1) * 100:.0f} % "
                    f"entre {elegidas[0]['kmh']:.0f} y {elegidas[-1]['kmh']:.0f} km/h")
        # La frenada se comprueba en su propia serie, de más rápido a más lento:
        # al bajar la velocidad el coche tiene que encoger.
        serie_frenada = sorted(frenada, key=lambda f: -f["kmh"])
        salida["frenada"] = [{"archivo": f["archivo"], "kmh": f["kmh"],
                              "alto_px": f["alto_px"], "alto_fraccion": f["alto_fraccion"]}
                             for f in serie_frenada]
        for anterior, actual in zip(serie_frenada, serie_frenada[1:]):
            if actual["alto_fraccion"] > anterior["alto_fraccion"] / SIZE_GROWTH_MIN:
                salida["errores"].append(
                    f"en el dispositivo, frenando de {anterior['kmh']:.0f} a "
                    f"{actual['kmh']:.0f} km/h el coche no encoge "
                    f"({anterior['alto_px']} → {actual['alto_px']} px)")
        for fila in conocidas:
            if fila["margen_min_px"] < FRAME_MARGIN_MIN:
                salida["errores"].append(f"{fila['archivo']}: la silueta toca el borde")
        # Cada captura debe haber elegido su mancha por la librea, no por tamaño:
        # si alguna cae al respaldo, la medida de esa captura no es la del coche.
        sin_semilla = [f["archivo"] for f in conocidas if f["semilla_px"] == 0]
        if sin_semilla:
            salida["errores"].append(
                "sin librea que identifique el coche en " + ", ".join(sin_semilla)
                + "; se midió la mancha más grande")
        salida["sin_semilla"] = sin_semilla
        if not fases:
            print("DISPOSITIVO aviso: sin capturas.json no se comprueba por fases; "
                  "la tendencia de conjunto se mide igual")
        salida["passed"] = not salida["errores"]
    destino = directorio / "pixeles-dispositivo.json"
    destino.write_text(json.dumps(salida, indent=2))
    for equivalencia in salida.get("equivalencias", []):
        print("DISPOSITIVO objetivo %4.0f km/h -> %s a %.1f km/h (%d px, %.2f %% del alto)"
              % (equivalencia["objetivo_kph"], equivalencia["archivo"], equivalencia["kmh"],
                 equivalencia["alto_px"], equivalencia["alto_fraccion"] * 100))
    for paso in salida.get("frenada", []):
        print("DISPOSITIVO frenada %6.1f km/h -> %s (%d px, %.2f %% del alto)"
              % (paso["kmh"], paso["archivo"], paso["alto_px"], paso["alto_fraccion"] * 100))
    for error in salida["errores"]:
        print(f"  ERROR {error}")
    print(f"DISPOSITIVO factor={salida.get('factor', 0.0):.2f} "
          f"max=%s km/h informe={destino} passed={salida['passed']} "
          f"errores={len(salida['errores'])}"
          % (f"{salida.get('velocidad_maxima_kph'):.1f}" if salida.get('velocidad_maxima_kph') else "?"))
    return 0 if salida["passed"] else 1


def modo_valida(directorio: Path) -> int:
    datos = json.loads((directorio / "medidas.json").read_text())
    peor = 0.0
    for caso in datos["casos"]:
        coche = directorio / "capturas" / f"{caso['id']}-coche.png"
        if not coche.exists():
            continue
        real = silueta_por_diferencia(coche, directorio / "capturas" / f"{caso['id']}-fondo.png")
        clasificador = silueta_por_clasificador(coche)
        razon = clasificador["alto_px"] / max(real["alto_px"], 1)
        peor = max(peor, abs(1.0 - razon))
        print(f"VALIDA {caso['id']:<16} diferencia={real['alto_px']:>4} px "
              f"clasificador={clasificador['alto_px']:>4} px razón={razon:.2f}")
    print(f"VALIDA peor desvío del clasificador={peor * 100:.1f} %")
    return 0 if peor < 0.35 else 1


def main() -> int:
    analizador = argparse.ArgumentParser(description=__doc__,
                                         formatter_class=argparse.RawDescriptionHelpFormatter)
    analizador.add_argument("modo", choices=["medida", "dispositivo", "valida"])
    analizador.add_argument("directorio", type=Path)
    argumentos = analizador.parse_args()
    if argumentos.modo == "medida":
        return modo_medida(argumentos.directorio)
    if argumentos.modo == "dispositivo":
        return modo_dispositivo(argumentos.directorio)
    return modo_valida(argumentos.directorio)


if __name__ == "__main__":
    sys.exit(main())
