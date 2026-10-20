#!/usr/bin/env python3
"""Salud geométrica de las ruedas del Red Bull (solo lectura).

Para cada malla (chasis y las cuatro ruedas) mide:
  * volumen firmado por el teorema de la divergencia: NEGATIVO = las caras
    miran hacia dentro (malla del revés, se ve el interior al renderizar)
  * cobertura de la banda de rodadura en 72 sectores de 5° (un neumático entero
    cubre los 72; un recorte deja sectores vacíos)
  * reparto de vértices por radio (0-0.5 R = llanta/buje, 0.5-0.75 R,
    0.75-0.93 R = flanco/banda, 0.93-1.05 R = banda de rodadura)
  * el corte transversal: ¿la sección radial es un círculo completo?

Uso: wheel_geometry.py <modelo.glb>
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from body_profile import COMPONENTS, FORMATS, SIZES, load_glb, node_matrix, read_accessor  # noqa: E402


def read_indices(gltf, binary, index) -> np.ndarray:
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    fmt = FORMATS[acc["componentType"]]
    size = SIZES[acc["componentType"]]
    stride = view.get("byteStride") or size
    base = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    return np.array([struct_unpack(fmt, binary, base + i * stride) for i in range(acc["count"])],
                    dtype=np.int64)


def struct_unpack(fmt, binary, offset):
    import struct
    return struct.unpack_from("<" + fmt, binary, offset)[0]


def main() -> int:
    gltf, binary = load_glb(Path(sys.argv[1]))
    print("== %s" % sys.argv[1])
    for node in gltf["nodes"]:
        name = (node.get("name") or "")
        if node.get("mesh") is None:
            continue
        if name.lower() != "body" and not name.lower().startswith("wheel"):
            continue
        matrix = node_matrix(node)
        verts = []
        faces = []
        base_index = 0
        for prim in gltf["meshes"][node["mesh"]]["primitives"]:
            pos = read_accessor(gltf, binary, prim["attributes"]["POSITION"])
            hom = np.hstack([pos, np.ones((len(pos), 1))])
            verts.append((matrix @ hom.T).T[:, :3])
            idx = read_indices(gltf, binary, prim["indices"]).reshape(-1, 3) + base_index
            faces.append(idx)
            base_index += len(pos)
        points = np.vstack(verts)
        tris = np.vstack(faces)
        a, b, c = points[tris[:, 0]], points[tris[:, 1]], points[tris[:, 2]]
        signed = float(np.sum(np.einsum("ij,ij->i", a, np.cross(b, c))) / 6.0)
        print("-- %s: %d vértices  %d triángulos  volumen firmado=%+.4f m3  %s"
              % (name, len(points), len(tris), signed,
                 "NORMALES HACIA DENTRO" if signed < 0 else "normales hacia fuera"))
        if name.lower() == "body":
            continue
        centre = (points.min(axis=0) + points.max(axis=0)) * 0.5
        rel = points - centre
        sizes = points.max(axis=0) - points.min(axis=0)
        axle = int(np.argmin(sizes))
        radial = [i for i in range(3) if i != axle]
        rho = np.sqrt(rel[:, radial[0]] ** 2 + rel[:, radial[1]] ** 2)
        angle = np.arctan2(rel[:, radial[1]], rel[:, radial[0]])
        rmax = float(rho.max())
        r_min = float(rho.min())
        sectors = np.zeros(72)
        for k, (rv, av) in enumerate(zip(rho, angle)):
            s = int(((av + math.pi) / (2 * math.pi)) * 72) % 72
            sectors[s] = max(sectors[s], rv)
        covered = int((sectors >= 0.93 * rmax).sum())
        empty = int((sectors <= 1e-6).sum())
        print("   centro=%s  eje=%s  r_max=%.4f  r_min=%.4f  (r_min/r_max=%.3f)"
              % (np.round(centre, 3).tolist(), "xyz"[axle], rmax, r_min, r_min / rmax))
        print("   banda: sectores con radio >=93%% de r_max: %d/72   sectores SIN geometría: %d"
              % (covered, empty))
        hist = []
        for lo, hi in [(0.0, 0.5), (0.5, 0.75), (0.75, 0.93), (0.93, 1.01)]:
            hist.append("%.2f-%.2fR: %d" % (lo, hi, int(((rho >= lo * rmax) & (rho < hi * rmax)).sum())))
        print("   vértices por radio: " + "  ".join(hist))
        gaps = [(i * 5 - 180, sectors[i]) for i in range(72) if sectors[i] < 0.93 * rmax]
        if gaps:
            print("   sectores incompletos (grados, r): %s"
                  % " ".join("%+d°(%.3f)" % (g[0], g[1] / rmax) for g in gaps[:18]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
