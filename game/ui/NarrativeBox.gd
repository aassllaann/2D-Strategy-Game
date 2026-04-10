extends Control

var rich_text: RichTextLabel

func _ready() -> void:
	for child in get_children():
		child.queue_free()
		
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	rich_text = RichTextLabel.new()
	rich_text.bbcode_enabled = true
	rich_text.visible_characters = 0
	margin.add_child(rich_text)

func show_narrative(text: String, philosophy: String = "") -> void:
	rich_text.text = text
	if philosophy != "":
		rich_text.text += "\n\n[i][color=#cccccc]" + philosophy + "[/color][/i]"
		
	var tween = get_tree().create_tween()
	rich_text.visible_characters = 0
	var duration = max(1.0, text.length() * 0.05)
	tween.tween_property(rich_text, "visible_ratio", 1.0, duration).set_trans(Tween.TRANS_LINEAR)

