#!/usr/bin/env python3
"""Hoja de contacto (autocontenida) de las capturas del morro y sus máscaras.

Las imágenes se reducen a 900 px de ancho y se pegan en un JPEG que viaja
embebido en base64 dentro del HTML: el visor sirve el HTML solo, así que las
rutas relativas a las capturas no resuelven.
"""

from __future__ import annotations

import base64
import io
from pathlib import Path

from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parents[3]
CAPTURAS = RAIZ / ".tools/recovery/fase-fp/capturas"
SALIDA = RAIZ / ".tools/recovery/fase-fp/hoja-de-contacto.html"

ANCHO = 880
FILAS = [
    ("Vista real de la cámara del morro (con escena y HUD)",
     [f"morro-{c}.png" for c in ("parado", "100", "150", "200", "curva", "frenada")]),
    ("Máscara del coche (magenta) y de los neumáticos delanteros (cian): la silueta se recorta por color con el circuito y el cielo ocultos",
     ["composicion-parado-coche-magenta.png", "composicion-parado-delanteras-cian.png",
      "composicion-200-coche-magenta.png", "composicion-200-delanteras-cian.png"]),
    ("Cambio de vista, en marcha: persecución → morro y morro → persecución",
     ["cambio-morro-00.png", "cambio-morro-08.png", "cambio-morro-16.png",
      "cambio-persecucion-00.png", "cambio-persecucion-08.png", "cambio-persecucion-16.png"]),
]

# Capturas del APARTADO (con toques reales). Viven fuera de `capturas/`.
FILAS_DISPOSITIVO = [
    ("En el emulador, cambiando de vista con el dedo (194 km/h de morro, 244 y 164 km/h de persecución, "
     "y el pedal pisado después del cambio a 197 km/h)",
     ["dispositivo-persecucion-1.png", "dispositivo-morro.png", "dispositivo-persecucion-2.png",
      "dispositivo-morro-pedal.png"]),
]
DISPOSITIVO = RAIZ / ".tools/recovery/integral/shots/morro"


def miniatura(archivo: str) -> Image.Image | None:
    ruta = CAPTURAS / archivo
    if not ruta.exists():
        ruta = DISPOSITIVO / archivo
    if not ruta.exists():
        return None
    imagen = Image.open(ruta).convert("RGB")
    alto = int(imagen.height * ANCHO / imagen.width)
    return imagen.resize((ANCHO, alto), Image.LANCZOS)


def main() -> int:
    filas = []
    for titulo, archivos in FILAS + FILAS_DISPOSITIVO:
        miniaturas = [(a, m) for a in archivos if (m := miniatura(a)) is not None]
        if miniaturas:
            filas.append((titulo, miniaturas))
    if not filas:
        print("no hay capturas")
        return 1
    alto_total = sum(26 + max((imagen.height for _, imagen in miniaturas), default=0) + 18
                     for _, miniaturas in filas) + 20
    ancho_pagina = ANCHO * 3 + 40
    lienzo = Image.new("RGB", (ancho_pagina, alto_total), (11, 15, 20))
    dibujo = ImageDraw.Draw(lienzo)
    y = 10
    for titulo, miniaturas in filas:
        dibujo.text((12, y), titulo[:180], fill=(143, 216, 176))
        y += 22
        x = 12
        for archivo, imagen in miniaturas:
            if x + ANCHO > ancho_pagina - 12:
                x = 12
                y += imagen.height + 18
            lienzo.paste(imagen, (x, y))
            dibujo.text((x + 4, y + imagen.height + 3), archivo.replace("composicion-", "").replace(".png", ""),
                        fill=(159, 182, 194))
            x += ANCHO + 8
        y += max((imagen.height for _, imagen in miniaturas), default=0) + 34
    memoria = io.BytesIO()
    lienzo.save(memoria, format="JPEG", quality=72)
    datos = base64.b64encode(memoria.getvalue()).decode("ascii")
    SALIDA.write_text(
        "<!doctype html><html lang='es'><head><meta charset='utf-8'>"
        "<title>Hoja de contacto — cámara del morro</title>"
        "<style>body{margin:0;background:#0b0f14}img{width:100%;display:block}</style></head>"
        f"<body><img alt='hoja de contacto' src='data:image/jpeg;base64,{datos}'></body></html>")
    print(f"hoja de contacto: {SALIDA} ({len(datos) // 1024} KiB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
