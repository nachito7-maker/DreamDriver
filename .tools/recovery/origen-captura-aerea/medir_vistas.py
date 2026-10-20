#!/usr/bin/env python3
"""Mide, sin opinar, rasgos objetivos de cada vista comparada.

Para qué: la imagen que describe el usuario (perspectiva aérea, coche parcialmente
fuera del encuadre, horizonte marrón, aspecto de maqueta) se puede contrastar con
medidas en vez de impresiones. En cada captura se calcula:

  * altura de la línea de horizonte (fila con el mayor salto de brillo),
  * porcentaje de píxeles de cielo (azul clarito y luminoso),
  * porcentaje de píxeles oscuros (luma < 45): un viewport del editor vacío es casi todo oscuro,
  * porcentaje de verde (vegetación/césped del circuito importado),
  * porcentaje de marrón/tierra (R>G>B con contraste cálido y brillo medio),
  * porcentaje de calzada: gris casi neutro y luminoso, que resume cuánto del encuadre ocupa
    la pista (en una vista rasante la llena; en una cenital es una cinta fina).

El tamaño del coche NO se mide aquí: el detector de librea azul (`marcar_coche.py`) acierta en
la captura de ahora, pero se infla con la cartelería azul del edificio de boxes en otras, así
que se verifica a ojo con la caja marcada y no se publica como cifra.

La ventana 3D del juego y la del editor se miden con el mismo código, así que las
cifras son comparables entre sí.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parents[3]


def luma(p: tuple[int, int, int]) -> float:
    r, g, b = p
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def clasificar(im: Image.Image) -> dict:
    im = im.convert("RGB")
    ancho, alto = im.size
    px = im.load()
    paso = max(1, min(ancho, alto) // 400)  # muestreo uniforme, independiente del tamaño

    total = cielo = oscuro = verde = marron = asfalto = 0
    suma = [0, 0, 0]
    filas = []
    for y in range(0, alto, paso):
        brillo_fila = 0
        n_fila = 0
        for x in range(0, ancho, paso):
            r, g, b = px[x, y]
            total += 1
            suma[0] += r
            suma[1] += g
            suma[2] += b
            l = luma((r, g, b))
            brillo_fila += l
            n_fila += 1
            if b > 150 and b > r + 15 and g > 120:
                cielo += 1
            if l < 45:
                oscuro += 1
            if g > r + 12 and g > b + 12 and g > 70:
                verde += 1
            if r > g > b and 20 <= r - b <= 110 and 55 <= l <= 175:
                marron += 1
            if abs(r - g) <= 12 and abs(g - b) <= 14 and 90 <= l <= 205:
                asfalto += 1
        filas.append((brillo_fila / max(1, n_fila), y))

    # línea de horizonte: mayor cambio de brillo entre filas consecutivas, en el 80 % superior
    corte = max(1, int(len(filas) * 0.8))
    saltos = [(abs(filas[i][0] - filas[i - 1][0]), filas[i][1]) for i in range(1, corte)]
    salto, fila_horizonte = max(saltos) if saltos else (0.0, 0)

    return {
        "tamaño": "%dx%d" % (ancho, alto),
        "media_rgb": tuple(round(c / max(1, total)) for c in suma),
        "cielo_%": round(100 * cielo / max(1, total), 1),
        "oscuro_%": round(100 * oscuro / max(1, total), 1),
        "verde_%": round(100 * verde / max(1, total), 1),
        "marron_%": round(100 * marron / max(1, total), 1),
        "calzada_%": round(100 * asfalto / max(1, total), 1),
        "horizonte_fila": fila_horizonte,
        "horizonte_%_alto": round(100 * fila_horizonte / alto, 1),
        "salto_brillo": round(salto, 1),
    }


def main(rutas: list[str]) -> int:
    for ruta in rutas:
        p = Path(ruta)
        if not p.is_absolute():
            p = RAIZ / ruta
        if not p.exists():
            print("--- (falta) %s" % ruta)
            continue
        m = clasificar(Image.open(p))
        print("--- %s" % ruta)
        print("    " + "  ".join("%s=%s" % (k, v) for k, v in m.items()))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
