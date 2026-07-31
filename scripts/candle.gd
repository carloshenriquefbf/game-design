extends Node2D

const LIT_COLOR := Color(1.0, 0.65, 0.15, 1.0)
const EXTINGUISHED_COLOR := Color(0.35, 0.35, 0.4, 1.0)

@onready var flame: ColorRect = $Flame

var lit: bool = true


func extinguish() -> void:
	if not lit:
		return

	lit = false
	flame.color = EXTINGUISHED_COLOR
	EventBus.candles_extinguished.emit()
