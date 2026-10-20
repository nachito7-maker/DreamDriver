extends SceneTree

const OUTPUT := "res://.tools/recovery/cockpit-black-20261018"
const LEGACY_RACE := "res://.tools/recovery/visual-20261017/helmet-iteration/race-before-helmet-component.gd"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var legacy_script := load(LEGACY_RACE) as Script
	if legacy_script == null:
		push_error("No se pudo cargar la escena de carrera legado del Red Bull")
		quit(2)
		return
	var race := Node3D.new()
	race.set_script(legacy_script)
	root.add_child(race)
	for i in 300:
		await physics_frame
	var nose: Camera3D = race.find_child("Nose camera", true, false) as Camera3D
	var suspect: MeshInstance3D = race.find_child("Halo front crossbar", true, false) as MeshInstance3D
	print("REDBULL_SCENE=", LEGACY_RACE)
	print("REDBULL_NODES=", race.get_child_count(), " NOSE_CAMERA=", nose != null)
	if suspect == null or nose == null:
		push_error("El artefacto Red Bull legado no contiene la cámara o barra esperada")
		quit(3)
		return
	print("REDBULL_SUSPECT=", suspect.get_path(), " mesh=", suspect.mesh.get_class(), " size=", (suspect.mesh as BoxMesh).size,
		" pos=", suspect.position, " layer=", suspect.layers)
	race.set_camera_mode(1)
	for i in 45:
		await process_frame
	var before := root.get_texture().get_image()
	print("REDBULL_BEFORE_SAVE=", before.save_png(OUTPUT + "/before/redbull-morro-mismo-plano.png"))
	suspect.visible = false
	for i in 4:
		await process_frame
	RenderingServer.force_draw(true)
	var after := root.get_texture().get_image()
	print("REDBULL_AFTER_SAVE=", after.save_png(OUTPUT + "/after/redbull-morro-sin-barra.png"))
	print("REDBULL_BAR_REMOVED=", not suspect.visible, " nose_camera_unchanged=", nose.current)
	race.set_camera_mode(0)
	for i in 45:
		await process_frame
	var chase := root.get_texture().get_image()
	print("REDBULL_EXTERIOR_SAVE=", chase.save_png(OUTPUT + "/after/redbull-exterior-sin-barra.png"))
	quit()
