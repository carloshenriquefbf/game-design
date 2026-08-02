extends HBoxContainer
class_name ConfirmButtons
## Shared Sim/Não row used by BaseEndScreen's main-menu-exit confirmation
## and PauseMenu's main-menu/quit-game confirmations. Owns nothing about
## what's being confirmed — callers connect to `confirmed`/`cancelled` and
## decide what that means for them.

signal confirmed
signal cancelled

@onready var yes_button: Button = $YesButton
@onready var no_button: Button = $NoButton


func _ready() -> void:
	yes_button.pressed.connect(func() -> void: confirmed.emit())
	no_button.pressed.connect(func() -> void: cancelled.emit())
