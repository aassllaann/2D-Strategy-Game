extends Control


func _ready() -> void:
	AppSettings.load_all()

	var root := ScrollContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	## ── AI 服务商选择 ──
	var provider_row := HBoxContainer.new()
	provider_row.add_theme_constant_override("separation", 8)
	var provider_lbl := Label.new()
	provider_lbl.text = "AI 服务商"
	provider_lbl.custom_minimum_size.x = 160
	provider_row.add_child(provider_lbl)
	var provider_opt := OptionButton.new()
	provider_opt.add_item("DeepSeek（国内可用）", AIManager.Provider.DEEPSEEK)
	provider_opt.add_item("Gemini（免费·需翻墙）", AIManager.Provider.GEMINI)
	provider_opt.add_item("Claude", AIManager.Provider.CLAUDE)
	# OptionButton.selected 是索引，需要按 id 查找
	for i in provider_opt.item_count:
		if provider_opt.get_item_id(i) == AIManager.provider:
			provider_opt.selected = i
			break
	provider_opt.custom_minimum_size.x = 200
	provider_row.add_child(provider_opt)
	vbox.add_child(provider_row)

	## ── Gemini API Key ──
	var gemini_row := HBoxContainer.new()
	gemini_row.add_theme_constant_override("separation", 8)
	var gemini_lbl := Label.new()
	gemini_lbl.text = "Gemini API Key"
	gemini_lbl.custom_minimum_size.x = 160
	gemini_row.add_child(gemini_lbl)
	var gemini_edit := LineEdit.new()
	gemini_edit.custom_minimum_size.x = 360
	gemini_edit.text = AIManager.gemini_key
	gemini_edit.secret = true
	gemini_edit.placeholder_text = "从 aistudio.google.com 获取"
	gemini_row.add_child(gemini_edit)
	vbox.add_child(gemini_row)

	## ── DeepSeek API Key ──
	var deepseek_row := HBoxContainer.new()
	deepseek_row.add_theme_constant_override("separation", 8)
	var deepseek_lbl := Label.new()
	deepseek_lbl.text = "DeepSeek API Key"
	deepseek_lbl.custom_minimum_size.x = 160
	deepseek_row.add_child(deepseek_lbl)
	var deepseek_edit := LineEdit.new()
	deepseek_edit.custom_minimum_size.x = 360
	deepseek_edit.text = AIManager.deepseek_key
	deepseek_edit.secret = true
	deepseek_edit.placeholder_text = "从 platform.deepseek.com 获取"
	deepseek_row.add_child(deepseek_edit)
	vbox.add_child(deepseek_row)

	## ── Claude API Key ──
	var claude_row := HBoxContainer.new()
	claude_row.add_theme_constant_override("separation", 8)
	var claude_lbl := Label.new()
	claude_lbl.text = "Claude API Key"
	claude_lbl.custom_minimum_size.x = 160
	claude_row.add_child(claude_lbl)
	var claude_edit := LineEdit.new()
	claude_edit.custom_minimum_size.x = 360
	claude_edit.text = AIManager.claude_key
	claude_edit.secret = true
	claude_edit.placeholder_text = "从 console.anthropic.com 获取"
	claude_row.add_child(claude_edit)
	vbox.add_child(claude_row)

	## ── 动画快速模式 ──
	var anim_chk := CheckButton.new()
	anim_chk.text = "动画快速模式（总时长约 50%）"
	anim_chk.button_pressed = AppSettings.animation_fast
	vbox.add_child(anim_chk)

	## ── 文字速度 ──
	var text_row := HBoxContainer.new()
	var ts_lbl := Label.new()
	ts_lbl.text = "文字速度 (1-5)"
	ts_lbl.custom_minimum_size.x = 160
	text_row.add_child(ts_lbl)
	var text_slider := HSlider.new()
	text_slider.min_value = 1
	text_slider.max_value = 5
	text_slider.step = 1
	text_slider.value = AppSettings.text_speed
	text_slider.custom_minimum_size.x = 280
	text_row.add_child(text_slider)
	var ts_val := Label.new()
	ts_val.text = str(int(text_slider.value))
	text_slider.value_changed.connect(func(v: float) -> void:
		ts_val.text = str(int(v))
	)
	text_row.add_child(ts_val)
	vbox.add_child(text_row)

	## ── 音量 ──
	var bgm_row := HBoxContainer.new()
	var bgm_lbl := Label.new()
	bgm_lbl.text = "背景音乐"
	bgm_lbl.custom_minimum_size.x = 160
	bgm_row.add_child(bgm_lbl)
	var bgm_slider := HSlider.new()
	bgm_slider.min_value = 0
	bgm_slider.max_value = 100
	bgm_slider.value = AppSettings.bgm_volume
	bgm_slider.custom_minimum_size.x = 280
	bgm_row.add_child(bgm_slider)
	vbox.add_child(bgm_row)

	var sfx_row := HBoxContainer.new()
	var sfx_lbl := Label.new()
	sfx_lbl.text = "音效"
	sfx_lbl.custom_minimum_size.x = 160
	sfx_row.add_child(sfx_lbl)
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.value = AppSettings.sfx_volume
	sfx_slider.custom_minimum_size.x = 280
	sfx_row.add_child(sfx_slider)
	vbox.add_child(sfx_row)

	## ── 全屏 ──
	var fs_chk := CheckButton.new()
	fs_chk.text = "全屏"
	fs_chk.button_pressed = AppSettings.fullscreen
	vbox.add_child(fs_chk)

	## ── 按钮 ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)

	var btn_save := Button.new()
	btn_save.text = "保存并返回"
	btn_save.pressed.connect(func() -> void:
		var sel_provider: int = provider_opt.get_selected_id()
		AIManager.save_settings(
			sel_provider,
			gemini_edit.text.strip_edges(),
			claude_edit.text.strip_edges(),
			deepseek_edit.text.strip_edges()
		)
		AppSettings.save_from_controls(
			anim_chk.button_pressed,
			int(text_slider.value),
			int(bgm_slider.value),
			int(sfx_slider.value),
			fs_chk.button_pressed
		)
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	btn_row.add_child(btn_save)

	var btn_back := Button.new()
	btn_back.text = "返回（不保存）"
	btn_back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	btn_row.add_child(btn_back)
	vbox.add_child(btn_row)
