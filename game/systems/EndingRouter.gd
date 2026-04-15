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
	var bd := ScoreCalculator.compute_score_breakdown()
	GameState.last_score_breakdown = bd
	GameState.last_score = mini(bd["raw_total"], 999)
	GameState.last_grade = "D"


static func _arm_score_for_win(best: bool) -> void:
	var bd := ScoreCalculator.compute_score_breakdown()
	GameState.last_score_breakdown = bd
	var sc: int = bd["raw_total"]
	if not best:
		sc = mini(sc, 4800)
	GameState.last_score = sc
	GameState.last_grade = ScoreCalculator.grade_for(sc)


static func is_victory(t: int) -> bool:
	return t == EndingType.WIN_PARTIAL or t == EndingType.WIN_TOTAL


static func get_accent_color(t: int) -> Color:
	match t:
		EndingType.WIN_TOTAL:
			return Color("#C9A227")
		EndingType.WIN_PARTIAL:
			return Color("#2E7D6B")
		EndingType.ENDING_STALE:
			return Color("#888888")
		_:
			return Color("#C0392B")


static func get_badge_for(t: int) -> String:
	match t:
		EndingType.WIN_TOTAL:   return "— 天命归一 —"
		EndingType.WIN_PARTIAL: return "— 保境安民 —"
		EndingType.ENDING_STALE: return "— 时运未济 —"
		_:                      return "— 大势已去 —"


static func get_body_for(t: int) -> String:
	match t:
		EndingType.DEFEAT_STRENGTH:
			return "国力耗竭，疆土四分五裂。边陲烽火未熄，腹地已遭侵蚀，王旗所向，无一响应之师。三军哗散，朝堂离心，纵有天命加身，亦难挽此颓势。一代基业，竟殒于一朝之间，史书之上，留下的不过是一页仓惶的败亡记录。"
		EndingType.DEFEAT_MORALE:
			return "军心涣散，哗变之声此起彼伏。士卒弃甲投戈，将帅阴怀异志，令行不止，禁而不绝。民间怨声载道，昔日赖以为根本的人心，已悄然流失殆尽。没有民心，纵有金城汤池，亦不过是空中楼阁，终成一场空。"
		EndingType.DEFEAT_TREASURY:
			return "府库空竭，百业凋零。军需粮秣无以为继，赏赐封爵皆成空文，将士寒心，商贾远遁。天下之事，未有无财而能立业者，枯竭的仓廪敲响了王朝的最后丧钟。钱粮既绝，兵无战心，民无耕意，大厦倾于一旦。"
		EndingType.DEFEAT_LATE_COLLAPSE:
			return "眼看大功垂成，却在最后关头轰然崩塌。二十余载运筹帷幄，一朝之间付诸东流。敌军趁虚而入，国力急转直下，再难挽回。棋至残局，方知一步错则满盘皆输。功败垂成，或许是最令人扼腕的结局。"
		EndingType.WIN_PARTIAL:
			return "天下未能混一，然疆土尚存，百姓得以休养生息。虽非一统之功，然能在乱世保境安民，亦是一方明主之德。史书或不会浓墨重彩地书写这段历史，但那片土地上的炊烟与笑声，终将成为最真实的注脚。"
		EndingType.WIN_TOTAL:
			return "三才俱旺，四海臣服。兵革止息，天下归于一统。国师妙算，运筹帷幄之中，决胜千里之外；诸侯俯首，百姓欢颜，史册将以盛世之名铭记这段传奇。易理深邃，变中有常，此番乾坤拨转，亦是卦象所指引的天命归宿。"
		EndingType.ENDING_STALE:
			return "二十五回合流光飞逝，然大业终未竟。三才勉强维系，却未能突破困局。时运弄人，或许只差一步，或许差之甚远。历史的洪流不因个人意志而停歇，这段未竟的篇章，终将成为一段留有遗憾的记忆。"
		_:
			return "故事告一段落。"


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
