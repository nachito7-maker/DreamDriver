#!/usr/bin/env python3
"""Composición de la cámara del MORRO, medida en píxeles.

La composición no se puede juzgar proyectando vértices: la cámara del morro está
a 12 cm del carenado, y una caja envolvente de geometría pegada al plano cercano
proyecta 21 anchos de lienzo con el encuadre perfectamente correcto (medido). Se
mide, como en la fase de la cámara de persecución, POR DIFERENCIA DE FOTOGRAMAS:
la sonda (`scripts/camera_nose_probe.gd`) deja por cada caso tres capturas del
mismo instante —

    composicion-<caso>-todo.png             coche entero visible
    composicion-<caso>-sin-coche.png        modelo oculto (fondo limpio)
    composicion-<caso>-sin-delanteras.png   sólo las ruedas delanteras ocultas

— y lo que cambia entre la primera y la segunda es la silueta del coche; entre
la primera y la tercera, la de los neumáticos delanteros.

Además se mide la REFERENCIA aprobada con una regla declarada (librea azul oscura
o negro neutro de neumático), para no comparar contra un recuerdo, y se exige que
la franja del coche del juego caiga dentro de ±0,18 de la de la referencia.

La sonda deja también dos capturas con el coche pintado de color PLANO (magenta el
cuerpo, cian los neumáticos delanteros), y la silueta se recorta por color: no
depende de lo que haya detrás. Ese es el recorte que decide en las SEIS situaciones,
y las dos reglas de este medidor —la pintada y la diferencia de fotogramas— se
calculan siempre y se comparan: si no coinciden, la captura pintada trae algo que no
es el coche y la comprobación lo publica como fallo (se admite 0,05 de diferencia).
Los números y el porqué están en el comentario de `TOLERANCIA_ENTRE_REGLAS`.

Sale con código distinto de cero si algo se sale del criterio.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

try:
    from scipy import ndimage
except ImportError:  # pragma: no cover
    ndimage = None

RAIZ = Path(__file__).resolve().parents[3]
CAPTURAS = RAIZ / ".tools/recovery/fase-fp/capturas"
REFERENCIA = RAIZ / ".tools/recovery/fase-fp/referencia.png"
INFORME = RAIZ / ".tools/recovery/fase-fp/morro-pixeles.json"

ORDEN = ["parado", "100", "150", "200", "curva", "frenada"]

DIFF_THRESHOLD = 14          # cambio mínimo por canal para contar un píxel
MIN_COMPONENTE_PX = 400      # mancha mínima que se considera coche o neumático

# --- criterios ---------------------------------------------------------------
# La franja del coche es lo que ocupa desde el borde inferior del cuadro hacia
# arriba (morro, alerón y neumáticos). El margen ancho de partida se cierra
# después contra la referencia medida.
CAR_BAND_MIN = 0.18
CAR_BAND_MAX = 0.62
CAR_BAND_TOLERANCIA = 0.18   # diferencia máxima admitida con la referencia
CAR_CENTRO_MAX = 0.12        # el morro va centrado: |centro_x − 0,5|
TIRE_MIN_PX = 0.005          # cada neumático, al menos 0,5 % del lienzo
TIRE_BANDA_Y_MIN = 0.42      # y siempre en la mitad inferior del cuadro
# Regla declarada para medir la referencia (no hay fondo limpio que restar).
REF_LIBREA_B_R_MIN = 18      # azul claramente dominante: chasis del Red Bull
REF_LIBREA_LUM_MAX = 120.0
REF_NEUMATICO_LUM_MAX = 58.0  # negro neutro del neumático
REF_NEUMATICO_SAT_MAX = 0.22  # ... pero no el bordillo rojo ni el césped


def _componentes(mascara: np.ndarray, banda_inferior: bool = False) -> np.ndarray:
    """Quita el ruido suelto: se queda con las manchas con tamaño.

    Con `banda_inferior` se queda además sólo con las manchas cuyo borde SUPERIOR
    cae en la parte baja del cuadro (por debajo de `TIRE_BANDA_Y_MIN` del alto):
    así lo que la regla de color pueda pescar del paisaje —una barandilla, un
    panel, el velo del horizonte, el cielo— queda fuera sin exigir que el coche
    forme UNA sola mancha pegada a la última fila.

    Esa exigencia —tocar la última fila— fue la regla anterior y estaba mal
    planteada para esta cámara: el morro del MP4/4 se ve como TRES manchas
    separadas (el alerón central y los dos grupos rueda-pontón) y cuál de ellas
    llega a la última fila depende del balanceo de la suspensión y de la curva
    (medido: a 150 km/h sólo la derecha llegaba, y el coche quedaba medido como
    medio coche, descentrado en x = 0,69). La banda inferior conserva lo que la
    regla del borde protegía —descartar el paisaje— sin atarse a una sola mancha.
    """
    if ndimage is None or not mascara.any():
        return mascara
    etiquetas, cuantas = ndimage.label(mascara)
    if cuantas == 0:
        return mascara
    tamanos = ndimage.sum(mascara, etiquetas, range(1, cuantas + 1))
    mayor = float(tamanos.max())
    minimo = max(MIN_COMPONENTE_PX, mayor * 0.05)
    quedan = [i + 1 for i, tamano in enumerate(tamanos) if tamano >= minimo]
    if banda_inferior:
        techo = mascara.shape[0] * TIRE_BANDA_Y_MIN
        cajas = ndimage.find_objects(etiquetas)
        quedan = [i for i in quedan if cajas[i - 1][0].start >= techo]
    return np.isin(etiquetas, quedan)


def _diferencia(a: Path, b: Path) -> np.ndarray:
    uno = np.asarray(Image.open(a).convert("RGB")).astype(np.int16)
    otro = np.asarray(Image.open(b).convert("RGB")).astype(np.int16)
    if uno.shape != otro.shape:
        raise ValueError(f"{a.name} y {b.name} tienen tamaños distintos")
    return _componentes(np.abs(uno - otro).max(axis=2) > DIFF_THRESHOLD)


def _lados(mascara: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Parte la silueta por la mitad del cuadro, conservando el tamaño completo
    para que las fracciones se midan contra el lienzo entero."""
    ancho = mascara.shape[1]
    izquierda = mascara.copy()
    izquierda[:, ancho // 2 :] = False
    derecha = mascara.copy()
    derecha[:, : ancho // 2] = False
    return izquierda, derecha


def _rueda(mascara: np.ndarray, lado: str) -> np.ndarray:
    """Silueta de UN neumático delantero: la mancha MÁS GRANDE de ese lado.

    Partir la máscara por la mitad (`_lados`) mide la rueda sólo mientras esa
    mitad contenga una única mancha. En las capturas pintadas del MP4/4 no es
    así: el cian de las delanteras marca también un elemento central (medido a
    100 km/h: 11.984 px en x 0,462–0,547), que al partir por la mitad entraba en
    las dos ruedas y arrastraba la caja de cada una hasta x = 0,50: el centro de
    la izquierda salía 0,37 y el de la derecha 0,63, y el criterio de composición
    —ruedas a los lados, centro de cada una fuera de ±0,15— fallaba en las seis
    situaciones por la MEDIDA, no por el encuadre. Con la mancha mayor por lado,
    la silueta es la de la rueda (x 0,234–0,352 y 0,645–0,770, centros 0,29 y
    0,71). Se devuelve el lienzo completo para que las fracciones sigan siendo
    contra el ancho y el alto del cuadro.
    """
    mitad = mascara.shape[1] // 2
    izquierda = lado == "izquierda"
    vista = mascara[:, :mitad] if izquierda else mascara[:, mitad:]
    resultado = np.zeros_like(mascara)
    if not vista.any():
        return resultado
    elegida = vista
    if ndimage is not None:
        etiquetas, cuantas = ndimage.label(vista)
        if cuantas > 1:
            tamanos = ndimage.sum(vista, etiquetas, range(1, cuantas + 1))
            elegida = etiquetas == int(np.argmax(tamanos)) + 1
    if izquierda:
        resultado[:, :mitad] = elegida
    else:
        resultado[:, mitad:] = elegida
    return resultado


def _medida(mascara: np.ndarray, lado: str = "") -> dict:
    alto, ancho = mascara.shape
    ys, xs = np.nonzero(mascara)
    if len(xs) == 0:
        return {"pixeles": 0, "fraccion_lienzo": 0.0, "caja": None}
    x0, x1, y0, y1 = int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max())
    return {
        "lado": lado,
        "pixeles": int(len(xs)),
        "fraccion_lienzo": round(len(xs) / (alto * ancho), 5),
        "caja": [x0, y0, x1, y1],
        "x0_fraccion": round(x0 / ancho, 4),
        "x1_fraccion": round(x1 / ancho, 4),
        "y0_fraccion": round(y0 / alto, 4),
        "y1_fraccion": round(y1 / alto, 4),
        "centro_x_fraccion": round((x0 + x1) / 2.0 / ancho, 4),
        "centro_y_fraccion": round((y0 + y1) / 2.0 / alto, 4),
        "toca_abajo": y1 >= alto - 2,
        "toca_lados": bool(x0 <= 1 or x1 >= ancho - 2),
    }


def referencia() -> dict:
    """Franja del coche en la referencia aprobada, con la regla declarada."""
    imagen = np.asarray(Image.open(REFERENCIA).convert("RGB")).astype(np.int16)
    alto, ancho = imagen.shape[0], imagen.shape[1]
    rojo, verde, azul = imagen[:, :, 0], imagen[:, :, 1], imagen[:, :, 2]
    luminancia = imagen.mean(axis=2)
    saturacion = (imagen.max(axis=2) - imagen.min(axis=2)) / np.maximum(imagen.max(axis=2), 1)
    librea = ((azul - rojo) >= REF_LIBREA_B_R_MIN) & (luminancia < REF_LIBREA_LUM_MAX)
    neumaticos = (luminancia < REF_NEUMATICO_LUM_MAX) & (saturacion < REF_NEUMATICO_SAT_MAX)
    mascara = _componentes(librea | neumaticos)
    # En una captura sin fondo limpio la regla también marca cosas oscuras que no
    # son el coche: el panel negro del marcador del circuito (arriba, en el
    # centro) entraba en la máscara y la franja salía 1,00 con el coche ocupando
    # media pantalla. El coche es la mancha oscura CONTIGUA al borde inferior, así
    # que de las manchas que tocan la última fila se toma la mayor.
    if ndimage is not None:
        etiquetas, cuantas = ndimage.label(mascara)
        borde = set(np.unique(etiquetas[-1]).tolist()) - {0}
        if borde:
            tamanos = ndimage.sum(mascara, etiquetas, list(borde))
            elegida = list(borde)[int(np.argmax(tamanos))]
            mascara = etiquetas == elegida
        else:
            mascara = mascara & (np.arange(alto)[:, None] >= alto * 0.5)
    coche = _medida(mascara)
    if coche["caja"] is None:
        return {"medida": False}
    franja = 1.0 - coche["y0_fraccion"]
    return {
        "medida": True,
        "lienzo": [ancho, alto],
        "franja_coche": round(franja, 4),
        "centro_x_fraccion": coche["centro_x_fraccion"],
        "pixeles_coche": coche["pixeles"],
        "neumatico_izquierdo": _medida(_rueda(mascara, "izquierda"), "izquierda"),
        "neumatico_derecho": _medida(_rueda(mascara, "derecha"), "derecha"),
    }


# Umbrales medidos sobre las propias capturas: el material plano magenta sale
# (255, 0, 255) y el cian (25, 104, 249), mientras el cielo —que sigue
# dibujándose aunque se oculte el nodo de entorno— sale (155, 199, 226). Con los
# umbrales flojos de partida (30) el cielo entraba en la máscara cian: min(g,b) − r
# = 44. Con 60 y el techo del canal opuesto en 110, el cielo queda fuera por los
# dos lados y las dos siluetas se recortan exactas.
COLOR_MAGENTA = "magenta"
COLOR_CIAN = "cian"
COLOR_UMBRAL = 60
COLOR_TECHO = 110


def _mascara_color(png: Path, color: str) -> np.ndarray:
    """Silueta recortada por el COLOR PLANO con el que la sonda la pinta.

    El coche se fotografía con un material magenta sin iluminación y los
    neumáticos delanteros con uno cian, así que la silueta se recorta por color y
    no depende del fondo (la diferencia de fotogramas sí depende, y donde el
    asfalto es tan oscuro como el neumático pierde el 80 % de su superficie:
    medido, 5.083 px a 150 km/h frente a 28.098 a 100 km/h con la misma cámara).
    Verde y rojo no sirven: el circuito lleva arbolado verde (que entraba en la
    máscara del coche y la hacía llegar al borde superior del cuadro) y rojo en
    bordillos, paneles y gradas.
    """
    imagen = np.asarray(Image.open(png).convert("RGB")).astype(np.int16)
    rojo, verde, azul = imagen[:, :, 0], imagen[:, :, 1], imagen[:, :, 2]
    if color == COLOR_MAGENTA:
        bajo = np.minimum(rojo, azul)
        return (bajo - verde > COLOR_UMBRAL) & (bajo > 120) & (verde < COLOR_TECHO)
    bajo = np.minimum(verde, azul)
    return (bajo - rojo > COLOR_UMBRAL) & (bajo > 120) & (rojo < COLOR_TECHO)


# La silueta del coche se mide recortando el COLOR PLANO con el que la sonda lo
# pinta (magenta), en las seis situaciones. Las dos reglas de este medidor —la
# pintada y la diferencia entre el fotograma con el coche y sin él— se calculan
# siempre y se comparan: si no coinciden, la captura pintada trae algo que no es el
# coche y la comprobación lo dice en vez de elegir la que más convenga. Estuvo
# pasando: mientras las fotografías de la curva se tomaban RODANDO, la captura
# pintada traía además una banda magenta sobre la parte alta del cuadro que el
# fotograma normal dibuja como cielo (medido: la fila 200, columna 1200 salía
# (255, 0, 255) contra (151, 187, 205)), y la franja pintada salía 0,87 frente a
# 0,32 por diferencia. Con las fotografías tomadas con el coche DETENIDO en el
# mismo punto del viraje (que es lo que hace ahora la sonda, ver
# `CURVA_ASENTAMIENTO_DETENIDO_S`) las dos reglas dan la misma franja y el mismo
# borde superior en las seis situaciones (0,316–0,336, y0 = 717–739), y esa banda
# ya no aparece.
TOLERANCIA_ENTRE_REGLAS = 0.05


def caso(nombre: str) -> dict | None:
    todo = CAPTURAS / f"composicion-{nombre}-todo.png"
    sin_coche = CAPTURAS / f"composicion-{nombre}-sin-coche.png"
    sin_delanteras = CAPTURAS / f"composicion-{nombre}-sin-delanteras.png"
    magenta = CAPTURAS / f"composicion-{nombre}-coche-magenta.png"
    cian = CAPTURAS / f"composicion-{nombre}-delanteras-cian.png"
    if not (todo.exists() and sin_coche.exists() and sin_delanteras.exists()
            and magenta.exists() and cian.exists()):
        return None
    pintada = _componentes(_mascara_color(magenta, COLOR_MAGENTA), banda_inferior=True)
    ruedas = _componentes(_mascara_color(cian, COLOR_CIAN), banda_inferior=True)
    alto, ancho = pintada.shape
    # La otra regla del medidor: la diferencia entre el fotograma con el coche y
    # sin él. Se calcula siempre y se compara con la pintada (ver arriba).
    dif_coche = _diferencia(todo, sin_coche)
    dif_ruedas = _diferencia(todo, sin_delanteras)
    medido = _medida(pintada)
    franja_pintada = round(1.0 - medido["y0_fraccion"], 4) if medido["caja"] else 0.0
    return {
        "id": nombre,
        "lienzo": [ancho, alto],
        "regla_de_la_silueta": "color pintado",
        "coche": medido,
        "franja_coche": franja_pintada,
        "franja_coche_pintada": franja_pintada,
        "pixeles_coche_pintado": _medida(pintada)["pixeles"],
        "neumatico_izquierdo": _medida(_rueda(ruedas, "izquierda"), "izquierda"),
        "neumatico_derecho": _medida(_rueda(ruedas, "derecha"), "derecha"),
        "por_diferencia": {
            "coche_px": _medida(dif_coche)["pixeles"],
            "franja_coche": (round(1.0 - _medida(dif_coche)["y0_fraccion"], 4)
                             if _medida(dif_coche)["caja"] else 0.0),
            "neumatico_izquierdo_px": _medida(_rueda(dif_ruedas, "izquierda"))["pixeles"],
            "neumatico_derecho_px": _medida(_rueda(dif_ruedas, "derecha"))["pixeles"],
        },
    }


def main() -> int:
    errores: list[str] = []
    if not REFERENCIA.exists():
        errores.append(f"falta la referencia aprobada en {REFERENCIA}")
        pat = {}
    else:
        pat = referencia()
        if pat.get("medida"):
            print(f"REFERENCIA {Path(REFERENCIA).name} {pat['lienzo'][0]}x{pat['lienzo'][1]}  "
                  f"franja_coche={pat['franja_coche']:.2f}  centro_x={pat['centro_x_fraccion']:.2f}  "
                  f"neumáticos: izq {pat['neumatico_izquierdo']['pixeles']} px "
                  f"(x {pat['neumatico_izquierdo']['x0_fraccion']:.2f}–{pat['neumatico_izquierdo']['x1_fraccion']:.2f})  "
                  f"der {pat['neumatico_derecho']['pixeles']} px")
        else:
            errores.append("no se pudo medir el coche en la referencia")

    if pat.get("medida"):
        banda = (max(CAR_BAND_MIN, pat["franja_coche"] - CAR_BAND_TOLERANCIA),
                 min(CAR_BAND_MAX, pat["franja_coche"] + CAR_BAND_TOLERANCIA))
    else:
        banda = (CAR_BAND_MIN, CAR_BAND_MAX)
    print(f"criterio de franja del coche con la referencia: {banda[0]:.2f} – {banda[1]:.2f} del alto")

    casos = []
    for nombre in ORDEN:
        medida = caso(nombre)
        if medida is None:
            errores.append(f"{nombre}: faltan las tres capturas de composición")
            continue
        casos.append(medida)
        c = medida["coche"]
        ancho, alto = medida["lienzo"]
        print(f"MORRO {nombre:<8} franja={medida['franja_coche']:.2f}  centro_x={c['centro_x_fraccion']:.2f}  "
              f"neumáticos {medida['neumatico_izquierdo']['pixeles']:>6} / {medida['neumatico_derecho']['pixeles']:>6} px")
        if medida["franja_coche"] < banda[0] or medida["franja_coche"] > banda[1]:
            errores.append(f"{nombre}: el coche ocupa la franja inferior {medida['franja_coche']:.2f} "
                           f"(se pide {banda[0]:.2f}–{banda[1]:.2f})")
        reglas = abs(medida["franja_coche"] - medida["por_diferencia"]["franja_coche"])
        print(f"MORRO   {nombre:<8} las dos reglas: pintada {medida['franja_coche']:.4f} / "
              f"diferencia {medida['por_diferencia']['franja_coche']:.4f} (difieren {reglas:.4f})")
        if reglas > TOLERANCIA_ENTRE_REGLAS:
            errores.append(f"{nombre}: la silueta pintada y la de diferencia no coinciden "
                           f"({medida['franja_coche']:.3f} frente a {medida['por_diferencia']['franja_coche']:.3f}, "
                           f"se admite {TOLERANCIA_ENTRE_REGLAS:.2f}): la captura pintada trae geometría que no es el coche")
        if abs(c["centro_x_fraccion"] - 0.5) > CAR_CENTRO_MAX:
            errores.append(f"{nombre}: el coche no está centrado (x = {c['centro_x_fraccion']:.2f} del ancho)")
        if not c["toca_abajo"]:
            errores.append(f"{nombre}: el coche no llega al borde inferior del cuadro")
        for lado, llave in (("izquierdo", "neumatico_izquierdo"), ("derecho", "neumatico_derecho")):
            rueda = medida[llave]
            if rueda["fraccion_lienzo"] < TIRE_MIN_PX:
                errores.append(f"{nombre}: el neumático {lado} se ve {rueda['fraccion_lienzo'] * 100:.2f} % "
                               f"del lienzo (se pide ≥ {TIRE_MIN_PX * 100:.2f} %)")
            if rueda["pixeles"] and rueda["y0_fraccion"] < TIRE_BANDA_Y_MIN:
                errores.append(f"{nombre}: el neumático {lado} sube hasta el {rueda['y0_fraccion'] * 100:.0f} % "
                               f"del alto (tiene que quedarse en la parte baja)")
            if rueda["pixeles"]:
                centro = rueda["centro_x_fraccion"]
                if lado == "izquierdo" and centro > 0.35:
                    errores.append(f"{nombre}: el neumático izquierdo está demasiado al centro (x = {centro:.2f})")
                if lado == "derecho" and centro < 0.65:
                    errores.append(f"{nombre}: el neumático derecho está demasiado al centro (x = {centro:.2f})")

    salida = {
        "referencia": pat,
        "criterios": {
            "franja_coche": banda,
            "centro_x_max_desvio": CAR_CENTRO_MAX,
            "neumatico_fraccion_min": TIRE_MIN_PX,
            "neumatico_banda_y_min": TIRE_BANDA_Y_MIN,
        },
        "casos": casos,
        "errores": errores,
        "passed": not errores,
    }
    INFORME.write_text(json.dumps(salida, indent=2, ensure_ascii=False))
    print(f"composición del morro: casos={len(casos)} errores={len(errores)} informe={INFORME}")
    for error in errores:
        print(f"  ERROR {error}")
    return 0 if not errores else 1


if __name__ == "__main__":
    sys.exit(main())
