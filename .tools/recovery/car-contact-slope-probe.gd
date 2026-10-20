extends SceneTree
const TD=preload("res://scripts/track_data.gd")
func _initialize()->void: call_deferred("_run")
func _run()->void:
	TD.reset_selection(); TD.select_track(TD.SUZUKA)
	var race: Node3D=(load("res://scenes/race.tscn") as PackedScene).instantiate(); root.add_child(race)
	Engine.max_fps=0
	var car: CharacterBody3D=race.car
	car.set_physics_process(false); car.set_process(false); car.collision_mask=0; car.collision_layer=0
	if race.assistance_line!=null: race.assistance_line.set_process(false)
	if race.hud!=null: race.hud.set_process(false)
	if race.controls!=null: race.controls.set_process(false)
	for i in 120: await physics_frame
	race.set_physics_process(false); race.set_process(false)
	for node in race.track_mesh.find_children("*","StaticBody3D",true,false):
		var b:=node as StaticBody3D
		if b.name=="1ROAD": b.collision_layer=1; b.collision_mask=0
	var line:=TD.get_centerline(); car.recover_to(line[1300],_yaw_at(line,1300)); car.collision_mask=0; car.collision_layer=0
	car.set_physics_process(true); car.set_meta("touch_throttle",0.55)
	for i in 90: await physics_frame
	var sample_ix:=1300
	for tick in 3000:
		await physics_frame
		var nearest:=_nearest(line,car.global_position,1300,1540)
		var target:=line[mini(nearest+20,1540)]
		var local:=car.to_local(target); var look:=maxf(14.0,car.speed_mps*1.1)
		var angle:=atan2(2.0*car.wheelbase_m*sin(atan2(local.x,-local.z)),look)
		car.set_meta("touch_steer",clampf(angle/maxf(car.debug_max_steer,0.1),-1.0,1.0)*0.45)
		var e: float=25.0-car.speed_mps; car.set_meta("touch_throttle",clampf(0.52+e*0.025,0.2,0.75)); car.set_meta("touch_brake",clampf(-e*0.04,0.0,0.3))
		if nearest>=sample_ix+20:
			var ahead:=line[mini(nearest+5,1540)]; var behind:=line[maxi(nearest-5,1300)]
			var t:Vector3=car.global_basis.inverse()*(ahead-behind).normalized()
			print("GRADE idx=%d slope_forward=%.4f expected_vy=%.3f actual_vy=%.3f speed=%.1f contacts=%d h=%.3f y=%.3f"%[nearest,t.y,car.speed_mps*t.y,car.velocity.y,car.speed_kph,car.wheel_contacts,car.suspension.height,car.global_position.y])
			sample_ix=nearest
		if nearest>=1540 or car.global_position.y < -60: break
	race.queue_free(); await process_frame; quit()
func _nearest(l:PackedVector3Array,p:Vector3,a:int,b:int)->int:
	var best:=a; var bd:=INF
	for i in range(a,b+1):
		var d:=Vector2(l[i].x-p.x,l[i].z-p.z).length_squared()
		if d<bd: bd=d; best=i
	return best
func _yaw_at(l:PackedVector3Array,i:int)->float:
	var t:Vector3=l[(i+6)%l.size()]-l[(i-6+l.size())%l.size()]
	return atan2(-t.x,-t.z)
