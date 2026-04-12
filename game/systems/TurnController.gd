class_name TurnController extends RefCounted

## State machine for the core hexagram consultation loop

enum GamePhase {
	IDLE,
	SELECTING_ACTION,
	WAITING_AI,
	RESOLVING_NARRATIVE,
	CHECKING_END,
	NEXT_TURN
}

signal phase_changed(new_phase: int)

var current_phase: int = GamePhase.IDLE

func start_selection() -> void:
	_change_phase(GamePhase.SELECTING_ACTION)

func submit_action(category: String, action_name: String) -> void:
	if current_phase != GamePhase.SELECTING_ACTION:
		return
	_change_phase(GamePhase.WAITING_AI)

	var hex := DatabaseManager.get_hexagram(GameState.current_hexagram_id)
	var stats := {
		"strength": GameState.strength,
		"morale": GameState.morale,
		"treasury": GameState.treasury
	}
	var recent := GameState.get_recent_narrative_summary()
	AIManager.consult(hex, category, action_name, stats, recent)

func on_ai_completed(_result: Dictionary) -> void:
	if current_phase != GamePhase.WAITING_AI:
		return
	_change_phase(GamePhase.RESOLVING_NARRATIVE)
	
	# Apply logic... handled by HexagramConsult scene usually, but controller tracks state
	
func proceed_to_check() -> void:
	if current_phase != GamePhase.RESOLVING_NARRATIVE:
		return
	_change_phase(GamePhase.CHECKING_END)

func complete_turn() -> void:
	if current_phase != GamePhase.CHECKING_END:
		return
	_change_phase(GamePhase.NEXT_TURN)
	GameState.advance_turn()
	start_selection()

func _change_phase(phase: int) -> void:
	current_phase = phase
	phase_changed.emit(phase)
