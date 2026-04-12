extends Node

signal consult_completed(result: Dictionary)
signal consult_failed(error_msg: String)
signal fallback_activated(fallback_result: Dictionary)

enum Provider { GEMINI, CLAUDE, DEEPSEEK }

const GEMINI_MODEL: String = "gemini-2.0-flash"
const CLAUDE_MODEL: String = "claude-haiku-4-5-20251001"
const DEEPSEEK_MODEL: String = "deepseek-chat"
const MAX_TOKENS: int = 1500

const SYSTEM_PROMPT: String = """【角色设定】
你是《执理者》游戏中的叙事 AI，以精通易经的古代军师视角进行叙述。
文风：简练、儒雅、深邃，使用文言白话混合风格。
严禁：现代词汇、网络用语、直接引用易经原文超过 10 字。

【任务】
根据以下输入，生成本回合战争叙事并判定动爻。

【输出规则】
1. 严格返回 JSON 对象本身，不得包含任何 JSON 之外的文字、Markdown 代码围栏或解释。
2. 字段名必须使用英文小写键：narrative, yao_changed, delta_stats, philosophy, analysis；可选 next_hexagram_hint。
3. narrative：100~200 字，描述本回合战事进展与后果，需体现卦象特性。
4. yao_changed：1~6 的整数（1=初爻，6=上爻）。激进行动多触发下位爻(1~3)；稳健多触发上位爻(4~6)。
5. delta_stats 对象内含 strength、morale、treasury 三个整数，每个范围 -20~+20。
6. philosophy：20~40 字判词，化用卦爻意象，勿长段照抄经文。
7. 数值变动须自洽，避免三项同时大幅正向飙升。
8. analysis：200~350 字的五段式推演解析，各段以【】标注段名，依序为：
   【情境背景】本回合所处局势与战略环境的简要说明；
   【选择后果】玩家此次行动带来的直接影响与具体结果；
   【因果推演】上述后果产生的深层原因——兵势、民心、地利、时机等多维分析；
   【卦爻解析】本卦卦象的核心象义，以及第 yao_changed 爻动变后所示的警示或启示；
   【卦象演变】结合因果推演与卦爻象义，说明此番动变为何导致卦象由本卦演变至下一卦，以及新卦预示的后续走势与应对之道。"""

var provider: int = Provider.DEEPSEEK
var gemini_key: String = ""
var claude_key: String = ""
var deepseek_key: String = ""

var _http_request: HTTPRequest = null
var _timeout_timer: Timer = null
var _fallback_data: Dictionary = {}
var _pending_category: String = "attack"
var _pending_action_name: String = ""
var _pending_hex_id: int = 1


func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)

	_timeout_timer = Timer.new()
	_timeout_timer.one_shot = true
	_timeout_timer.wait_time = 30.0
	add_child(_timeout_timer)
	_timeout_timer.timeout.connect(_on_request_timeout)

	_load_settings()
	_load_fallback_data()


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return
	provider = int(config.get_value("AI", "provider", Provider.DEEPSEEK))
	gemini_key = str(config.get_value("AI", "gemini_key", ""))
	claude_key = str(config.get_value("AI", "claude_key", ""))
	deepseek_key = str(config.get_value("AI", "deepseek_key", ""))
	# 兼容旧版单 api_key 字段
	var legacy: String = str(config.get_value("AI", "api_key", ""))
	if not legacy.is_empty():
		if legacy.begins_with("sk-ant-"):
			claude_key = legacy
		else:
			gemini_key = legacy


func save_settings(new_provider: int, new_gemini_key: String, new_claude_key: String, new_deepseek_key: String) -> void:
	provider = new_provider
	gemini_key = new_gemini_key
	claude_key = new_claude_key
	deepseek_key = new_deepseek_key
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("AI", "provider", provider)
	config.set_value("AI", "gemini_key", gemini_key)
	config.set_value("AI", "claude_key", claude_key)
	config.set_value("AI", "deepseek_key", deepseek_key)
	config.erase_section_key("AI", "api_key")
	config.save("user://settings.cfg")


func _active_key() -> String:
	match provider:
		Provider.GEMINI: return gemini_key
		Provider.CLAUDE: return claude_key
		Provider.DEEPSEEK: return deepseek_key
	return ""


