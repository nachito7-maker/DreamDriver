#!/usr/bin/env python3
"""Mide en los PNG de `calibrar.gd` el color que el motor PINTA con cada albedo.

`calibrar.gd` deja, en la misma pose congelada (misma cámara, misma luz, misma
velocidad) y con el desgaste apagado:

  * `disparos-calib/mascara-linea.png`: el listón forzado a un gris claro.
  * `disparos-calib/mascara-base.png`:  el mismo instante con el listón oculto.
  * `disparos-calib/<candidato>.png`:   la misma pose con la paleta del candidato.

La diferencia entre los dos primeros PNG ES el listón dibujado; sobre sus píxeles
—los más sólidos, restringidos a la mitad inferior del lienzo, que es la calzada
cerca del coche— se mide el color de cada candidato. El asfalto con el que se compara
es el de la MISMA fila, a menos de ~60 px del listón y sin cambiar entre los dos
fotogramas de la máscara (así es el mismo material, la misma profundidad y la misma
luz).

Para cada candidato informa lo que decide si la pintura está integrada o no:

  * el color medio y mediano que sale en pantalla,
  * su CROMATICIDAD (máx − mín)/255 y su SATURACIÓN (máx − mín)/máx: lo estridente,
  * su LUMINANCIA, que tiene que quedar por debajo de la de la calzada,
  * la DIFERENCIA MÁXIMA POR CANAL contra el asfalto de al lado, que es lo que hace
    que la pintura se pueda distinguir (y medir).

No comprueba nada: es la medida con la que se elige la paleta.

Uso:  python3 .tools/recovery/linea-visual/calibrar.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

DIR = Path(__file__).resolve().parent
SHOTS = DIR / "disparos-calib"

# El listón se reconoce por su COLOR en el fotograma con la línea forzada a magenta: no
# hay nada magenta en el circuito, así que la máscara no depende de que dos fotogramas
# distintos caigan en la misma pose (que es lo que fallaba midiendo diferencias).
MAGENTA_MIN = 50.0        # cuánto tienen que subir rojo y azul sobre el verde
# Diferencia máxima (sobre 255) entre el fotograma del listón y su repetición: si el
# lienzo se dibuja igual, los dos PNG son el mismo y la máscara es válida.
# Dónde se busca el listón: la mitad inferior del lienzo (la calzada cerca del coche) y
# la franja central por la que va la trazada con la cámara de persecución.
REGION = (0.30, 0.55, 0.70, 0.98)   # x0, y0, x1, y1 en fracciones del lienzo
# Radio del anillo de asfalto con el que se compara, en píxeles.
ANILLO_PX = 60
ANILLO_DIFERENCIA_MAX = 4.0


def leer(ruta: Path) -> np.ndarray:
    return np.asarray(Image.open(ruta).convert("RGB")).astype(np.float64)


def luminancia(color: np.ndarray | list[float]) -> float:
    return float(0.299 * color[0] + 0.587 * color[1] + 0.114 * color[2])


def cromaticidad(color: np.ndarray) -> float:
    return float((color.max() - color.min()) / 255.0)


def saturacion(color: np.ndarray) -> float:
    mayor = float(color.max())
    return float((mayor - float(color.min())) / mayor) if mayor > 0.0 else 0.0


def main() -> int:
    registro = DIR / "calibracion.json"
    if not registro.exists():
        print(f"no existe {registro}: ejecuta antes calibrar.gd")
        return 1
    datos = json.loads(registro.read_text())
    con = leer(SHOTS / "mascara-linea.png")
    repetida = leer(SHOTS / "mascara-linea2.png")
    base = leer(SHOTS / "mascara-base.png")
    if con.shape != base.shape or con.shape != repetida.shape:
        print("los fotogramas de la máscara no tienen el mismo tamaño")
        return 1
    # El lienzo tiene que volverse a dibujar IGUAL entre dos capturas del mismo estado:
    # si no, la máscara de un fotograma no vale para los demás.
    deriva = float(np.abs(con - repetida).max())
    print("LINEA_CAL repeticion del mismo estado: diferencia maxima %.0f (px>4: %d)" % (
        deriva, int((np.abs(con - repetida).max(axis=2) > 4.0).sum())))
    alto, ancho = con.shape[0], con.shape[1]
    x0, y0, x1, y1 = REGION
    region = np.zeros((alto, ancho), dtype=bool)
    region[int(alto * y0) : int(alto * y1), int(ancho * x0) : int(ancho * x1)] = True
    magenta = ((con[..., 0] - con[..., 1] > MAGENTA_MIN) & (con[..., 2] - con[..., 1] > MAGENTA_MIN)
               & (con[..., 0] > MAGENTA_MIN) & (con[..., 2] > MAGENTA_MIN))
    visible = magenta & region
    if int(visible.sum()) < 200:
        print(f"la máscara del listón sólo tiene {int(visible.sum())} píxeles: ¿se dibuja la línea?")
        return 1
    # El núcleo: los píxeles magenta que tienen vecinos magenta a los cuatro lados (así
    # queda fuera la orla mezclada con el asfalto, que es la que promedia colores).
    vecinos = np.zeros_like(visible, dtype=int)
    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        vecinos += np.roll(np.roll(visible, dy, axis=0), dx, axis=1).astype(int)
    nucleo = visible & (vecinos >= 4)
    if int(nucleo.sum()) < 60:
        nucleo = visible
    dif = np.abs(con - base).max(axis=2)
    ys, xs = np.nonzero(nucleo)
    print("LINEA_CAL mascara=%d px visibles, nucleo=%d px en filas %d..%d (de %d) columnas %d..%d" % (
        int(visible.sum()), int(nucleo.sum()), int(ys.min()), int(ys.max()), alto, int(xs.min()), int(xs.max())))
    # El asfalto: el anillo alrededor del núcleo, sin cambiar entre los dos fotogramas.
    caja = np.zeros((alto, ancho), dtype=bool)
    caja[max(0, int(ys.min()) - ANILLO_PX) : min(alto, int(ys.max()) + ANILLO_PX + 1),
         max(0, int(xs.min()) - ANILLO_PX) : min(ancho, int(xs.max()) + ANILLO_PX + 1)] = True
    anillo = caja & (dif <= ANILLO_DIFERENCIA_MAX) & ~visible
    if int(anillo.sum()) < 500:
        print("no hay asfalto medible alrededor del listón")
        return 1
    asfalto = np.median(base[anillo], axis=0)
    print("LINEA_CAL asfalto de al lado (%d px): rgb=(%.0f,%.0f,%.0f) luminancia=%.0f" % (
        int(anillo.sum()), *asfalto, luminancia(asfalto)))

    medidas = []
    print("LINEA_CAL %-12s %-18s %-18s %8s %8s %8s %10s" % (
        "candidato", "albedo", "pintado", "cromat", "saturac", "lumin", "dif_max"))
    for candidato in datos["candidatos"]:
        ruta = SHOTS / candidato["archivo"]
        if not ruta.exists():
            print(f"LINEA_CAL falta {ruta}")
            continue
        imagen = leer(ruta)
        color = np.median(imagen[nucleo], axis=0)
        medio = np.mean(imagen[nucleo], axis=0)
        diferencia = np.abs(color - asfalto)
        medida = {
            "etiqueta": candidato["etiqueta"],
            "ranura": candidato["ranura"],
            "albedo": candidato["albedo"],
            "rgb": [float(v) for v in color],
            "rgb_medio": [float(v) for v in medio],
            "cromaticidad": cromaticidad(color),
            "saturacion": saturacion(color),
            "luminancia": luminancia(color),
            "dif_max": float(diferencia.max()),
            "dif_por_canal": [float(v) for v in diferencia],
        }
        medidas.append(medida)
        print("LINEA_CAL %-12s (%3.0f,%3.0f,%3.0f) (%3.0f,%3.0f,%3.0f) %8.2f %8.2f %8.0f %10.0f (%s)" % (
            candidato["etiqueta"], *[v * 255.0 for v in candidato["albedo"]], *color,
            medida["cromaticidad"], medida["saturacion"], medida["luminancia"], medida["dif_max"],
            "/".join("%.0f" % v for v in diferencia)))
    salida = DIR / "calibracion-medida.json"
    salida.write_text(json.dumps({
        "asfalto": [float(v) for v in asfalto],
        "asfalto_luminancia": luminancia(asfalto),
        "nucleo_px": int(nucleo.sum()),
        "visible_px": int(visible.sum()),
        "medidas": medidas,
    }, indent=2))
    print("LINEA_CAL medidas=%d escrito=%s" % (len(medidas), salida))
    return 0


if __name__ == "__main__":
    sys.exit(main())
