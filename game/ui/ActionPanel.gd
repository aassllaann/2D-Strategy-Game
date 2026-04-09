extends Control

signal action_selected(action_id: String)

@onready var action_buttons_container = $VBoxContainer/ButtonsContainer
var _turn_controller: TurnController

func setup(controller: TurnController) -> void:
	_turn_controller = controller
	
func populate_actions(category: String) -> void:
	# Stub method to populate specific strategy actions based on category
	# MVP uses fixed buttons for now
	for child in action_buttons_container.get_children():
		child.queue_free()
		
	var actions = ["Full Frontal Assault", "Feint and Retreat", "Supply Sabotage"]
	for act in actions:
		var btn = Button.new()
		btn.text = act
		btn.pressed.connect(func(): _on_action_pressed(act))
		action_buttons_container.add_child(btn)

func _on_action_pressed(action_id: String) -> void:
	action_selected.emit(action_id)
	if _turn_controller:
		_turn_controller.submit_action(action_id)