func _load_fallback_data() -> void:
	var path := "res://resources/fallback_narratives.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("AIManager: fallback JSON parse error")
		return
	var res = json.data
	if res is Dictionary:
		_fallback_data = res


func consult(hexagram: Dictionary, category: String, action_name: String, stats: Dictionary, recent_summary: String) -> void:
	_pending_category = _normalize_category_key(category)
	_pending_action_name = action_name
	_pending_hex_id = int(hexagram.get("id", GameState.current_hexagram_id))

	var key := _active_key()
	if key.is_empty():
		_finish_with_fallback("未配置 API Key，使用本地兜底叙事。")
		return

	var user_message := _build_user_message(hexagram, _pending_category, action_name, stats, recent_summary)
	var url: String
	var headers: PackedStringArray
	var body: Dictionary

	if provider == Provider.GEMINI:
		url = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s" % [GEMINI_MODEL, key]
		headers = ["Content-Type: application/json"]
		body = {
			"system_instruction": {"parts": [{"text": SYSTEM_PROMPT}]},
			"contents": [{"role": "user", "parts": [{"text": user_message}]}],
			"generationConfig": {
				"temperature": 1.0,
				"maxOutputTokens": MAX_TOKENS,
				"responseMimeType": "application/json"
			}
		}
	elif provider == Provider.CLAUDE:
		url = "https://api.anthropic.com/v1/messages"
		headers = [
			"Content-Type: application/json",
			"x-api-key: " + key,
			"anthropic-version: 2023-06-01"
		]
		body = {
			"model": CLAUDE_MODEL,
			"max_tokens": MAX_TOKENS,
			"temperature": 1.0,
			"system": SYSTEM_PROMPT,
			"messages": [{"role": "user", "content": user_message}]
		}
	else:  # DEEPSEEK
		url = "https://api.deepseek.com/v1/chat/completions"
		headers = [
			"Content-Type: application/json",
			"Authorization: Bearer " + key
		]
		body = {
			"model": DEEPSEEK_MODEL,
			"max_tokens": MAX_TOKENS,
			"temperature": 1.0,
			"response_format": {"type": "json_object"},
			"messages": [
				{"role": "system", "content": SYSTEM_PROMPT},
				{"role": "user", "content": user_message}
			]
		}

	_timeout_timer.start()
	var err := _http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_timeout_timer.stop()
		push_error("AIManager: HTTP request failed to start: %s" % err)
		_finish_with_fallback("无法发起网络请求，已切换兜底。")


func _build_user_message(hexagram: Dictionary, category: String, action_name: String, stats: Dictionary, recent_summary: String) -> String:
	var name_zh := str(hexagram.get("name_zh", hexagram.get("name", "")))
	var hid := int(hexagram.get("id", 0))
	var nature := str(hexagram.get("nature", ""))
	var summ := recent_summary.strip_edges()
	if summ.is_empty():
		summ = "（无）"
	return """当前卦象：%s (卦号: %d)，卦性：%s
当前三才：国力 %d / 民心 %d / 资财 %d
玩家行动：%s → %s
历史背景：%s""" % [
		name_zh, hid, nature,
		int(stats.get("strength", 50)),
		int(stats.get("morale", 50)),
		int(stats.get("treasury", 50)),
		category, action_name,
		summ
	]


