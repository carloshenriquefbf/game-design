extends Control
## Small centered instructions panel opened from PauseMenu. Instances the
## same instructions_content.tscn as the full-screen instructions_screen —
## the content itself lives in exactly one place.

signal close_requested

@export var click_sfx: AudioStream

@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var close_button: Button = $Panel/Layout/CloseButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	click_sound.stream = click_sfx


func _on_close_pressed() -> void:
	_play_click_sfx()
	close_requested.emit()


func _play_click_sfx() -> void:
	print("[instructions_modal] click sfx hook fired")
	if click_sound.stream:
		click_sound.play()
