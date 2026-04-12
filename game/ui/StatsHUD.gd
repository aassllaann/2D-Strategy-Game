extends Control

var _bars: Dictionary = {}
var _round_label: Label
var _crisis_panel: PanelContainer


func _ready() -> void:
	for child in get_children():
		child.queue_free()

	_crisis_panel = PanelContainer.new()
	_crisis_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var crisis_style := StyleBoxFlat.new()
	crisis_style.bg_color = Color(0.08, 0.06, 0.05, 0.35)
	crisis_style.set_border_width_all(2)
	crisis_style.border_color = Color(0.3, 0.3, 0.3, 0.0)
	_crisis_panel.add_theme_stylebox_override("panel", crisis_style)
	add_child(_crisis_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	_crisis_panel.add_child(vbox)

	_round_label = Label.new()
	_round_label.text = _round_text()
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_round_label)

	var title := Label.new()
	title.text = "三才态势"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_create_stat_bar(vbox, "strength", "国力", Color("#2E7D6B"))
	_create_stat_bar(vbox, "morale", "民心", Color("#D35400"))
	_create_stat_bar(vbox, "treasury", "资财", Color("#C9A227"))

	GameState.stats_changed.connect(_on_stats_changed)
	GameState.turn_advanced.connect(func (_t: int) -> void:
		_round_label.text = _round_text()
	)
	_on_stats_changed({
		"strength": GameState.strength,
		"morale": GameState.morale,
		"treasury": GameState.treasury
	})


func _round_text() -> String:
	return "回合 %d / %d" % [GameState.current_turn, GameState.max_turns]


func _create_stat_bar(parent: Control, key: String, display_name: String, color: Color) -> void:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = display_name
	label.custom_minimum_size.x = 56
	hbox.add_child(label)

	var bar := ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.min_value = 0
	bar.max_value = 100
	bar.step = 1
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	bar.add_theme_stylebox_override("fill", sb)

	hbox.add_child(bar)
	parent.add_child(hbox)
	_bars[key] = bar


func _on_stats_changed(stats: Dictionary) -> void:
	_round_label.text = _round_text()
	var crisis := false
	for key in stats.keys():
		if _bars.has(key):
			var tween := create_tween()
			tween.tween_property(_bars[key], "value", float(stats[key]), 0.5).set_trans(Tween.TRANS_SINE)
		if int(stats[key]) < 30:
			crisis = true
	var base := _crisis_panel.get_theme_stylebox("panel")
	if base != null:
		var sb: StyleBoxFlat = base.duplicate() as StyleBoxFlat
		sb.border_color = Color(0.75, 0.15, 0.12, 1.0) if crisis else Color(0.3, 0.3, 0.3, 0.0)
		_crisis_panel.add_theme_stylebox_override("panel", sb)
