import bpy, json, os
from pathlib import Path
images=[]; missing=[]; mapped=[]
for im in bpy.data.images:
 if im.name in {'Render Result','Viewer Node'}: continue
 if im.packed_file is not None:
  images.append((im.name,'packed',im.packed_file.size)); continue
 key=Path(im.name).stem.lower().strip()
 root=Path('.tools/recovery/montreal-guide-20261019/source/content/tracks/montreal/texture')
 matches=[p for p in root.iterdir() if p.is_file() and p.stem.lower().strip()==key]
 if matches: im.filepath=str(matches[0].resolve()); mapped.append((im.name,str(matches[0])))
 else:
  png=next((p for p in (root/'png').glob('*.png') if p.stem.lower().strip()==key),None)
  if png: im.filepath=str(png.resolve()); mapped.append((im.name,str(png)))
  else: missing.append(im.name)
print('FBX_TEXTURE_SOURCES',len(images),'resolved_unpacked',len(mapped),'missing',len(missing),missing[:20])
with open('.tools/recovery/montreal-guide-20261019/blender/fbx-textures.json','w') as f: json.dump({'packed':images,'resolved':mapped,'missing':missing},f,indent=2)
