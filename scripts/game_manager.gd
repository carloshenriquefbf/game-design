extends Node


enum GameState { PLAYING, VICTORY, DEFEAT }

var state: GameState = GameState.PLAYING


func restart_level() -> void:
	state = GameState.PLAYING
	get_tree().reload_current_scene()


func trigger_victory() -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.VICTORY
	EventBus.level_completed.emit()


func trigger_defeat(guard: Node2D = null) -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.DEFEAT
	EventBus.player_captured.emit(guard)
