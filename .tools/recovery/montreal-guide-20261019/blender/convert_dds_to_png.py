import bpy, sys
from pathlib import Path
src=Path('.tools/recovery/montreal-guide-20261019/source/content/tracks/montreal/texture')
out=src/'png'
out.mkdir(exist_ok=True)
files=list(src.glob('*.dds'))+list(src.glob('*.DDS'))
errors=[]
for i,p in enumerate(files):
 try:
  img=bpy.data.images.load(str(p.resolve()), check_existing=False)
  img.filepath_raw=str((out/(p.stem+'.png')).resolve())
  img.file_format='PNG'
  img.save()
  bpy.data.images.remove(img)
 except Exception as e:
  errors.append((p.name,str(e)))
 if (i+1)%25==0: print('DDS_PROGRESS',i+1,'/',len(files))
print('DDS_TO_PNG complete=',len(files)-len(errors),'errors=',len(errors),'output=',out)
for name,msg in errors: print('DDS_ERROR',name,msg)
if errors: sys.exit(2)
