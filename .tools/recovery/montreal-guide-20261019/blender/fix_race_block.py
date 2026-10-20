from pathlib import Path
p=Path('scripts/race.gd')
s=p.read_text()
start=s.index('\tvar collision_count := 0', s.index('func _build_world'))
end=s.index('\t_hundir_relieve_de_calzada()', start)
new='''\tvar collision_count := 0
\tvar surface_mesh_count := 0
\tvar walls_enabled := 0
\tvar montreal_labels := {
\t\t"Asphalt": "ROAD",
\t\t"Grass": "GRASS",
\t\t"Runoff": "SAND",
\t\t"Kerbs": "KERB",
\t\t"Barriers": "WALL",
\t\t"Fences": "WALL",
\t\t"PitBuildings": "PITS",
\t}
\tfor node in track_mesh.find_children("*", "StaticBody3D", true, false):
\t\tvar body := node as StaticBody3D
\t\tvar extras: Dictionary = body.get_meta("extras", {})
\t\tif extras.get("kn5_source_obj", "") == "4.obj":
\t\t\tbody.collision_layer = 0
\t\t\tcontinue
\t\tbody.collision_layer = 1
\t\tbody.collision_mask = 0
\t\tvar source_nodes := String(extras.get("ac_source_nodes", body.name))
\t\tvar surface_label := TrackScript.get_surface_for_node(source_nodes)
\t\tvar imported_montreal_surface := TrackScript.get_selected_track_id() == TrackScript.MONTREAL and montreal_labels.has(body.name)
\t\tif TrackScript.get_selected_track_id() == TrackScript.MONTREAL and body.name in ["Buildings", "PitBuildings"]:
\t\t\tbody.collision_layer = 0
\t\t\tcontinue
\t\tif imported_montreal_surface:
\t\t\tsurface_label = String(montreal_labels[body.name])
\t\tvar imported_suzuka_surface := TrackScript.get_selected_track_id() == TrackScript.SUZUKA and body.name in [
\t\t\t"1ROAD", "1PITLANE", "1KERB", "1GRASS", "1GREEN", "1SAND", "1TURF", "1CUT", "1CARPET", "1WALL"
\t\t]
\t\tif not TrackScript.is_physics_node(source_nodes) and not imported_suzuka_surface and not imported_montreal_surface:
\t\t\tbody.collision_layer = 0
\t\t\tcontinue
\t\tvar is_wall_surface := (imported_montreal_surface and body.name in ["Barriers", "Fences"]) or bool(body.get_meta("ac_wall", false)) or TrackScript.is_wall_node(source_nodes) or TrackScript.is_wall_node(body.name)
\t\tif is_wall_surface:
\t\t\tbody.collision_layer = 2
\t\t\twalls_enabled += 1
\t\tbody.set_meta("ac_surface", surface_label)
\t\tbody.set_meta("ac_source", extras.get("kn5_source_obj", ""))
\t\tvar relieve := _relief_group_of(String(extras.get("ac_source_nodes", "")) + " " + String(body.name))
\t\tbody.set_meta("ac_relief", relieve)
\t\tif relieve != "":
\t\t\trelief_bodies.append(body)
\t\tcollision_count += 1
\tvar meshes := track_mesh.find_children("*", "MeshInstance3D", true, false)
\tvar montreal_visual_batches := ["Asphalt-visual", "Grass-visual", "Runoff-visual", "Kerbs-visual", "Barriers-visual", "Fences-visual", "PitBuildings-visual"]
\tfor node in meshes:
\t\tvar mesh := node as MeshInstance3D
\t\tif TrackScript.get_selected_track_id() == TrackScript.MONTREAL and montreal_visual_batches.has(String(mesh.name)):
\t\t\tcontinue
\t\tvar physics: bool = bool(mesh.get_meta("ac_physics", false)) or String(mesh.name).ends_with("-colonly")
\t\tvar source_nodes := String(mesh.get_meta("ac_source_nodes", mesh.name))
\t\tif not physics:
\t\t\tphysics = TrackScript.is_physics_node(mesh.name) or TrackScript.is_physics_node(source_nodes)
\t\tif physics:
\t\t\tmesh.visible = false
\t\t\tvar mapped_surface := TrackScript.get_surface_for_node(source_nodes)
\t\t\tif mapped_surface.is_empty() and TrackScript.get_selected_track_id() == TrackScript.MONTREAL:
\t\t\t\tmapped_surface = TrackScript.classify_surface(mesh.name)
\t\t\tsurface_mesh_count += 1 if not mapped_surface.is_empty() else 0
\t\t\tif String(mesh.get_meta("kn5_source_obj", "")) == "4.obj":
\t\t\t\tcontinue
\t\t\tvar body := StaticBody3D.new()
\t\t\tbody.name = "AC physics " + mesh.name
\t\t\tvar sources := String(mesh.get_meta("kn5_source_obj", ""))
\t\t\tbody.set_meta("ac_surface", mapped_surface)
\t\t\tbody.set_meta("ac_source", sources)
\t\t\tbody.set_meta("ac_source_nodes", source_nodes)
\t\t\tbody.set_meta("ac_wall", TrackScript.is_wall_node(mesh.name) or TrackScript.is_wall_node(source_nodes))
\t\t\tbody.collision_layer = 1
\t\t\tbody.collision_mask = 0
\t\t\tmesh.add_child(body)
\t\t\tvar shape := CollisionShape3D.new()
\t\t\tshape.shape = mesh.mesh.create_trimesh_shape()
\t\t\tbody.add_child(shape)
\t\t\tcollision_count += 1
\t\telse:
\t\t\tfor i in mesh.mesh.get_surface_count():
\t\t\t\tvar mat := mesh.mesh.surface_get_material(i) as StandardMaterial3D
\t\t\t\tif mat != null:
\t\t\t\t\tmat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
\t\t\t\t\tvar material_extras: Dictionary = mat.get_meta("extras", {})
\t\t\t\t\tvar metadata: Dictionary = JSON.parse_string(String(material_extras.get("ac_material", "{}")))
\t\t\t\t\tif metadata.get("alpha_tested", false) or metadata.get("alpha_blend", false) or "Alpha" in String(metadata.get("shader", "")):
\t\t\t\t\t\tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
\t\t\t\t\t\tmat.alpha_scissor_threshold = 0.35
\t\t\t\t\tif _es_goma_de_trazada(mat) and not goma_sin_corregir:
\t\t\t\t\t\t_neutralizar_goma(mesh, i, mat)
'''
p.write_text(s[:start]+new+s[end:])
print('replaced region lines', s[:start].count('\n')+1, 'to', s[:end].count('\n')+1)
