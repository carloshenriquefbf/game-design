extends Node
## Tracks stage progression (corridor -> kitchen -> garden) and which
## levels are unlocked for level-select. Progression is fully linear:
## GameManager drives advance_to_next_stage() on exit, nothing here
## touches scenes directly.

const STAGE_SCENES: Array[String] = [
	"res://scenes/1_tower.tscn", # corridor
	"res://scenes/2_kitchen.tscn", # kitchen
	"res://scenes/1_tower.tscn", # garden (placeholder until its scene lands)
]

var current_stage_index: int = 0
var total_stage_count: int = STAGE_SCENES.size()

var _unlocked_levels: Dictionary = {}


func unlock_level(id: int) -> void:
	_unlocked_levels[id] = true


func is_level_unlocked(id: int) -> bool:
	return _unlocked_levels.get(id, false)


func is_last_stage() -> bool:
	return current_stage_index >= total_stage_count - 1


func advance_to_next_stage() -> void:
	if is_last_stage():
		return
	current_stage_index += 1


func get_current_stage_path() -> String:
	return STAGE_SCENES[current_stage_index]
