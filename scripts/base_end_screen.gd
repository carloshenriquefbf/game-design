extends Control
class_name BaseEndScreen
## Shared end-of-run overlay for stage failure and (future) full-game
## victory. Owns what's common to both: applying per-instance title/color/
## primary-button text, and quitting to the main menu — which replaces the
## title text and button row in place (no popup) with a lose-progress
## confirmation, since leaving mid-run discards progress.
##
## DefeatScreen (and the future VictoryScreen) instance base_end_screen.tscn
## and attach a script extending this one that sets the exports below and
## connects primary_action_requested to whatever "continue" means for them.

const TITLE_FONT_SIZE := 32
const MAIN_MENU_CONFIRM_TEXT := "Todo o progresso será perdido.\nTem certeza que deseja voltar ao menu principal?"
const MAIN_MENU_CONFIRM_FONT_SIZE := 22

signal primary_action_requested

@export var title_text: String = ""
@export var background_color: Color = Color(0.1, 0.1, 0.1, 1.0)
@export var primary_button_text: String = "Continuar"
## Screens with no run left to lose (e.g. credits after full completion)
## can hide this and let the primary button itself go straight to the
## menu, skipping the "progress will be lost" confirmation entirely.
@export var show_main_menu_button: bool = true

@onready var background: ColorRect = $Background
@onready var title: Label = $Title
@onready var default_buttons: VBoxContainer = $Buttons/DefaultButtons
@onready var primary_button: Button = $Buttons/DefaultButtons/PrimaryButton
@onready var main_menu_button: Button = $Buttons/DefaultButtons/MainMenuButton
@onready var confirm_buttons: HBoxContainer = $Buttons/ConfirmButtons
@onready var confirm_yes_button: Button = $Buttons/ConfirmButtons/YesButton
@onready var confirm_no_button: Button = $Buttons/ConfirmButtons/NoButton


func _ready() -> void:
	title.text = title_text
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	background.color = background_color
	primary_button.text = primary_button_text
	main_menu_button.visible = show_main_menu_button

	primary_button.pressed.connect(func() -> void: primary_action_requested.emit())
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	confirm_yes_button.pressed.connect(_on_quit_confirmed)
	confirm_no_button.pressed.connect(_on_quit_cancelled)


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
