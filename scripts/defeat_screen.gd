extends "res://scripts/base_end_screen.gd"
## Game-over instance of BaseEndScreen. Task 14 owns the final look/feel —
## this just wires the primary button to a stage restart.


func _ready() -> void:
	super._ready()
	primary_action_requested.connect(GameManager.restart_level)
