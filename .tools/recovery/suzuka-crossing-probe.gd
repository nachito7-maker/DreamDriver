extends SceneTree
const TD=preload("res://scripts/track_data.gd")
func _initialize():
	TD.reset_selection(); TD.select_track(TD.SUZUKA)
	var line: PackedVector3Array=TD.get_centerline()
	var count:=0
	for i in range(1250,1550):
		var a:Vector2=Vector2(line[i].x,line[i].z)
		for j in range(i+120,line.size()):
			var b:Vector2=Vector2(line[j].x,line[j].z)
			var d:=a.distance_to(b)
			if d<18.0 and absf(line[i].y-line[j].y)>3.0:
				print("CROSS i=",i," j=",j," xz_m=",d," y1=",line[i].y," y2=",line[j].y," delta=",absf(line[i].y-line[j].y))
				count+=1
	print("CROSS COUNT=",count)
	quit(0)
