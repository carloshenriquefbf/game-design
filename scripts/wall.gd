extends StaticBody2D


@export var size: Vector2 = Vector2(20, 374):
	set(value):
		size = value
		if is_node_ready():
			_apply_size()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	_apply_size()


func _apply_size() -> void:
	var shape := collision_shape.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision_shape.shape = shape
	shape.size = size

	color_rect.position = -size / 2.0
	color_rect.size = size
