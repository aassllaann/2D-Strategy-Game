extends Control

var symbol_label: Label
var name_label: Label
var nature_label: Label

func _ready() -> void:
	for child in get_children():
		child.queue_free()
		
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	
	symbol_label = Label.new()
	symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol_label.add_theme_font_size_override("font_size", 120)
	vbox.add_child(symbol_label)
	
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(name_label)
	
	nature_label = Label.new()
	nature_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nature_label.add_theme_font_size_override("font_size", 20)
	nature_label.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(nature_label)

	GameState.hexagram_changed.connect(_on_hexagram_changed)
	_on_hexagram_changed(GameState.current_hexagram_id)

func _on_hexagram_changed(hex_id: int) -> void:
	var hex_data = DatabaseManager.get_hexagram(hex_id)
	if not hex_data.is_empty():
		symbol_label.text = hex_data.get("symbol", "")
		name_label.text = hex_data.get("name", "Unknown Hexagram")
		nature_label.text = hex_data.get("nature", "Unknown Nature")
		
		# Flash animation
		if symbol_label.is_inside_tree():
			var tween = create_tween()
			symbol_label.modulate = Color(2.0, 2.0, 2.0, 0.0)
			tween.tween_property(symbol_label, "modulate", Color.WHITE, 1.0).set_trans(Tween.TRANS_QUAD)
