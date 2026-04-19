extends Control

# ══════════════════════════════════════════════════════════════
# 页面流程：情境页→卦象页→决策页→[AI]→选择后果页→因果推演页→(循环)
# ══════════════════════════════════════════════════════════════

enum _Page { NONE, SITUATION, HEXAGRAM, DECISION, CONSEQUENCE, CAUSAL }

# ── 主布局列（需要按页面显示/隐藏）──
var _left_col:  VBoxContainer
var _right_col: VBoxContainer

# ── 主布局中的核心 UI ──
var stats_hud:        Control
var hexagram_display: Control
var action_panel:     Control
var narrative_box:    Control
var continue_btn:     Button

var _yao_analysis_panel: PanelContainer
var _yao_analysis_label: RichTextLabel

# ── 覆盖层（CanvasLayer 15，用于全屏居中页面）──
var _page_layer: CanvasLayer
var _page_nodes: Array = []

# ── AI 蒙层（CanvasLayer 20）──
var _ai_overlay:     CanvasLayer
var _tutorial_layer: CanvasLayer

# ── 状态 ──
var _cur_page:  int = _Page.NONE
var _turn_controller: TurnController
var _last_category: String = ""
var _last_action:   String = ""

# ── AI 内容缓存 ──
var _cached_situation:   String = ""
var _cached_yao_section: String = ""
var _consequence_text:   String = ""
var _causal_text:        String = ""
var _cause_effect_text:  String = ""
var _hex_evolution_text: String = ""

# ── 卦象演变待处理数据（在因果推演页动画时使用）──
var _pending_old_hex:    int = -1
var _pending_new_hex:    int = -1
var _pending_yao_changed: int = 1

# ── 教程 ──
var _tutorial_dismissed_round: int = -1
var _tutorial_nodes: Array = []

# ── 决策页：安全港（action_panel 不在覆盖层时存放于此）──
var _action_safe_harbor: Control


