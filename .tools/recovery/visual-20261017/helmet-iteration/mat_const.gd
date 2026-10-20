extends SceneTree
func _initialize():
 for p in ClassDB.class_get_enum_list("BaseMaterial3D"):
  print(p, " ", ClassDB.class_get_enum_constants("BaseMaterial3D", p))
 quit()
