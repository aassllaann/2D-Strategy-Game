extends Control

var action_panel: Control
var narrative_box: Control
var continue_btn: Button

var _turn_controller: TurnController

func _ready() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)
	
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	action_panel = preload("res://ui/ActionPanel.tscn").instantiate()
	hbox.add_child(action_panel)
	
	narrative_box = preload("res://ui/NarrativeBox.tscn").instantiate()
	vbox.add_child(narrative_box)
	
	continue_btn = Button.new()
	continue_btn.text = "Continue"
	vbox.add_child(continue_btn)
	
	_turn_controller = TurnController.new()
	_turn_controller.phase_changed.connect(_on_phase_changed)
	action_panel.setup(_turn_controller)
	AIManager.consult_completed.connect(_on_ai_completed)
	
	continue_btn.pressed.connect(_on_continue_pressed)
	continue_btn.hide()
	
	action_panel.populate_actions("Attack") # test data
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
