extends Control

func _ready() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "Settings"
	vbox.add_child(title)
	
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	var label = Label.new()
	label.text = "Claude API Key:"
	hbox.add_child(label)
	
	var line_edit = LineEdit.new()
	line_edit.custom_minimum_size.x = 300
	line_edit.text = AIManager.api_key
	line_edit.secret = true
	hbox.add_child(line_edit)
	
	var btn_save = Button.new()
	btn_save.text = "Save & Return"
	btn_save.pressed.connect(func():
		AIManager.api_key = line_edit.text.strip_edges()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	vbox.add_child(btn_save)
