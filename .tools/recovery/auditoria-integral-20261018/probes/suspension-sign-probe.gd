extends SceneTree

const SuspensionScript = preload("res://scripts/wheel_suspension.gd")

func _initialize() -> void:
	var suspension = SuspensionScript.new()
	var corners := PackedVector3Array([
		Vector3(-0.93, 0.0, -1.51), Vector3(0.93, 0.0, -1.51),
		Vector3(-0.88, 0.0, 1.95), Vector3(0.88, 0.0, 1.95),
	])
	var front := PackedInt32Array([1, 1, 0, 0])
	var heights := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	var grounded := PackedInt32Array([1, 1, 1, 1])
	suspension.configure(corners, front)
	for i in 120:
		suspension.step(1.0 / 60.0, heights, grounded, 0.0, 4.0)
	var lateral_mm := PackedFloat32Array()
	for offset in suspension.offset:
		lateral_mm.append(offset * 1000.0)
	print("UNIT lateral +4 m/s2; x=- left, x=+ right; offsets_mm=%s loads_N=%s roll_deg=%.4f" % [
		str(lateral_mm), str(suspension.load), rad_to_deg(suspension.roll_relative)])
	for i in 120:
		suspension.step(1.0 / 60.0, heights, grounded, 4.0, 0.0)
	var longitudinal_mm := PackedFloat32Array()
	for offset in suspension.offset:
		longitudinal_mm.append(offset * 1000.0)
	print("UNIT longitudinal +4 m/s2; z=- front, z=+ rear; offsets_mm=%s pitch_deg=%.4f" % [
		str(longitudinal_mm), rad_to_deg(suspension.pitch_relative)])
	quit()
