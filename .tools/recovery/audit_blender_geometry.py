import bpy,json
from pathlib import Path
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=str(Path('.tools/tutorial-conversion/obj/barcelona_remastered.obj').resolve()),forward_axis='NEGATIVE_Z',up_axis='Y',use_split_objects=False,use_split_groups=True)
source=json.loads(Path('.tools/recovery/source_metadata.json').read_text())['barcelona_remastered.obj']['nodes']
source={n.replace(' ','_'):d for n,d in source.items()}
differences=[]
for o in bpy.data.objects:
    if o.type!='MESH':continue
    original=source[o.name]['triangles']
    imported=sum(len(p.vertices)-2 for p in o.data.polygons)
    if original!=imported: differences.append({'node':o.name,'source':original,'imported':imported,'removed':original-imported})
Path('.tools/recovery/obj_validation_removed_faces.json').write_text(json.dumps(differences,indent=2))
print('REMOVED_BY_OBJ_VALIDATION',differences)
assert sum(x['removed'] for x in differences)==20