# ════════════════════════════════════════════════════════════════
# _ready
# ════════════════════════════════════════════════════════════════
func _ready() -> void:
	# ── 背景 ──
	var bg := ColorRect.new()
	bg.color = Color("#1a1008")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── 页面覆盖层（CanvasLayer 15）──
	_page_layer = CanvasLayer.new()
	_page_layer.layer = 15
	add_child(_page_layer)

	# ── AI 蒙层（CanvasLayer 20）──
	_ai_overlay = CanvasLayer.new()
	_ai_overlay.layer = 20
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.visible = false
	shade.name = "Shade"
	_ai_overlay.add_child(shade)
	var ai_lbl := Label.new()
	ai_lbl.name = "AiLabel"
	ai_lbl.text = "国师沉思中……"
	ai_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ai_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	ai_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ai_lbl.add_theme_font_size_override("font_size", 28)
	ai_lbl.visible = false
	_ai_overlay.add_child(ai_lbl)
	add_child(_ai_overlay)

	# ── 教程气泡层（CanvasLayer 30）──
	_tutorial_layer = CanvasLayer.new()
	_tutorial_layer.layer = 30
	add_child(_tutorial_layer)

	# ════════════════════════════════════════════
	# 主布局：VBox（顶部栏 + 三列内容）
	# ════════════════════════════════════════════
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	main_vbox.add_child(_build_top_bar())

	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_bottom",  8)
	main_vbox.add_child(margin)

	var root_cols := HBoxContainer.new()
	root_cols.add_theme_constant_override("separation", 8)
	margin.add_child(root_cols)

	# ── 左列（340px）──
	_left_col = VBoxContainer.new()
	_left_col.custom_minimum_size.x = 340
	_left_col.size_flags_horizontal = Control.SIZE_FILL
	_left_col.add_theme_constant_override("separation", 6)
	root_cols.add_child(_left_col)

	# ── 中列（弹性）──
	var center_col := VBoxContainer.new()
	center_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_col.add_theme_constant_override("separation", 8)
	root_cols.add_child(center_col)

	# ── 右列（280px）──
	_right_col = VBoxContainer.new()
	_right_col.custom_minimum_size.x = 280
	_right_col.size_flags_horizontal = Control.SIZE_FILL
	root_cols.add_child(_right_col)

	# ── 左列内容：卦象 + 卦爻解析 ──
	hexagram_display = preload("res://ui/HexagramDisplay.tscn").instantiate()
	hexagram_display.custom_minimum_size = Vector2(320, 280)
	_left_col.add_child(hexagram_display)

	var yao_title := Label.new()
	yao_title.text = "卦爻解析"
	yao_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yao_title.add_theme_font_size_override("font_size", 14)
	yao_title.modulate = Color(0.85, 0.78, 0.55)
	_left_col.add_child(yao_title)

	_yao_analysis_panel = PanelContainer.new()
	_yao_analysis_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var yao_style := StyleBoxFlat.new()
	yao_style.bg_color = Color(0.08, 0.07, 0.05, 0.85)
	yao_style.set_border_width_all(1)
	yao_style.border_color = Color(0.4, 0.35, 0.25, 0.6)
	yao_style.content_margin_left   = 8
	yao_style.content_margin_right  = 8
	yao_style.content_margin_top    = 6
	yao_style.content_margin_bottom = 6
	_yao_analysis_panel.add_theme_stylebox_override("panel", yao_style)
	var yao_scroll := ScrollContainer.new()
	yao_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_yao_analysis_label = RichTextLabel.new()
	_yao_analysis_label.bbcode_enabled = true
	_yao_analysis_label.fit_content = true
	_yao_analysis_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_yao_analysis_label.add_theme_font_size_override("font_size", 13)
	_yao_analysis_label.modulate = Color(0.82, 0.76, 0.60)
	yao_scroll.add_child(_yao_analysis_label)
	_yao_analysis_panel.add_child(yao_scroll)
	_left_col.add_child(_yao_analysis_panel)

	# ── 中列内容：叙事 + 继续按钮 ──
	narrative_box = preload("res://ui/NarrativeBox.tscn").instantiate()
	narrative_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	narrative_box.custom_minimum_size = Vector2(400, 160)
	center_col.add_child(narrative_box)

	continue_btn = Button.new()
	continue_btn.custom_minimum_size = Vector2(0, 44)
	center_col.add_child(continue_btn)

	# action_panel 不放入 center_col；由决策页覆盖层动态载入
	_action_safe_harbor = Control.new()
	_action_safe_harbor.visible = false
	add_child(_action_safe_harbor)

	action_panel = preload("res://ui/ActionPanel.tscn").instantiate()
	_action_safe_harbor.add_child(action_panel)

	# ── 右列内容：三才 HUD ──
	stats_hud = preload("res://ui/StatsHUD.tscn").instantiate()
	stats_hud.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_col.add_child(stats_hud)

	# ── 信号连接 ──
	_turn_controller = TurnController.new()
	_turn_controller.phase_changed.connect(_on_phase_changed)
	action_panel.setup(_turn_controller)
	action_panel.strategy_chosen.connect(_on_strategy_chosen)

	AIManager.consult_completed.connect(_on_ai_completed)
	AIManager.consult_failed.connect(_on_consult_failed)
	AIManager.fallback_activated.connect(_on_fallback_activated)

	continue_btn.pressed.connect(_on_continue_pressed)
	continue_btn.hide()
	action_panel.hide()

	_turn_controller.start_selection()


# ════════════════════════════════════════════════════════════════
# 顶部栏
# ════════════════════════════════════════════════════════════════
func _build_top_bar() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 60)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0d0a06")
	style.border_width_bottom = 1
	style.border_color = Color(0.35, 0.30, 0.20, 0.8)
	style.content_margin_left  = 16
	style.content_margin_right = 16
	bar.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_spacer)

	var lbl := Label.new()
	lbl.text = "天命·乾坤"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.modulate = Color(0.92, 0.85, 0.62)
	hbox.add_child(lbl)

	var right_box := HBoxContainer.new()
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.alignment = BoxContainer.ALIGNMENT_END
	var save_btn := Button.new()
	save_btn.text = "手动存档"
	save_btn.custom_minimum_size = Vector2(96, 36)
	save_btn.pressed.connect(_on_manual_save_pressed)
	right_box.add_child(save_btn)
	hbox.add_child(right_box)

	bar.add_child(hbox)
	return bar


func _on_manual_save_pressed() -> void:
	SaveManager.write_manual()
	_show_save_toast()


func _show_save_toast() -> void:
	var lbl := Label.new()
	lbl.text = "手动存档成功"
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.modulate = Color(0.85, 0.78, 0.50)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lbl.position = Vector2(get_viewport_rect().size.x - 200, 18)
	_tutorial_layer.add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)


# ════════════════════════════════════════════════════════════════
# 页面覆盖层工具
# ════════════════════════════════════════════════════════════════
func _clear_page() -> void:
	# 决策页覆盖层被销毁前，先把 action_panel 救回安全港
	if is_instance_valid(action_panel) \
			and is_instance_valid(_action_safe_harbor) \
			and action_panel.get_parent() != _action_safe_harbor:
		action_panel.reparent(_action_safe_harbor)
		action_panel.hide()
	for n in _page_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_page_nodes.clear()


