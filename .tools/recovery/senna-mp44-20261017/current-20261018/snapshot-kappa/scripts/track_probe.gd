extends SceneTree
const TD=preload("res://scripts/track_data.gd")
func _initialize():
 var p=TD.get_centerline(); var total=0.0
 for i in p.size(): total+=p[i].distance_to(p[(i+1)%p.size()])
 print("track points=",p.size(),"length=",total,"spawn=",TD.get_spawn_position(),"yaw=",TD.get_spawn_yaw())
 quit(0 if p.size()>2800 and total>4500 and total<5100 else 1)
