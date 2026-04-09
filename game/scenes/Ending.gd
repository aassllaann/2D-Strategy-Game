extends Control

func _ready() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "Game Over"
	title.add_theme_font_size_override("font_size", 64)
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "The cycle concludes."
	vbox.add_child(desc)
	
	var btn = Button.new()
	btn.text = "Return to Title"
	btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	vbox.add_child(btn)
