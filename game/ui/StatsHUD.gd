extends Control

var _bars: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		child.queue_free()
	
	# Build UI
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	
	var title = Label.new()
	title.text = "NATIONAL STATUS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	_create_stat_bar(vbox, "strength", "Strength", Color.DARK_RED)
	_create_stat_bar(vbox, "morale", "Morale", Color.DARK_BLUE)
	_create_stat_bar(vbox, "treasury", "Treasury", Color.GOLD)

	GameState.stats_changed.connect(_on_stats_changed)
	_on_stats_changed({
		"strength": GameState.strength,
		"morale": GameState.morale,
		"treasury": GameState.treasury
	})

func _create_stat_bar(parent: Control, key: String, display_name: String, color: Color) -> void:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = display_name
	label.custom_minimum_size.x = 100
	hbox.add_child(label)
	
	var bar = ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.min_value = 0
	bar.max_value = 100
	bar.step = 1
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	bar.add_theme_stylebox_override("fill", sb)
	
	hbox.add_child(bar)
	parent.add_child(hbox)
	_bars[key] = bar

func _on_stats_changed(stats: Dictionary) -> void:
	for key in stats.keys():
		if _bars.has(key):
			# Use tween for smooth animation
			var tween = create_tween()
			tween.tween_property(_bars[key], "value", float(stats[key]), 0.5).set_trans(Tween.TRANS_SINE)

