extends Control

var symbol_label: Label
var name_label: Label
var nature_label: Label


func _ready() -> void:
	for child in get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
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
	nature_label.add_theme_font_size_override("font_size", 18)
	nature_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nature_label.modulate = Color(0.75, 0.75, 0.75)
	vbox.add_child(nature_label)

	GameState.hexagram_changed.connect(_on_hexagram_changed)
	_on_hexagram_changed(GameState.current_hexagram_id)


## PRD FR-05 五段节奏（此处以符号线动画为主，六爻逐线高亮可后续接专用控件）
func play_hexagram_sequence(from_id: int, to_id: int, _changed_yao: int) -> void:
	if not is_inside_tree():
		return
	var sp := AppSettings.get_anim_speed_mult()
	var tree := get_tree()
	var from_data := DatabaseManager.get_hexagram(from_id)
	var to_data := DatabaseManager.get_hexagram(to_id)

	symbol_label.text = str(from_data.get("symbol", ""))
	name_label.text = str(from_data.get("name_zh", from_data.get("name", "")))
	nature_label.text = str(from_data.get("nature", ""))

	## 1 当前卦脉动（象征六爻依次涌动）
	var tw_pulse := create_tween()
	tw_pulse.set_loops(5)
	tw_pulse.tween_property(symbol_label, "scale", Vector2(1.06, 1.06), 0.14 * sp)
	tw_pulse.tween_property(symbol_label, "scale", Vector2.ONE, 0.14 * sp)
	await tree.create_timer(0.82 * sp).timeout
	tw_pulse.kill()

	## 2 变爻闪烁
	var t_flash := create_tween()
	t_flash.tween_property(symbol_label, "modulate", Color(1.7, 0.25, 0.2), 0.28 * sp)
	t_flash.tween_property(symbol_label, "modulate", Color.WHITE, 0.32 * sp)
	await t_flash.finished
	await tree.create_timer(0.55 * sp).timeout

	## 3 新卦自下而上翻入（缩放近似）
	symbol_label.scale = Vector2(0.12, 0.12)
	symbol_label.text = str(to_data.get("symbol", ""))
	name_label.text = str(to_data.get("name_zh", to_data.get("name", "")))
	nature_label.text = str(to_data.get("nature", ""))
	var t_in := create_tween()
	t_in.tween_property(symbol_label, "scale", Vector2.ONE, 1.15 * sp).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t_in.finished

	## 4~5 背景 / BGM 过渡留由美术接入；此处略作清场
	symbol_label.modulate = Color.WHITE


func _on_hexagram_changed(hex_id: int) -> void:
	var hex_data := DatabaseManager.get_hexagram(hex_id)
	if not hex_data.is_empty():
		symbol_label.text = str(hex_data.get("symbol", ""))
		name_label.text = str(hex_data.get("name_zh", hex_data.get("name", "卦")))
		nature_label.text = str(hex_data.get("nature", ""))
		if symbol_label.is_inside_tree():
			var tween := create_tween()
			symbol_label.modulate = Color(2.0, 2.0, 2.0, 0.0)
			tween.tween_property(symbol_label, "modulate", Color.WHITE, 0.85).set_trans(Tween.TRANS_QUAD)
