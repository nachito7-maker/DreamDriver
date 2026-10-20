#!/usr/bin/env python3
"""Emite `scripts/video_speed_traces.gd` desde las trazas medidas de los vídeos.

La consigna de velocidad de cada vídeo se muestrea a 10 Hz y se escribe como una
constante de GDScript, para que `scripts/video_replay_probe.gd` la pueda seguir
dentro del juego sin depender de leer ficheros de `.tools` desde el motor.
"""
from __future__ import annotations

import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[3]
VIDEOS = RAIZ / ".tools" / "recovery" / "fase-muros" / "videos"
SALIDA = RAIZ / "scripts" / "video_speed_traces.gd"
CADA_S = 0.1
NOMBRES = ("9880", "9879")


def muestrear(trazas: dict) -> list:
    tiempos, valores = trazas["t_s"], trazas["kmh"]
    muestras, objetivo, i = [], 0.0, 0
    while objetivo <= tiempos[-1]:
        while i + 1 < len(tiempos) and tiempos[i + 1] < objetivo:
            i += 1
        muestras.append(round(valores[i], 1))
        objetivo += CADA_S
    return muestras


def main() -> int:
    lineas = [
        "extends RefCounted",
        "",
        "# Velocidad medida en los vídeos del encargo, muestreada a 10 Hz para poder",
        "# reproducirla dentro del juego. La genera `.tools/recovery/fase-muros/emitir_trazas.py`",
        "# a partir de las trazas de `.tools/recovery/fase-muros/videos/` (medidas fotograma a",
        "# fotograma con la barra del HUD).",
        "const TRAZAS := {",
    ]
    for nombre in NOMBRES:
        datos = json.loads((VIDEOS / (nombre + ".json")).read_text())
        muestras = muestrear(datos["traza"])
        # En GDScript no hay tuplas: los sucesos van como listas.
        sucesos = [[s["tipo"], s["t_inicio_s"], s.get("kmh_antes")] for s in datos["sucesos"]]
        lineas.append('\t"%s": {"fps": 10.0, "fotogramas": %d, "duracion_s": %.2f, "sucesos": %s,'
                      % (nombre, datos["fotogramas"], datos["duracion_s"], str(sucesos)))
        lineas.append('\t\t"kmh": %s},' % str([float(v) for v in muestras]))
    lineas.append("}")
    SALIDA.write_text("\n".join(lineas) + "\n")
    print("escrito %s" % SALIDA.relative_to(RAIZ))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
