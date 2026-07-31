extends CanvasLayer
## Reusable scene-switching autoload. Other systems call goto_scene(path)
## instead of touching get_tree().change_scene_to_file() directly, so every
## transition gets the same fade and stays in one place to extend later.

@export var fade_duration: float = 0.25

var _fade_rect: ColorRect
var _busy: bool = false


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.modulate.a = 0.0
	add_child(_fade_rect)


func goto_scene(path: String) -> void:
	if _busy:
		return
	_busy = true

	await _fade(1.0)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await _fade(0.0)

	_busy = false


func _fade(target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", target_alpha, fade_duration)
	await tween.finished
