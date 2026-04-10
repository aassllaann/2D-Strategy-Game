extends Control

@onready var strength_label = $HBoxContainer/StrengthLabel
@onready var morale_label = $HBoxContainer/MoraleLabel
@onready var treasury_label = $HBoxContainer/TreasuryLabel

func _ready() -> void:
	GameState.stats_changed.connect(_on_stats_changed)
	_on_stats_changed({
		"strength": GameState.strength,
		"morale": GameState.morale,
		"treasury": GameState.treasury
	})

func _on_stats_changed(stats: Dictionary) -> void:
	if strength_label:
		strength_label.text = "Strength: %d" % stats.get("strength", 50)
	if morale_label:
		morale_label.text = "Morale: %d" % stats.get("morale", 50)
	if treasury_label:
		treasury_label.text = "Treasury: %d" % stats.get("treasury", 50)
