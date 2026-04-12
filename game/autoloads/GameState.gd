extends Node

signal stats_changed(stats: Dictionary)
signal hexagram_changed(id: int)
signal turn_advanced(turn_index: int)

var strength: int = 60
var morale: int = 55
var treasury: int = 50

var current_turn: int = 1
var max_turns: int = 25
var current_hexagram_id: int = 1

## Last up to 10 turn summaries for AI payload (FR-08 历史背景)
var narrative_history: Array = []

## 9.3 连续同爻记录（不含本回合将要写入的爻）
var _yao_history: Array = []

## 10.1 功败垂成：上一回合国力变化量
var last_strength_delta: int = 0

## 10.2 连贯性奖励：是否曾进入危机（任一 < 30）
var ever_in_crisis: bool = false

## FR-09 / FR-11
var flags: Dictionary = {
	"tutorial_completed": false,
	"first_crisis_triggered": false
}

## 结局场景展示用（由 EndingRouter 写入）
var last_ending_type: int = 0
var last_score: int = 0
var last_grade: String = ""

const BANNED_START_HEX_IDS: Array = [29, 47]

func _ready() -> void:
	pass


func get_recent_narrative_summary(max_len: int = 50) -> String:
	if narrative_history.is_empty():
		return ""
	var parts: PackedStringArray = PackedStringArray()
	var take := mini(2, narrative_history.size())
	var start_idx := narrative_history.size() - take
	for i in range(start_idx, narrative_history.size()):
		var entry: Variant = narrative_history[i]
		if entry is Dictionary:
			var t: String = str(entry.get("narrative", "")).strip_edges()
			if not t.is_empty():
				parts.append(t)
	if parts.is_empty():
		return ""
	var joined := "；".join(parts)
	if joined.length() > max_len:
		return joined.substr(0, max_len) + "…"
	return joined


func record_narrative_turn(narrative: String, category: String, action_name: String) -> void:
	narrative_history.append({
		"round": current_turn,
		"narrative": narrative,
		"category": category,
		"action": action_name
	})
	while narrative_history.size() > 10:
		narrative_history.pop_front()

func apply_delta(delta: Dictionary) -> void:
	if delta.has("strength"):
		strength = clampi(strength + int(delta["strength"]), 0, 100)
	if delta.has("morale"):
		morale = clampi(morale + int(delta["morale"]), 0, 100)
	if delta.has("treasury"):
		treasury = clampi(treasury + int(delta["treasury"]), 0, 100)

	if strength < 30 or morale < 30 or treasury < 30:
		ever_in_crisis = true

	stats_changed.emit({
		"strength": strength,
		"morale": morale,
		"treasury": treasury
	})


func apply_turn_deltas(delta: Dictionary, yao_hint: int) -> int:
	var pre_s := strength
	var pre_m := morale
	var pre_t := treasury
	var d: Dictionary = AIResponseParser.parse_delta_stats(delta)
	var y: int = clampi(yao_hint, 1, 6)
	y = _enforce_yao_variety(y)
	if pre_s < 30 or pre_m < 30 or pre_t < 30:
		d = _scale_deltas_crisis(d)
	if pre_s < 25 and int(d.get("strength", 0)) < -10:
		d["strength"] = -10

	apply_delta(d)
	last_strength_delta = int(d.get("strength", 0))

	_yao_history.append(y)
	if _yao_history.size() > 3:
		_yao_history.pop_front()

	_apply_passive_linkage()
	return y


func _scale_deltas_crisis(d: Dictionary) -> Dictionary:
	var out := d.duplicate()
	for k in ["strength", "morale", "treasury"]:
		var v: int = int(out.get(k, 0))
		var sgn := 1 if v > 0 else (-1 if v < 0 else 0)
		var av := absi(v)
		out[k] = clampi(int(floor(av * 1.5)) * sgn, AIResponseParser.STAT_MIN, AIResponseParser.STAT_MAX)
	return out


func _enforce_yao_variety(y: int) -> int:
	if _yao_history.size() < 3:
		return y
	var a: int = int(_yao_history[_yao_history.size() - 3])
	var b: int = int(_yao_history[_yao_history.size() - 2])
	var c: int = int(_yao_history[_yao_history.size() - 1])
	if a == b and b == c and c == y:
		var banned: int = c
		for alt in range(1, 7):
			if alt != banned:
				return alt
	return y


func _apply_passive_linkage() -> void:
	var changed := false
	if morale < 30:
		var nt := clampi(treasury - 3, 0, 100)
		if nt != treasury:
			treasury = nt
			changed = true
	if treasury < 30:
		var ns := clampi(strength - 2, 0, 100)
		if ns != strength:
			strength = ns
			changed = true
	if changed:
		if strength < 30 or morale < 30 or treasury < 30:
			ever_in_crisis = true
		stats_changed.emit({
			"strength": strength,
			"morale": morale,
			"treasury": treasury
		})

func set_hexagram(new_id: int) -> void:
	current_hexagram_id = new_id
	hexagram_changed.emit(new_id)

func advance_turn() -> void:
	if current_turn < max_turns:
		current_turn += 1
		turn_advanced.emit(current_turn)
	
func reset_game() -> void:
	_reset_run_state()
	set_hexagram(1)
	stats_changed.emit({
		"strength": strength,
		"morale": morale,
		"treasury": treasury
	})


func start_new_run() -> void:
	_reset_run_state()
	var ids: Array = DatabaseManager.get_all_ids()
	var pick := 1
	if not ids.is_empty():
		for _i in range(64):
			var cand: int = int(ids[randi() % ids.size()])
			if cand in BANNED_START_HEX_IDS:
				continue
			pick = cand
			break
	set_hexagram(pick)
	stats_changed.emit({
		"strength": strength,
		"morale": morale,
		"treasury": treasury
	})


func get_yao_history_copy() -> Array:
	return _yao_history.duplicate()


func apply_save_dict(d: Dictionary) -> void:
	current_turn = int(d.get("current_round", 1))
	max_turns = int(d.get("max_rounds", 25))
	var st: Variant = d.get("stats", {})
	if st is Dictionary:
		strength = clampi(int(st.get("strength", 60)), 0, 100)
		morale = clampi(int(st.get("morale", 55)), 0, 100)
		treasury = clampi(int(st.get("treasury", 50)), 0, 100)
	narrative_history.clear()
	var hist: Variant = d.get("history", [])
	if hist is Array:
		for item in hist:
			narrative_history.append(item)
	flags = {}
	var fg: Variant = d.get("flags", {})
	if fg is Dictionary:
		flags = fg.duplicate(true)
	ever_in_crisis = bool(d.get("ever_in_crisis", false))
	_yao_history.clear()
	var yh: Variant = d.get("yao_history", [])
	if yh is Array:
		for y in yh:
			_yao_history.append(int(y))
	set_hexagram(int(d.get("current_hexagram_id", 1)))
	stats_changed.emit({
		"strength": strength,
		"morale": morale,
		"treasury": treasury
	})
	turn_advanced.emit(current_turn)


func _reset_run_state() -> void:
	strength = 60
	morale = 55
	treasury = 50
	current_turn = 1
	narrative_history.clear()
	_yao_history.clear()
	last_strength_delta = 0
	ever_in_crisis = false
	flags = {
		"tutorial_completed": false,
		"first_crisis_triggered": false
	}
	last_ending_type = 0
	last_score = 0
	last_grade = ""
	turn_advanced.emit(current_turn)
