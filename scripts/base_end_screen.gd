extends "res://scripts/base_screen.gd"
class_name BaseEndScreen
## Shared end-of-run overlay for stage failure and (future) full-game
## victory. Builds on BaseScreen's background/title shell (background_color
## and title_text/title_anchor_top are inherited exports) and owns what's
## common to both outcomes: applying per-instance primary-button text, and
## quitting to the main menu — which replaces the title text and button
## row in place (no popup) with a lose-progress confirmation, since
## leaving mid-run discards progress.
##
## DefeatScreen (and the future VictoryScreen) instance base_end_screen.tscn
## and attach a script extending this one that sets the exports below and
## connects primary_action_requested to whatever "continue" means for them.

const MAIN_MENU_CONFIRM_TEXT := "Todo o progresso será perdido.\nTem certeza que deseja voltar ao menu principal?"
const MAIN_MENU_CONFIRM_FONT_SIZE := 22

signal primary_action_requested

@export var primary_button_text: String = "Continuar"
## Screens with no run left to lose (e.g. credits after full completion)
## can hide this and let the primary button itself go straight to the
## menu, skipping the "progress will be lost" confirmation entirely.
@export var show_main_menu_button: bool = true

@onready var default_buttons: VBoxContainer = $Buttons/DefaultButtons
@onready var primary_button: Button = $Buttons/DefaultButtons/PrimaryButton
@onready var main_menu_button: Button = $Buttons/DefaultButtons/MainMenuButton
@onready var confirm_buttons: ConfirmButtons = $Buttons/ConfirmButtons


func _ready() -> void:
	super._ready()

	primary_button.text = primary_button_text
	main_menu_button.visible = show_main_menu_button

	primary_button.pressed.connect(func() -> void: primary_action_requested.emit())
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	confirm_buttons.confirmed.connect(_on_quit_confirmed)
	confirm_buttons.cancelled.connect(_on_quit_cancelled)


func _on_main_menu_pressed() -> void:
	title.text = MAIN_MENU_CONFIRM_TEXT
	title.add_theme_font_size_override("font_size", MAIN_MENU_CONFIRM_FONT_SIZE)
	default_buttons.hide()
	confirm_buttons.show()


func _on_quit_confirmed() -> void:
	GameManager.quit_to_main_menu()


func _on_quit_cancelled() -> void:
	title.text = title_text
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	confirm_buttons.hide()
	default_buttons.show()
