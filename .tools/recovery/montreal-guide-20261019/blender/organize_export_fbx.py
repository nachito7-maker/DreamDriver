import bpy
import json
import os
from collections import Counter
from pathlib import Path

BLEND = Path('.tools/recovery/montreal-guide-20261019/blender/montreal-original-groups.blend').resolve()
FBX = Path('.tools/recovery/montreal-guide-20261019/blender/montreal.fbx').resolve()
OBJECTS = [o for o in bpy.context.scene.objects if o.type == 'MESH']

# Categories come from the converted KN5 group names and their actual material
# names; these criteria were cross-checked against the game's surfaces.ini.
TERMS = {
    'Asphalt': ('road', 'rdabd', 'rdilcs', 'roadline', 'roadgrid', 'roadsfl'),
    'Grass': ('grassa', 'grassblade', 'hedge', 'treeline'),
    'Runoff': ('runoffg', 'sand', 'gravel', 'carpet', 'roadverge', 'grasssand', 'roadb', 'roadblue'),
    'Kerbs': ('kerb', 'curb', 'rumble', 'rmbla', 'rmblg', 'rmbfg', 'creteg', 'conilred'),
    'Barriers': ('armco', 'barrier', 'guard', 'wall_armco', 'cmwall', 'concretewall', 'twall', 'pwall'),
    'Fences': ('fence', 'railing'),
    'PitBuildings': ('pitbuilding', 'pitbox', 'garage'),
    'Buildings': ('building', 'casino', 'tower', 'bridge', 'stand', 'grandstand'),
    'Decor': ('tree', 'light', 'advert', 'crowd', 'vehicle', 'car', 'water', 'sedan', 'van'),
}
SURFACES = {'Asphalt', 'Grass', 'Runoff', 'Kerbs', 'Barriers', 'Fences'}

def category(obj):
    name = obj.name.lower()
    materials = [slot.material.name.lower() for slot in obj.material_slots if slot.material]
    if name.startswith('ac_') or 'actiming' in name:
        return 'Auxiliary'
    if name.startswith('1wall') and ('armco' in name or 'wall' in name):
        return 'Barriers'
    if name.startswith('1road'):
        if any('runoffg' in m for m in materials):
            return 'Runoff'
        if any(any(t in m for t in ('roada', 'rdabd', 'rdilcs', 'roadg', 'roadsfl')) for m in materials):
            return 'Asphalt'
        if any(any(t in m for t in ('roadb', 'roadblue')) for m in materials):
            return 'Runoff'
    if name.startswith('1grass'):
        if any('grasssand' in m for m in materials):
            return 'Runoff'
        if any('grassa' in m for m in materials):
            return 'Grass'
    if name.startswith('1kerb') and any(any(t in m for t in ('rmb', 'creteg', 'conilred')) for m in materials):
        return 'Kerbs'
    if 'pits' in name:
        return 'Asphalt' if any(any(t in m for t in ('road', 'rdabd', 'rdilcs', 'roadblue')) for m in materials) else 'PitBuildings'
    if name.startswith('1sand'):
        return 'Runoff'
    if name.startswith('1sand'):
        return 'Runoff'
    for group in ('Kerbs', 'Runoff', 'Asphalt', 'Grass', 'Barriers', 'Fences', 'PitBuildings', 'Buildings', 'Decor'):
        if any(any(term in m for term in TERMS[group]) for m in materials):
            return group
    for group in ('Kerbs', 'Runoff', 'Asphalt', 'Grass', 'Barriers', 'Fences', 'PitBuildings', 'Buildings', 'Decor'):
        if any(term in name for term in TERMS[group]):
            return group
    return 'Other'

collections = {}
for obj in OBJECTS:
    group = category(obj)
    collection = collections.get(group)
    if collection is None:
        collection = bpy.data.collections.new(group)
        bpy.context.scene.collection.children.link(collection)
        collections[group] = collection
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    collection.objects.link(obj)

print('GUIDE_CATEGORIES', dict(Counter(category(o) for o in OBJECTS)))

