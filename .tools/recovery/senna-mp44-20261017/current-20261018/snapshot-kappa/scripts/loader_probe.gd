extends SceneTree
func _initialize():
 print("GLTFDocument class ", ClassDB.class_exists("GLTFDocument"))
 print("GLTFState class ", ClassDB.class_exists("GLTFState"))
 var doc = GLTFDocument.new()
 var state = GLTFState.new()
 print("append_from_file ", doc.append_from_file("res://assets/RedBull.glb", state))
 print("generate_scene ", doc.generate_scene(state))
 quit()
