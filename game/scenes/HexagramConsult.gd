extends Control

var stats_hud: Control
var hexagram_display: Control
var action_panel: Control
var narrative_box: Control
var continue_btn: Button

var _turn_controller: TurnController

func _ready() -> void:
	# 1. Background (Ink Deep)
	var bg = ColorRect.new()
	bg.color = Color("#1a1a1a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 2. Outer Layout
	var outer_vbox = VBoxContainer.new()
	outer_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer_vbox.add_theme_constant_override("separation", 20)
	add_child(outer_vbox)
	
	# 3. Top Row: Stats
	stats_hud = preload("res://ui/StatsHUD.tscn").instantiate()
	stats_hud.custom_minimum_size.y = 60
	outer_vbox.add_child(stats_hud)
	
	# 4. Middle Area: Content (Hexagram + Actions)
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 40)
	outer_vbox.add_child(content_hbox)
	
	hexagram_display = preload("res://ui/HexagramDisplay.tscn").instantiate()
	hexagram_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(hexagram_display)
	
	action_panel = preload("res://ui/ActionPanel.tscn").instantiate()
	action_panel.custom_minimum_size.x = 300
	content_hbox.add_child(action_panel)
	
	# 5. Bottom Area: Narratives
	narrative_box = preload("res://ui/NarrativeBox.tscn").instantiate()
	narrative_box.custom_minimum_size.y = 150
	outer_vbox.add_child(narrative_box)
	
	continue_btn = Button.new()
	continue_btn.text = "CONSULT COMPLETE - NEXT PHASE"
	continue_btn.custom_minimum_size.y = 50
	outer_vbox.add_child(continue_btn)
	
	# 6. Logic Binding
	_turn_controller = TurnController.new()
	_turn_controller.phase_changed.connect(_on_phase_changed)
	action_panel.setup(_turn_controller)
	AIManager.consult_completed.connect(_on_ai_completed)
	
	continue_btn.pressed.connect(_on_continue_pressed)
	continue_btn.hide()
	
	action_panel.populate_actions("Attack") 
	_turn_controller.start_selection()

func _on_phase_changed(phase: int) -> void:
	match phase:
		TurnController.GamePhase.SELECTING_ACTION:
			action_panel.show()
			continue_btn.hide()
		TurnController.GamePhase.WAITING_AI:
			action_panel.hide()
			narrative_box.show_narrative("Consulting the Heavens...")
		TurnController.GamePhase.RESOLVING_NARRATIVE:
			continue_btn.show()

func _on_ai_completed(result: Dictionary) -> void:
	_turn_controller.on_ai_completed(result)
	
	var text = result.get("Narrative", "The spirits are silent.")
	var philosophy = result.get("Philosophy", "")
	narrative_box.show_narrative(text, philosophy)
	
	if result.has("State_Changes"):
		GameState.apply_delta(result["State_Changes"])
		
	if result.has("Next_Yao_Index"):
		var next_hex = RuleEngine.get_next_hexagram(GameState.current_hexagram_id, result["Next_Yao_Index"])
		GameState.set_hexagram(next_hex)

func _on_continue_pressed() -> void:
	_turn_controller.proceed_to_check()
	var ending = EndingRouter.check_ending()
	if ending != EndingRouter.EndingType.NONE:
		var path = EndingRouter.get_ending_scene_path(ending)
		if not path.is_empty():
			get_tree().change_scene_to_file(path)
			return
			
	_turn_controller.complete_turn()
