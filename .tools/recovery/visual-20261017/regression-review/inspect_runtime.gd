extends SceneTree
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var race: Node = (load("res://scenes/race.tscn") as PackedScene).instantiate()
 root.add_child(race)
 for i in 10:
  await physics_frame
 _walk(race, "")
 quit()
func _walk(node: Node, prefix: String) -> void:
 var p := prefix + "/" + String(node.name)
 if node is Label3D:
  print("LABEL ",p," text=",(node as Label3D).text)
 if node is MeshInstance3D:
  var m := node as MeshInstance3D
  print("MESH ",p," count=",m.mesh.get_surface_count()," aabb=",m.get_aabb())
  for i in m.mesh.get_surface_count():
   var mat := m.get_active_material(i)
   if mat is StandardMaterial3D:
    var s := mat as StandardMaterial3D
    print(" MAT ",i," col=",s.albedo_color," tex=",s.albedo_texture," metal=",s.metallic," rough=",s.roughness," spec=",s.specular_mode)
 for child in node.get_children():
  _walk(child,p)
