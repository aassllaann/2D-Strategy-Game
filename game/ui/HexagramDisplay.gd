extends Control

@onready var symbol_label = $VBoxContainer/SymbolLabel
@onready var name_label = $VBoxContainer/NameLabel
@onready var nature_label = $VBoxContainer/NatureLabel

func _ready() -> void:
	GameState.hexagram_changed.connect(_on_hexagram_changed)
	_on_hexagram_changed(GameState.current_hexagram_id)

func _on_hexagram_changed(hex_id: int) -> void:
	var hex_data = DatabaseManager.get_hexagram(hex_id)
	if not hex_data.is_empty():
		symbol_label.text = hex_data.get("symbol", "")
		name_label.text = hex_data.get("name", "Unknown Hexagram")
		nature_label.text = hex_data.get("nature", "Unknown Nature")
