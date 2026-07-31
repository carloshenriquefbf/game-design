extends CharacterBody2D


enum State { IDLE, WALKING }

const SPEED := 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var state: State = State.IDLE


func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	velocity = input_direction * SPEED

	move_and_slide()

	_update_state(input_direction)
	_update_animation(input_direction)


func _update_state(input_direction: Vector2) -> void:
	state = State.WALKING if input_direction != Vector2.ZERO else State.IDLE


func _update_animation(input_direction: Vector2) -> void:
	if input_direction.x != 0:
		animated_sprite.flip_h = input_direction.x < 0

	var animation_name := "walk" if state == State.WALKING else "idle"
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