# Convert explicit surfaces into functional groups. Join related visible meshes
# and preserve their original UVs/material slots. Keep non-surface/scenery
# pieces independent where separate collision or rendering behavior is useful.
joined_groups = 0
for group in ('Asphalt', 'Grass', 'Runoff', 'Kerbs', 'Barriers', 'Fences', 'PitBuildings', 'Buildings'):
    members = [o for o in OBJECTS if category(o) == group]
    if group in ('Asphalt', 'Grass', 'Runoff', 'Kerbs', 'Barriers', 'Fences'):
        members = [o for o in members if o.name.lower() != '1wall_armcocol01_gmt']
    # The only separately-authored barrier collision source already has the
    # exact AC wall name and is not part of the visual combined barrier batch.
    if group == 'Barriers':
        members = [o for o in members if o.name.lower() != '1wall_armcocol01_gmt']
    if group in ('Asphalt', 'Runoff', 'Kerbs'):
        members = [o for o in members if not (group == 'Asphalt' and o.name.lower().startswith('1pits'))]
    if len(members) < 2:
        continue
    bpy.ops.object.select_all(action='DESELECT')
    for obj in members:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = members[0]
    bpy.ops.object.join()
    OBJECTS = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    visual = members[0]
    visual.name = group + '-visual'
    visual.data.name = group + '-VisualMesh'
    collider = visual.copy()
    collider.data = visual.data.copy()
    collider.name = group + '-colonly'
    collider.data.name = group + '-CollisionMesh'
    collections[group].objects.link(collider)
    collider.data.materials.clear()
    collider.hide_render = True
    joined_groups += 1

# preserve separately named actual barrier/armco group as a collision-specific
# surface; the renderable original group remains untouched and identifiable.
wall = bpy.data.objects.get('1WALL_armcocol01_gmt')
if wall is not None:
    wall.name = 'MontrealBarrier-colonly'
    wall.data.materials.clear()
    wall.hide_render = True
    collections['Barriers'].objects.link(wall) if collections['Barriers'] not in wall.users_collection else None

images = [im for im in bpy.data.images if im.source == 'FILE']
missing = []
source_textures = Path('.tools/recovery/montreal-guide-20261019/source/content/tracks/montreal/texture')
for image in images:
    if image.packed_file is not None:
        continue
    stem = Path(image.name).stem.lower().strip()
    original = next((p for p in source_textures.iterdir() if p.is_file() and p.stem.lower().strip() == stem), None)
    converted = next((p for p in (source_textures / 'png').glob('*.png') if p.stem.lower().strip() == stem), None)
    if original is not None:
        image.filepath = str(original.resolve())
    elif converted is not None:
        image.filepath = str(converted.resolve())
    else:
        missing.append(image.name)
print('GUIDE_IMAGE_AUDIT', 'images', len(images), 'missing', len(missing), missing[:12])
if missing:
    raise RuntimeError('FBX export blocked: source image references unresolved')

mesh_objects = [o for o in bpy.context.scene.objects if o.type == 'MESH']
collision_names = [o.name for o in mesh_objects if o.name.endswith('-colonly')]
print('GUIDE_SCENE', 'mesh_objects', len(mesh_objects), 'joined_groups', joined_groups,
      'collision_meshes', collision_names,
      'bounds', [(o.name, tuple(round(v, 2) for v in o.dimensions)) for o in mesh_objects if o.name.endswith('-colonly')])
bpy.ops.wm.save_as_mainfile(filepath=str(BLEND))
bpy.ops.object.select_all(action='DESELECT')
for obj in mesh_objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = mesh_objects[0]
bpy.ops.export_scene.fbx(filepath=str(FBX), use_selection=True,
                         apply_scale_options='FBX_SCALE_ALL', bake_space_transform=False,
                         object_types={'MESH'}, path_mode='COPY', embed_textures=True,
                         add_leaf_bones=False, axis_forward='-Z', axis_up='Y')
assert FBX.stat().st_size > 1_000_000
print('GUIDE_FBX_EXPORTED', str(FBX), FBX.stat().st_size, 'mesh_objects', len(mesh_objects))
print('GUIDE_FBX_VERIFIED', 'size_bytes', FBX.stat().st_size,
      'objects', len(mesh_objects), 'collision_meshes', len(collision_names), 'textures', len(images))
review = {'blender': bpy.app.version_string, 'mesh_objects': len(mesh_objects),
          'categories': dict(Counter(category(o) for o in mesh_objects)),
          'collision_meshes': collision_names, 'texture_images': len(images),
          'unresolved_textures': missing, 'fbx': str(FBX), 'fbx_bytes': FBX.stat().st_size}
Path('.tools/recovery/montreal-guide-20261019/blender/export-review.json').write_text(json.dumps(review, indent=2))
