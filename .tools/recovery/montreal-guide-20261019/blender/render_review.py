import bpy
from mathutils import Vector
from pathlib import Path
scene=bpy.context.scene
scene.render.engine='BLENDER_EEVEE_NEXT'
scene.render.resolution_x=1600; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.view_settings.view_transform='Standard'
scene.render.film_transparent=False
scene.world.color=(0.24,0.32,0.42)
# Source-geometry review capture only; clearly labelled Blender render, not game evidence.
views=[((-75,40,-410),(-80,0,-430),'blender-track-start-review.png'),((-320,75,-900),(-270,0,-820),'blender-track-southwest-review.png'),((350,95,500),(250,0,400),'blender-track-northeast-review.png')]
for loc,target,name in views:
 for o in list(bpy.context.scene.objects):
  if o.type=='CAMERA': bpy.data.objects.remove(o,do_unlink=True)
 bpy.ops.object.camera_add(location=loc); cam=bpy.context.object
 cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.lens=42; scene.camera=cam
 out=Path('.tools/recovery/montreal-guide-20261019/blender')/name; scene.render.filepath=str(out)
 bpy.ops.render.render(write_still=True); print('BLENDER_GEOMETRY_REVIEW_RENDER',out,out.stat().st_size)
 bpy.data.objects.remove(cam,do_unlink=True)
