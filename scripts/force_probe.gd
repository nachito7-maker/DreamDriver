extends SceneTree
func _initialize():call_deferred("run")
func run():
 var c=load("res://scripts/car_controller.gd").new(); root.add_child(c); await process_frame
 var f= -c.global_basis.z; var r=c.global_basis.x
 for i in 3:
  c.throttle_input=1.0;c.speed_mps=0.0
  c._update_engine_and_forces(1.0/120,f,r,c.velocity.dot(f),c.velocity.dot(r))
  print(i," vel ",c.velocity," spm ",c.speed_mps," kph ",c.speed_kph," accel ",c.acceleration_longitudinal," th ",c.throttle_input," lat ",c.acceleration_lateral)
 quit()
