extends Node3D

@export_file("*.glb", "*.gltf") var source_path := ""
var loaded_scene: Node3D

func _ready() -> void:
	if source_path.is_empty():
		return
	var packed := load(source_path) as PackedScene
	if packed == null:
		push_error("Could not load imported glTF scene: " + source_path)
		return
	loaded_scene = packed.instantiate() as Node3D
	loaded_scene.name = "Imported glTF model"
	add_child(loaded_scene)
