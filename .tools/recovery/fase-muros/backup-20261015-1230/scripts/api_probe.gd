extends SceneTree
func _initialize():
 print("LANDSCAPE", DisplayServer.SCREEN_LANDSCAPE, "portrait", DisplayServer.SCREEN_PORTRAIT, "flipped", DisplayServer.SCREEN_REVERSE_LANDSCAPE)
 print("project setting orient:", ProjectSettings.get_setting("display/window/handheld/orientation"))
 print("orient project", ProjectSettings.get_setting("display/window/handheld/orientation"))
 quit()