func _overlay_bg() -> ColorRect:
	var bg := ColorRect.new()
	bg.color = Color("#1a1008")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_layer.add_child(bg)
	_page_nodes.append(bg)
	return bg


func _card_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.10, 0.09, 0.06, 0.97)
	s.set_border_width_all(1)
	s.border_color = Color(0.55, 0.48, 0.32, 0.8)
	s.corner_radius_top_left     = 10
	s.corner_radius_top_right    = 10
	s.corner_radius_bottom_left  = 10
	s.corner_radius_bottom_right = 10
	s.content_margin_left   = 24
	s.content_margin_right  = 24
	s.content_margin_top    = 20
	s.content_margin_bottom = 20
	return s


# ── 居中容器（锚点全填，内部 VBox 居中）──
func _centered_vbox(min_w: float) -> VBoxContainer:
	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_layer.add_child(anchor)
	_page_nodes.append(anchor)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	vbox.custom_minimum_size.x = min_w
	anchor.add_child(vbox)
	return vbox


# ════════════════════════════════════════════════════════════════
# 页面 1：情境背景页（全屏居中叙事 + "卜卦"）
# ════════════════════════════════════════════════════════════════
func _show_situation_page() -> void:
	_cur_page = _Page.SITUATION
	_clear_page()
	_left_col.hide()
	_right_col.hide()

	_overlay_bg()
	var vbox := _centered_vbox(760.0)

	# 标题
	var title := Label.new()
	title.text = "▌情境背景"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.90, 0.85, 0.60)
	vbox.add_child(title)

	# 叙事文本
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.add_theme_font_size_override("normal_font_size", 17)
	rtl.add_theme_color_override("default_color", Color("#e8d5a3"))
	rtl.custom_minimum_size = Vector2(760, 0)

	if not _cached_situation.is_empty():
		rtl.text = _cached_situation
	else:
		var hex_data := DatabaseManager.get_hexagram(GameState.current_hexagram_id)
		rtl.text = _build_opening_narrative(hex_data)

	vbox.add_child(rtl)

	# 分隔线
	var sep := HSeparator.new()
	sep.modulate = Color(0.4, 0.35, 0.25, 0.5)
	vbox.add_child(sep)

	# "卜卦" 按钮
	var btn := Button.new()
	btn.text = "卜卦"
	btn.custom_minimum_size = Vector2(160, 48)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(btn)

	_page_nodes.append(vbox.get_parent())  # anchor 已在 _centered_vbox 内追踪

	_maybe_show_tutorial()


# ════════════════════════════════════════════════════════════════
# 页面 2：卦象页（居中卡牌：左卦象 + 右卦爻解析 + "进入决策"）
# ════════════════════════════════════════════════════════════════
func _show_hexagram_page() -> void:
	_cur_page = _Page.HEXAGRAM
	_clear_page()
	_left_col.hide()
	_right_col.hide()

	_overlay_bg()

	# 外层居中锚
	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_layer.add_child(anchor)
	_page_nodes.append(anchor)

	# 主 VBox（卡牌 + 按钮）
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 24)
	outer.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	outer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	outer.grow_vertical   = Control.GROW_DIRECTION_BOTH
	anchor.add_child(outer)

	# ── 卡牌（HBox：左卦象 | 右卦爻解析）──
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())
	outer.add_child(card)

	var card_hbox := HBoxContainer.new()
	card_hbox.add_theme_constant_override("separation", 24)
	card.add_child(card_hbox)

	# 左：卦象图
	var hex_disp := preload("res://ui/HexagramDisplay.tscn").instantiate()
	hex_disp.custom_minimum_size = Vector2(300, 320)
	card_hbox.add_child(hex_disp)

	# 右：卦爻解析文字（可滚动）
	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 8)
	right_vbox.custom_minimum_size = Vector2(380, 320)
	card_hbox.add_child(right_vbox)

	var hex_data := DatabaseManager.get_hexagram(GameState.current_hexagram_id)
	var name_zh: String = str(hex_data.get("name_zh", ""))
	var nature: String  = str(hex_data.get("nature", ""))

	var name_lbl := Label.new()
	name_lbl.text = "%s卦" % name_zh
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.modulate = Color(0.92, 0.85, 0.55)
	right_vbox.add_child(name_lbl)

	if not nature.is_empty():
		var nat_lbl := Label.new()
		nat_lbl.text = nature
		nat_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nat_lbl.add_theme_font_size_override("font_size", 14)
		nat_lbl.modulate = Color(0.80, 0.74, 0.55)
		right_vbox.add_child(nat_lbl)

	var sep_lbl := Label.new()
	sep_lbl.text = "── 爻辞 ──"
	sep_lbl.add_theme_font_size_override("font_size", 13)
	sep_lbl.modulate = Color(0.55, 0.50, 0.38)
	right_vbox.add_child(sep_lbl)

	var yao_scroll := ScrollContainer.new()
	yao_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	yao_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_vbox.add_child(yao_scroll)

	var yao_rtl := RichTextLabel.new()
	yao_rtl.bbcode_enabled = true
	yao_rtl.fit_content = true
	yao_rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yao_rtl.add_theme_font_size_override("normal_font_size", 13)
	yao_rtl.add_theme_color_override("default_color", Color("#d4c8a0"))
	yao_scroll.add_child(yao_rtl)

	# 填充卦爻内容（优先 AI 缓存，否则静态数据）
	if not _cached_yao_section.is_empty():
		yao_rtl.text = _cached_yao_section
	else:
		_fill_yao_rtl_static(yao_rtl, hex_data)

	# ── "进入决策" 按钮 ──
	var btn := Button.new()
	btn.text = "进入决策"
	btn.custom_minimum_size = Vector2(200, 48)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.pressed.connect(_on_continue_pressed)
	outer.add_child(btn)


