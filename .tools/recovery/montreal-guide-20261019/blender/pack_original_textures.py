import bpy
import os
from pathlib import Path

pngs = Path('.tools/recovery/montreal-guide-20261019/source/content/tracks/montreal/texture/png').resolve()
index = {p.stem.lower(): p for p in pngs.glob('*.png')}
packed = 0
missing = []
failed = []
for image in bpy.data.images:
    if image.name in {'Render Result', 'Viewer Node'}:
        continue
    key = Path(image.name).stem.strip().lower()
    path = index.get(key)
    if path is None:
        missing.append(image.name)
        continue
    try:
        converted = bpy.data.images.load(str(path), check_existing=False)
        if converted.size[0] <= 0 or converted.size[1] <= 0:
            failed.append((image.name, 'no image size'))
            bpy.data.images.remove(converted)
            continue
        converted.pack()
        converted.filepath = '//texture/png/' + path.name
        for material in bpy.data.materials:
            for node in material.node_tree.nodes if material.use_nodes else []:
                if node.type == 'TEX_IMAGE' and node.image == image:
                    node.image = converted
        bpy.data.images.remove(image)
        packed += 1
    except Exception as exc:
        failed.append((image.name, str(exc)))
print('GUIDE_TEXTURE_PACKED', packed, 'MISSING', len(missing), missing[:10], 'FAILED', len(failed), failed[:10])
if missing or failed or packed == 0:
    raise RuntimeError('Could not load all imported source textures')
blend = os.path.abspath('.tools/recovery/montreal-guide-20261019/blender/montreal-original-groups.blend')
bpy.ops.wm.save_as_mainfile(filepath=blend)
print('GUIDE_TEXTURE_BLEND_SAVED', blend, os.path.getsize(blend))
