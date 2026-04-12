class_name ScoreCalculator extends RefCounted

## PRD 10.2 评分（结局画面用）


static func hexagram_reward(hex_id: int) -> int:
	var h: Dictionary = DatabaseManager.get_hexagram(hex_id)
	var lines: Variant = h.get("yao_lines", [])
	if not (lines is Array):
		return 200
	var good := 0
	var bad := 0
	for L in lines:
		if not (L is Dictionary):
			continue
		var r: String = str(L.get("rating", ""))
		if r == "吉":
			good += 1
		elif r == "凶":
			bad += 1
	if good >= 3:
		return 500
	if bad >= 3:
		return 0
	return 200


static func compute_score() -> int:
	var gs := GameState
	var base := (gs.strength + gs.morale + gs.treasury) * 10
	var round_bonus := (gs.max_turns - gs.current_turn) * 50
	var hex_bonus := hexagram_reward(gs.current_hexagram_id)
	var coherence := 0 if gs.ever_in_crisis else 300
	return base + round_bonus + hex_bonus + coherence


static func grade_for(score: int) -> String:
	if score >= 5000:
		return "S"
	if score >= 3500:
		return "A"
	if score >= 2000:
		return "B"
	if score >= 1000:
		return "C"
	return "D"
