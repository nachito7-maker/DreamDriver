import bpy,json
from pathlib import Path
names=[]
for o in bpy.data.objects:
 if o.type!='MESH': continue
 mats=sorted({s.material.name.lower() for s in o.material_slots if s.material})
 if o.name.lower().startswith(('1road','1pits','1kerb','1grass','1sand')) or any(x in m for m in mats for x in ('roada','roadb','roadpits','pits','rmbla','rmblg','grassa','grassesand','sand')):
  names.append((o.name,mats,len(o.data.polygons)))
print('SURFACE_GROUP_MESHES',len(names))
for r in names[:100]: print('SURFACE',r)
Path('.tools/recovery/montreal-guide-20261019/blender/surface-group-audit.json').write_text(json.dumps(names,indent=2))