func _normalize_category_key(cat: String) -> String:
	var c := cat.strip_edges().to_lower()
	match c:
		"attack", "攻击":
			return "attack"
		"defense", "defend", "防御":
			return "defense"
		"scheme", "plot", "计谋":
			return "scheme"
		"diplomacy", "peace", "和谈":
			return "diplomacy"
		_:
			return "attack"


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_timeout_timer.stop()
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		var body_str := body.get_string_from_utf8()
		push_warning("AIManager: API HTTP error result=%s code=%s body=%s" % [result, response_code, body_str])
		_finish_with_fallback("网络或 API 错误，已切换兜底。")
		return

	var response_str := body.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(response_str) != OK:
		_finish_with_fallback("无法解析 API 外层 JSON。")
		return
	var data = json.data

	var text: String = ""
	if provider == Provider.GEMINI:
		# Gemini: candidates -> content -> parts -> text
		if not (data is Dictionary) or not data.has("candidates") or data["candidates"].is_empty():
			_finish_with_fallback("Gemini 响应结构异常（缺失 candidates）。")
			return
		var cand = data["candidates"][0]
		if not cand.has("content") or cand["content"]["parts"].is_empty():
			_finish_with_fallback("Gemini 响应内容缺失。")
			return
		text = str(cand["content"]["parts"][0].get("text", ""))
	elif provider == Provider.CLAUDE:
		# Claude: content -> [0] -> text
		if not (data is Dictionary) or not data.has("content") or data["content"].is_empty():
			var err_msg: String = str(data.get("error", {}).get("message", "")) if data is Dictionary else ""
			push_warning("AIManager: Claude 响应异常 msg=%s" % err_msg)
			_finish_with_fallback("Claude 响应结构异常。")
			return
		var first_block = data["content"][0]
		if not (first_block is Dictionary) or first_block.get("type", "") != "text":
			_finish_with_fallback("Claude 响应内容块类型非 text。")
			return
		text = str(first_block.get("text", ""))
	else:
		# DeepSeek (OpenAI 兼容): choices -> [0] -> message -> content
		if not (data is Dictionary) or not data.has("choices") or data["choices"].is_empty():
			var err_msg: String = str(data.get("error", {}).get("message", "")) if data is Dictionary else ""
			push_warning("AIManager: DeepSeek 响应异常 msg=%s" % err_msg)
			_finish_with_fallback("DeepSeek 响应结构异常。")
			return
		text = str(data["choices"][0].get("message", {}).get("content", ""))

	_try_emit_from_ai_text(text)


func _try_emit_from_ai_text(raw_text: String) -> void:
	var regex := RegEx.new()
	regex.compile("\\{[\\s\\S]*\\}")
	var regex_match := regex.search(raw_text)
	if regex_match == null:
		_finish_with_fallback("响应中未找到 JSON 对象。")
		return
	var json_str := regex_match.get_string()
	var json := JSON.new()
	if json.parse(json_str) != OK or not (json.data is Dictionary):
		_finish_with_fallback("JSON 解析失败。")
		return
	var normalized := AIResponseParser.normalize(json.data)
	consult_completed.emit(normalized)


func _on_request_timeout() -> void:
	_http_request.cancel_request()
	_finish_with_fallback("请求超过 30 秒，已切换兜底。")


func _finish_with_fallback(reason: String) -> void:
	consult_failed.emit(reason)
	var raw := _pick_fallback_entry(_pending_hex_id, _pending_category)
	var normalized := AIResponseParser.normalize(raw)
	fallback_activated.emit(normalized)
	consult_completed.emit(normalized)


func _pick_fallback_entry(hex_id: int, category: String) -> Dictionary:
	var hex_str := str(hex_id)
	var cat := _normalize_category_key(category)

	var hexes: Variant = _fallback_data.get("hexagrams", null)
	if hexes is Dictionary:
		var bucket: Variant = hexes.get(hex_str, {})
		if bucket is Dictionary:
			var list: Variant = bucket.get(cat, [])
			if list is Array and list.size() > 0:
				var pick: Variant = list[randi() % list.size()]
				if pick is Dictionary:
					return pick
			for k in bucket.keys():
				var alt: Variant = bucket[k]
				if alt is Array and alt.size() > 0:
					var item: Variant = alt[randi() % alt.size()]
					if item is Dictionary:
						return item

	var legacy: Variant = _fallback_data.get(hex_str, [])
	if legacy is Array and legacy.size() > 0:
		var it: Variant = legacy[randi() % legacy.size()]
		if it is Dictionary:
			return it

	return _synthetic_fallback(hex_id, cat)


