#!/usr/bin/env python3
"""Contraste REAL de la pintura estación a estación, sobre las capturas ya hechas.

`capturar.gd` guarda por caso `<caso>-linea.png` y `<caso>-base.png` (el mismo
instante con y sin la línea) y en `capturas.json` el punto de pantalla donde cae cada
estación de la ventana visible. Este script mide en esos PNG, para cada estación, la
DIFERENCIA MÁXIMA POR CANAL del cuadradito de 3x3 alrededor del punto —la misma medida
que usa la propia sonda para decidir si la línea "se ve" y puede medirse—, y la clasifica
con los dos umbrales declarados:

  * 60 (`FUERTE_DIFERENCIA` en `capturar.gd`): por encima, la estación sirve para medir
    los colores de referencia. El caso necesita al menos 6 así.
  * 30 (`DIFERENCIA_LINEA` en `linea_pixeles.py`): por encima, la estación cuenta como
    "la línea se ve" para la cobertura, que tiene que llegar al 45 %.

Sirve para saber CUÁNTO contraste hace falta en las estaciones lejanas (que es lo que
decide si un caso se puede medir) en vez de suponerlo.

Uso:  python3 contraste_por_estacion.py <dir-de-capturas> [caso]
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

FUERTE_DIFERENCIA = 60.0
DIFERENCIA_LINEA = 30.0


def leer(ruta: Path) -> np.ndarray:
    return np.asarray(Image.open(ruta).convert("RGB")).astype(np.float64)


def medir(imagen: np.ndarray, punto: dict, radio: int = 1) -> np.ndarray | None:
    if punto.get("detras"):
        return None
    x, y = int(round(float(punto["x"]))), int(round(float(punto["y"])))
    alto, ancho = imagen.shape[0], imagen.shape[1]
    if x < radio or y < radio or x >= ancho - radio or y >= alto - radio:
        return None
    bloque = imagen[y - radio : y + radio + 1, x - radio : x + radio + 1]
    return bloque.reshape(-1, 3).mean(axis=0)


def main() -> int:
    if len(sys.argv) < 2:
        print("uso: contraste_por_estacion.py <dir-de-capturas> [caso]")
        return 1
    directorio = Path(sys.argv[1])
    filtro = sys.argv[2] if len(sys.argv) > 2 else None
    if not (directorio / "capturas.json").exists():
        print("no hay capturas.json en %s" % directorio)
        return 1
    registro = json.loads((directorio / "capturas.json").read_text())
    # El registro está en el directorio de la fase y los PNG en su `disparos/`.
    fotos = directorio if (directorio / "recta-linea.png").exists() else directorio / "disparos"
    print("CONTRASTE dir=%s modo=%s casos=%d" % (fotos, registro.get("modo"), len(registro["casos"])))
    for caso in registro["casos"]:
        ident = caso["id"]
        if filtro and ident != filtro:
            continue
        con = leer(fotos / ("%s-linea.png" % ident))
        base = leer(fotos / ("%s-base.png" % ident))
        fuertes = mirados = tapadas = 0
        filas = []
        for muestra in caso["muestras"]:
            if muestra["ocluido"] or muestra.get("mixta"):
                continue
            a = medir(con, muestra["punto"])
            b = medir(base, muestra["punto"])
            if a is None or b is None:
                continue
            dif = float(np.abs(a - b).max())
            marca = "FUERTE" if dif > FUERTE_DIFERENCIA else ("visible" if dif > DIFERENCIA_LINEA else "tapada")
            if dif > FUERTE_DIFERENCIA:
                fuertes += 1
            if dif > DIFERENCIA_LINEA:
                mirados += 1
            else:
                tapadas += 1
            filas.append((muestra["ds"], muestra["estado"], dif, marca, a, b))
        cobertura = mirados / (mirados + tapadas) * 100.0 if (mirados + tapadas) else 0.0
        print("\nCONTRASTE caso=%-13s muestras=%2d medibles(>60)=%2d visibles(>30)=%2d cobertura=%.0f %%"
              % (ident, len(filas), fuertes, mirados, cobertura))
        for ds, estado, dif, marca, a, b in filas:
            print("   ds=%6.0f m %-8s dif=%5.0f  %-8s linea=(%3.0f,%3.0f,%3.0f) asfalto=(%3.0f,%3.0f,%3.0f)"
                  % (ds, estado, dif, marca, *a, *b))
    return 0


if __name__ == "__main__":
    sys.exit(main())
