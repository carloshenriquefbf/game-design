extends Node


enum GameState { PLAYING, VICTORY, DEFEAT }

var state: GameState = GameState.PLAYING


func _ready() -> void:
	EventBus.player_captured.connect(trigger_defeat)


func restart_level() -> void:
	SuspicionManager.reset()
	state = GameState.PLAYING
	get_tree().paused = false
	get_tree().reload_current_scene()


func trigger_victory() -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.VICTORY
	print("[level] complete (next stage placeholder)")
	get_tree().paused = true
	EventBus.level_completed.emit()


func trigger_defeat(guard: Node2D = null) -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.DEFEAT
	print("[game over] captured by ", guard)
	get_tree().paused = true
