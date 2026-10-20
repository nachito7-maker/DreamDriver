import bpy
import math
from pathlib import Path
fbx=Path('montreal-guide.fbx').resolve()
bpy.ops.wm.open_mainfile(filepath=str(Path('.tools/recovery/montreal-guide-20261019/blender/montreal-original-groups.blend').resolve()))
# Rotate every mesh position and vertices in Blender by pi about world Y.
rot=math.pi
for obj in bpy.context.scene.objects:
    if obj.type!='MESH': continue
    obj.location.x *= -1.0
    obj.location.z *= -1.0
    # The road height and scale remain unchanged; this maps +AC coordinates to the FBX convention.
    obj.data.transform(__import__('mathutils').Matrix.Rotation(rot,4,'Y'))
    obj.data.update()
# Include only the approved collision bodies and keep visuals all non-colonly.
allowed={'Asphalt','Grass','Runoff','Kerbs','Barriers','Fences'}
for obj in bpy.context.scene.objects:
    if obj.type!='MESH': continue
    if obj.name.endswith('-colonly') and obj.name.split('-')[0] not in allowed:
        obj.name=obj.name.replace('-colonly','-visual')
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for obj in meshes: obj.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,apply_scale_options='FBX_SCALE_ALL',bake_space_transform=False,object_types={'MESH'},path_mode='COPY',embed_textures=True,add_leaf_bones=False,axis_forward='-Z',axis_up='Y')
print('MONTREAL_REALIGNED_FBX',fbx,fbx.stat().st_size,'meshes',len(meshes),'colliders',[o.name for o in meshes if o.name.endswith('-colonly')])
