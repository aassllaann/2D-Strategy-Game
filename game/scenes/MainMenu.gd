extends Control

func _ready() -> void:
	var bg = ColorRect.new()
	bg.color = Color("#121212")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "I Ching Grand Strategy"
	title.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title)
	
	var btn_start = Button.new()
	btn_start.text = "Start Game"
	btn_start.pressed.connect(func():
		GameState.reset_game()
		get_tree().change_scene_to_file("res://scenes/HexagramConsult.tscn")
	)
	vbox.add_child(btn_start)
	
	var btn_settings = Button.new()
	btn_settings.text = "Settings"
	btn_settings.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/Settings.tscn")
	)
	vbox.add_child(btn_settings)
