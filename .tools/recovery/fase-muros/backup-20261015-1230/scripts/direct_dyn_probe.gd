extends SceneTree
func _initialize():
 call_deferred("run")
func run():
 var c=load("res://scripts/car_controller.gd").new()
 root.add_child(c); await process_frame
 c.throttle_input=1.0; c.speed_mps=0.0
 for i in 480:
  c.speed_mps=maxf(0.0,c.velocity.dot(-c.global_basis.z))
  c._update_engine_and_forces(1.0/120.0,-c.global_basis.z,c.global_basis.x,c.speed_mps,c.velocity.dot(c.global_basis.x))
  c.move_and_slide()
 print("speed=" ,c.speed_kph," v=",c.velocity)
 quit()
