extends Control

## B3：布局与交互时序规范
## 顶部栏 60px / 左侧卦象区 340px / 中间主交互区 EXPAND / 右侧 HUD 280px
## 交互三阶段：A 情境背景+卦爻解析 / B 决策中 / C 因果推演+卦爻演变

var stats_hud: Control
var hexagram_display: Control
var action_panel: Control
var narrative_box: Control
var continue_btn: Button
var _ai_overlay: CanvasLayer
var _tutorial_layer: CanvasLayer

var _yao_analysis_panel: PanelContainer
var _yao_analysis_label: RichTextLabel
var _phase_label: Label

var _turn_controller: TurnController
var _last_category: String = ""
var _last_action: String = ""
var _tutorial_dismissed_round: int = -1


func _ready() -> void:
	# ── 背景 ──
	var bg := ColorRect.new()
	bg.color = Color("#1a1008")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

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
	ai_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ai_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ai_lbl.add_theme_font_size_override("font_size", 28)
	ai_lbl.visible = false
	_ai_overlay.add_child(ai_lbl)
	add_child(_ai_overlay)

	# ── 教程气泡层（CanvasLayer 30）──
	_tutorial_layer = CanvasLayer.new()
	_tutorial_layer.layer = 30
	add_child(_tutorial_layer)

	# ══════════════════════════════════════════
	# 主布局：VBoxContainer（顶部栏 + 内容区）
	# ══════════════════════════════════════════
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	# ── 顶部栏（60px）──
	main_vbox.add_child(_build_top_bar())

	# ── 内容区（含边距）──
	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	main_vbox.add_child(margin)

	var root_cols := HBoxContainer.new()
	root_cols.add_theme_constant_override("separation", 8)
	margin.add_child(root_cols)

	# ── 左侧卦象区（340px 固定）──
	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size.x = 340
	left_col.size_flags_horizontal = Control.SIZE_FILL
	left_col.add_theme_constant_override("separation", 6)
	root_cols.add_child(left_col)

	# ── 中间主交互区（弹性填充）──
	var center_col := VBoxContainer.new()
	center_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_col.add_theme_constant_override("separation", 8)
	root_cols.add_child(center_col)

	# ── 右侧 HUD（280px 固定）──
	var right_col := VBoxContainer.new()
	right_col.custom_minimum_size.x = 280
	right_col.size_flags_horizontal = Control.SIZE_FILL
	root_cols.add_child(right_col)

	# ════════════════════════
	# 左侧：卦象 + 卦爻解析
	# ════════════════════════
	hexagram_display = preload("res://ui/HexagramDisplay.tscn").instantiate()
	hexagram_display.custom_minimum_size = Vector2(320, 280)
	left_col.add_child(hexagram_display)

	var yao_title := Label.new()
	yao_title.text = "卦爻解析"
	yao_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yao_title.add_theme_font_size_override("font_size", 14)
	yao_title.modulate = Color(0.85, 0.78, 0.55)
	left_col.add_child(yao_title)

	_yao_analysis_panel = PanelContainer.new()
	_yao_analysis_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var yao_style := StyleBoxFlat.new()
	yao_style.bg_color = Color(0.08, 0.07, 0.05, 0.85)
	yao_style.set_border_width_all(1)
	yao_style.border_color = Color(0.4, 0.35, 0.25, 0.6)
	yao_style.content_margin_left = 8
	yao_style.content_margin_right = 8
	yao_style.content_margin_top = 6
	yao_style.content_margin_bottom = 6
	_yao_analysis_panel.add_theme_stylebox_override("panel", yao_style)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_yao_analysis_label = RichTextLabel.new()
	_yao_analysis_label.bbcode_enabled = true
	_yao_analysis_label.fit_content = true
	_yao_analysis_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_yao_analysis_label.add_theme_font_size_override("font_size", 13)
	_yao_analysis_label.modulate = Color(0.82, 0.76, 0.60)
	scroll.add_child(_yao_analysis_label)
	_yao_analysis_panel.add_child(scroll)
	left_col.add_child(_yao_analysis_panel)

	# ════════════════════════════════
	# 中间：阶段标题 + 叙事区 + 决策区
	# ════════════════════════════════
	_phase_label = Label.new()
	_phase_label.text = "▌情境背景"
	_phase_label.add_theme_font_size_override("font_size", 15)
	_phase_label.modulate = Color(0.90, 0.85, 0.60)
	center_col.add_child(_phase_label)

	narrative_box = preload("res://ui/NarrativeBox.tscn").instantiate()
	narrative_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	narrative_box.custom_minimum_size = Vector2(400, 160)
	center_col.add_child(narrative_box)

	action_panel = preload("res://ui/ActionPanel.tscn").instantiate()
	action_panel.custom_minimum_size = Vector2(360, 220)
	center_col.add_child(action_panel)

	continue_btn = Button.new()
	continue_btn.text = "本回合已阅 — 继续"
	continue_btn.custom_minimum_size = Vector2(0, 44)
	center_col.add_child(continue_btn)

	# ════════════════
	# 右侧：三才 HUD
	# ════════════════
	stats_hud = preload("res://ui/StatsHUD.tscn").instantiate()
	stats_hud.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_child(stats_hud)

	# ── 信号连接 ──
	_turn_controller = TurnController.new()
	_turn_controller.phase_changed.connect(_on_phase_changed)
	action_panel.setup(_turn_controller)
	action_panel.strategy_chosen.connect(_on_strategy_chosen)
	action_panel.hint_requested.connect(_on_hint_requested)

	AIManager.consult_completed.connect(_on_ai_completed)
	AIManager.consult_failed.connect(_on_consult_failed)
	AIManager.fallback_activated.connect(_on_fallback_activated)

	continue_btn.pressed.connect(_on_continue_pressed)
	continue_btn.hide()

	action_panel.populate_actions()
	_turn_controller.start_selection()

	# 第一回合开场叙事
	if GameState.current_turn == 1:
		var hex_data := DatabaseManager.get_hexagram(GameState.current_hexagram_id)
		var hex_name: String = str(hex_data.get("name_zh", ""))
		var hex_nature: String = str(hex_data.get("nature", ""))
		narrative_box.show_narrative(
			"天命所系，运筹帷幄。国师展开卦盘，六爻错落，%s卦现于眼前——\n\n%s\n\n三才在握，战机未明。请静观卦象，择策而动。" % [hex_name, hex_nature]
		)


