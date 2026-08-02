extends StaticBody2D

## Fixed height of the "capped end" texture, in world units — matches the
## native pixel height of side-exterior-wall.png.
const CAP_HEIGHT := 16.0

@export var size: Vector2 = Vector2(20, 374):
	set(value):
		size = value
		if is_node_ready():
			_apply_size()
## When true, this wall butts up against another wall (e.g. a border
## corner) and skips the capped-end texture, since the connecting wall
## already reads as the "end" of the run. When false (default), the wall
## is freestanding and gets a capped top for visual depth.
@export var connects_to_wall: bool = false:
	set(value):
		connects_to_wall = value
		if is_node_ready():
			_apply_size()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var cap: TextureRect = $Cap
@onready var body: TextureRect = $Body


func _ready() -> void:
	_apply_size()


func _apply_size() -> void:
	var shape := collision_shape.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision_shape.shape = shape
	shape.size = size

	var top_left := -size / 2.0
	var cap_height := 0.0 if connects_to_wall else CAP_HEIGHT

	cap.visible = not connects_to_wall
	cap.position = top_left
	cap.size = Vector2(size.x, cap_height)

	body.position = top_left + Vector2(0.0, cap_height)
	body.size = Vector2(size.x, size.y - cap_height)
