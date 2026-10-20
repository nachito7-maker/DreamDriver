extends SceneTree
const TD = preload("res://scripts/track_data.gd")
const START_INDEX := 1300
const END_INDEX := 1540
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	TD.reset_selection(); TD.select_track(TD.SUZUKA)
	var race := (load("res://scenes/race.tscn") as PackedScene).instantiate(); root.add_child(race)
	Engine.max_fps = 0
	var car: CharacterBody3D = race.car
	car.set_physics_process(false); car.set_process(false); car.collision_mask = 0; car.collision_layer = 0
	if race.assistance_line != null: race.assistance_line.set_process(false)
	if race.hud != null: race.hud.set_process(false)
	if race.controls != null: race.controls.set_process(false)
	for i in 120: await physics_frame
	race.set_physics_process(false); race.set_process(false)
	for node in race.track_mesh.find_children("*", "StaticBody3D", true, false):
		var body := node as StaticBody3D
		if body.name == "1ROAD": body.collision_layer = 1; body.collision_mask = 0
	var line := TD.get_centerline()
	car.recover_to(line[START_INDEX], _yaw_at(line, START_INDEX)); car.collision_mask = 0; car.collision_layer = 0
	car.set_physics_process(true); car.set_meta("touch_throttle", 0.55); car.set_meta("touch_brake", 0.0); car.set_meta("touch_steer", 0.0)
	for i in 90: await physics_frame
	var contact_loss_ticks := 0
	var recontact_events := 0
	var prior_contacts: int = car.wheel_contacts
	var max_vy := 0.0
	var max_step := 0.0
	var previous_height: float = car.suspension.height
	var last_index := START_INDEX
	var max_error := 0.0
	for tick in 4200:
		await physics_frame
		var nearest := _nearest(line, car.global_position, START_INDEX, END_INDEX)
		var err := Vector2(car.global_position.x-line[nearest].x,car.global_position.z-line[nearest].z).length()
		max_error=maxf(max_error,err)
		var contacts: int = car.wheel_contacts
		if contacts == 0: contact_loss_ticks += 1
		if prior_contacts == 0 and contacts > 0: recontact_events += 1
		prior_contacts=contacts
		max_vy=maxf(max_vy,absf(car.velocity.y))
		max_step=maxf(max_step,absf(car.suspension.height-previous_height)); previous_height=car.suspension.height
		var target := mini(nearest+20,END_INDEX)
		var local := car.to_local(line[target])
		var lookahead := maxf(14.0, car.speed_mps*1.1)
		var angle := atan2(2.0*car.wheelbase_m*sin(atan2(local.x,-local.z)),lookahead)
		car.set_meta("touch_steer",clampf(angle/maxf(car.debug_max_steer,0.1),-1.0,1.0)*0.45)
		var v_error: float = 25.0-car.speed_mps
		car.set_meta("touch_throttle",clampf(0.52+v_error*0.025,0.2,0.75))
		car.set_meta("touch_brake",clampf(-v_error*0.04,0.0,0.3))
		if contacts != prior_contacts or nearest > last_index+2 or tick%300==0:
			print("SEG tick=%d idx=%d contacts=%d prev=%d err=%.2f y=%.2f vy=%.2f h=%.3f step=%.3f seated=%s slopes=(%.3f,%.3f)" % [tick,nearest,contacts,prior_contacts,err,car.global_position.y,car.velocity.y,car.suspension.height,absf(car.suspension.height-previous_height),str(car.suspension.seated),car.suspension.road_slope_x,car.suspension.road_slope_z])
		last_index=nearest
		if nearest>=END_INDEX or err>12.0 or car.global_position.y < -60.0: break
	print("SEGMENT result idx=%d contact_loss=%d recontacts=%d maxvy=%.2f maxstep=%.3f maxerr=%.2f"%[_nearest(line,car.global_position,START_INDEX,END_INDEX),contact_loss_ticks,recontact_events,max_vy,max_step,max_error])
	race.queue_free(); await process_frame; quit()
func _nearest(line: PackedVector3Array, p: Vector3, a: int, b: int) -> int:
	var best:=a; var d_best:=INF
	for i in range(a,b+1):
		var d:=Vector2(line[i].x-p.x,line[i].z-p.z).length_squared()
		if d<d_best: d_best=d; best=i
	return best
func _yaw_at(line: PackedVector3Array, i: int) -> float:
	var t: Vector3=line[(i+6)%line.size()]-line[(i-6+line.size())%line.size()]
	return atan2(-t.x,-t.z)
