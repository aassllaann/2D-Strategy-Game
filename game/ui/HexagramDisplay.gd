extends Control

## FR-05 五段变卦演出
## _yao_labels[0] = 初爻（底），_yao_labels[5] = 上爻（顶）
## VBox 中从上到下为上爻→初爻，符合传统卦图方向

# ─── UI 节点 ─────────────────────────────────────────────
var _yao_labels: Array = []  # 6 个 Label，[0]=初爻…[5]=上爻
var _hex_name_label: Label
var _nature_label: Label

# ─── 视觉常量 ─────────────────────────────────────────────
const YAO_YANG    := "──────────────"
const YAO_YIN     := "──────  ──────"
const C_NORMAL    := Color(0.85, 0.78, 0.60, 1.0)
const C_HIGHLIGHT := Color(1.00, 0.95, 0.75, 1.0)
const C_CHANGED   := Color(1.00, 0.22, 0.15, 1.0)
const C_DIM       := Color(0.50, 0.45, 0.35, 0.70)


func _ready() -> void:
	for child in get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	_hex_name_label = Label.new()
	_hex_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hex_name_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_hex_name_label)

	# 爻线容器：上爻在顶，初爻在底
	var yao_vbox := VBoxContainer.new()
	yao_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	yao_vbox.add_theme_constant_override("separation", 5)
	vbox.add_child(yao_vbox)

	_yao_labels.resize(6)
	# 从 index 5（上爻）到 0（初爻）添加到 VBox，使上爻视觉上在顶
	for i in range(5, -1, -1):
		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.modulate = C_NORMAL
		yao_vbox.add_child(lbl)
		_yao_labels[i] = lbl

	_nature_label = Label.new()
	_nature_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nature_label.add_theme_font_size_override("font_size", 16)
	_nature_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_nature_label.modulate = Color(0.75, 0.75, 0.75)
	vbox.add_child(_nature_label)

	GameState.hexagram_changed.connect(_on_hexagram_changed)
	_on_hexagram_changed(GameState.current_hexagram_id)


func _on_hexagram_changed(hex_id: int) -> void:
	_update_static_display(DatabaseManager.get_hexagram(hex_id))


## 静态刷新显示（非动画场景使用）
func _update_static_display(data: Dictionary) -> void:
	if data.is_empty():
		return
	_hex_name_label.text = str(data.get("name_zh", data.get("name", "")))
	_nature_label.text   = str(data.get("nature", ""))
	_apply_binary(str(data.get("binary", "111111")), C_NORMAL)


## 根据 binary 字符串设置 6 爻文本与颜色
## 约定：binary[0]=初爻（底），binary[5]=上爻（顶）
func _apply_binary(binary: String, color: Color) -> void:
	for i in range(6):
		var is_yang := i < binary.length() and binary[i] == "1"
		_yao_labels[i].text     = YAO_YANG if is_yang else YAO_YIN
		_yao_labels[i].modulate = color


## ─────────────────────────────────────────────────────────
## PRD FR-05 五段变卦演出（供 HexagramConsult 以 await 调用）
## 正常模式总时长约 3.2s，快速模式约 1.6s
## ─────────────────────────────────────────────────────────
func play_hexagram_sequence(from_id: int, to_id: int, changed_yao: int) -> void:
	if not is_inside_tree():
		return

	var sp          := AppSettings.get_anim_speed_mult()
	var tree        := get_tree()
	var from_data   := DatabaseManager.get_hexagram(from_id)
	var to_data     := DatabaseManager.get_hexagram(to_id)
	var from_bin    := str(from_data.get("binary", "111111"))
	var to_bin      := str(to_data.get("binary", "111111"))
	# 变爻下标：yao_changed 1=初爻→0，6=上爻→5
	var changed_idx := clampi(changed_yao - 1, 0, 5)

	# 初始状态：显示起始卦，所有爻线正常显示
	_hex_name_label.text = str(from_data.get("name_zh", ""))
	_nature_label.text   = str(from_data.get("nature", ""))
	_apply_binary(from_bin, C_NORMAL)

	# ── 阶段 2：变爻红色双闪（约 0.6s）+ 音效占位 ───────────────
	var tw2 := create_tween()
	tw2.set_loops(2)
	tw2.tween_property(_yao_labels[changed_idx], "modulate", C_CHANGED, 0.15 * sp)
	tw2.tween_property(_yao_labels[changed_idx], "modulate", C_NORMAL,  0.15 * sp)
	await tw2.finished
	# TODO D4：AudioManager.play_sfx("yao_change")

	# ── 阶段 3：新卦爻线从初爻到上爻逐行翻入（总计约 1.2s）──────
	_hex_name_label.text = str(to_data.get("name_zh", ""))
	_nature_label.text   = str(to_data.get("nature", ""))
	var reveal := 0.2 * sp  # 6 × 0.2s = 1.2s
	for i in range(6):
		var is_yang := i < to_bin.length() and to_bin[i] == "1"
		_yao_labels[i].text     = YAO_YANG if is_yang else YAO_YIN
		_yao_labels[i].modulate = C_DIM
		var tw3 := create_tween()
		tw3.tween_property(_yao_labels[i], "modulate", C_HIGHLIGHT, reveal * 0.4)
		tw3.tween_property(_yao_labels[i], "modulate", C_NORMAL,    reveal * 0.6)
		await tree.create_timer(reveal).timeout

	# ── 阶段 4：背景淡入切换（0.6s，D4 美术资产接入后启用）───────
	# TODO D4：
	# var bg_path := str(to_data.get("background_image", ""))
	# if not bg_path.is_empty() and ResourceLoader.exists(bg_path):
	#     var tw4 := create_tween()
	#     tw4.tween_property(background_rect, "modulate:a", 0.0, 0.2 * sp)
	#     background_rect.texture = load(bg_path)
	#     tw4.tween_property(background_rect, "modulate:a", 1.0, 0.4 * sp)
	#     await tw4.finished

	# ── 阶段 5：BGM 平滑过渡（2.0s，与阶段 4 并行，D4 接入）─────
	# TODO D4：
	# var bgm_path := str(to_data.get("bgm_track", ""))
	# if not bgm_path.is_empty():
	#     AppSettings.crossfade_bgm(bgm_path, 2.0 * sp)
