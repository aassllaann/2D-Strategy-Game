extends Node

signal stats_changed(stats: Dictionary)
signal hexagram_changed(id: int)

var strength: int = 50
var morale: int = 50
var treasury: int = 50

var current_turn: int = 1
var max_turns: int = 25
var current_hexagram_id: int = 1

func _ready() -> void:
	pass

func apply_delta(delta: Dictionary) -> void:
	if delta.has("strength"):
		strength = clampi(strength + delta["strength"], 0, 100)
	if delta.has("morale"):
		morale = clampi(morale + delta["morale"], 0, 100)
	if delta.has("treasury"):
		treasury = clampi(treasury + delta["treasury"], 0, 100)
	
	stats_changed.emit({
		"strength": strength,
		"morale": morale,
		"treasury": treasury
	})

func set_hexagram(new_id: int) -> void:
	current_hexagram_id = new_id
	hexagram_changed.emit(new_id)

func advance_turn() -> void:
	current_turn += 1
	
func reset_game() -> void:
	strength = 50
	morale = 50
	treasury = 50
	current_turn = 1
	set_hexagram(1)
	stats_changed.emit({
		"strength": strength,
		"morale": morale,
		"treasury": treasury
	})
