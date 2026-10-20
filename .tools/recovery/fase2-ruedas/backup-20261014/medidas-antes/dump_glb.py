#!/usr/bin/env python3
"""Auditoría read-only de un GLB: jerarquía, transforms y cajas de las mallas.

No escribe nada. Imprime, por nodo: nombre, malla, transform (T/R/S) y la caja
envolvente en espacio de MUNDO (mm), además de un resumen de sospechas: escalas
fuera de rango, nodos de rueda, centros y radios de rueda, y la relación del
conjunto con el plano de contacto (y = 0).

Uso:  dump_glb.py <modelo.glb> [--wheels] [--all]
"""
from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

import numpy as np

WHEEL_TOKENS = ("wheel", "rueda", "tyre", "tire", "neumatic", "rim", "llanta",
                "w_f", "w_r", "_l0", "f1_wheel")


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
        offset += 8 + chunk_len + ((4 - chunk_len % 4) % 4 if chunk_len % 4 else 0)
    return gltf, binary


def accessor_minmax(gltf, index):
    acc = gltf["accessors"][index]
    if "min" in acc and "max" in acc:
        return np.array(acc["min"], float), np.array(acc["max"], float)
    return None, None


def trs_matrix(node):
    if "matrix" in node:
        return np.array(node["matrix"], float).reshape(4, 4).T
    m = np.eye(4)
    t = node.get("translation", [0.0, 0.0, 0.0])
    r = node.get("rotation", [0.0, 0.0, 0.0, 1.0])
    s = node.get("scale", [1.0, 1.0, 1.0])
    x, y, z, w = r
    rot = np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ])
    m[:3, :3] = rot * np.array(s, float)[None, :]
    m[:3, 3] = t
    return m


def mesh_bbox(gltf, mesh_index):
    lo = np.array([np.inf] * 3)
    hi = np.array([-np.inf] * 3)
    for prim in gltf["meshes"][mesh_index]["primitives"]:
        amin, amax = accessor_minmax(gltf, prim["attributes"]["POSITION"])
        if amin is None:
            continue
        lo = np.minimum(lo, amin)
        hi = np.maximum(hi, amax)
    if not np.isfinite(lo).all():
        return None, None
    return lo, hi


def corners(lo, hi):
    return np.array([[x, y, z] for x in (lo[0], hi[0])
                     for y in (lo[1], hi[1]) for z in (lo[2], hi[2])])


def world_bbox(lo, hi, matrix):
    pts = corners(lo, hi)
    hom = np.hstack([pts, np.ones((8, 1))])
    out = (matrix @ hom.T).T[:, :3]
    return out.min(axis=0), out.max(axis=0)


def main() -> int:
    path = Path(sys.argv[1])
    show_all = "--all" in sys.argv
    gltf, _ = load_glb(path)
    nodes = gltf.get("nodes", [])
    children = set()
    for n in nodes:
        for c in n.get("children", []):
            children.add(c)
    roots = [i for i in range(len(nodes)) if i not in children]

    print("== %s" % path)
    print("   nodos=%d mallas=%d materiales=%d escenas=%s"
          % (len(nodes), len(gltf.get("meshes", [])), len(gltf.get("materials", [])),
             gltf.get("scene")))
    print("   raíces: %s" % [nodes[r].get("name") for r in roots])

    rows = []
    sospechas = []
    wheels = []

    def walk(index, parent_matrix, depth):
        node = nodes[index]
        local = trs_matrix(node)
        world = parent_matrix @ local
        name = node.get("name", "<sin nombre>")
        scale = np.linalg.norm(local[:3, :3], axis=0)
        if node.get("mesh") is not None:
            lo, hi = mesh_bbox(gltf, node["mesh"])
            if lo is not None:
                wlo, whi = world_bbox(lo, hi, world)
                rows.append((depth, name, node["mesh"], local, wlo, whi))
                low = name.lower()
                if any(t in low for t in WHEEL_TOKENS):
                    wheels.append((name, wlo, whi, world))
        if abs(scale.max() - 1.0) > 0.02:
            sospechas.append((name, depth, scale, node.get("translation")))
        if depth < 6 or show_all:
            print("   %s%s  T=%s R=%s S=%s%s"
                  % ("  " * depth, name,
                     np.round(local[:3, 3], 4).tolist(),
                     np.round(node.get("rotation", [0, 0, 0, 1]), 4).tolist(),
                     np.round(scale, 4).tolist(),
                     "  mesh=%d" % node["mesh"] if node.get("mesh") is not None else ""))
        for c in node.get("children", []):
            walk(c, world, depth + 1)

    for r in roots:
        walk(r, np.eye(4), 0)

    if rows:
        lo = np.min([r[4] for r in rows], axis=0)
        hi = np.max([r[5] for r in rows], axis=0)
        print("== caja total (mundo, mm): x %.1f..%.1f  y %.1f..%.1f  z %.1f..%.1f"
              % (lo[0] * 1000, hi[0] * 1000, lo[1] * 1000, hi[1] * 1000, lo[2] * 1000, hi[2] * 1000))
        print("   dimensiones (largo/alto/ancho, mm): %.1f x %.1f x %.1f"
              % ((hi[2] - lo[2]) * 1000, (hi[1] - lo[1]) * 1000, (hi[0] - lo[0]) * 1000))

    print("== escalas distintas de 1 (>2%%): %d" % len(sospechas))
    for name, depth, scale, t in sospechas[:25]:
        print("   %s (nivel %d) S=%s T=%s" % (name, depth, np.round(scale, 3).tolist(),
                                              np.round(np.array(t or [0, 0, 0], float), 3).tolist()))

    print("== nodos de rueda por nombre: %d" % len(wheels))
    for name, lo, hi, _ in wheels:
        center = (lo + hi) * 0.5
        radio = (hi[1] - lo[1]) * 0.5
        print("   %-28s centro=(%+.4f, %+.4f, %+.4f) m  radio_y=%.4f m  ancho=%.4f m  fondo_y=%+.4f m"
              % (name, center[0], center[1], center[2], radio, hi[0] - lo[0], lo[1]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
