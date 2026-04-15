extends Control

signal strategy_chosen(category_key: String, action_name: String)
signal hint_requested

@onready var _buttons_container: VBoxContainer = $VBoxContainer/ButtonsContainer
@onready var _title: Label = $VBoxContainer/Label

var _turn_controller: TurnController
var _hint_btn: Button


func _ready() -> void:
	_hint_btn = Button.new()
	_hint_btn.text = "【提示】查看卦爻解析"
	_hint_btn.visible = false
	_hint_btn.pressed.connect(func() -> void: hint_requested.emit())
	# 插入到 VBoxContainer 中 Label 之后、ButtonsContainer 之前
	var vbox: VBoxContainer = _buttons_container.get_parent() as VBoxContainer
	vbox.add_child(_hint_btn)
	vbox.move_child(_hint_btn, 1)


func show_hint_button(v: bool) -> void:
	if _hint_btn:
		_hint_btn.visible = v
var _category_keys: Array[String] = ["attack", "defense", "scheme", "diplomacy"]
var _category_labels: Dictionary = {
	"attack": "攻击",
	"defense": "防御",
	"scheme": "计谋",
	"diplomacy": "和谈"
}
var _current_category: String = ""


func setup(controller: TurnController) -> void:
	_turn_controller = controller


func show_category_selection() -> void:
	_current_category = ""
	_title.text = "战略范畴"
	_clear_buttons()
	var grid := HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 12)
	for cat in _category_keys:
		var b := Button.new()
		b.text = _category_labels.get(cat, cat)
		b.custom_minimum_size = Vector2(120, 44)
		var c := cat
		b.pressed.connect(func () -> void: _show_actions_for_category(c))
		grid.add_child(b)
	_buttons_container.add_child(grid)


func _show_actions_for_category(category_key: String) -> void:
	_current_category = category_key
	_title.text = "具体行动 — " + str(_category_labels.get(category_key, category_key))
	_clear_buttons()
	var actions := _actions_for_category(category_key)
	for act in actions:
		var btn := Button.new()
		btn.text = act
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var a: String = act
		btn.pressed.connect(func () -> void: _commit_action(category_key, a))
		_buttons_container.add_child(btn)
	var back := Button.new()
	back.text = "返回范畴"
	back.pressed.connect(show_category_selection)
	_buttons_container.add_child(back)


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


func _clear_buttons() -> void:
	for child in _buttons_container.get_children():
		child.queue_free()


## Legacy hook — now opens category UI
func populate_actions(_category: String = "") -> void:
	show_category_selection()
