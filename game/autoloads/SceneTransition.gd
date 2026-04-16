extends CanvasLayer

var _overlay: ColorRect
var _is_transitioning := false


func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


## 淡出→换场→淡入。duration 单位秒，默认 0.4s。
func change_scene(path: String, duration: float = 0.4) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var tw := create_tween()
	tw.tween_property(_overlay, "color:a", 1.0, duration)
	await tw.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	var tw2 := create_tween()
	tw2.tween_property(_overlay, "color:a", 0.0, duration)
	await tw2.finished

	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
