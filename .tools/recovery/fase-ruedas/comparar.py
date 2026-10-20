#!/usr/bin/env python3
"""Compara las capturas de la fase de ruedas: antes y después, mismo encuadre.

NO OPINA: MIDE. Para cada pareja (misma cámara, mismo escenario, mismo punto de
pista) calcula:

  * diferencia media por píxel en toda la pantalla (0-255),
  * porcentaje de píxeles que cambian de forma apreciable (|Δ| > 24),
  * la CAJA de esos píxeles cambiados: si el cambio está en las ruedas, la caja
    baja hasta el asfalto y se queda en las cuatro esquinas del coche; si algo se
    hubiera movido en la carrocería, la caja la cubriría entera.

Y escribe un montaje lado a lado (antes | después) en
`.tools/recovery/fase-ruedas/comparativa/`, que es lo que se mira a ojo.

Uso:
    python3 .tools/recovery/fase-ruedas/comparar.py
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

RAIZ = Path(".tools/recovery/fase-ruedas/vistas")
SALIDA = Path(".tools/recovery/fase-ruedas/comparativa")
UMBRAL_PIXEL = 24


def comparar(nombre: str) -> dict:
    a = Image.open(RAIZ / "antes" / nombre).convert("RGB")
    b = Image.open(RAIZ / "despues" / nombre).convert("RGB")
    if a.size != b.size:
        return {"nombre": nombre, "error": "tamaños distintos %s y %s" % (a.size, b.size)}
    na = np.asarray(a, dtype=np.int16)
    nb = np.asarray(b, dtype=np.int16)
    delta = np.abs(na - nb).max(axis=2)
    mask = delta > UMBRAL_PIXEL
    filas = np.where(mask.any(axis=1))[0]
    columnas = np.where(mask.any(axis=0))[0]
    caja = None
    if filas.size and columnas.size:
        caja = [int(columnas[0]), int(filas[0]), int(columnas[-1]), int(filas[-1])]
    # Montaje con título.
    ancho, alto = a.size
    lienzo = Image.new("RGB", (ancho * 2 + 12, alto + 34), (18, 18, 20))
    lienzo.paste(a, (0, 34))
    lienzo.paste(b, (ancho + 12, 34))
    lapiz = ImageDraw.Draw(lienzo)
    lapiz.text((6, 10), "ANTES  %s" % nombre, fill=(255, 210, 120))
    lapiz.text((ancho + 18, 10), "DESPUES  %s" % nombre, fill=(150, 255, 170))
    lapiz.text((6, alto + 16), "diferencia media %.2f/255 · %.2f%% de píxeles cambiados"
               % (float(delta.mean()), 100.0 * float(mask.mean())), fill=(200, 200, 200))
    SALIDA.mkdir(parents=True, exist_ok=True)
    lienzo.save(SALIDA / nombre)
    return {"nombre": nombre, "media": float(delta.mean()),
            "fraccion": float(mask.mean()), "caja": caja, "tamano": a.size}


def main() -> int:
    antes = sorted(p.name for p in (RAIZ / "antes").glob("*.png"))
    despues = {p.name for p in (RAIZ / "despues").glob("*.png")}
    parejas = [n for n in antes if n in despues]
    faltan = [n for n in antes if n not in despues]
    if faltan:
        print("sin pareja: %s" % faltan)
    resultados = [comparar(n) for n in parejas]
    resultados = [r for r in resultados if "error" not in r]
    resultados.sort(key=lambda r: -r["media"])
    print("%-42s %8s %9s  %s" % ("captura", "media", "% pix.", "caja de lo cambiado (x0,y0,x1,y1)"))
    for r in resultados:
        print("%-42s %8.2f %8.2f%%  %s" % (r["nombre"], r["media"], r["fraccion"] * 100.0, r["caja"]))
    medias = [r["media"] for r in resultados]
    print("\nparejas=%d  diferencia media global=%.2f/255  máxima=%.2f (%s)"
          % (len(resultados), float(np.mean(medias)), max(medias),
             resultados[0]["nombre"] if resultados else "-"))
    print("montajes: %s" % SALIDA)
    return 0


if __name__ == "__main__":
    sys.exit(main())
