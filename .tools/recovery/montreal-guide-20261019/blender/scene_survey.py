import bpy
from mathutils import Vector
from pathlib import Path
scene=bpy.context.scene
scene.render.engine='BLENDER_EEVEE'; scene.render.resolution_x=1400; scene.render.resolution_y=900; scene.render.resolution_percentage=70
scene.render.image_settings.file_format='PNG'; scene.view_settings.view_transform='Standard'; scene.render.film_transparent=False
scene.world=bpy.data.worlds.new('Montreal review world'); scene.world.color=(0.24,0.32,0.42)
for o in list(scene.objects):
 if o.type=='CAMERA': bpy.data.objects.remove(o,do_unlink=True)
center=Vector((-330,0,-470)); bpy.ops.object.camera_add(location=center+Vector((900,950,1200)))
cam=bpy.context.object; cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.lens=44; scene.camera=cam
out=Path('.tools/recovery/montreal-guide-20261019/blender/source-track-overview.png'); scene.render.filepath=str(out)
bpy.ops.render.render(write_still=True); print('BLENDER_SOURCE_TRACK_OVERVIEW',out,out.stat().st_size)
