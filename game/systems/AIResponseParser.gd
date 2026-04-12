class_name AIResponseParser extends RefCounted

## Normalizes AI / fallback payloads to PRD FR-08 shape:
## narrative, yao_changed (1-6), delta_stats {strength,morale,treasury}, philosophy, next_hexagram_hint?

const STAT_MIN := -20
const STAT_MAX := 20

static func random_yao() -> int:
	return randi_range(1, 6)


static func clamp_stat_delta(v: Variant) -> int:
	var n := int(v) if v != null else 0
	return clampi(n, STAT_MIN, STAT_MAX)


static func parse_delta_stats(raw: Variant) -> Dictionary:
	var out := {"strength": 0, "morale": 0, "treasury": 0}
	if raw == null or not (raw is Dictionary):
		return out
	var d: Dictionary = raw
	var keys := [
		["strength", "strength", "Strength"],
		["morale", "morale", "Morale"],
		["treasury", "treasury", "Treasury"],
	]
	for triple in keys:
		var k: String = triple[0]
		for alias in triple:
			if d.has(alias):
				out[k] = clamp_stat_delta(d[alias])
				break
	return out


## Accepts PRD keys or legacy keys (Narrative, Next_Yao_Index, State_Changes).
static func normalize(raw: Dictionary) -> Dictionary:
	var narrative := str(
		raw.get("narrative", raw.get("Narrative", ""))
	).strip_edges()
	if narrative.is_empty():
		narrative = "天机晦冥，军中暂且按兵不动，静观其变。"

	var yv: Variant = raw.get("yao_changed", raw.get("Next_Yao_Index", raw.get("next_yao", 1)))
	var yao_changed := int(yv)
	if yao_changed < 1 or yao_changed > 6:
		yao_changed = random_yao()

	var delta_stats := parse_delta_stats(raw.get("delta_stats", raw.get("State_Changes", {})))

	var philosophy := str(
		raw.get("philosophy", raw.get("Philosophy", ""))
	).strip_edges()
	if philosophy.is_empty():
		philosophy = "刚柔相推，变在其中。"

	var hint := ""
	if raw.has("next_hexagram_hint"):
		hint = str(raw["next_hexagram_hint"]).strip_edges()

	var analysis := str(
		raw.get("analysis", raw.get("Analysis", ""))
	).strip_edges()

	return {
		"narrative": narrative,
		"yao_changed": yao_changed,
		"delta_stats": delta_stats,
		"philosophy": philosophy,
		"next_hexagram_hint": hint,
		"analysis": analysis,
	}
