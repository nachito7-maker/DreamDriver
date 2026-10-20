#!/usr/bin/env python3
"""¿La malla del chasis invade el volumen de las ruedas? (solo lectura)

Por cada rueda se cuenta cuántos vértices del CHASIS caen dentro del cilindro de
esa rueda (mismo eje, radio, anchura y centro medidos en el propio GLB). Un
chasis limpio da valores ~0 en la banda de rodadura; una rueda fusionada que
sobrevivió al recorte da miles. También mide, por franja longitudinal, la
anchura del chasis, para localizar los bultos anchos.

Uso: body_vs_wheels.py <modelo.glb>
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
    print("== %s" % sys.argv[1])
    print("   chasis: %d vértices" % len(body))
    for node in nodes:
        name = (node.get("name") or "").lower()
        if not name.startswith("wheel") or node.get("mesh") is None:
            continue
        wheel = points_of(name)
        lo, hi = wheel.min(axis=0), wheel.max(axis=0)
        centre = (lo + hi) * 0.5
        # El eje de menor extensión es el de giro; el radio es la media de los otros dos.
        sizes = hi - lo
        axle = int(np.argmin(sizes))
        radial = [i for i in range(3) if i != axle]
        radius = float(np.mean([sizes[i] for i in radial]) * 0.5)
        half_width = float(sizes[axle] * 0.5)
        rel = body - centre
        along = np.abs(rel[:, axle]) <= half_width
        cross = np.sqrt(sum(rel[:, i] ** 2 for i in radial)) <= radius
        inside = int((along & cross).sum())
        band = int(((np.abs(rel[:, axle]) <= half_width * 0.6)
                    & (np.sqrt(sum(rel[:, i] ** 2 for i in radial)) > radius * 0.75)
                    & (np.sqrt(sum(rel[:, i] ** 2 for i in radial)) <= radius * 1.05)
                    & (np.abs(rel[:, 1]) > 0.05)).sum())
        print("   %-9s centro=%s radio=%.3f anchura=%.3f -> vértices del chasis DENTRO: %d"
              "   (corona 0.75-1.05 R: %d)"
              % (name, np.round(centre, 3).tolist(), radius, half_width * 2, inside, band))
    print("   == anchura del chasis por franja longitudinal y altura")
    for za, zb in [(-2.80, -2.40), (-2.40, -2.00), (-2.00, -1.60), (-1.60, -1.20),
                   (-1.20, -0.80), (-0.80, -0.40), (-0.40, 0.0), (0.0, 0.40),
                   (0.40, 0.80), (0.80, 1.20), (1.20, 1.60), (1.60, 2.00),
                   (2.00, 2.40), (2.40, 2.80)]:
        sel = body[(body[:, 2] >= za) & (body[:, 2] < zb)]
        if len(sel) == 0:
            continue
        low = sel[sel[:, 1] < 0.50]
        wide = len(sel[np.abs(sel[:, 0]) > 0.85])
        print("   z %+.2f..%+.2f  x %+.3f..%+.3f  y %+.3f..%+.3f  |x|>0.85: %5d  (bajo y<0.5: %5d)"
              % (za, zb, sel[:, 0].min(), sel[:, 0].max(), sel[:, 1].min(), sel[:, 1].max(),
                 wide, len(low)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
