extends SceneTree
const TD=preload("res://scripts/track_data.gd")
func _initialize():
	TD.reset_selection(); TD.select_track(TD.SUZUKA)
	var line: PackedVector3Array=TD.get_centerline()
	for i in range(1350, 1540, 10):
		var a: Vector3=line[i]; var b: Vector3=line[i+1]
		var d:=a.distance_to(b)
		print("ELEV idx=",i," xyz=",a," dy1=",b.y-a.y," slope=",(b.y-a.y)/maxf(d,0.001))
	quit(0)
