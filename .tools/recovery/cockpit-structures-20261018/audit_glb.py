import bpy
import json
import os
import sys
from mathutils import Vector

OUT = os.path.join(os.path.dirname(__file__), "blender-mesh-audit.txt")
MODELS = [
    os.path.abspath("assets/RB22-2026-Verstappen.glb"),
    os.path.abspath("assets/MP44-Senna.glb"),
]

with open(OUT, "w", encoding="utf-8") as report:
    for filepath in MODELS:
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.object.delete(use_global=False)
        bpy.ops.import_scene.gltf(filepath=filepath)
        bpy.context.view_layer.update()
        meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
        report.write(f"\nMODEL {filepath} mesh_objects={len(meshes)}\n")
        for obj in meshes:
            local = obj.bound_box
            corners = [obj.matrix_world @ Vector(corner) for corner in local]
            mins = [min(v[i] for v in corners) for i in range(3)]
            maxs = [max(v[i] for v in corners) for i in range(3)]
            dims = [maxs[i] - mins[i] for i in range(3)]
            parent = obj.parent.name if obj.parent else "<root>"
            world_pos = tuple(round(v, 5) for v in obj.matrix_world.translation)
            world_scale = tuple(round(v, 5) for v in obj.matrix_world.to_scale())
            rot = tuple(round(v, 5) for v in obj.matrix_world.to_euler())
            raw = obj.get("extras")
            row = {
                "name": obj.name,
                "parent": parent,
                "world_position": world_pos,
                "world_euler_rad": rot,
                "world_scale": world_scale,
                "world_bounds_min": tuple(round(v, 5) for v in mins),
                "world_bounds_max": tuple(round(v, 5) for v in maxs),
                "world_dimensions": tuple(round(v, 5) for v in dims),
                "vertices": len(obj.data.vertices),
                "polygons": len(obj.data.polygons),
                "extras": raw,
            }
            report.write(json.dumps(row, ensure_ascii=False, default=str) + "\n")
        report.flush()
print(f"Wrote Blender inspection: {OUT}")
