extends Control
## Placeholder audio hook: drop a real AudioStream into click_sfx/menu_music
## in the editor when the final assets land — code doesn't need to change.

const FIRST_LEVEL_SCENE := "res://scenes/1_tower.tscn"
const QUIT_SFX_DELAY: float = 0.15

## Click sound for all buttons [som: clicar]. Placeholder until final asset lands.
@export var click_sfx: AudioStream
## "Tom tenso" opening theme. Placeholder until final asset lands.
@export var menu_music: AudioStream

@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var play_button: Button = $Buttons/PlayButton
@onready var quit_button: Button = $Buttons/QuitButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	click_sound.stream = click_sfx
	music_player.stream = menu_music
	_play_music()


func _on_play_pressed() -> void:
	_play_click_sfx()
	SceneTransition.goto_scene(FIRST_LEVEL_SCENE)


func _on_quit_pressed() -> void:
	_play_click_sfx()
	await get_tree().create_timer(QUIT_SFX_DELAY).timeout
	get_tree().quit()


func _play_click_sfx() -> void:
	print("[main_menu] click sfx hook fired")
	if click_sound.stream:
		click_sound.play()


func _play_music() -> void:
	if music_player.stream:
		music_player.play()
	else:
		print("[main_menu] menu music placeholder (no asset assigned yet)")
