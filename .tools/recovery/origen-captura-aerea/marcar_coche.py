#!/usr/bin/env python3
"""Dibuja sobre una copia la caja que detecta el medidor de vehículo.

Verificar el detector es parte de la medida: si la caja no rodea el coche, la cifra
«tamaño del coche» no vale y no debe publicarse. Escribe .tools/recovery/
origen-captura-aerea/crops/coche-marcado-<nombre>.png.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parents[2]


def detectar(im: Image.Image) -> tuple[int | None, int | None, int | None, int | None, int]:
    im = im.convert("RGB")
    ancho, alto = im.size
    px = im.load()
    caja: list[int | None] = [None, None, None, None]
    n = 0
    for y in range(int(0.20 * alto), int(0.72 * alto)):
        for x in range(int(0.30 * ancho), int(0.70 * ancho)):
            r, g, b = px[x, y]
            l = 0.2126 * r + 0.7152 * g + 0.0722 * b
            if 70 <= b <= 170 and b > r + 40 and b > g + 30 and l < 110:
                n += 1
                caja[0] = x if caja[0] is None else min(caja[0], x)
                caja[1] = y if caja[1] is None else min(caja[1], y)
                caja[2] = x if caja[2] is None else max(caja[2], x)
                caja[3] = y if caja[3] is None else max(caja[3], y)
    return caja[0], caja[1], caja[2], caja[3], n


def main(rutas: list[str]) -> int:
    destino = AQUI / "crops"
    destino.mkdir(exist_ok=True)
    for r in rutas:
        p = Path(r)
        if not p.is_absolute():
            p = RAIZ / p
        if not p.exists():
            print("falta %s" % r)
            continue
        im = Image.open(p).convert("RGB")
        x0, y0, x1, y1, n = detectar(im)
        ancho, alto = im.size
        print("%-58s caja=%s  alto_caja=%.1f%% del lienzo  píxeles=%d"
              % (p.name, (x0, y0, x1, y1),
                 100 * ((y1 - y0) / alto) if x0 is not None else 0.0, n))
        copia = im.copy()
        if x0 is not None:
            d = ImageDraw.Draw(copia)
            d.rectangle([x0 - 6, y0 - 6, x1 + 6, y1 + 6], outline=(255, 0, 255), width=4)
        copia.save(destino / ("coche-marcado-%s" % p.name))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
