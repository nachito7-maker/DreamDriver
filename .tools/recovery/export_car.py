import bpy, json, math
from pathlib import Path
from mathutils import Matrix, Vector
bpy.ops.wm.read_factory_settings(use_empty=True)
# Preserve the original livery material from the supplied fused model.
bpy.ops.import_scene.gltf(filepath=str(Path('assets/RedBull.glb').resolve()))
original = [o for o in bpy.data.objects if o.type == 'MESH'][0]
body_material = original.data.materials[0]
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.import_scene.fbx(filepath=str(Path('VehiclePrototypes/_backup_fill_20260921/redbull/model.fbx').resolve()))
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
print('CAR_PARTS', [(o.name, tuple(o.location), tuple(o.dimensions), [m.name for m in o.data.materials]) for o in meshes])
assert len(meshes) == 5
# Existing fleet source faces -Y in Blender; glTF maps this to +Z. Rotate 180
# before export so forward is Godot -Z. Raise from fleet offset to ground zero.
for o in meshes:
    world = o.matrix_world.copy()
    o.parent = None
    o.matrix_world = Matrix.Translation((0,0,0.0936)) @ Matrix.Rotation(math.pi,4,'Z') @ world
    if 'body' in o.name:
        o.data.materials.clear()
        o.data.materials.append(body_material)
        o.name = 'Body'
    else:
        suffix = next(s for s in ('fl','fr','bl','br') if '_'+s in o.name)
        o.name = 'wheel_'+suffix.replace('b','r')
        # Fleet capture wheels use the body atlas, not a replacement colour.
        o.data.materials.clear()
        o.data.materials.append(body_material)
bpy.context.view_layer.update()
report = {'parts': []}
for o in meshes:
    report['parts'].append({'name':o.name,'position': list(o.matrix_world.translation), 'dimensions':list(o.dimensions)})
output = Path('assets/RedBull-Drive.glb').resolve()
bpy.ops.export_scene.gltf(filepath=str(output), export_format='GLB', export_yup=True, export_materials='EXPORT', export_animations=False)
Path('.tools/recovery/car_report.json').write_text(json.dumps(report,indent=2))
print('CAR_EXPORTED',report)
