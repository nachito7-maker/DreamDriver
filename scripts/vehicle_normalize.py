import bpy
import math
from mathutils import Vector

# Usage: blender --background --factory-startup --python scripts/vehicle_normalize.py -- source.glb output.glb
args = bpy.context.preferences.filepaths
import sys
argv = sys.argv[sys.argv.index("--") + 1:]
source, destination = argv[0], argv[1]
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=source)
meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
for obj in bpy.context.scene.objects:
    if obj.type != "MESH":
        bpy.data.objects.remove(obj, do_unlink=True)
coords = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
mins = Vector(tuple(min(point[i] for point in coords) for i in range(3)))
maxs = Vector(tuple(max(point[i] for point in coords) for i in range(3)))
center = (mins + maxs) * 0.5
longest_axis = max(range(3), key=lambda i: maxs[i] - mins[i])
# Original prototype is 1.896 m along local X. Rotate that longitudinal axis to Godot's -Z.
if longest_axis == 0:
    rotation = math.pi * 0.5
elif longest_axis == 2:
    rotation = 0.0
else:
    raise RuntimeError("Expected a longitudinal X or Z axis, got %s" % longest_axis)
scale = 5.526 / (maxs[longest_axis] - mins[longest_axis])
for obj in meshes:
    obj.location -= center
    obj.rotation_euler[1] = rotation
    obj.scale = (scale, scale, scale)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.select_set(False)
# Relocate to contact plane; actual geometry is a fused solid without articulated wheel pivots.
coords = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
lowest_y = min(point.y for point in coords)
for obj in meshes:
    obj.location.y -= lowest_y
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=destination, export_format="GLB", export_apply=True, export_yup=True)
print("NORMALIZED Red Bull: length=5.526 m, fused mesh, wheel pivots unavailable; output=", destination)