# ════════════════════════════════════════════════════════════════
# 页面 3：决策页（主三列布局）
# ════════════════════════════════════════════════════════════════
func _show_decision_page() -> void:
	_cur_page = _Page.DECISION
	_clear_page()
	_left_col.show()
	_right_col.show()
	continue_btn.hide()

	# 刷新左列卦爻解析
	if not _cached_yao_section.is_empty():
		_show_yao_section(_cached_yao_section)
	else:
		_populate_yao_analysis_static()

	narrative_box.show_narrative("战机已明，运筹帷幄——\n请择策而动。")

	# ── 书卷浮于页面正中，其余板块布局不变 ──────────────────────
	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_layer.add_child(anchor)
	_page_nodes.append(anchor)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.add_child(center)

	action_panel.custom_minimum_size = Vector2(880, 400)
	action_panel.reparent(center)
	action_panel.show()
	action_panel.populate_actions()


# ════════════════════════════════════════════════════════════════
# 页面 4：选择后果页（全屏居中 + "原因"）
# ════════════════════════════════════════════════════════════════
func _show_consequence_page() -> void:
	_cur_page = _Page.CONSEQUENCE
	_clear_page()
	_left_col.hide()
	_right_col.hide()
	continue_btn.hide()

	_overlay_bg()
	var vbox := _centered_vbox(760.0)

	var title := Label.new()
	title.text = "▌选择后果"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.95, 0.82, 0.55)
	vbox.add_child(title)

	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.add_theme_font_size_override("normal_font_size", 17)
	rtl.add_theme_color_override("default_color", Color("#e8d5a3"))
	rtl.custom_minimum_size = Vector2(760, 0)
	rtl.text = _consequence_text
	vbox.add_child(rtl)

	var sep := HSeparator.new()
	sep.modulate = Color(0.4, 0.35, 0.25, 0.5)
	vbox.add_child(sep)

	var btn := Button.new()
	btn.text = "解读"
	btn.custom_minimum_size = Vector2(160, 48)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(btn)


