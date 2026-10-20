import bpy, json
p='.tools/recovery/montreal-guide-20261019/blender/montreal.fbx'
r=bpy.ops.import_scene.fbx(filepath=p, use_image_search=True)
mesh=[o for o in bpy.context.scene.objects if o.type=='MESH']
coll=[o.name for o in mesh if o.name.endswith('-colonly')]
mat=[s.material for o in mesh for s in o.material_slots if s.material]
images=[i for m in set(mat) if m.use_nodes for n in m.node_tree.nodes if n.type=='TEX_IMAGE' for i in [n.image] if i]
print('FBX_REIMPORT',r,'meshes',len(mesh),'collider_names',coll,'materials',len(set(mat)),'texture_nodes',len(images),'missing_image_data',sum(not x.has_data for x in images))
print('FBX_NAMES',[(o.name,len(o.data.polygons),len(o.material_slots)) for o in mesh if o.name.endswith('-colonly')])
if len(mesh)<800 or len(coll)!=8: raise RuntimeError('FBX geometry/name/collision reimport mismatch')
