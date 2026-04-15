extends Control

## C1 + C2：六结局展示场景
## 布局：胜负徽章 → 标题 → 正文 → 三才面板 → 评分明细 → 按钮

const PANEL_WIDTH := 840
const PANEL_PAD   := 40
const BAR_HEIGHT  := 72

## 评级对应颜色
const GRADE_COLORS := {
	"S": Color("#C9A227"),
	"A": Color("#2E7D6B"),
	"B": Color("#2980B9"),
	"C": Color("#AAAAAA"),
	"D": Color("#C0392B"),
}


func _ready() -> void:
	var t       := GameState.last_ending_type
	var accent  := EndingRouter.get_accent_color(t)
	var victory := EndingRouter.is_victory(t)

	# ── 全屏背景 ──
	var bg := ColorRect.new()
	bg.color = Color("#0d0a06")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	if victory:
		var glow := ColorRect.new()
		glow.color = Color(accent.r, accent.g, accent.b, 0.06)
		glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(glow)

	# ── 居中容器（滚动，防止低分辨率裁切）──
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	# ── 主面板 ──
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.08, 0.06, 0.96)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(accent.r, accent.g, accent.b, 0.55)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left   = PANEL_PAD
	panel_style.content_margin_right  = PANEL_PAD
	panel_style.content_margin_top    = PANEL_PAD
	panel_style.content_margin_bottom = PANEL_PAD
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# [1] 胜负徽章
	var badge := Label.new()
	badge.text = EndingRouter.get_badge_for(t)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 14)
	badge.modulate = accent
	vbox.add_child(badge)

	# [2] 结局标题
	var title := Label.new()
	title.text = EndingRouter.get_title_for(t)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.modulate = accent
	vbox.add_child(title)

	# [3] 分隔线
	vbox.add_child(_make_sep(accent))

	# [4] 结局正文
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content    = true
	body.custom_minimum_size = Vector2(PANEL_WIDTH - PANEL_PAD * 2, 0)
	body.add_theme_font_size_override("font_size", 16)
	body.modulate = Color(0.88, 0.82, 0.66)
	body.append_text("[center]%s[/center]" % EndingRouter.get_body_for(t))
	vbox.add_child(body)

	# [5] 最终三才面板（C1 保留）
	vbox.add_child(_build_stats_panel())

	# [6] 分隔线
	vbox.add_child(_make_sep(accent))

	# [7] 评分明细面板（C2 新增）
	vbox.add_child(_build_score_panel(t, accent))

	# [8] 按钮行
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	var btn_menu := Button.new()
	btn_menu.text = "返回主菜单"
	btn_menu.custom_minimum_size = Vector2(160, 44)
	btn_menu.pressed.connect(_on_return_menu)
	btn_row.add_child(btn_menu)

	var btn_again := Button.new()
	btn_again.text = "再战一局"
	btn_again.custom_minimum_size = Vector2(160, 44)
	btn_again.pressed.connect(_on_play_again)
	btn_row.add_child(btn_again)

	# ── 入场动画 ──
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(panel, "modulate:a", 1.0, 0.6)


# ────────────────────────────────────────────────────────────
# [5] 最终三才面板
# ────────────────────────────────────────────────────────────
func _build_stats_panel() -> Control:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 32)
	var stats := [
		["国力", GameState.strength,  Color("#2E7D6B")],
		["民心", GameState.morale,    Color("#D35400")],
		["资财", GameState.treasury,  Color("#C9A227")],
	]
	for entry in stats:
		hbox.add_child(_stat_column(entry[0], entry[1], entry[2]))
	return hbox


func _stat_column(label_text: String, value: int, bar_color: Color) -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(180, 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	bar.min_value = 0
	bar.max_value = 100
	bar.value     = value
	bar.show_percentage = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = bar_color
	bar.add_theme_stylebox_override("fill", sb)
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.15, 0.12, 0.09)
	bar.add_theme_stylebox_override("background", bg_sb)
	col.add_child(bar)

	var val_lbl := Label.new()
	val_lbl.text = str(value)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_size_override("font_size", 26)
	val_lbl.modulate = bar_color
	col.add_child(val_lbl)

	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.modulate = Color(0.70, 0.65, 0.50)
	col.add_child(name_lbl)

	return col


