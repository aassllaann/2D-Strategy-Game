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
		_apply_audio()   # 用默认值初始化总线
		return
	animation_fast = bool(c.get_value("display", "animation_fast", false))
	text_speed = int(c.get_value("display", "text_speed", 3))
	bgm_volume = int(c.get_value("audio", "bgm_volume", 70))
	sfx_volume = int(c.get_value("audio", "sfx_volume", 80))
	fullscreen = bool(c.get_value("display", "fullscreen", false))
	_apply_window_mode()
	_apply_audio()


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
	_apply_audio()
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


## 将 0–100 音量线性值写入 AudioServer 对应总线
func _apply_audio() -> void:
	_ensure_bus("BGM")
	_ensure_bus("SFX")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), _vol_to_db(bgm_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _vol_to_db(sfx_volume))


## 若总线不存在则动态创建并挂到 Master
func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


## 线性 0–100 → dB（0 → -80 dB 静音，100 → 0 dB 满音量）
func _vol_to_db(v: int) -> float:
	if v <= 0:
		return -80.0
	return linear_to_db(v / 100.0)
