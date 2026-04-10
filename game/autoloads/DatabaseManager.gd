extends Node

signal db_loaded

var _hexagrams: Dictionary = {}

func _ready() -> void:
	_load_database()

func _load_database() -> void:
	var path_to_json: String = "res://hexagrams.json"
	if not FileAccess.file_exists(path_to_json):
		push_error("Cannot find hexagrams.json at %s" % path_to_json)
		return
		
	var file := FileAccess.open(path_to_json, FileAccess.READ)
	var content := file.get_as_text()
	var json := JSON.new()
	var error := json.parse(content)
	
	if error == OK:
		var result = json.data
		if result is Array:
			for item in result:
				if item is Dictionary and item.has("id"):
					_hexagrams[int(item["id"])] = item
		print("DatabaseManager: Loaded ", _hexagrams.size(), " hexagrams.")
		db_loaded.emit()
	else:
		push_error("JSON Parse Error at line %s: %s" % [json.get_error_line(), json.get_error_message()])

func get_hexagram(id: int) -> Dictionary:
	return _hexagrams.get(id, {})

func get_all_ids() -> Array:
	return _hexagrams.keys()
