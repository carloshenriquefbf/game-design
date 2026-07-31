extends "res://scripts/base_end_screen.gd"
## Shown once, after the last stage's objectives are done and the exit is
## reached. The whole game is complete at that point, so there's no run
## left to protect — the primary button goes straight back to the main
## menu (reusing quit_to_main_menu's reset) with no confirmation and no
## separate Main Menu button.


func _ready() -> void:
	super._ready()
	primary_action_requested.connect(GameManager.quit_to_main_menu)
