extends CharacterBody2D


enum State { IDLE, PATROL, ALERT, LOOK_AROUND }

const ARRIVAL_DISTANCE := 4.0
const CONE_SEGMENTS := 12
const LOOK_AROUND_ANGLE_HARD_CEILING_DEGREES := 80.0

@export var speed: float = 100.0
@export var vision_range: float = 220.0
@export var vision_angle_degrees: float = 70.0
@export var patrol_loop: bool = false
@export var dimmed_vision_multiplier: float = 0.75
@export var look_around_sweep_angle_degrees: float = 45.0
@export var look_around_sweep_duration: float = 2.0
@export var look_around_idle_interval: float = 4.0
@export var invisibility_cone_color: Color = Color(0.5, 0.5, 0.5, 0.25)

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
var _contact_capture_triggered: bool = false
var _dimmed: bool = false
var _base_vision_range: float
var _base_vision_angle_degrees: float
var _base_cone_color: Color

var _state_before_look_around: State = State.IDLE
var _look_around_tween: Tween = null
var _look_around_base_angle: float = 0.0
var _idle_look_around_timer: float = 0.0


func _ready() -> void:
	_collect_waypoints()
	state = State.PATROL if waypoints.size() >= 2 else State.IDLE
	if waypoints.size() == 1:
		var to_waypoint := waypoints[0] - global_position
		if to_waypoint.length() > 0.001:
			facing_direction = to_waypoint.normalized()
	_player = get_tree().get_first_node_in_group("player")

	_base_vision_range = vision_range
	_base_vision_angle_degrees = vision_angle_degrees
	_base_cone_color = vision_polygon.color

	EventBus.candles_extinguished.connect(_dim_vision)
	EventBus.power_up_activated.connect(_on_power_up_activated)
	EventBus.power_up_expired.connect(_on_power_up_expired)


func _on_power_up_activated(item_id: StringName, _duration: float) -> void:
	if item_id != &"invisibility_potion":
		return
	vision_polygon.color = invisibility_cone_color


func _on_power_up_expired(item_id: StringName) -> void:
	if item_id != &"invisibility_potion":
		return
	vision_polygon.color = _base_cone_color


func _dim_vision() -> void:
	if _dimmed:
		return
	_dimmed = true
	vision_range = _base_vision_range * dimmed_vision_multiplier
	vision_angle_degrees = _base_vision_angle_degrees * dimmed_vision_multiplier


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			_process_idle(delta)
		State.PATROL:
			_process_patrol()
		State.ALERT:
			_process_alert()
		State.LOOK_AROUND:
			velocity = Vector2.ZERO

	move_and_slide()
	_update_animation()

	_update_facing_direction()
	_update_vision_cone_transform()
	_update_vision_polygon()
	_update_detection(delta)
	_update_contact_capture()


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
		var next_target := waypoints[current_waypoint_index]
		var to_next := next_target - global_position
		if to_next.length() > 0.001:
			facing_direction = to_next.normalized()
		_start_look_around()
		return

	velocity = to_target.normalized() * speed


func _process_idle(delta: float) -> void:
	_idle_look_around_timer += delta
	if _idle_look_around_timer >= look_around_idle_interval:
		_idle_look_around_timer = 0.0
		_start_look_around()


func _advance_waypoint() -> void:
	if patrol_loop:
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
		return

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


func _start_look_around() -> void:
	if state == State.LOOK_AROUND:
		return

	_state_before_look_around = state
	state = State.LOOK_AROUND
	velocity = Vector2.ZERO
	_look_around_base_angle = facing_direction.angle()

	var half_angle := deg_to_rad(
		clamp(look_around_sweep_angle_degrees, 0.0, LOOK_AROUND_ANGLE_HARD_CEILING_DEGREES)
	) / 2.0
	var quarter_duration := look_around_sweep_duration / 4.0

	if _look_around_tween:
		_look_around_tween.kill()

	_look_around_tween = create_tween()
	_look_around_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_look_around_tween.tween_method(_set_look_around_offset, 0.0, half_angle, quarter_duration)
	_look_around_tween.tween_method(
		_set_look_around_offset, half_angle, -half_angle, quarter_duration * 2.0
	)
	_look_around_tween.tween_method(_set_look_around_offset, -half_angle, 0.0, quarter_duration)
	_look_around_tween.finished.connect(_on_look_around_finished)


func _set_look_around_offset(offset: float) -> void:
	facing_direction = Vector2.RIGHT.rotated(_look_around_base_angle + offset)


func _on_look_around_finished() -> void:
	_look_around_tween = null
	state = _state_before_look_around


func _cancel_look_around() -> void:
	if _look_around_tween:
		_look_around_tween.kill()
		_look_around_tween = null
	state = _state_before_look_around


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


func _update_vision_polygon() -> void:
	var half_angle := deg_to_rad(vision_angle_degrees) / 2.0
	var space_state := get_world_2d().direct_space_state
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	for i in range(CONE_SEGMENTS + 1):
		var t := lerpf(-half_angle, half_angle, float(i) / float(CONE_SEGMENTS))
		var direction := facing_direction.rotated(t)
		var query := PhysicsRayQueryParameters2D.create(
			global_position, global_position + direction * vision_range, los_ray.collision_mask
		)
		query.exclude = [get_rid()]
		var result := space_state.intersect_ray(query)
		var length := vision_range if result.is_empty() else global_position.distance_to(result.position)
		points.append(Vector2.RIGHT.rotated(t) * length)
	vision_polygon.polygon = points


func _update_detection(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return

	var has_los: bool = _can_see_player() and not _player.is_invisible()
	SuspicionManager.report_visibility(self, has_los)

	if has_los:
		if not player_detected:
			player_detected = true
			EventBus.player_detected.emit(self)
			_play_alert_placeholder()
		if state == State.LOOK_AROUND:
			_cancel_look_around()
	else:
		if player_detected:
			player_detected = false
			EventBus.player_lost.emit(self)
			print("[perception] lost sight of player")


func _update_contact_capture() -> void:
	if _player == null:
		return

	var touching_player := false
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == _player:
			touching_player = true
			break

	if touching_player:
		if not _contact_capture_triggered:
			_contact_capture_triggered = true
			EventBus.player_captured.emit(self)
	else:
		_contact_capture_triggered = false


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
