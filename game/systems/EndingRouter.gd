class_name EndingRouter extends RefCounted

## PRD 第 10 节：六结局优先级

enum EndingType {
	NONE = 0,
	## 国脉断绝
	DEFEAT_STRENGTH = 1,
	## 兵乱哗变
	DEFEAT_MORALE = 2,
	## 民生凋敝
	DEFEAT_TREASURY = 3,
	## 功败垂成
	DEFEAT_LATE_COLLAPSE = 4,
	## 偏安一隅
	WIN_PARTIAL = 5,
	## 天下一统
	WIN_TOTAL = 6,
	## 第25回合未达胜利线时的收束
	ENDING_STALE = 7
}


static func check_ending() -> int:
	## 即时败局（最高优先）
	if GameState.strength < 20:
		_arm_score_for_defeat()
		return EndingType.DEFEAT_STRENGTH
	if GameState.morale < 15:
		_arm_score_for_defeat()
		return EndingType.DEFEAT_MORALE
	if GameState.treasury < 10:
		_arm_score_for_defeat()
		return EndingType.DEFEAT_TREASURY

	## 第21~25回合单回合国力暴跌
	if GameState.current_turn >= 21 and GameState.current_turn <= GameState.max_turns:
		if GameState.last_strength_delta < -15:
			_arm_score_for_defeat()
			return EndingType.DEFEAT_LATE_COLLAPSE

	## 第25回合收束
	if GameState.current_turn >= GameState.max_turns:
		if GameState.strength > 60 and GameState.morale > 60 and GameState.treasury > 60:
			_arm_score_for_win(true)
			return EndingType.WIN_TOTAL
		if GameState.strength >= 40 and GameState.strength <= 59 and GameState.morale >= 30 and GameState.treasury >= 30:
			_arm_score_for_win(false)
			return EndingType.WIN_PARTIAL
		_arm_score_for_defeat()
		return EndingType.ENDING_STALE

	return EndingType.NONE


static func _arm_score_for_defeat() -> void:
	var sc := ScoreCalculator.compute_score()
	GameState.last_score = mini(sc, 999)
	GameState.last_grade = "D"


static func _arm_score_for_win(best: bool) -> void:
	var sc := ScoreCalculator.compute_score()
	if not best:
		sc = mini(sc, 4800)
	GameState.last_score = sc
	GameState.last_grade = ScoreCalculator.grade_for(sc)


static func get_ending_scene_path(ending_type: int) -> String:
	if ending_type == EndingType.NONE:
		return ""
	return "res://scenes/Ending.tscn"


static func get_title_for(ending_type: int) -> String:
	match ending_type:
		EndingType.DEFEAT_STRENGTH:
			return "国脉断绝"
		EndingType.DEFEAT_MORALE:
			return "兵乱哗变"
		EndingType.DEFEAT_TREASURY:
			return "民生凋敝"
		EndingType.DEFEAT_LATE_COLLAPSE:
			return "功败垂成"
		EndingType.WIN_PARTIAL:
			return "偏安一隅"
		EndingType.WIN_TOTAL:
			return "天下一统"
		EndingType.ENDING_STALE:
			return "气数难续"
		_:
			return "未定之天"