# ────────────────────────────────────────────────────────────
# 顶部栏构建
# ────────────────────────────────────────────────────────────
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

	# 三节布局：左占位 | 中标题 | 右存档按钮
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
	# 定位到右上角 TopBar 内
	lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lbl.position = Vector2(get_viewport_rect().size.x - 200, 18)
	_tutorial_layer.add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)


# ────────────────────────────────────────────────────────────
# 阶段 A：填充静态卦爻解析（nature + yao_lines）
# ────────────────────────────────────────────────────────────
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
	var yao_lines = data.get("yao_lines", [])
	if yao_lines is Array and not yao_lines.is_empty():
		_yao_analysis_label.append_text("[color=#9b8a6a]── 爻辞 ──[/color]\n")
		for line in yao_lines:
			_yao_analysis_label.append_text("• " + str(line) + "\n")


# ────────────────────────────────────────────────────────────
# 阶段 C：用 AI 返回的 analysis 更新解析面板
# ────────────────────────────────────────────────────────────
func _update_yao_analysis_ai(analysis: String) -> void:
	if analysis.is_empty():
		return
	_yao_analysis_label.clear()
	_yao_analysis_label.add_text(analysis)


# ────────────────────────────────────────────────────────────
# 【提示】按钮：高亮左侧解析面板
# ────────────────────────────────────────────────────────────
func _on_hint_requested() -> void:
	var tw := create_tween()
	tw.tween_property(_yao_analysis_panel, "modulate", Color(1.5, 1.3, 0.7), 0.15)
	tw.tween_property(_yao_analysis_panel, "modulate", Color(1.0, 1.0, 1.0), 0.35)


# ────────────────────────────────────────────────────────────
# AI 蒙层开关
# ────────────────────────────────────────────────────────────
func _set_ai_overlay(on: bool) -> void:
	var shade: ColorRect = _ai_overlay.get_node("Shade") as ColorRect
	var lbl: Label    = _ai_overlay.get_node("AiLabel") as Label
	shade.visible = on
	lbl.visible   = on


