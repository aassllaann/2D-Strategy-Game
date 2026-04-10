extends Control

signal action_selected(action_id: String)

@onready var action_buttons_container = $VBoxContainer/ButtonsContainer
var _turn_controller: TurnController

func setup(controller: TurnController) -> void:
	_turn_controller = controller
	
func populate_actions(category: String) -> void:
	# Clear old buttons
	for child in action_buttons_container.get_children():
		child.queue_free()
		
	var actions = []
	match category.to_lower():
		"attack": actions = ["Full Frontal Assault", "Flanking Maneuver", "Night Raid", "Siege Combat"]
		"defend": actions = ["Fortify Walls", "Scorched Earth", "Ambush Trap", "Strategic Retreat"]
		"plot": actions = ["Sowing Discord", "Surrender Invitation", "Spy Infiltration", "Rumor Campaign"]
		"peace": actions = ["Alliance Negotiation", "Tribute Offering", "Trade Agreement", "Dynastic Marriage"]
		_: actions = ["Proceed Cautiously"]
		
	for act in actions:
		var btn = Button.new()
		btn.text = act
		btn.pressed.connect(func(): _on_action_pressed(act))
		action_buttons_container.add_child(btn)

func _on_action_pressed(action_id: String) -> void:
	action_selected.emit(action_id)
	if _turn_controller:
		_turn_controller.submit_action(action_id)