# ────────────────────────────────────────────────────────────
# [7] 评分明细面板（C2）
# ────────────────────────────────────────────────────────────
func _build_score_panel(t: int, accent: Color) -> Control:
	var bd := GameState.last_score_breakdown

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)

	# 标题
	var section_lbl := Label.new()
	section_lbl.text = "评分明细"
	section_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_lbl.add_theme_font_size_override("font_size", 14)
	section_lbl.modulate = Color(0.70, 0.65, 0.50)
	outer.add_child(section_lbl)

	# 明细表（GridContainer 3列：标签 / 计算式 / 数值）
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	outer.add_child(grid)

	var gs := GameState
	var hex_data := DatabaseManager.get_hexagram(gs.current_hexagram_id)
	var hex_name: String = str(hex_data.get("name_zh", ""))
	var tier: String = str(bd.get("hex_tier", "中"))

	_add_score_row(grid,
		"基础分",
		"（%d + %d + %d）× 10" % [gs.strength, gs.morale, gs.treasury],
		int(bd.get("base", 0)),
		false)

	_add_score_row(grid,
		"回合奖励",
		"（%d − %d）× 50" % [gs.max_turns, gs.current_turn],
		int(bd.get("round_bonus", 0)),
		false)

	_add_score_row(grid,
		"卦象奖励",
		"%s · %s卦" % [hex_name, tier],
		int(bd.get("hex_bonus", 0)),
		int(bd.get("hex_bonus", 0)) == 0)

	_add_score_row(grid,
		"连贯性奖励",
		"曾触危机" if gs.ever_in_crisis else "从未触危机",
		int(bd.get("coherence", 0)),
		gs.ever_in_crisis)

	# 细分隔线
	outer.add_child(_make_sep(Color(accent.r, accent.g, accent.b, 0.25)))

	# 总分 + 评级（大字）
	var total_row := HBoxContainer.new()
	total_row.alignment = BoxContainer.ALIGNMENT_CENTER
	total_row.add_theme_constant_override("separation", 32)
	outer.add_child(total_row)

	var total_lbl := Label.new()
	total_lbl.text = "总分　%d" % GameState.last_score
	total_lbl.add_theme_font_size_override("font_size", 26)
	total_lbl.modulate = Color(0.90, 0.85, 0.65)
	total_row.add_child(total_lbl)

	var grade_str  := GameState.last_grade
	var grade_color: Color = GRADE_COLORS.get(grade_str, Color(0.8, 0.8, 0.8))
	var grade_lbl  := Label.new()
	grade_lbl.text = "评级　%s" % grade_str
	grade_lbl.add_theme_font_size_override("font_size", 26)
	grade_lbl.modulate = grade_color
	total_row.add_child(grade_lbl)

	# 败局说明（得分被上限至 999）
	if not EndingRouter.is_victory(t):
		var cap_lbl := Label.new()
		cap_lbl.text = "（败局得分上限 999，评级固定 D）"
		cap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap_lbl.add_theme_font_size_override("font_size", 12)
		cap_lbl.modulate = Color(0.50, 0.48, 0.45)
		outer.add_child(cap_lbl)

	return outer


## 向 GridContainer 添加一行：标签 / 计算式 / 数值
func _add_score_row(grid: GridContainer, label: String, formula: String,
		value: int, is_zero: bool) -> void:
	var dim := Color(0.55, 0.52, 0.45)
	var val_color := dim if is_zero else Color(0.88, 0.82, 0.66)

	var lbl := Label.new()
	lbl.text = label
	lbl.modulate = dim
	lbl.add_theme_font_size_override("font_size", 14)
	grid.add_child(lbl)

	var form := Label.new()
	form.text = formula
	form.modulate = Color(0.70, 0.65, 0.50)
	form.add_theme_font_size_override("font_size", 13)
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(form)

	var val := Label.new()
	val.text = ("+ %d" % value) if value > 0 else ("0" if value == 0 else "%d" % value)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.modulate = val_color
	val.add_theme_font_size_override("font_size", 14)
	grid.add_child(val)


# ────────────────────────────────────────────────────────────
# 辅助
# ────────────────────────────────────────────────────────────
func _make_sep(color: Color) -> Control:
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(color.r, color.g, color.b, 0.35)
	return sep


func _on_return_menu() -> void:
	var p := "user://save/autosave.json"
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_play_again() -> void:
	GameState.start_new_run()
	get_tree().change_scene_to_file("res://scenes/Intro.tscn")
