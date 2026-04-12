extends Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#121212")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	var title := Label.new()
	title.text = "易经大战略：执理者"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)

	var btn_continue := Button.new()
	btn_continue.text = "继续游戏"
	btn_continue.visible = SaveManager.has_autosave()
	btn_continue.pressed.connect(func () -> void:
		if SaveManager.load_autosave():
			get_tree().change_scene_to_file("res://scenes/HexagramConsult.tscn")
	)
	vbox.add_child(btn_continue)

	var btn_start := Button.new()
	btn_start.text = "新游戏"
	btn_start.pressed.connect(func () -> void:
		SaveManager.delete_autosave()
		GameState.start_new_run()
		get_tree().change_scene_to_file("res://scenes/Intro.tscn")
	)
	vbox.add_child(btn_start)

	var btn_settings := Button.new()
	btn_settings.text = "设置"
	btn_settings.pressed.connect(func () -> void:
		get_tree().change_scene_to_file("res://scenes/Settings.tscn")
	)
	vbox.add_child(btn_settings)
