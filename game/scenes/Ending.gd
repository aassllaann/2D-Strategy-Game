extends Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0d0d0d")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(root)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.text = EndingRouter.get_title_for(GameState.last_ending_type)
	root.add_child(title)

	var score_line := Label.new()
	score_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_line.text = "评分：%d　评级：%s" % [GameState.last_score, GameState.last_grade]
	root.add_child(score_line)

	var desc := Label.new()
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.text = _body_for_ending(GameState.last_ending_type)
	root.add_child(desc)

	var btn := Button.new()
	btn.text = "返回标题"
	btn.pressed.connect(_return_title)
	root.add_child(btn)


func _body_for_ending(t: int) -> String:
	match t:
		EndingRouter.EndingType.DEFEAT_STRENGTH:
			return "国力气竭，疆土崩裂，王朝不继。"
		EndingRouter.EndingType.DEFEAT_MORALE:
			return "军心离散，哗变四起，大势已去。"
		EndingRouter.EndingType.DEFEAT_TREASURY:
			return "府库空虚，民生凋敝，再难支应。"
		EndingRouter.EndingType.DEFEAT_LATE_COLLAPSE:
			return "末路一战，损耗过巨，终致倾覆。"
		EndingRouter.EndingType.WIN_PARTIAL:
			return "虽未混一宇内，然保境息民，亦可偏安。"
		EndingRouter.EndingType.WIN_TOTAL:
			return "三才俱旺，兵革止息，天下归于一统。"
		EndingRouter.EndingType.ENDING_STALE:
			return "二十五回合届满，时运未济，功业难全。"
		_:
			return "故事告一段落。"


func _return_title() -> void:
	var p := "user://save/autosave.json"
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