# ════════════════════════════════════════════════════════════════
# 页面 5：因果推演页（主布局：左卦象动画 + 中推演文本）
# ════════════════════════════════════════════════════════════════
func _show_causal_page() -> void:
	_cur_page = _Page.CAUSAL
	_clear_page()
	_left_col.hide()
	_right_col.hide()
	continue_btn.hide()

	_overlay_bg()

	# ── 居中外层锚 ──────────────────────────────────────────────
	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_layer.add_child(anchor)
	_page_nodes.append(anchor)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 20)
	outer.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	outer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	outer.grow_vertical   = Control.GROW_DIRECTION_BOTH
	anchor.add_child(outer)

	# ── 标题 ────────────────────────────────────────────────────
	var title := Label.new()
	title.text = "▌因果推演"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.95, 0.82, 0.55)
	outer.add_child(title)

	# ── 内容卡（左：变卦动画 | 右：分析文本）────────────────────
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())
	outer.add_child(card)

	var card_hbox := HBoxContainer.new()
	card_hbox.add_theme_constant_override("separation", 28)
	card.add_child(card_hbox)

	# ── 左列：变爻后的卦象卡牌（含演变动画，无下方爻析）─────────
	var hex_disp := preload("res://ui/HexagramDisplay.tscn").instantiate()
	hex_disp.custom_minimum_size = Vector2(240, 300)
	hex_disp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card_hbox.add_child(hex_disp)

	# 竖向分隔线
	var vsep := VSeparator.new()
	vsep.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_hbox.add_child(vsep)

	# ── 右列：分析文本（自适应高度，无滚动条）───────────────────
	var right_rtl := RichTextLabel.new()
	right_rtl.bbcode_enabled = true
	right_rtl.fit_content = true
	right_rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_rtl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right_rtl.custom_minimum_size = Vector2(420, 0)
	right_rtl.add_theme_font_size_override("normal_font_size", 15)
	right_rtl.add_theme_color_override("default_color", Color("#e8d5a3"))
	card_hbox.add_child(right_rtl)

	# 组装右侧文本
	var parts: PackedStringArray = PackedStringArray()

	if not _cause_effect_text.is_empty():
		parts.append("[color=#e76f51][b]【因果推演】[/b][/color]\n" + _cause_effect_text)

	# 卦爻解析：仅取第 _pending_yao_changed 爻的警示/启示
	var new_hex_data := DatabaseManager.get_hexagram(_pending_new_hex)
	var yao_lines    = new_hex_data.get("yao_lines", [])
	var yao_idx      := clampi(_pending_yao_changed - 1, 0, 5)
	if yao_idx < yao_lines.size() and yao_lines[yao_idx] is Dictionary:
		var yao: Dictionary    = yao_lines[yao_idx]
		var label_s: String    = str(yao.get("label",         "第%d爻" % _pending_yao_changed))
		var yao_ci: String     = str(yao.get("yao_ci",        ""))
		var vernacular: String = str(yao.get("vernacular",    ""))
		var hint: String       = str(yao.get("strategy_hint", ""))
		var yao_block := "[color=#9bb1d4][b]【卦爻解析】[/b][/color]\n"
		yao_block += "[b]%s[/b]" % label_s
		if not yao_ci.is_empty():
			yao_block += "　%s" % yao_ci
		yao_block += "\n"
		if not vernacular.is_empty():
			yao_block += "[color=#a09070]%s[/color]\n" % vernacular
		if not hint.is_empty():
			yao_block += "[color=#7a9070]%s[/color]" % hint
		parts.append(yao_block)

	if not _hex_evolution_text.is_empty():
		parts.append("[color=#d4a8d4][b]【卦象演变】[/b][/color]\n" + _hex_evolution_text)

	right_rtl.text = "\n\n".join(parts)

	# ── 继续按钮（动画结束后才显示）─────────────────────────────
	var causal_btn := Button.new()
	causal_btn.text = "本回合已阅 — 继续"
	causal_btn.custom_minimum_size = Vector2(200, 48)
	causal_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	causal_btn.hide()
	causal_btn.pressed.connect(_on_continue_pressed)
	outer.add_child(causal_btn)

	# ── 播放卦象演变动画 ─────────────────────────────────────────
	if hex_disp.has_method("play_hexagram_sequence") \
			and _pending_old_hex >= 0 and _pending_new_hex >= 0:
		await hex_disp.play_hexagram_sequence(
			_pending_old_hex, _pending_new_hex, _pending_yao_changed)
	else:
		hex_disp.call_deferred("_update_static_display", new_hex_data)

	GameState.set_hexagram(_pending_new_hex)
	causal_btn.show()


# ════════════════════════════════════════════════════════════════
# 继续按钮统一入口
# ════════════════════════════════════════════════════════════════
func _on_continue_pressed() -> void:
	match _cur_page:
		_Page.SITUATION:
			_show_hexagram_page()
		_Page.HEXAGRAM:
			_show_decision_page()
		_Page.CONSEQUENCE:
			_show_causal_page()
		_Page.CAUSAL:
			_finish_turn()


func _finish_turn() -> void:
	_turn_controller.proceed_to_check()
	var ending := EndingRouter.check_ending()
	if ending != EndingRouter.EndingType.NONE:
		GameState.last_ending_type = ending
		var path := EndingRouter.get_ending_scene_path(ending)
		if not path.is_empty():
			SaveManager.write_autosave()
			get_tree().change_scene_to_file(path)
			return
	_turn_controller.complete_turn()
	SaveManager.write_autosave()


