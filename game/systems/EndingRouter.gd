class_name EndingRouter extends RefCounted

## Checks for game over conditions after a turn resolves

enum EndingType {
	NONE,
	VICTORY_TIME,
	DEFEAT_STRENGTH,
	DEFEAT_MORALE,
	DEFEAT_TREASURY
}

static func check_ending() -> int:
	if GameState.current_turn >= GameState.max_turns:
		return EndingType.VICTORY_TIME
	
	if GameState.strength <= 20:
		return EndingType.DEFEAT_STRENGTH
		
	if GameState.morale <= 15:
		return EndingType.DEFEAT_MORALE
		
	if GameState.treasury <= 10:
		return EndingType.DEFEAT_TREASURY
		
	return EndingType.NONE

static func get_ending_scene_path(ending_type: int) -> String:
	match ending_type:
		EndingType.VICTORY_TIME:
			return "res://scenes/Ending.tscn" # Add variables to load specific text
		EndingType.DEFEAT_STRENGTH, EndingType.DEFEAT_MORALE, EndingType.DEFEAT_TREASURY:
			return "res://scenes/Ending.tscn"
		_:
			return ""
