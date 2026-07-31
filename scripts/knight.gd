extends CharacterBody2D


enum State { IDLE, PATROL, ALERT }

const ARRIVAL_DISTANCE := 4.0
const CONE_SEGMENTS := 12

@export var speed: float = 100.0

@export var vision_range: float = 220.0:
	set(value):
		vision_range = value
		if is_node_ready():
			_rebuild_vision_polygon()

@export var vision_angle_degrees: float = 70.0:
	set(value):
		vision_angle_degrees = value
		if is_node_ready():
			_rebuild_vision_polygon()

@export var grace_period: float = 8.0

@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var patrol_route: Node2D = get_node_or_null("PatrolRoute")
@onready var vision_cone: Node2D = $VisionCone
@onready var vision_polygon: Polygon2D = $VisionCone/Polygon2D
@onready var los_ray: RayCast2D = $LineOfSightRay
@onready var alert_sound: AudioStreamPlayer2D = $AlertSound

var state: State = State.IDLE
var waypoints: Array[Vector2] = []
var current_waypoint_index: int = 0
var patrol_direction: int = 1

var facing_direction: Vector2 = Vector2.RIGHT
var player_detected: bool = false

var _player: Node2D = null
var _grace_time_left: float = 0.0


func _ready() -> void:
	_collect_waypoints()
	state = State.PATROL if waypoints.size() >= 2 else State.IDLE
	_player = get_tree().get_first_node_in_group("player")
	_rebuild_vision_polygon()


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.PATROL:
			_process_patrol()
		State.ALERT:
			_process_alert()

	move_and_slide()
	_update_animation()

	_update_facing_direction()
	_update_vision_cone_transform()
	_update_detection(delta)


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


func _update_facing_direction() -> void:
	if velocity.length() > 0.01:
		facing_direction = velocity.normalized()


func _update_vision_cone_transform() -> void:
	vision_cone.rotation = facing_direction.angle()


func _rebuild_vision_polygon() -> void:
	var half_angle := deg_to_rad(vision_angle_degrees) / 2.0
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	for i in range(CONE_SEGMENTS + 1):
		var t := lerpf(-half_angle, half_angle, float(i) / float(CONE_SEGMENTS))
		points.append(Vector2.RIGHT.rotated(t) * vision_range)
	vision_polygon.polygon = points


func _update_detection(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return

	var has_los := _can_see_player()

	if has_los:
		_grace_time_left = 0.0
		if not player_detected:
			player_detected = true
			EventBus.player_detected.emit(self)
			_play_alert_placeholder()
	elif player_detected:
		_grace_time_left += delta
		if _grace_time_left >= grace_period:
			player_detected = false
			_grace_time_left = 0.0
			EventBus.player_lost.emit(self)


func _can_see_player() -> bool:
	var to_player := _player.global_position - global_position
	var distance := to_player.length()
	if distance > vision_range:
		return false

	var angle_to_player := absf(facing_direction.angle_to(to_player))
	if angle_to_player > deg_to_rad(vision_angle_degrees) / 2.0:
		return false

	los_ray.target_position = to_local(_player.global_position)
	los_ray.force_raycast_update()
	return not los_ray.is_colliding()


func _play_alert_placeholder() -> void:
	print("[som: alerta!]")
	if alert_sound.stream != null:
		alert_sound.play()
