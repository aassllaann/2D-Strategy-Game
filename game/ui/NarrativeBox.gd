extends Control

var _scroll: ScrollContainer
var _story_label: RichTextLabel
var _analysis_box: VBoxContainer
var _analysis_label: RichTextLabel


func _ready() -> void:
	for child in get_children():
		child.queue_free()

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(_scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 0)
	_scroll.add_child(vbox)

	# 叙事文本
	_story_label = RichTextLabel.new()
	_story_label.bbcode_enabled = true
	_story_label.fit_content = true
	_story_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_story_label.add_theme_font_size_override("normal_font_size", 16)
	_story_label.add_theme_color_override("default_color", Color("#e8d5a3"))
	vbox.add_child(_story_label)

	# 推演解析区（分隔线 + 标题 + 内容）
	_analysis_box = VBoxContainer.new()
	_analysis_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_analysis_box.add_theme_constant_override("separation", 4)
	_analysis_box.hide()
	vbox.add_child(_analysis_box)

	var sep_label := RichTextLabel.new()
	sep_label.bbcode_enabled = true
	sep_label.fit_content = true
	sep_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep_label.text = "\n[color=#555555]───────────────[/color]"
	_analysis_box.add_child(sep_label)

	var title_label := RichTextLabel.new()
	title_label.bbcode_enabled = true
	title_label.fit_content = true
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.text = "[color=#e8d5a3][b]推演解析[/b][/color]\n"
	_analysis_box.add_child(title_label)

	_analysis_label = RichTextLabel.new()
	_analysis_label.bbcode_enabled = true
	_analysis_label.fit_content = true
	_analysis_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_analysis_box.add_child(_analysis_label)


func show_narrative(text: String, philosophy: String = "", analysis: String = "") -> void:
	# 隐藏并清空上次的分析区
	_analysis_box.hide()
	_analysis_label.text = ""

	# 组装叙事文本
	var story_text := text
	if philosophy != "":
		story_text += "\n\n[i][color=#cccccc]" + philosophy + "[/color][/i]"

	_story_label.text = story_text
	_scroll.scroll_vertical = 0

	# 推演解析区（分析内容直接显示，无动画）
	if analysis.strip_edges() != "":
		var formatted := analysis.strip_edges()
		formatted = formatted.replace("【情境背景】", "[color=#a8d8a8][b]【情境背景】[/b][/color]")
		formatted = formatted.replace("【选择后果】", "[color=#f4a261][b]【选择后果】[/b][/color]")
		formatted = formatted.replace("【因果推演】", "[color=#e76f51][b]【因果推演】[/b][/color]")
		formatted = formatted.replace("【卦爻解析】", "[color=#9bb1d4][b]【卦爻解析】[/b][/color]")
		formatted = formatted.replace("【卦象演变】", "[color=#d4a8d4][b]【卦象演变】[/b][/color]")
		_analysis_label.text = formatted
		_analysis_box.show()
	else:
		_analysis_box.hide()
