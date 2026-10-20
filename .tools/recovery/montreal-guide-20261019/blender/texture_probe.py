import bpy
from pathlib import Path
p=Path('.tools/recovery/montreal-guide-20261019/source/content/tracks/montreal/texture/png')
print('PNG_FILES',len(list(p.glob('*.png'))))
for name in ['armco.dds','fencec.dds','montreal_pitbuilding_checkeredwood_d.dds']:
    im=next((i for i in bpy.data.images if i.name.lower()==name.lower()),None)
    f=next((x for x in p.glob('*.png') if x.stem.lower()==Path(name).stem.lower()),None)
    print('BEFORE',name,'image',im,'path',im.filepath if im else None,'size',tuple(im.size) if im else None,'data',im.has_data if im else None,'png',f, f.exists() if f else None)
    if im and f:
        im.filepath=str(f.resolve())
        print('SET',im.filepath)
        try: im.reload()
        except Exception as e: print('RELOAD_ERROR',repr(e))
        print('AFTER',im.filepath,tuple(im.size),im.has_data,im.packed_file)
    elif f:
        try:
            x=bpy.data.images.load(str(f.resolve()),check_existing=False)
            print('LOAD_NEW',x.name,x.filepath,tuple(x.size),x.has_data, x.packed_file)
        except Exception as e: print('LOAD_ERROR',repr(e))
