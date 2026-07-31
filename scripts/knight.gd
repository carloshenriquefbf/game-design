extends CharacterBody2D


enum State { IDLE, PATROL, ALERT }

const ARRIVAL_DISTANCE := 4.0

@export var speed: float = 100.0

@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var patrol_route: Node2D = get_node_or_null("PatrolRoute")

var state: State = State.IDLE
var waypoints: Array[Vector2] = []
var current_waypoint_index: int = 0
var patrol_direction: int = 1


func _ready() -> void:
	_collect_waypoints()
	state = State.PATROL if waypoints.size() >= 2 else State.IDLE


func _physics_process(_delta: float) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.PATROL:
			_process_patrol()
		State.ALERT:
			_process_alert()

	move_and_slide()
	_update_animation()


func _collect_waypoints() -> void:
	waypoints.clear()
	if patrol_route == null:
		return
	for child in patrol_route.get_children():
		if child is Node2D:
			waypoints.append(child.global_position)


func _process_patrol() -> void:
	if waypoints.is_empty():
		velocity = Vector2.ZERO
		return

	var target := waypoints[current_waypoint_index]
	var to_target := target - global_position

	if to_target.length() <= ARRIVAL_DISTANCE:
		_advance_waypoint()
		target = waypoints[current_waypoint_index]
		to_target = target - global_position

	velocity = to_target.normalized() * speed


func _advance_waypoint() -> void:
	current_waypoint_index += patrol_direction

	if current_waypoint_index >= waypoints.size():
		patrol_direction = -1
		current_waypoint_index = waypoints.size() - 2
	elif current_waypoint_index < 0:
		patrol_direction = 1
		current_waypoint_index = 1


func _process_alert() -> void:
	# Stub: the vision cone / suspicion system will drive this state next.
	velocity = Vector2.ZERO


func _update_animation() -> void:
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0

	var animation_name := "walk" if velocity.length() > 0.1 else "idle"
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
