import bpy
import json
import os
from collections import Counter

source = os.path.abspath('.tools/recovery/montreal-guide-20261019/source/content/tracks/montreal')
scene_dir = os.path.abspath('.tools/recovery/montreal-guide-20261019/blender')
obj_path = os.path.join(source, 'montreal.obj')

bpy.ops.wm.read_factory_settings(use_empty=True)
# Required guide setting: use_split_groups=True; use_split_objects=False.
result = bpy.ops.wm.obj_import(
    filepath=obj_path,
    forward_axis='NEGATIVE_Z',
    up_axis='Y',
    use_split_objects=False,
    use_split_groups=True,
    import_vertex_groups=False,
    validate_meshes=True,
)
if 'FINISHED' not in result:
    raise RuntimeError(f'Blender OBJ import failed: {result}')

objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
collections = sorted({collection.name for obj in objects for collection in obj.users_collection})
print(f'GUIDE_OBJ_IMPORT finished={result} objects={len(objects)} meshes={sum(len(o.data.polygons) for o in objects)} collections={collections}')
classes = Counter()
materials = Counter()
for obj in objects:
    name = obj.name.lower()
    if any(term in name for term in ('road', 'kerb', 'grass', 'runoff', 'sand', 'carpet', 'pit', 'cut')):
        category = 'road_or_surface'
    elif any(term in name for term in ('armco', 'wall', 'fence', 'barrier', 'guard')):
        category = 'barrier_or_fence'
    elif any(term in name for term in ('building', 'bridge', 'stand', 'casino', 'tower', 'box')):
        category = 'building_or_grandstand'
    elif any(term in name for term in ('water', 'tree', 'hedge', 'grassblade')):
        category = 'environment'
    else:
        category = 'other'
    classes[category] += 1
    for slot in obj.material_slots:
        if slot.material:
            materials[slot.material.name] += 1
print('GUIDE_GROUP_CATEGORIES', dict(classes))
print('GUIDE_MATERIALS', len(materials), 'slots', sum(materials.values()))
print('GUIDE_BOUNDS', [min((o.bound_box[i][axis] + o.location[axis] for o in objects for i in range(8)), default=0) for axis in range(3)], [max((o.bound_box[i][axis] + o.location[axis] for o in objects for i in range(8)), default=0) for axis in range(3)])
blend_path = os.path.join(scene_dir, 'montreal-original-groups.blend')
bpy.ops.wm.save_as_mainfile(filepath=blend_path)
print('GUIDE_BLEND_SAVED', blend_path, os.path.getsize(blend_path))
report = {'source_obj': obj_path, 'split_by_group': True, 'split_by_object': False,
          'objects': len(objects), 'mesh_polygons': sum(len(o.data.polygons) for o in objects),
          'collections': collections, 'categories': dict(classes),
          'material_count': len(materials), 'material_slots': sum(materials.values()),
          'material_names': sorted(materials), 'blend_path': blend_path}
with open(os.path.join(scene_dir, 'import-review.json'), 'w') as f:
    json.dump(report, f, indent=2)
