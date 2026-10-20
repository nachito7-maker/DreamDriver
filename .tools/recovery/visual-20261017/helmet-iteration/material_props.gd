extends SceneTree
func _initialize():
 var m=StandardMaterial3D.new()
 for p in m.get_property_list():
  if String(p.name).contains("depth") or String(p.name).contains("render_priority"):
   print(p.name, "=", m.get(p.name))
 quit()
