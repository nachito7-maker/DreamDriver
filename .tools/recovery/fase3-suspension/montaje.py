#!/usr/bin/env python3
"""Hojas comparativas de la suspensión: el mismo coche en cuatro estados.

    comparativa-rueda.png     primer plano de la rueda trasera izquierda
    comparativa-chasis.png    vista baja desde atrás (el chasis sobre las ruedas)
    comparativa-camara.png    la vista real del juego

Estados: parado, frenada (delanteras comprimidas y traseras extendidas), curva
rápida (exteriores comprimidas) y resalto de prueba (izquierdas al tope).
"""
from __future__ import annotations

import os

from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
VISTAS = os.path.join(AQUI, "vistas")
ESTADOS = [
    ("reposo", "PARADO\nrecorrido 0,0 mm"),
    ("frenada", "FRENADA 33 m/s2\ndel. +8,8 / +10,3 · tras. -10,6 / -10,8 mm"),
    ("curva_rapida", "CURVA RÁPIDA 1,07 g\nbal. +0,34° · exterior +5,6 / +5,3 mm"),
    ("resalto", "RESALTO 30 mm\nizq. +35 (tope) · der. -30 (tope)"),
]
VISTAS_A_MONTAR = [
    ("rueda_trasera_izq", "comparativa-rueda.png", "Rueda trasera izquierda"),
    ("trasera_baja", "comparativa-chasis.png", "Chasis visto desde atrás y abajo"),
    ("camara_del_juego", "comparativa-camara.png", "Vista real del juego"),
]


def montar(view: str, salida: str, titulo: str) -> None:
    paneles = []
    for estado, pie in ESTADOS:
        ruta = os.path.join(VISTAS, "%s-%s.png" % (estado, view))
        if not os.path.exists(ruta):
            print("  falta %s" % ruta)
            return
        imagen = Image.open(ruta).convert("RGB")
        imagen = imagen.resize((720, int(imagen.height * 720 / imagen.width)))
        paneles.append((imagen, "%s\n%s" % (pie, estado.upper())))
    alto = paneles[0][0].height
    hoja = Image.new("RGB", (720 * 2, (alto + 34) * 2), (16, 16, 18))
    dibujo = ImageDraw.Draw(hoja)
    for indice, (imagen, pie) in enumerate(paneles):
        columna = indice % 2
        fila = indice // 2
        x = columna * 720
        y = fila * (alto + 34)
        hoja.paste(imagen, (x, y + 34))
        dibujo.text((x + 10, y + 8), pie, fill=(255, 210, 90))
    destino = os.path.join(AQUI, salida)
    hoja.save(destino)
    print("%s: %s (%dx%d)" % (titulo, destino, hoja.width, hoja.height))


def main() -> int:
    for view, salida, titulo in VISTAS_A_MONTAR:
        montar(view, salida, titulo)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