func _synthetic_fallback(_hex_id: int, category: String) -> Dictionary:
	var y := AIResponseParser.random_yao()
	var ds := {"strength": 0, "morale": 0, "treasury": 0}
	var analysis_text := ""
	match category:
		"attack":
			ds = {"strength": 6, "morale": 2, "treasury": -4}
			analysis_text = "【情境背景】当前卦象示以进取之机，军心可用，出兵攻伐合乎时势。【选择后果】攻势奏效，国力与士气皆有提振，然征战消耗粮草辎重，财政压力有所加剧。【因果推演】强攻以刚克刚，短期收效显著，然持续用兵须防后勤断绝；胜势之中尤需警惕骄兵之失。【卦爻解析】动爻示变，卦象由刚转柔，提示胜而知止，适时收兵整顿，方能保全既得之利，为下一回合蓄力。【卦象演变】动爻触发阴阳易位，强攻所造成的资财损耗与锐气消减，推动卦象向更需谨慎行事的格局演变。因果与爻变共同指向：新卦预示下一阶段宜收敛锋芒、整顿内部，切忌盲目扩大战果，以免在敌方反扑时陷入被动。"
		"defense":
			ds = {"strength": 2, "morale": 4, "treasury": -2}
			analysis_text = "【情境背景】当前卦象主守，敌势方盛，以坚壁应之乃顺时之举，切忌轻易出战。【选择后果】守御稳固，敌攻受挫，士气逐渐回升，然日常守备消耗物资，财政仍有小额亏损。【因果推演】以逸待劳、消耗敌方锐气，是守势最大的战略红利。守而不乱，可令敌失去耐心而主动撤退或寻求和谈。【卦爻解析】动爻居守位，象征静中生变。此刻当厚积实力，待卦象转机之时主动出击，守终非目的，进方为归宿。【卦象演变】守御令阴阳力量重新平衡，民心回升与实力积蓄推动卦象向蓄势待发的格局演进。因果与爻变共同揭示：新卦预示我方已完成由弱转强的内在积累，下一阶段将出现可以主动出击的窗口，需保持警觉，把握转机。"
		"scheme":
			ds = {"strength": 3, "morale": -2, "treasury": 1}
			analysis_text = "【情境背景】当前卦象隐含谋略之机，以正面交锋不如以奇谋制敌，可借势而为，四两拨千斤。【选择后果】计谋施展令敌方阵脚大乱，国力小有斩获，然诡道行事难以服众，部分士卒心存疑虑，士气略降。【因果推演】谋略成功依赖信息优势与敌方内部弱点，二者缺一则效果大打折扣；且诡道易引发反制，须防敌方以牙还牙。【卦爻解析】动爻示奇变之机，提示谋略需与实力相辅，单纯依赖奇计而忽视正兵，终难持久。宜以此番胜势充实正面力量。【卦象演变】谋略导致的士气分化与格局重构，触发了爻变，令卦象转向需要重建内部凝聚力的方向。因果推演与爻变共同说明：新卦预示下一阶段须以诚信正道弥合因诡谋而产生的内部裂痕，以正兵为主、奇谋为辅，才能将谋略之利转化为持续的战略优势。"
		"diplomacy":
			ds = {"strength": -2, "morale": 3, "treasury": 2}
			analysis_text = "【情境背景】当前卦象有柔顺周旋之象，外交斡旋正当其时，可借谈判化解眼前危局，积蓄恢复元气。【选择后果】和谈达成，边境暂息，百姓得以安居，民心回暖，互市贸易亦带动财政小有盈余，然军事姿态有所收缩。【因果推演】以和换时，令我方获得整军备战的窗口期；然对方同样借机休养，须警惕和平之后的新一轮冲突。【卦爻解析】动爻示柔中有韧，外交折冲非软弱，而是蓄势之道。提示：谈判成果须有实力背书，切勿在和平期荒废军政，以免被对方视为可欺之弱国。【卦象演变】和谈带来的民心聚合与资财积累，使阴阳趋于平衡，推动卦象向更具包容与主动性的格局演变。因果与爻变合力指向：新卦预示和平期是充实内政、积蓄力量的黄金窗口，须抓紧在对方重整之前完成军政改革，以备下一轮博弈时握有更强底牌。"
		_:
			analysis_text = "【情境背景】局势纷繁，卦象变幻，一时难以明辨吉凶。【选择后果】行动已出，结果尚待观察，各方数据微有波动。【因果推演】动静之间，因果难以完全预料，宜审时度势，随机应变。【卦爻解析】动爻示变，提醒凡事不可固执一端，顺势而为、随时调整方为上策。【卦象演变】爻变牵动卦象流转，旧势已去，新局将开。因果与爻变共同昭示：无论新卦为何，皆是天道运行的自然结果，宜放下成见，以开放之心迎接下一阶段的挑战与机遇。"
	return {
		"narrative": "军中传令既出，诸营整备，或进或止，唯待天时。卦象流转，局势微妙，宜慎之又慎。",
		"yao_changed": y,
		"delta_stats": ds,
		"philosophy": "知进退存亡而不失其正者，其惟圣人乎。",
		"analysis": analysis_text,
	}