# ────────────────────────────────────────────────────────────
# 信号处理
# ────────────────────────────────────────────────────────────
func _on_strategy_chosen(category_key: String, action_name: String) -> void:
	_last_category = category_key
	_last_action   = action_name


func _on_phase_changed(phase: int) -> void:
	match phase:
		TurnController.GamePhase.SELECTING_ACTION:
			# 阶段 A：情境背景 + 卦爻解析
			_set_ai_overlay(false)
			_phase_label.text = "▌情境背景"
			action_panel.show()
			action_panel.show_hint_button(true)
			continue_btn.hide()
			_populate_yao_analysis_static()
			_maybe_show_tutorial()
		TurnController.GamePhase.WAITING_AI:
			# 阶段 B → 等待 AI
			_set_ai_overlay(true)
			action_panel.show_hint_button(false)
			action_panel.hide()
			narrative_box.show_narrative("国师凝神推演，静候天机……")
		TurnController.GamePhase.RESOLVING_NARRATIVE:
			# 阶段 C：因果推演
			_set_ai_overlay(false)
			_phase_label.text = "▌因果推演"
			action_panel.show_hint_button(false)
			continue_btn.show()


func _on_consult_failed(error_msg: String) -> void:
	push_warning("AIManager: %s" % error_msg)


func _on_fallback_activated(_fallback_result: Dictionary) -> void:
	var lbl: Label = _ai_overlay.get_node("AiLabel") as Label
	lbl.text = "国师援引古卷，以先贤智慧应对……"


func _on_ai_completed(result: Dictionary) -> void:
	_turn_controller.on_ai_completed(result)
	var text: String      = str(result.get("narrative", ""))
	var philosophy: String = str(result.get("philosophy", ""))
	var analysis: String  = str(result.get("analysis", ""))
	narrative_box.show_narrative(text, philosophy, analysis)

	# 阶段 C：用 AI analysis 更新左侧卦爻解析面板
	_update_yao_analysis_ai(analysis)

	var old_id   := GameState.current_hexagram_id
	var deltas: Dictionary = result.get("delta_stats", {})
	var yc: int  = GameState.apply_turn_deltas(deltas, int(result.get("yao_changed", 1)))
	var next_hex := RuleEngine.get_next_hexagram(old_id, yc)

	continue_btn.hide()  # 动画期间隐藏，防止提前继续
	if hexagram_display.has_method("play_hexagram_sequence"):
		await hexagram_display.play_hexagram_sequence(old_id, next_hex, yc)
	GameState.set_hexagram(next_hex)
	GameState.record_narrative_turn(text, _last_category, _last_action)
	continue_btn.show()


func _on_continue_pressed() -> void:
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
	action_panel.populate_actions()


# ────────────────────────────────────────────────────────────
# 教程气泡（前三回合）
# ────────────────────────────────────────────────────────────
func _maybe_show_tutorial() -> void:
	if bool(GameState.flags.get("tutorial_completed", false)):
		return
	var r := GameState.current_turn
	if r > 3 or _tutorial_dismissed_round == r:
		return
	for c in _tutorial_layer.get_children():
		c.queue_free()
	var bubble := PanelContainer.new()
	bubble.offset_left = 40
	bubble.offset_top  = 120 + (r - 1) * 40
	var vb := VBoxContainer.new()
	bubble.add_child(vb)
	var msg := Label.new()
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	match r:
		1: msg.text = "提示：请选择战略范畴，再选定具体行动。"
		2: msg.text = "提示：卦象象征当前战局本质，随变爻而迁转。左侧「卦爻解析」可辅助决策。"
		_: msg.text = "提示：国力、民心、资财为三才根基，任一长期濒危则大势难支。"
	vb.add_child(msg)
	var hb  := HBoxContainer.new()
	vb.add_child(hb)
	var close := Button.new()
	close.text = "知道了"
	close.pressed.connect(func() -> void:
		_tutorial_dismissed_round = r
		if r >= 3:
			GameState.flags["tutorial_completed"] = true
		bubble.queue_free()
	)
	hb.add_child(close)
	_tutorial_layer.add_child(bubble)
