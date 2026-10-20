import bpy, json
from collections import Counter
rows=[]
for mat in bpy.data.materials:
 if not mat.use_nodes: continue
 imgs=[n.image.name for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
 if imgs: rows.append((mat.name,imgs,mat.blend_method if hasattr(mat,'blend_method') else None))
print('MATERIAL_COUNT',len(bpy.data.materials),'MATERIALS_WITH_TEXTURES',len(rows),'UNIQUE_IMAGES',len(set(x for _,xs,_ in rows for x in xs)))
for x in rows[:20]: print('MATERIAL',x)
with open('.tools/recovery/montreal-guide-20261019/blender/material-texture-review.json','w') as f: json.dump(rows,f,indent=2)
