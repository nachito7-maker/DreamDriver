#!/usr/bin/env python3
"""Attach the AC surface sidecar to matching mesh nodes in the converted Montreal glTF.

The existing converter deliberately writes surface metadata as a sidecar. The
runtime uses glTF node extras to select physics meshes, so this integration joins
the two source-derived artifacts without altering vertex, material, or texture data.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
GLTF = ROOT / "assets/montreal/montreal-circuit-gilles-villeneuve.gltf"
SIDECAR = ROOT / "assets/montreal/montreal-circuit-gilles-villeneuve.surfaces.json"

scene = json.loads(GLTF.read_text())
surface_data = json.loads(SIDECAR.read_text())
by_name = surface_data.get("nodes", {})
unkeyed = surface_data.get("unkeyed", {})
walls = set(surface_data.get("walls", []))
mesh_names = {mesh.get("name", "") for mesh in scene.get("meshes", [])}
matched = 0
for node in scene.get("nodes", []):
    if "mesh" not in node:
        continue
    name = str(node.get("name", ""))
    if name not in mesh_names:
        continue
    extra = {"ac_source_nodes": name}
    if name in by_name or name in unkeyed or name in walls:
        extra["ac_physics"] = True
        matched += 1
    node["extras"] = extra

if matched != len(by_name) + len(unkeyed) + len(walls):
    raise SystemExit(
        f"Surface mapping mismatch: annotated={matched}, sidecar="
        f"{len(by_name) + len(unkeyed) + len(walls)}")
GLTF.write_text(json.dumps(scene, separators=(",", ":"), allow_nan=False))
print(f"ANNOTATED physics_nodes={matched} road={sum(v == 'ROAD' for v in by_name.values())} "
      f"walls={len(walls)} unkeyed={len(unkeyed)} total_mesh_nodes={sum('mesh' in n for n in scene['nodes'])}")
