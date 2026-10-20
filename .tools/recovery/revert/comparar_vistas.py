#!/usr/bin/env python3
"""Compara la vista recuperada con las capturas anteriores.

No hay opinion aqui: se mide. Para cada pareja de imagenes se calcula la
diferencia media por pixel en toda la pantalla, en la zona 3D (2/3 superiores,
sin HUD) y la fila del horizonte, que es lo que delata la camara aerea que
introdujo la ultima intervencion.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageChops

REFERENCIA_PREVIA = [
    ".tools/recovery/integral/shots/pantalla.png",
    ".tools/recovery/integral/shots/final-hash-screen.png",
    ".tools/recovery/integral/shots/final-apk.png",
]
INTERVENCION = [
    ".tools/recovery/shots-steering-installed-final.png",
    ".tools/recovery/revert/estado-antes-de-revertir.png",
]
RECUPERADO = ".tools/recovery/revert/shot-apk-recuperado-final.png"


def horizonte(image: Image.Image) -> int:
    """Fila con el mayor cambio de brillo a lo ancho en el tercio central.

    El horizonte se ve como un corte brusco entre cielo y suelo; la camara
    aerea lo sube hacia el borde superior y el corte del fondo marron lo
    desplaza. Es una medida, no una impresion.
    """
    gray = image.convert("L")
    width, height = gray.size
    px = gray.load()
    filas = []
    for y in range(1, int(height * 0.75)):
        a = sum(px[x, y - 1] for x in range(0, width, 16))
        b = sum(px[x, y] for x in range(0, width, 16))
        filas.append((abs(b - a), y))
    mejor = max(filas)
    return mejor[1]


def comparar(a_path: str, b_path: str) -> dict:
    a = Image.open(a_path).convert("RGB")
    b = Image.open(b_path).convert("RGB")
    if a.size != b.size:
        return {"error": "tamaños distintos %s vs %s" % (a.size, b.size)}
    diff = ImageChops.difference(a, b)
    ancho, alto = a.size
    global_mad = sum(sum(p) for p in diff.getdata()) / (ancho * alto * 3)
    zona3d = diff.crop((0, 0, ancho, int(alto * 0.68)))
    w, h = zona3d.size
    mad3d = sum(sum(p) for p in zona3d.getdata()) / (w * h * 3)
    return {
        "mad_global": global_mad,
        "mad_3d": mad3d,
        "horizonte_a": horizonte(a),
        "horizonte_b": horizonte(b),
    }


def main() -> int:
    if not Path(RECUPERADO).exists():
        RECUPERADO_FALLBACK = ".tools/recovery/revert/shot-apk-recuperado.png"
        print("RECUPERADO no existe; se usa %s" % RECUPERADO_FALLBACK)
    rec = Image.open(RECUPERADO)
    print("RECUPERADO %s %s" % (RECUPERADO, rec.size))
    print("HORIZONTE recuperado: fila %d de %d" % (horizonte(rec), rec.size[1]))
    fallos = 0
    print("\n--- Frente a referencias ANTERIORES a la intervencion ---")
    for ref in REFERENCIA_PREVIA:
        if not Path(ref).exists():
            print("(falta %s)" % ref)
            continue
        r = comparar(RECUPERADO, ref)
        if "error" in r:
            print("%-52s %s" % (Path(ref).name, r["error"]))
            fallos += 1
            continue
        print("%-52s MAD total %5.2f  MAD 3D %5.2f  horizonte ref %d / recuperado %d"
              % (Path(ref).name, r["mad_global"], r["mad_3d"],
                 r["horizonte_a"], r["horizonte_b"]))
    print("\n--- Frente a capturas de la ULTIMA intervencion ---")
    for ref in INTERVENCION:
        if not Path(ref).exists():
            print("(falta %s)" % ref)
            continue
        r = comparar(RECUPERADO, ref)
        if "error" in r:
            print("%-52s %s" % (Path(ref).name, r["error"]))
            continue
        print("%-52s MAD total %5.2f  MAD 3D %5.2f  horizonte interv %d / recuperado %d"
              % (Path(ref).name, r["mad_global"], r["mad_3d"],
                 r["horizonte_a"], r["horizonte_b"]))
    return 1 if fallos else 0


if __name__ == "__main__":
    sys.exit(main())
