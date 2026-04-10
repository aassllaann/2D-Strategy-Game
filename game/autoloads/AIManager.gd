extends Node

signal consult_completed(result: Dictionary)
signal consult_failed(error_msg: String)
signal fallback_activated(fallback_result: Dictionary)

const SYSTEM_PROMPT: String = """You are the I Ching Grand Strategy Game AI. 
The player provides an Action under a specific Hexagram and Game State.
You must return only JSON describing the Narrative and State Deltas.
Max limits: Strength +10 to -10, etc."""

var api_key: String = ""
var _http_request: HTTPRequest = null
var _timeout_timer: Timer = null
var _fallback_data: Dictionary = {}

func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	
	_timeout_timer = Timer.new()
	_timeout_timer.one_shot = true
	_timeout_timer.wait_time = 8.0
	add_child(_timeout_timer)
	_timeout_timer.timeout.connect(_on_request_timeout)
	
	_load_settings()
	_load_fallback_data()

func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		api_key = config.get_value("AI", "api_key", "")

func save_settings(new_key: String) -> void:
	api_key = new_key
	var config = ConfigFile.new()
	config.set_value("AI", "api_key", api_key)
	config.save("user://settings.cfg")


func _load_fallback_data() -> void:
	var path := "res://resources/fallback_narratives.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var content := file.get_as_text()
		var json := JSON.new()
		if json.parse(content) == OK:
			var res = json.data
			if res is Dictionary:
				_fallback_data = res

func consult(hexagram: Dictionary, action: String, stats: Dictionary) -> void:
	# If no API key, use fallback
	if api_key.is_empty():
		_use_fallback(str(hexagram.get("id", "1")), action)
		return
		
	var url := "https://api.anthropic.com/v1/messages"
	var headers := [
		"Content-Type: application/json",
		"x-api-key: " + api_key,
		"anthropic-version: 2023-06-01"
	]
	
	var user_message := "Hexagram: %s\nAction: %s\nStats: Strength %d, Morale %d, Treasury %d" % [
		hexagram.get("name", ""), action, stats.get("strength", 50), stats.get("morale", 50), stats.get("treasury", 50)
	]
	
	var body := {
		"model": "claude-3-haiku-20240307",
		"max_tokens": 500,
		"system": SYSTEM_PROMPT,
		"messages": [
			{"role": "user", "content": user_message}
		]
	}
	
	_timeout_timer.start()
	var err := _http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_timeout_timer.stop()
		consult_failed.emit("Failed to send HTTP request")

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_timeout_timer.stop()
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_use_fallback(str(GameState.current_hexagram_id), "Network/API Error")
		return
		
	var response_str := body.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(response_str) == OK:
		var data = json.data
		if data is Dictionary and data.has("content") and data["content"].size() > 0:
			var text: String = data["content"][0]["text"]
			_parse_ai_response(text)
		else:
			consult_failed.emit("Invalid API response structure.")
	else:
		consult_failed.emit("Failed to parse API JSON.")

func _parse_ai_response(raw_text: String) -> void:
	# Regex to extract JSON block from markdown ```json\n...\n```
	var regex := RegEx.new()
	regex.compile("\\{[\\s\\S]*\\}")
	var regex_match := regex.search(raw_text)
	if regex_match:
		var json_str := regex_match.get_string()
		var json := JSON.new()
		if json.parse(json_str) == OK and json.data is Dictionary:
			consult_completed.emit(json.data)
			return
			
	consult_failed.emit("Could not extract valid JSON from AI response")

func _on_request_timeout() -> void:
	_http_request.cancel_request()
	_use_fallback(str(GameState.current_hexagram_id), "Timeout")

func _use_fallback(hex_id: String, action: String) -> void:
	var fallback_list = _fallback_data.get(hex_id, [])
	var chosen: Dictionary
	if fallback_list.size() > 0:
		chosen = fallback_list[0] # Just pick first for MVP fallback
	else:
		chosen = {
			"Narrative": "Fallback narrative: The heavens are silent. You proceed with caution.",
			"Next_Yao_Index": 1,
			"State_Changes": {"strength": 0, "morale": -5, "treasury": 0}
		}
	
	await get_tree().create_timer(1.0).timeout # Fake delay
	fallback_activated.emit(chosen)
	consult_completed.emit(chosen)
