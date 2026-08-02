extends Node2D

@export var flip_h: bool = false:
	set(value):
		flip_h = value
		if is_node_ready():
			_apply_flip()

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var lit: bool = true


func _ready() -> void:
	_apply_flip()


func extinguish() -> void:
	if not lit:
		return

	lit = false
	sprite.play(&"blown")
	EventBus.candles_extinguished.emit()


func _apply_flip() -> void:
	sprite.flip_h = flip_h
