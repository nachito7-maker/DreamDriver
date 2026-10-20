#!/usr/bin/env python3
"""Escribe ver.html con las imágenes indicadas incrustadas (sin servidor).

Uso: python3 ver.py ruta1 ruta2 ...
"""
from __future__ import annotations

import base64
import io
import sys
from pathlib import Path

from PIL import Image

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parents[2]


def incrustar(ruta: Path, ancho_max: int = 1200) -> str:
    im = Image.open(ruta).convert("RGB")
    if im.width > ancho_max:
        im = im.resize((ancho_max, round(im.height * ancho_max / im.width)), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=85, optimize=True)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def main(rutas: list[str]) -> int:
    partes = []
    for r in rutas:
        p = Path(r)
        if not p.is_absolute():
            p = RAIZ / p
        if not p.exists():
            partes.append('<p class="falta">falta %s</p>' % r)
            continue
        partes.append('<figure><figcaption>%s</figcaption><img src="%s"></figure>' % (r, incrustar(p)))
    html = """<!doctype html><html lang="es"><meta charset="utf-8"><title>Inspección</title>
<style>body{margin:0;background:#0b0e12;color:#eef2f7;font:13px/1.4 system-ui,sans-serif}
figure{margin:12px;background:#141a21;border:1px solid #2b323d;border-radius:8px;overflow:hidden}
figcaption{padding:6px 9px;font-weight:600}img{display:block;width:100%%;height:auto}
.falta{color:#ff9b9b;padding:0 12px}</style><body>%s</body></html>""" % "\n".join(partes)
    destino = AQUI / "ver.html"
    destino.write_text(html)
    print("escrito %s (%d KiB)" % (destino, destino.stat().st_size // 1024))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
