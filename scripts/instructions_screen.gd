extends Control
## Full-screen instructions view. Reached from the main menu; instances the
## shared instructions_content.tscn for the actual item explanations.

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

@export var click_sfx: AudioStream

@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var back_button: Button = $BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	click_sound.stream = click_sfx


func _on_back_pressed() -> void:
	_play_click_sfx()
	SceneTransition.goto_scene(MAIN_MENU_SCENE)


func _play_click_sfx() -> void:
	print("[instructions_screen] click sfx hook fired")
	if click_sound.stream:
		click_sound.play()
