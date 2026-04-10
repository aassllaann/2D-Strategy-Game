extends Control

@onready var rich_text = $PanelContainer/MarginContainer/RichTextLabel

func _ready() -> void:
	rich_text.visible_characters = 0

func show_narrative(text: String, philosophy: String = "") -> void:
	rich_text.text = text
	if philosophy != "":
		rich_text.text += "\n\n[i]" + philosophy + "[/i]"
		
	var tween = get_tree().create_tween()
	rich_text.visible_characters = 0
	tween.tween_property(rich_text, "visible_ratio", 1.0, 2.0).set_trans(Tween.TRANS_LINEAR)
