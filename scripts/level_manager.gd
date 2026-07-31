extends Node


var _unlocked_levels: Dictionary = {}


func unlock_level(id: int) -> void:
	_unlocked_levels[id] = true


func is_level_unlocked(id: int) -> bool:
	return _unlocked_levels.get(id, false)
