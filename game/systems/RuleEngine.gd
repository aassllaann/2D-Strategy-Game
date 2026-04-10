class_name RuleEngine extends RefCounted

## Determines the next hexagram ID based on current hexagram and yao index changes.
## Relies on the database having `yao_rules` per hexagram.
## yao_index is 1-indexed (1 to 6)

static func get_next_hexagram(current_id: int, yao_index: int) -> int:
	var hex_data := DatabaseManager.get_hexagram(current_id)
	if hex_data.is_empty() or not hex_data.has("yao_rules"):
		push_error("RuleEngine: current hexagram %d has no yao_rules" % current_id)
		return 1 # Fallback to 1 (Qian)
		
	var rules_dict: Dictionary = hex_data["yao_rules"]
	var str_index := str(yao_index)
	if rules_dict.has(str_index):
		var target = rules_dict[str_index]
		if typeof(target) == TYPE_INT or typeof(target) == TYPE_FLOAT:
			return int(target)
		elif typeof(target) == TYPE_STRING:
			return int(target)
		
	push_warning("RuleEngine: yao_index %d not found in rules for %d. Returning current." % [yao_index, current_id])
	return current_id
