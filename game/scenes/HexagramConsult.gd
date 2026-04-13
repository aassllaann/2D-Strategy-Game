extends Control

var stats_hud: Control
var hexagram_display: Control
var action_panel: Control
var narrative_box: Control
var continue_btn: Button
var _ai_overlay: CanvasLayer
var _tutorial_layer: CanvasLayer

var _turn_controller: TurnController
var _last_category: String = ""
var _last_action: String = ""
var _tutorial_dismissed_round: int = -1


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#1a1008")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

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

	_tutorial_layer = CanvasLayer.new()
	_tutorial_layer.layer = 30
	add_child(_tutorial_layer)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var root_cols := HBoxContainer.new()
	root_cols.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_cols.add_theme_constant_override("separation", 12)
	margin.add_child(root_cols)

	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size.x = 220
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_cols.add_child(left_col)

	var center_col := VBoxContainer.new()
	center_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_col.size_flags_stretch_ratio = 2.2
	root_cols.add_child(center_col)

	var right_col := VBoxContainer.new()
	right_col.custom_minimum_size.x = 200
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_cols.add_child(right_col)

	hexagram_display = preload("res://ui/HexagramDisplay.tscn").instantiate()
	hexagram_display.custom_minimum_size = Vector2(200, 260)
	left_col.add_child(hexagram_display)

	narrative_box = preload("res://ui/NarrativeBox.tscn").instantiate()
	narrative_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	narrative_box.custom_minimum_size = Vector2(400, 160)
	center_col.add_child(narrative_box)

	action_panel = preload("res://ui/ActionPanel.tscn").instantiate()
	action_panel.custom_minimum_size = Vector2(360, 220)
	center_col.add_child(action_panel)

	stats_hud = preload("res://ui/StatsHUD.tscn").instantiate()
	stats_hud.custom_minimum_size = Vector2(180, 200)
	right_col.add_child(stats_hud)

	continue_btn = Button.new()
	continue_btn.text = "本回合已阅 — 继续"
	continue_btn.custom_minimum_size = Vector2(0, 44)
	center_col.add_child(continue_btn)

	_turn_controller = TurnController.new()
	_turn_controller.phase_changed.connect(_on_phase_changed)
	action_panel.setup(_turn_controller)
	action_panel.strategy_chosen.connect(_on_strategy_chosen)

	AIManager.consult_completed.connect(_on_ai_completed)
	AIManager.consult_failed.connect(_on_consult_failed)

	continue_btn.pressed.connect(_on_continue_pressed)
	continue_btn.hide()

	action_panel.populate_actions()
	_turn_controller.start_selection()


func _set_ai_overlay(on: bool) -> void:
	var shade: ColorRect = _ai_overlay.get_node("Shade") as ColorRect
	var ai_lbl: Label = _ai_overlay.get_node("AiLabel") as Label
	shade.visible = on
	ai_lbl.visible = on


func _on_strategy_chosen(category_key: String, action_name: String) -> void:
	_last_category = category_key
	_last_action = action_name


func _on_phase_changed(phase: int) -> void:
	match phase:
		TurnController.GamePhase.SELECTING_ACTION:
			_set_ai_overlay(false)
			action_panel.show()
			continue_btn.hide()
			_maybe_show_tutorial()
		TurnController.GamePhase.WAITING_AI:
			_set_ai_overlay(true)
			action_panel.hide()
			narrative_box.show_narrative("国师凝神推演，静候天机……")
		TurnController.GamePhase.RESOLVING_NARRATIVE:
			_set_ai_overlay(false)
			continue_btn.show()


func _on_consult_failed(error_msg: String) -> void:
	push_warning("AIManager: %s" % error_msg)


func _on_ai_completed(result: Dictionary) -> void:
	_turn_controller.on_ai_completed(result)
	var text: String = str(result.get("narrative", ""))
	var philosophy: String = str(result.get("philosophy", ""))
	var analysis: String = str(result.get("analysis", ""))
	narrative_box.show_narrative(text, philosophy, analysis)

	var old_id := GameState.current_hexagram_id
	var deltas: Dictionary = result.get("delta_stats", {})
	var yc: int = GameState.apply_turn_deltas(deltas, int(result.get("yao_changed", 1)))
	var next_hex := RuleEngine.get_next_hexagram(old_id, yc)
	if hexagram_display.has_method("play_hexagram_sequence"):
		await hexagram_display.play_hexagram_sequence(old_id, next_hex, yc)
	GameState.set_hexagram(next_hex)

	GameState.record_narrative_turn(text, _last_category, _last_action)


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


func _maybe_show_tutorial() -> void:
	if bool(GameState.flags.get("tutorial_completed", false)):
		return
	var r := GameState.current_turn
	if r > 3:
		return
	if _tutorial_dismissed_round == r:
		return
	for c in _tutorial_layer.get_children():
		c.queue_free()
	var bubble := PanelContainer.new()
	bubble.offset_left = 40
	bubble.offset_top = 120 + (r - 1) * 40
	var vb := VBoxContainer.new()
	bubble.add_child(vb)
	var msg := Label.new()
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	match r:
		1:
			msg.text = "提示：请选择战略范畴，再选定具体行动。"
		2:
			msg.text = "提示：卦象象征当前战局本质，随变爻而迁转。"
		_:
			msg.text = "提示：国力、民心、资财为三才根基，任一长期濒危则大势难支。"
	vb.add_child(msg)
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	var close := Button.new()
	close.text = "知道了"
	close.pressed.connect(func () -> void:
		_tutorial_dismissed_round = r
		if r >= 3:
			GameState.flags["tutorial_completed"] = true
		bubble.queue_free()
	)
	hb.add_child(close)
	_tutorial_layer.add_child(bubble)
