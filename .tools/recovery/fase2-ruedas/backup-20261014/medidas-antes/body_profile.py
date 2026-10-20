#!/usr/bin/env python3
"""Perfil de la carrocería del Red Bull por franjas de altura (solo lectura).

Responde a una pregunta concreta: ¿la malla del chasis incluye una losa ancha al
nivel del suelo (más ancha que la vía de las ruedas)? Se mide, por franja de
altura, la extensión lateral (X) y longitudinal (Z) de la geometría, y se
compara con la vía y el diámetro de las ruedas.

Uso: body_profile.py <modelo.glb>
"""
from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

import numpy as np

COMPONENTS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}
FORMATS = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I", 5126: "f"}
SIZES = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}


def load_glb(path: Path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67, "no es un GLB"
    offset = 12
    gltf = None
    binary = b""
    while offset < length:
        chunk_len, chunk_type = struct.unpack_from("<II", data, offset)
        payload = data[offset + 8: offset + 8 + chunk_len]
        if chunk_type == 0x4E4F534A:
            gltf = json.loads(payload.decode("utf-8"))
        elif chunk_type == 0x004E4942:
            binary = payload
        offset += 8 + chunk_len
    return gltf, binary


def read_accessor(gltf, binary, index):
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    count = acc["count"]
    ncomp = COMPONENTS[acc["type"]]
    fmt = FORMATS[acc["componentType"]]
    size = SIZES[acc["componentType"]]
    stride = view.get("byteStride") or ncomp * size
    base = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    out = np.empty((count, ncomp), dtype=np.float64)
    for i in range(count):
        out[i] = struct.unpack_from("<" + fmt * ncomp, binary, base + i * stride)
    return out


def node_matrix(node):
    if "matrix" in node:
        return np.array(node["matrix"], float).reshape(4, 4).T
    m = np.eye(4)
    t = node.get("translation", [0.0, 0.0, 0.0])
    x, y, z, w = node.get("rotation", [0.0, 0.0, 0.0, 1.0])
    s = node.get("scale", [1.0, 1.0, 1.0])
    rot = np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ])
    m[:3, :3] = rot * np.array(s, float)[None, :]
    m[:3, 3] = t
    return m


def main() -> int:
    path = Path(sys.argv[1])
    gltf, binary = load_glb(path)
    nodes = gltf["nodes"]
    print("== %s" % path)
    body = next(n for n in nodes if n.get("name", "").lower() == "body")
    matrix = node_matrix(body)
    points = []
    for prim in gltf["meshes"][body["mesh"]]["primitives"]:
        pos = read_accessor(gltf, binary, prim["attributes"]["POSITION"])
        hom = np.hstack([pos, np.ones((len(pos), 1))])
        points.append((matrix @ hom.T).T[:, :3])
    points = np.vstack(points)
    lo, hi = points.min(axis=0), points.max(axis=0)
    print("   carrocería: x %.3f..%.3f  y %.3f..%.3f  z %.3f..%.3f (m)"
          % (lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]))
    print("   anchura=%.3f m  alto=%.3f m  largo=%.3f m  vértices=%d"
          % (hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2], len(points)))
    print("   == extensión por franjas de altura (y), en metros")
    print("   %-14s %-9s %-19s %-19s %s" % ("franja y", "verts", "x (lateral)", "z (longitudinal)", "anchura"))
    bands = [(lo[1], 0.02), (0.02, 0.05), (0.05, 0.10), (0.10, 0.18), (0.18, 0.26),
             (0.26, 0.35), (0.35, 0.45), (0.45, 0.60), (0.60, 0.80), (0.80, 1.05), (1.05, hi[1] + 0.01)]
    for a, b in bands:
        sel = points[(points[:, 1] >= a) & (points[:, 1] < b)]
        if len(sel) == 0:
            print("   %6.2f..%6.2f  vacía" % (a, b))
            continue
        print("   %6.2f..%6.2f  %7d  %+.3f..%+.3f  %+.3f..%+.3f  %.3f"
              % (a, b, len(sel), sel[:, 0].min(), sel[:, 0].max(),
                 sel[:, 2].min(), sel[:, 2].max(), sel[:, 0].max() - sel[:, 0].min()))
    # Radiografía de la franja baja: ¿hay una losa ancha pegada al suelo?
    low = points[points[:, 1] < 0.03]
    if len(low):
        print("   == geometría por debajo de y=0.03: %d vértices, x %.3f..%.3f, z %.3f..%.3f"
              % (len(low), low[:, 0].min(), low[:, 0].max(), low[:, 2].min(), low[:, 2].max()))
    # Ensanchado: cuántos vértices están fuera de la huella razonable del monoplaza
    for limit in (0.60, 0.75, 0.90, 1.00, 1.05):
        sel = points[np.abs(points[:, 0]) > limit]
        if len(sel):
            print("   |x| > %.2f m: %6d vértices, y %.3f..%.3f, z %.3f..%.3f"
                  % (limit, len(sel), sel[:, 1].min(), sel[:, 1].max(), sel[:, 2].min(), sel[:, 2].max()))
    print("   == extensión lateral (x) por tramo longitudinal (z), todo el chasis")
    for za, zb in [(-2.80, -2.0), (-2.0, -1.2), (-1.2, -0.4), (-0.4, 0.4),
                   (0.4, 1.2), (1.2, 2.0), (2.0, 2.80)]:
        sel = points[(points[:, 2] >= za) & (points[:, 2] < zb)]
        if len(sel) == 0:
            continue
        print("   z %+.2f..%+.2f  %7d verts  x %+.3f..%+.3f (%.3f)  y %+.3f..%+.3f"
              % (za, zb, len(sel), sel[:, 0].min(), sel[:, 0].max(),
                 sel[:, 0].max() - sel[:, 0].min(), sel[:, 1].min(), sel[:, 1].max()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
