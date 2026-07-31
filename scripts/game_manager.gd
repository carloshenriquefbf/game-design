extends Node


enum GameState { PLAYING, STAGE_COMPLETE, GAME_COMPLETE, DEFEAT }

const DEFEAT_SCREEN_SCENE := "res://scenes/defeat_screen.tscn"
const CREDITS_SCREEN_SCENE := "res://scenes/credits_screen.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

var state: GameState = GameState.PLAYING


func _ready() -> void:
	EventBus.player_captured.connect(trigger_defeat)


func restart_level() -> void:
	SuspicionManager.reset()
	state = GameState.PLAYING
	SceneTransition.goto_scene(LevelManager.get_current_stage_path())


## Called when the exit door confirms all of the current stage's
## objectives are done. Branches on whether this is the last stage: mid-run
## stages get the stage-complete prompt-then-advance behavior, the last
## stage skips straight to the credits with no per-stage victory screen.
func complete_stage() -> void:
	if state != GameState.PLAYING:
		return

	if LevelManager.is_last_stage():
		trigger_game_complete()
		return

	state = GameState.STAGE_COMPLETE
	EventBus.level_completed.emit()
	SuspicionManager.reset()
	LevelManager.advance_to_next_stage()
	await SceneTransition.goto_scene(LevelManager.get_current_stage_path())
	state = GameState.PLAYING


## Called when the last stage's objectives are done and the exit is
## reached. The game is fully complete, so progression resets right away —
## there's nothing left to "continue" toward, and pressing Play from the
## main menu after this should start a brand new run at stage 1.
func trigger_game_complete() -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.GAME_COMPLETE
	EventBus.level_completed.emit()
	LevelManager.current_stage_index = 0
	SceneTransition.goto_scene(CREDITS_SCREEN_SCENE)


func trigger_defeat(guard: Node2D = null) -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.DEFEAT
	print("[game over] captured by ", guard)
	SceneTransition.goto_scene(DEFEAT_SCREEN_SCENE)


## Called after the player confirms they want to abandon the run from the
## DefeatScreen. Wipes stage progression and suspicion so the next "Jogar"
## from the main menu starts a completely fresh run.
func quit_to_main_menu() -> void:
	SuspicionManager.reset()
	LevelManager.current_stage_index = 0
	state = GameState.PLAYING
	SceneTransition.goto_scene(MAIN_MENU_SCENE)