# ════════════════════════════════════════════════════════════════
# 信号处理
# ════════════════════════════════════════════════════════════════
func _on_strategy_chosen(category_key: String, action_name: String) -> void:
	_last_category = category_key
	_last_action   = action_name


func _on_phase_changed(phase: int) -> void:
	match phase:
		TurnController.GamePhase.SELECTING_ACTION:
			_set_ai_overlay(false)
			_show_situation_page()
		TurnController.GamePhase.WAITING_AI:
			_clear_page()
			_set_ai_overlay(true)
		TurnController.GamePhase.RESOLVING_NARRATIVE:
			pass  # 由 _on_ai_completed 接管


func _on_consult_failed(error_msg: String) -> void:
	push_warning("AIManager: %s" % error_msg)


func _on_fallback_activated(_fallback_result: Dictionary) -> void:
	var lbl: Label = _ai_overlay.get_node("AiLabel") as Label
	lbl.text = "国师援引古卷，以先贤智慧应对……"


func _on_ai_completed(result: Dictionary) -> void:
	_turn_controller.on_ai_completed(result)

	var text: String       = str(result.get("narrative",  ""))
	var philosophy: String = str(result.get("philosophy", ""))
	var analysis: String   = str(result.get("analysis",   ""))

	# ── 解析五段式 ──
	_cached_situation   = _extract_section(analysis, "情境背景")
	_cached_yao_section = _extract_section(analysis, "卦爻解析")
	var consequence     := _extract_section(analysis, "选择后果")
	var cause_effect    := _extract_section(analysis, "因果推演")
	var hex_evolution   := _extract_section(analysis, "卦象演变")
	_cause_effect_text  = cause_effect
	_hex_evolution_text = hex_evolution

	# ── 选择后果页文本 ──
	var cons_parts: PackedStringArray = PackedStringArray()
	if not text.is_empty():
		cons_parts.append(text)
	if not philosophy.is_empty():
		cons_parts.append("[i][color=#cccccc]%s[/color][/i]" % philosophy)
	if not consequence.is_empty():
		cons_parts.append(consequence)
	_consequence_text = "\n\n".join(cons_parts)

	# ── 因果推演页文本 ──
	var causal_parts: PackedStringArray = PackedStringArray()
	if not cause_effect.is_empty():
		causal_parts.append("[color=#e76f51][b]【因果推演】[/b][/color]\n" + cause_effect)
	if not _cached_yao_section.is_empty():
		causal_parts.append("[color=#9bb1d4][b]【卦爻解析】[/b][/color]\n" + _cached_yao_section)
	if not hex_evolution.is_empty():
		causal_parts.append("[color=#d4a8d4][b]【卦象演变】[/b][/color]\n" + hex_evolution)
	_causal_text = "\n\n".join(causal_parts)

	# ── 应用三才变化，计算下一卦 ──
	var old_id: int         = GameState.current_hexagram_id
	var deltas: Dictionary  = result.get("delta_stats", {})
	var yc: int             = GameState.apply_turn_deltas(deltas, int(result.get("yao_changed", 1)))
	_pending_old_hex        = old_id
	_pending_new_hex        = RuleEngine.get_next_hexagram(old_id, yc)
	_pending_yao_changed    = yc

	GameState.record_narrative_turn(text, _last_category, _last_action)

	_set_ai_overlay(false)
	_show_consequence_page()


# ════════════════════════════════════════════════════════════════
# AI 蒙层开关
# ════════════════════════════════════════════════════════════════
func _set_ai_overlay(on: bool) -> void:
	var s: ColorRect = _ai_overlay.get_node("Shade")   as ColorRect
	var l: Label     = _ai_overlay.get_node("AiLabel") as Label
	s.visible = on
	l.visible = on


# ════════════════════════════════════════════════════════════════
# 卦爻解析面板填充
# ════════════════════════════════════════════════════════════════
func _populate_yao_analysis_static() -> void:
	var data := DatabaseManager.get_hexagram(GameState.current_hexagram_id)
	if data.is_empty():
		return
	_yao_analysis_label.clear()
	var name_zh: String = str(data.get("name_zh", ""))
	_yao_analysis_label.append_text("[b]%s[/b]\n\n" % name_zh)
	var nature: String = str(data.get("nature", ""))
	if not nature.is_empty():
		_yao_analysis_label.append_text(nature + "\n\n")
	_fill_yao_label_from_data(data)


