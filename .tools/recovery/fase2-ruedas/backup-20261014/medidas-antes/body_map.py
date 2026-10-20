#!/usr/bin/env python3
"""Mapa de ocupación en planta del chasis del Red Bull (solo lectura).

Dibuja, por franjas de altura, qué celdas (x lateral, z longitudinal) contienen
geometría del chasis. Un monoplaza real deja las ruedas como la parte más ancha y
un suelo de ~1 m; una losa o una rueda fusionada aparecen como una banda ancha
continua a la altura de las ruedas. Sirve para VER, con números, si el chasis
invade la huella de las ruedas.

Uso: body_map.py <modelo.glb>
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from body_profile import load_glb, node_matrix, read_accessor  # noqa: E402


def main() -> int:
    gltf, binary = load_glb(Path(sys.argv[1]))
    nodes = gltf["nodes"]
    columns = 52
    rows = 40
    x_range = (-1.25, 1.25)
    z_range = (2.80, -2.80)  # morro arriba: -Z es delante

    def points_of(name: str) -> np.ndarray:
        node = next(n for n in nodes if n.get("name", "").lower() == name)
        matrix = node_matrix(node)
        chunks = []
        for prim in gltf["meshes"][node["mesh"]]["primitives"]:
            pos = read_accessor(gltf, binary, prim["attributes"]["POSITION"])
            hom = np.hstack([pos, np.ones((len(pos), 1))])
            chunks.append((matrix @ hom.T).T[:, :3])
        return np.vstack(chunks)

    body = points_of("body")
    wheels = {n.get("name"): points_of(n.get("name").lower())
              for n in nodes if n.get("name", "").lower().startswith("wheel")}
    print("== %s" % sys.argv[1])
    for label, lo, hi in [("SUELO (y 0.00-0.03)", 0.0, 0.03),
                          ("BAJO (y 0.03-0.12)", 0.03, 0.12),
                          ("RUEDAS (y 0.12-0.45)", 0.12, 0.45),
                          ("MEDIO (y 0.45-0.90)", 0.45, 0.90)]:
        grid = [["." for _ in range(columns)] for _ in range(rows)]
        for pts, glyph in [(body, "#")] + [(w, n[6:8].upper()) for n, w in wheels.items()]:
            sel = pts[(pts[:, 1] >= lo) & (pts[:, 1] < hi)]
            for x, y, z in sel[:, [0, 1, 2]]:
                col = int((x - x_range[0]) / (x_range[1] - x_range[0]) * (columns - 1))
                row = int((z - z_range[0]) / (z_range[1] - z_range[0]) * (rows - 1))
                if 0 <= col < columns and 0 <= row < rows:
                    if grid[row][col] == "." or glyph != "#":
                        grid[row][col] = glyph
        print("-- %s   (arriba = morro, -Z)" % label)
        print("   x %.2f .. %.2f m" % x_range)
        for r, line in enumerate(grid):
            print("   %s" % "".join(line))
    return 0


if __name__ == "__main__":
    sys.exit(main())
