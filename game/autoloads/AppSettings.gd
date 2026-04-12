extends Node

## FR-10 与全局演出倍率（动画快速模式等）

signal settings_changed

var animation_fast: bool = false
var text_speed: int = 3
var bgm_volume: int = 70
var sfx_volume: int = 80
var fullscreen: bool = false


func _ready() -> void:
	load_all()


func load_all() -> void:
	var c := ConfigFile.new()
	if c.load("user://settings.cfg") != OK:
		return
	animation_fast = bool(c.get_value("display", "animation_fast", false))
	text_speed = int(c.get_value("display", "text_speed", 3))
	bgm_volume = int(c.get_value("audio", "bgm_volume", 70))
	sfx_volume = int(c.get_value("audio", "sfx_volume", 80))
	fullscreen = bool(c.get_value("display", "fullscreen", false))
	_apply_window_mode()


func save_from_controls(anim_fast: bool, t_speed: int, bgm: int, sfx: int, fs: bool) -> void:
	animation_fast = anim_fast
	text_speed = clampi(t_speed, 1, 5)
	bgm_volume = clampi(bgm, 0, 100)
	sfx_volume = clampi(sfx, 0, 100)
	fullscreen = fs
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://settings.cfg"):
		c.load("user://settings.cfg")
	c.set_value("display", "animation_fast", animation_fast)
	c.set_value("display", "text_speed", text_speed)
	c.set_value("display", "fullscreen", fullscreen)
	c.set_value("audio", "bgm_volume", bgm_volume)
	c.set_value("audio", "sfx_volume", sfx_volume)
	c.save("user://settings.cfg")
	_apply_window_mode()
	settings_changed.emit()


func get_anim_speed_mult() -> float:
	return 0.5 if animation_fast else 1.0


func get_typewriter_char_seconds() -> float:
	## text_speed 1~5 → 每字耗时递减
	return lerpf(0.12, 0.03, float(text_speed - 1) / 4.0)


func _apply_window_mode() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
