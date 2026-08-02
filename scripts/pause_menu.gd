extends CanvasLayer
## In-level pause menu. Toggled by the "pause" input action. Root's
## process_mode is set to ALWAYS in the scene so this (and its buttons, and
## the instructions modal) stay interactive while get_tree().paused freezes
## everything else (Knight AI, Player, SuspicionManager timers, animations)
## left at their default PROCESS_MODE_INHERIT.

enum ConfirmAction { NONE, MAIN_MENU, QUIT_GAME }

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const MAIN_MENU_CONFIRM_TEXT := "Todo o progresso será perdido.\nTem certeza que deseja voltar ao menu principal?"
const QUIT_GAME_CONFIRM_TEXT := "Todo o progresso será perdido.\nTem certeza que deseja sair do jogo?"

@export var click_sfx: AudioStream

@onready var root: Control = $Root
@onready var buttons_panel: VBoxContainer = $Root/ButtonsPanel
@onready var continue_button: Button = $Root/ButtonsPanel/ContinueButton
@onready var instructions_button: Button = $Root/ButtonsPanel/InstructionsButton
@onready var main_menu_button: Button = $Root/ButtonsPanel/MainMenuButton
@onready var quit_game_button: Button = $Root/ButtonsPanel/QuitGameButton
@onready var instructions_modal: Control = $Root/InstructionsModal
@onready var confirm_panel: VBoxContainer = $Root/ConfirmPanel
@onready var confirm_label: Label = $Root/ConfirmPanel/ConfirmLabel
@onready var confirm_buttons: ConfirmButtons = $Root/ConfirmPanel/ConfirmButtons
@onready var click_sound: AudioStreamPlayer = $ClickSound

var _pending_confirm_action: ConfirmAction = ConfirmAction.NONE


func _ready() -> void:
	click_sound.stream = click_sfx

	continue_button.pressed.connect(_on_continue_pressed)
	instructions_button.pressed.connect(_on_instructions_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_game_button.pressed.connect(_on_quit_game_pressed)
	instructions_modal.close_requested.connect(_on_instructions_modal_closed)
	confirm_buttons.confirmed.connect(_on_confirm_yes_pressed)
	confirm_buttons.cancelled.connect(_on_confirm_no_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not root.visible and event.is_action_pressed("pause"):
		_open_pause_menu()


func _open_pause_menu() -> void:
	buttons_panel.visible = true
	instructions_modal.visible = false
	confirm_panel.visible = false
	root.visible = true
	get_tree().paused = true


func resume_game() -> void:
	get_tree().paused = false
	root.visible = false


func _on_continue_pressed() -> void:
	_play_click_sfx()
	resume_game()


func _on_instructions_pressed() -> void:
	_play_click_sfx()
	buttons_panel.visible = false
	instructions_modal.visible = true


func _on_instructions_modal_closed() -> void:
	instructions_modal.visible = false
	buttons_panel.visible = true


func _on_main_menu_pressed() -> void:
	_play_click_sfx()
	_show_confirm(ConfirmAction.MAIN_MENU, MAIN_MENU_CONFIRM_TEXT)


func _on_quit_game_pressed() -> void:
	_play_click_sfx()
	_show_confirm(ConfirmAction.QUIT_GAME, QUIT_GAME_CONFIRM_TEXT)


func _show_confirm(action: ConfirmAction, text: String) -> void:
	_pending_confirm_action = action
	confirm_label.text = text
	buttons_panel.visible = false
	confirm_panel.visible = true


func _on_confirm_yes_pressed() -> void:
	_play_click_sfx()
	var action := _pending_confirm_action
	_pending_confirm_action = ConfirmAction.NONE

	match action:
		ConfirmAction.MAIN_MENU:
			get_tree().paused = false
			root.visible = false
			GameManager.quit_to_main_menu()
		ConfirmAction.QUIT_GAME:
			get_tree().quit()


func _on_confirm_no_pressed() -> void:
	_play_click_sfx()
	_pending_confirm_action = ConfirmAction.NONE
	confirm_panel.visible = false
	buttons_panel.visible = true


func _play_click_sfx() -> void:
	print("[pause_menu] click sfx hook fired")
	if click_sound.stream:
		click_sound.play()