func _fill_yao_label_from_data(data: Dictionary) -> void:
	var yao_lines = data.get("yao_lines", [])
	if not (yao_lines is Array) or yao_lines.is_empty():
		return
	_yao_analysis_label.append_text("[color=#9b8a6a]── 爻辞 ──[/color]\n\n")
	for line in yao_lines:
		if line is Dictionary:
			var label_str: String  = str(line.get("label",         ""))
			var yao_ci: String     = str(line.get("yao_ci",        ""))
			var vernacular: String = str(line.get("vernacular",    ""))
			var rating: String     = str(line.get("rating",        ""))
			var hint: String       = str(line.get("strategy_hint", ""))
			_yao_analysis_label.append_text("[b]%s[/b]　%s" % [label_str, yao_ci])
			if not rating.is_empty():
				_yao_analysis_label.append_text("　[color=#c0a060][%s][/color]" % rating)
			_yao_analysis_label.append_text("\n")
			if not vernacular.is_empty():
				_yao_analysis_label.append_text("[color=#a09070]%s[/color]\n" % vernacular)
			if not hint.is_empty():
				_yao_analysis_label.append_text("[color=#7a9070]%s[/color]\n" % hint)
			_yao_analysis_label.append_text("\n")
		else:
			_yao_analysis_label.append_text("• " + str(line) + "\n")


# 卦象页覆盖层内的卦爻 RichTextLabel 填充（静态数据）
func _fill_yao_rtl_static(rtl: RichTextLabel, data: Dictionary) -> void:
	var yao_lines = data.get("yao_lines", [])
	if not (yao_lines is Array) or yao_lines.is_empty():
		return
	for line in yao_lines:
		if line is Dictionary:
			var label_str: String  = str(line.get("label",         ""))
			var yao_ci: String     = str(line.get("yao_ci",        ""))
			var vernacular: String = str(line.get("vernacular",    ""))
			var rating: String     = str(line.get("rating",        ""))
			rtl.append_text("[b]%s[/b]　%s" % [label_str, yao_ci])
			if not rating.is_empty():
				rtl.append_text("　[color=#c0a060][%s][/color]" % rating)
			rtl.append_text("\n")
			if not vernacular.is_empty():
				rtl.append_text("[color=#a09070]%s[/color]\n" % vernacular)
			rtl.append_text("\n")


func _show_yao_section(content: String) -> void:
	if content.is_empty():
		return
	_yao_analysis_label.clear()
	_yao_analysis_label.append_text("[color=#9bb1d4][b]【卦爻解析】[/b][/color]\n\n" + content)


# ════════════════════════════════════════════════════════════════
# 工具：提取 analysis 中的指定段落
# ════════════════════════════════════════════════════════════════
func _extract_section(text: String, section_name: String) -> String:
	var all_markers: Array[String] = ["情境背景", "选择后果", "因果推演", "卦爻解析", "卦象演变"]
	var start_marker := "【" + section_name + "】"
	var start_idx := text.find(start_marker)
	if start_idx == -1:
		return ""
	start_idx += start_marker.length()
	var end_idx := text.length()
	for marker in all_markers:
		if marker == section_name:
			continue
		var m := "【" + marker + "】"
		var nidx := text.find(m, start_idx)
		if nidx != -1 and nidx < end_idx:
			end_idx = nidx
	return text.substr(start_idx, end_idx - start_idx).strip_edges()


# ════════════════════════════════════════════════════════════════
# 说书人开场叙事（融合三才 + 卦象）
# ════════════════════════════════════════════════════════════════
func _build_opening_narrative(hex_data: Dictionary) -> String:
	var hex_name: String = str(hex_data.get("name_zh", "未知"))
	var nature: String   = str(hex_data.get("nature",  ""))
	var hints            = hex_data.get("philosophy_hints", [])
	var s := GameState.strength
	var m := GameState.morale
	var t := GameState.treasury

	var s_phrase: String
	if   s >= 80: s_phrase = "铁甲雄师、所向披靡"
	elif s >= 60: s_phrase = "兵力尚整、战力可用"
	elif s >= 40: s_phrase = "军力渐损、将士疲惫"
	elif s >= 20: s_phrase = "兵员短缺、危在旦夕"
	else:         s_phrase = "残兵败将、摇摇欲坠"

	var m_phrase: String
	if   m >= 80: m_phrase = "万民归心、军民齐力"
	elif m >= 60: m_phrase = "民心尚稳、上下同欲"
	elif m >= 40: m_phrase = "民意浮动、人心惶惶"
	elif m >= 20: m_phrase = "怨声载道、军心涣散"
	else:         m_phrase = "民怨沸腾、叛乱四起"

	var t_phrase: String
	if   t >= 80: t_phrase = "府库充盈、钱粮充足"
	elif t >= 60: t_phrase = "军资尚足、后勤无忧"
	elif t >= 40: t_phrase = "钱粮渐乏、后勤堪忧"
	elif t >= 20: t_phrase = "府库空虚、坐吃山空"
	else:         t_phrase = "粮草将尽、军心动摇"

	var avg := (s + m + t) / 3
	var opening: String
	if   avg >= 70: opening = "话说天下虽乱，吾主根基犹稳。"
	elif avg >= 45: opening = "话说烽烟四起，局势险中有机。"
	else:           opening = "话说山河动荡，吾主正处危难之秋。"

	var body := opening + "\n\n"
	body += "时值此刻，麾下%s，%s，%s。" % [s_phrase, m_phrase, t_phrase]
	body += "朝野上下，皆寄望于国师一语以定乾坤。\n\n"
	body += "国师夜观天象，焚香布卦，六爻依次落定——[b]【%s卦】[/b]横空而出。" % hex_name

	if not nature.is_empty():
		body += "\n\n「[i]%s[/i]」\n\n国师抚须沉吟，此卦玄机深远，须细细参详。" % nature
	else:
		body += "\n\n国师抚须沉吟，此卦玄机深远，须细细参详。"

	if hints is Array and not hints.is_empty():
		body += "\n\n古语有云：「[i]%s[/i]」——此乃天机所示，请君细辨。" % str(hints[0])

	return body


