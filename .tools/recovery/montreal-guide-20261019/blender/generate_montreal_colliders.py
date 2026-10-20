import bpy
from pathlib import Path
from collections import Counter
blend=Path('.tools/recovery/montreal-guide-20261019/blender/montreal-original-groups.blend').resolve()
fbx=Path('montreal-guide.fbx').resolve()
bpy.ops.wm.open_mainfile(filepath=str(blend))
# Original exported scene has separate large categories for visuals and collision.
# Exclude only scenery-building concave mesh; retain road, runoffs, grass, kerbs, walls/fences.
allowed={'Asphalt','Grass','Runoff','Kerbs','Barriers','Fences'}
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
for obj in list(meshes):
    if obj.name.endswith('-colonly') and obj.name.split('-')[0] not in allowed:
        obj.name=obj.name.replace('-colonly','-visual') if obj.name.endswith('-colonly') else obj.name
print('MONTREAL_COLLIDER_ALLOWLIST', [(o.name,len(o.data.polygons)) for o in bpy.context.scene.objects if o.type=='MESH' and o.name.endswith('-colonly')])
# Move start line alignment to generated track world coordinates: Blender FBX's source frame
# is rotated 180 degrees from the Assetto Corsa AI lane. Rotate mesh objects around origin.
# The track catalog will retain rotation PI; here intentionally leave source geometry as-is.
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in meshes: o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=True, apply_scale_options='FBX_SCALE_ALL', bake_space_transform=False, object_types={'MESH'}, path_mode='COPY', embed_textures=True, add_leaf_bones=False, axis_forward='-Z', axis_up='Y')
print('MONTREAL_FBX_REEXPORTED', fbx.stat().st_size)
