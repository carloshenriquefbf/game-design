extends StaticBody2D

@export var size: Vector2 = Vector2(20, 374):
	set(value):
		size = value
		if is_node_ready():
			_apply_size()
## When true, this wall butts up against another wall (e.g. a border
## corner) and skips the boot texture, since the connecting wall already
## reads as the "grounding" of the run. When false (default), the wall is
## freestanding and gets a booted base for visual depth.
@export var connects_to_wall: bool = false:
	set(value):
		connects_to_wall = value
		if is_node_ready():
			_apply_size()

## Per-instance override for the Boot/Body textures authored on
## base_wall.tscn. Leave unset to keep whichever texture the base scene
## authors on $Boot/$Body.
@export var body_texture: Texture2D:
	set(value):
		body_texture = value
		if is_node_ready():
			_apply_textures()
@export var boot_texture: Texture2D:
	set(value):
		boot_texture = value
		if is_node_ready():
			_apply_textures()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var boot: TextureRect = $Boot
@onready var body: TextureRect = $Body


func _ready() -> void:
	_apply_size()
	_apply_textures()


func _apply_textures() -> void:
	if body_texture != null:
		body.texture = body_texture
	if boot_texture != null:
		boot.texture = boot_texture


func _apply_size() -> void:
	var shape := collision_shape.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		collision_shape.shape = shape
	shape.size = size
	collision_shape.position = Vector2(0.0, -size.y / 2.0)

	# The node's own position is the wall's *base* (bottom-center), not its
	# center — Y-sort compares raw node position, and a tall freestanding
	# pillar needs its sort key at its ground-contact point (like the
	# player's origin sits near their feet), or the player would sort in
	# front of the top half and behind the bottom half depending on which
	# side of the pillar's midpoint they're standing on.
	var top_left := Vector2(-size.x / 2.0, -size.y)
	var boot_height := 0.0 if connects_to_wall else float(boot.texture.get_height())

	boot.visible = not connects_to_wall
	boot.position = top_left + Vector2(0.0, size.y - boot_height)
	boot.size = Vector2(size.x, boot_height)

	body.position = top_left
	body.size = Vector2(size.x, size.y - boot_height)
