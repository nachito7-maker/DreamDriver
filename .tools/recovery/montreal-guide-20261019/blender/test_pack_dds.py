import bpy
im=bpy.data.images.get('armco.dds')
print('SOURCE',im.name,im.filepath,im.size,im.has_data,im.packed_file)
try:
 im.pack()
 print('PACKED',im.packed_file, im.packed_file.size if im.packed_file else None, im.filepath)
except Exception as e: print('PACK_ERROR',repr(e))
