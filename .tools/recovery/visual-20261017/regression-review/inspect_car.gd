extends SceneTree
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 print("INSPECT START")
 var root_node: Node3D = (load("res://assets/RedBull.tscn") as PackedScene).instantiate()
 root.add_child(root_node)
 _walk(root_node, "")
 quit()
func _walk(node: Node, prefix: String) -> void:
 var p := prefix + "/" + String(node.name)
 print("NODE ",p," ",node.get_class())
 if node is MeshInstance3D:
  var m := node as MeshInstance3D
  print("MESH ",p," count=",m.mesh.get_surface_count() if m.mesh else -1)
  if m.mesh:
   for i in m.mesh.get_surface_count():
    var mat := m.get_active_material(i)
    print("  SURFACE ",i," mat=",mat.resource_name if mat else "null"," type=",mat.get_class() if mat else "null")
    if mat is StandardMaterial3D:
     var s := mat as StandardMaterial3D
     print("    color=",s.albedo_color," tex=",s.albedo_texture," metal=",s.metallic," rough=",s.roughness)
 for child in node.get_children():
  _walk(child,p)
