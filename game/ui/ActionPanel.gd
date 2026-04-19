extends Control

signal strategy_chosen(category_key: String, action_name: String)

var _turn_controller: TurnController

const _CATEGORY_KEYS: Array[String] = ["attack", "defense", "scheme", "diplomacy"]
const _CATEGORY_LABELS: Dictionary = {
	"attack": "攻 击",
	"defense": "防 御",
	"scheme": "计 谋",
	"diplomacy": "和 谈",
}
const _CATEGORY_COLORS: Dictionary = {
	"attack":    "#e76f51",
	"defense":   "#9bb1d4",
	"scheme":    "#d4a8d4",
	"diplomacy": "#a8d8a8",
}


func _ready() -> void:
	_build_scroll_ui()


func _build_scroll_ui() -> void:
	for child in get_children():
		child.queue_free()

	# ── 外层面板 ──────────────────────────────────────────────
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 18)
	for side in ["margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	panel.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(root_vbox)

	# ── 卷轴标题 ──────────────────────────────────────────────
	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text = "[center][color=#e8d5a3][font_size=17]— 决 策 书 卷 —[/font_size][/color][/center]"
	root_vbox.add_child(title)

	var top_rule := RichTextLabel.new()
	top_rule.bbcode_enabled = true
	top_rule.fit_content = true
	top_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_rule.text = "[center][color=#5a4020]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color][/center]"
	root_vbox.add_child(top_rule)

	# ── 卷内容滚动区 ──────────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root_vbox.add_child(scroll)

	# 四列横排
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 0)
	scroll.add_child(hbox)

	for i in range(_CATEGORY_KEYS.size()):
		var cat_key: String = _CATEGORY_KEYS[i]

		# ── 竖向分隔线（第一列之前不加）──────────────────────
		if i > 0:
			var vsep := RichTextLabel.new()
			vsep.bbcode_enabled = true
			vsep.fit_content = false
			vsep.size_flags_vertical = Control.SIZE_EXPAND_FILL
			vsep.custom_minimum_size = Vector2(18, 0)
			vsep.text = "[center][color=#5a4020]┊[/color][/center]"
			hbox.add_child(vsep)

		# ── 单列 ─────────────────────────────────────────────
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 5)
		hbox.add_child(col)

		# 类别标题
		var hex: String = _CATEGORY_COLORS.get(cat_key, "#e8d5a3")
		var header := RichTextLabel.new()
		header.bbcode_enabled = true
		header.fit_content = true
		header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.text = "[center][color=%s][font_size=15][b]%s[/b][/font_size][/color][/center]" \
			% [hex, _CATEGORY_LABELS.get(cat_key, cat_key)]
		col.add_child(header)

		# 标题下细线
		var under := RichTextLabel.new()
		under.bbcode_enabled = true
		under.fit_content = true
		under.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		under.text = "[center][color=#5a4020]───────[/color][/center]"
		col.add_child(under)

		# 行动按钮
		for act: String in _actions_for_category(cat_key):
			var btn := Button.new()
			btn.text = act
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.custom_minimum_size = Vector2(0, 34)
			var ck := cat_key
			var ak := act
			btn.pressed.connect(func() -> void: _commit_action(ck, ak))
			col.add_child(btn)

	# ── 卷轴底部装饰线 ────────────────────────────────────────
	var bot_rule := RichTextLabel.new()
	bot_rule.bbcode_enabled = true
	bot_rule.fit_content = true
	bot_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_rule.text = "[center][color=#5a4020]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color][/center]"
	root_vbox.add_child(bot_rule)


func _actions_for_category(category_key: String) -> PackedStringArray:
	match category_key:
		"attack":
			return PackedStringArray(["正面强攻", "奇袭侧翼", "火攻焚营", "水攻决堤", "围点打援"])
		"defense":
			return PackedStringArray(["坚壁清野", "深沟高垒", "以逸待劳", "诱敌深入", "收缩防线"])
		"scheme":
			return PackedStringArray(["离间计", "劝降", "间谍渗透", "盟约谈判", "声东击西"])
		"diplomacy":
			return PackedStringArray(["遣使议和", "割地求和", "联姻结盟", "纳贡称臣", "暗中备战"])
		_:
			return PackedStringArray(["按兵不动"])


func _commit_action(category_key: String, action_name: String) -> void:
	strategy_chosen.emit(category_key, action_name)
	if _turn_controller:
		_turn_controller.submit_action(category_key, action_name)


func setup(controller: TurnController) -> void:
	_turn_controller = controller


## Legacy hook — 书卷已在 _ready 时一次性展开，无需重建
func populate_actions(_category: String = "") -> void:
	pass


## Legacy hook — 已废弃两步式流程
func show_category_selection() -> void:
	pass
