import bpy, json
from collections import Counter
items=[]
for o in bpy.data.objects:
 if o.type!='MESH': continue
 items.append((o.name, [s.material.name for s in o.material_slots if s.material], len(o.data.polygons)))
print('TOTAL',len(items))
for test in ('ROAD','GRASS','RUNOFF','SAND','KERB','CURB','WALL','ARMCO','FENCE','BARRIER','PIT','BUILD','TREE','WATER','COLLISION','BILLBOARD','STAND','BRIDGE'):
 hit=[x for x in items if test in x[0].upper() or any(test in m.upper() for m in x[1])]
 print('MATCH',test,len(hit),'SAMPLE',hit[:8])
with open('.tools/recovery/montreal-guide-20261019/blender/object-inventory.json','w') as f: json.dump(items,f,indent=2)