# ════════════════════════════════════════════════════════════════
# 教程气泡（前三回合）
# ════════════════════════════════════════════════════════════════
func _maybe_show_tutorial() -> void:
	if bool(GameState.flags.get("tutorial_completed", false)):
		return
	var r := GameState.current_turn
	if r > 3 or _tutorial_dismissed_round == r:
		return
	_clear_tutorial_nodes()
	await get_tree().process_frame
	match r:
		1: _show_tutorial_bubble_centered(
				"[b]【情境背景】[/b]\n这里描述当前战局形势与国师卜卦之结果。\n点击「卜卦」可查看具体卦象与爻辞。")
		2: _show_tutorial_bubble_centered(
				"[b]【战略决策】[/b]\n从四个战略方向选择一种行动。\n你的决策将触发变爻，推动卦象流转。")
		3: _show_tutorial_bubble_centered(
				"[b]【三才 HUD】[/b]\n国力·民心·资财为三才根基。\n任一归零则游戏结束，须时刻兼顾。")


func _clear_tutorial_nodes() -> void:
	for n in _tutorial_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_tutorial_nodes.clear()


func _show_tutorial_bubble_centered(text: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 35
	add_child(layer)
	_tutorial_nodes.append(layer)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(shade)

	var bubble := PanelContainer.new()
	var bub_style := StyleBoxFlat.new()
	bub_style.bg_color = Color(0.10, 0.09, 0.06, 0.95)
	bub_style.set_border_width_all(1)
	bub_style.border_color = Color(1.0, 0.85, 0.3, 0.8)
	bub_style.corner_radius_top_left     = 8
	bub_style.corner_radius_top_right    = 8
	bub_style.corner_radius_bottom_left  = 8
	bub_style.corner_radius_bottom_right = 8
	bub_style.content_margin_left   = 20
	bub_style.content_margin_right  = 20
	bub_style.content_margin_top    = 16
	bub_style.content_margin_bottom = 16
	bubble.add_theme_stylebox_override("panel", bub_style)
	layer.add_child(bubble)

	var bvbox := VBoxContainer.new()
	bvbox.add_theme_constant_override("separation", 12)
	bubble.add_child(bvbox)

	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.custom_minimum_size = Vector2(320, 0)
	lbl.add_theme_font_size_override("normal_font_size", 15)
	lbl.add_theme_color_override("default_color", Color("#e8d5a3"))
	lbl.text = text
	bvbox.add_child(lbl)

	var r := GameState.current_turn
	var close_btn := Button.new()
	close_btn.text = "知道了"
	close_btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	close_btn.pressed.connect(func() -> void:
		_tutorial_dismissed_round = r
		if r >= 3:
			GameState.flags["tutorial_completed"] = true
			SaveManager.write_autosave()
		layer.queue_free()
		_tutorial_nodes.erase(layer)
	)
	bvbox.add_child(close_btn)

	await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	var bx := clampf((vp.x - bubble.size.x) / 2.0, 8.0, vp.x - bubble.size.x - 8.0)
	var by := clampf((vp.y - bubble.size.y) / 2.0, 8.0, vp.y - bubble.size.y - 8.0)
	bubble.position = Vector2(bx, by)
