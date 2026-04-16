extends Control

const INTRO_TEXT := """[center][color=#e8d5a3][font_size=28]易经大战略：执理者[/font_size][/color][/center]
[center][color=#888888]────────────────────────────[/color][/center]

[color=#e8d5a3][b]【世界背景】[/b][/color]
战国之世，诸侯纷争，烽火连年。你身为一方诸侯，手握山河社稷，身侧有精通易经的国师辅佐，以卦象推演军国大事。

每一次出征、每一次和谈、每一次运筹帷幄，皆在卦象的流转中留下印记。二十五个回合，便是你与命运的全部博弈。



[color=#e8d5a3][b]【三才：你的国家命脉】[/b][/color]
[color=#a8d8a8][b]国力[/b][/color]　军队战力与边境安全的根基。归零则城破国灭。
[color=#f4a261][b]民心[/b][/color]　百姓对君主的信任与拥戴。归零则内乱四起。
[color=#9bb1d4][b]资财[/b][/color]　粮草辎重与国库储备。归零则兵马难继。

三才皆需兼顾——顾此失彼，国家将在某一面首先崩溃。



[color=#e8d5a3][b]【卦象：局势的象征】[/b][/color]
每一回合，国师以当前卦象判断战局本质。六十四卦各有象义，或刚健、或柔顺、或险阻、或通达。

你的行动将触发某一爻的动变，令卦象流转至下一卦，战略形势随之改变。读懂卦象，方能顺势而为。



[color=#e8d5a3][b]【行动：每回合的抉择】[/b][/color]
每回合从以下四个方向各选一种具体行动：

[color=#e76f51][b]  攻击[/b][/color]　主动出兵，争夺战略优势，国力与民心风险并存。
[color=#9bb1d4][b]  防御[/b][/color]　固守疆土，积蓄实力，以稳换时。
[color=#a8d8a8][b]  计谋[/b][/color]　奇谋间谍，以智取胜，代价是民心的消耗。
[color=#f4a261][b]  外交[/b][/color]　谈判和谈，换取喘息，付出的是资财与军事空间。

没有绝对正确的选择——只有符合当下卦象与三才状态的最优解。



[color=#e8d5a3][b]【推演解析：国师的智慧】[/b][/color]
每次行动后，国师将给出五段推演解析：

[color=#a8d8a8][b]情境背景[/b][/color]　当前战局的形势说明
[color=#f4a261][b]选择后果[/b][/color]　此次行动的直接影响
[color=#e76f51][b]因果推演[/b][/color]　后果背后的深层逻辑
[color=#9bb1d4][b]卦爻解析[/b][/color]　动爻的警示与启示
[color=#d4a8d4][b]卦象演变[/b][/color]　卦象流转的原因与新局预示



[color=#e8d5a3][b]【结局：二十五回合后的审判】[/b][/color]
二十五回合终结，或三才耗尽提前落幕，历史将依你的功过给出裁决。
不同的三才状态与卦象轨迹，将通向截然不同的结局——

霸业未竟，还是乱世终结？一切由你书写。


[center][color=#888888]────────────────────────────[/color][/center]
[center][color=#cccccc]以卦观势，以势制策，以策定天下。[/color][/center]
"""


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#1a1008")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 外层布局：滚动区 + 底部按钮固定栏
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(outer)

	# 滚动区
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 20)
	scroll.add_child(margin)

	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rich.add_theme_font_size_override("normal_font_size", 16)
	rich.add_theme_font_size_override("bold_font_size", 16)
	rich.add_theme_color_override("default_color", Color("#dddddd"))
	rich.text = INTRO_TEXT
	margin.add_child(rich)

	# 底部固定按钮栏
	var btn_bar := PanelContainer.new()
	outer.add_child(btn_bar)

	var btn_margin := MarginContainer.new()
	btn_margin.add_theme_constant_override("margin_left", 40)
	btn_margin.add_theme_constant_override("margin_right", 40)
	btn_margin.add_theme_constant_override("margin_top", 12)
	btn_margin.add_theme_constant_override("margin_bottom", 12)
	btn_bar.add_child(btn_margin)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 16)
	btn_margin.add_child(btn_row)

	var btn_back := Button.new()
	btn_back.text = "返回主菜单"
	btn_back.custom_minimum_size = Vector2(140, 44)
	btn_back.pressed.connect(func() -> void:
		SceneTransition.change_scene("res://scenes/MainMenu.tscn")
	)
	btn_row.add_child(btn_back)

	var btn_start := Button.new()
	btn_start.text = "出征 ——"
	btn_start.custom_minimum_size = Vector2(140, 44)
	btn_start.add_theme_font_size_override("font_size", 18)
	btn_start.pressed.connect(func() -> void:
		SceneTransition.change_scene("res://scenes/HexagramConsult.tscn")
	)
	btn_row.add_child(btn_start)
