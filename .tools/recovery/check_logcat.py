#!/usr/bin/env python3
"""Revisa el registro del dispositivo buscando errores reales.

La advertencia `Failed to load cached shader, recompiling` aparece siempre en la
primera ejecución en este emulador y no es un fallo: Godot recompila el shader y
sigue. El logcat parte el mensaje en dos líneas (el texto y su `at:` de
seguimiento), así que se descartan también las que citan `_load_from_cache`.
Todo lo demás que salga como error se trata como error.

Uso:  check_logcat.py <logcat.txt>
"""
from __future__ import annotations

import sys
from pathlib import Path

IGNORADAS = ("Failed to load cached shader", "_load_from_cache")
GRAVES = ("FATAL EXCEPTION", "SCRIPT ERROR", "Parse Error", "Segmentation fault",
          "signal 11", "SUPPORTED_ABIS", "not responding")


def main() -> int:
    text = Path(sys.argv[1]).read_text(errors="replace")
    lines = text.splitlines()
    if not lines:
        print("el registro está vacío")
        return 1

    graves = [line for line in lines if any(g in line for g in GRAVES)]
    errores = [line for line in lines
               if " E godot " in line and not any(i in line for i in IGNORADAS)]
    anuncio = [line for line in lines if "[track] Barcelona 2023 Moto" in line]

    for line in graves[:5]:
        print("GRAVE:", line.strip()[:160])
    for line in errores[:5]:
        print("ERROR:", line.strip()[:160])
    for line in anuncio[:2]:
        print("PISTA:", line.split("godot   :")[-1].strip()[:160])

    ok = not graves and not errores and bool(anuncio)
    if not anuncio:
        print("el juego no anunció la variante de motos")
    print("LOGCAT PASS=", ok, " líneas=", len(lines))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
