extends Control

## C3：主菜单 — 继续游戏读 autosave，读取手动存档读 manual.json
## 损坏存档弹对话框，不崩溃

var _btn_continue:    Button
var _btn_load_manual: Button


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

	# ── 继续游戏（autosave）──
	_btn_continue = Button.new()
	_btn_continue.text = "继续游戏"
	_btn_continue.visible = SaveManager.has_autosave()
	_btn_continue.pressed.connect(_on_continue_pressed)
	vbox.add_child(_btn_continue)

	# ── 读取手动存档（manual.json）──
	_btn_load_manual = Button.new()
	_btn_load_manual.text = "读取手动存档"
	_btn_load_manual.visible = SaveManager.has_manual()
	_btn_load_manual.pressed.connect(_on_load_manual_pressed)
	vbox.add_child(_btn_load_manual)

	# ── 新游戏 ──
	var btn_start := Button.new()
	btn_start.text = "新游戏"
	btn_start.pressed.connect(func() -> void:
		SaveManager.delete_autosave()
		GameState.start_new_run()
		get_tree().change_scene_to_file("res://scenes/Intro.tscn")
	)
	vbox.add_child(btn_start)

	# ── 设置 ──
	var btn_settings := Button.new()
	btn_settings.text = "设置"
	btn_settings.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/Settings.tscn")
	)
	vbox.add_child(btn_settings)


func _on_continue_pressed() -> void:
	if SaveManager.load_autosave():
		get_tree().change_scene_to_file("res://scenes/HexagramConsult.tscn")
	else:
		_show_corrupt_dialog("autosave")


func _on_load_manual_pressed() -> void:
	if SaveManager.load_manual():
		get_tree().change_scene_to_file("res://scenes/HexagramConsult.tscn")
	else:
		_show_corrupt_dialog("manual")


## 损坏存档对话框：提示玩家删除或取消
func _show_corrupt_dialog(slot: String) -> void:
	var slot_label := "自动存档" if slot == "autosave" else "手动存档"
	var dlg := ConfirmationDialog.new()
	dlg.title = "存档异常"
	dlg.dialog_text = "「%s」已损坏，无法读取。\n是否删除该存档？" % slot_label
	dlg.ok_button_text     = "删除存档"
	dlg.cancel_button_text = "取消"
	dlg.confirmed.connect(func() -> void:
		if slot == "autosave":
			SaveManager.delete_autosave()
			_btn_continue.visible = false
		else:
			SaveManager.delete_manual()
			_btn_load_manual.visible = false
		dlg.queue_free()
	)
	dlg.canceled.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered()
