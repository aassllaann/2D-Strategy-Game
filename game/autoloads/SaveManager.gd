extends Node

const AUTOSAVE_PATH := "user://save/autosave.json"
const MANUAL_PATH := "user://save/manual.json"


func has_autosave() -> bool:
	return FileAccess.file_exists(AUTOSAVE_PATH)


func has_manual() -> bool:
	return FileAccess.file_exists(MANUAL_PATH)


func delete_autosave() -> void:
	if not FileAccess.file_exists(AUTOSAVE_PATH):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(AUTOSAVE_PATH))


func delete_manual() -> void:
	if not FileAccess.file_exists(MANUAL_PATH):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(MANUAL_PATH))


func write_autosave() -> void:
	_write_file(AUTOSAVE_PATH)


func write_manual() -> void:
	_write_file(MANUAL_PATH)


func load_autosave() -> bool:
	return _read_file(AUTOSAVE_PATH)


func load_manual() -> bool:
	return _read_file(MANUAL_PATH)


func _write_file(path: String) -> void:
	var dir := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var data := {
		"version": "1.0",
		"saved_at": Time.get_datetime_string_from_system(true),
		"current_round": GameState.current_turn,
		"max_rounds": GameState.max_turns,
		"current_hexagram_id": GameState.current_hexagram_id,
		"stats": {
			"strength": GameState.strength,
			"morale": GameState.morale,
			"treasury": GameState.treasury
		},
		"history": _trim_history(GameState.narrative_history),
		"flags": GameState.flags.duplicate(true),
		"ever_in_crisis": GameState.ever_in_crisis,
		"yao_history": GameState.get_yao_history_copy(),
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot write %s" % path)
		return
	f.store_string(JSON.stringify(data))


func _trim_history(h: Array) -> Array:
	var out: Array = []
	var start := maxi(0, h.size() - 10)
	for i in range(start, h.size()):
		out.append(h[i])
	return out


func _read_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_warning("SaveManager: corrupt save %s" % path)
		return false
	var d = json.data
	if not d is Dictionary:
		return false
	GameState.apply_save_dict(d)
	return true
