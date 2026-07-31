extends CharacterBody2D


enum State { IDLE, WALKING }

const SPEED := 300.0
const INVISIBILITY_POTION := &"invisibility_potion"
const WIND_BAG := &"wind_bag"
const MAX_INVENTORY_SIZE := 3

@export var invisibility_duration: float = 6.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var invisibility_timer: Timer = $InvisibilityTimer
@onready var drink_sound: AudioStreamPlayer2D = $DrinkSound
@onready var wind_sound: AudioStreamPlayer2D = $WindSound

var state: State = State.IDLE

var _inventory: Array[StringName] = []
var _invisible: bool = false


func _ready() -> void:
	invisibility_timer.one_shot = true
	invisibility_timer.timeout.connect(_on_invisibility_timer_timeout)


func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	velocity = input_direction * SPEED

	move_and_slide()

	_update_state(input_direction)
	_update_animation(input_direction)

	if Input.is_action_just_pressed("use_potion"):
		_drink_invisibility_potion()

	if Input.is_action_just_pressed("use_wind_bag"):
		_use_wind_bag()


func add_item(item_id: StringName) -> bool:
	if _inventory.size() >= MAX_INVENTORY_SIZE:
		return false

	_inventory.append(item_id)
	EventBus.item_picked_up.emit(item_id)
	return true


func _consume_item(item_id: StringName) -> bool:
	var index := _inventory.find(item_id)
	if index == -1:
		return false

	_inventory.remove_at(index)
	return true


func is_invisible() -> bool:
	return _invisible


func get_invisibility_time_left() -> float:
	return invisibility_timer.time_left if _invisible else 0.0


func _drink_invisibility_potion() -> void:
	if not _consume_item(INVISIBILITY_POTION):
		return

	_play_drink_placeholder()

	_invisible = true
	invisibility_timer.start(invisibility_duration)
	EventBus.power_up_activated.emit(INVISIBILITY_POTION, invisibility_duration)


func _on_invisibility_timer_timeout() -> void:
	_invisible = false
	EventBus.power_up_expired.emit(INVISIBILITY_POTION)


func _play_drink_placeholder() -> void:
	print("[som: beber poção]")
	if drink_sound.stream != null:
		drink_sound.play()


func _use_wind_bag() -> void:
	if not _consume_item(WIND_BAG):
		return

	_play_wind_bag_placeholder()

	for candle in get_tree().get_nodes_in_group("candle"):
		candle.extinguish()


func _play_wind_bag_placeholder() -> void:
	print("[som: assoprar]")
	if wind_sound.stream != null:
		wind_sound.play()


func _update_state(input_direction: Vector2) -> void:
	state = State.WALKING if input_direction != Vector2.ZERO else State.IDLE


func _update_animation(input_direction: Vector2) -> void:
	if input_direction.x != 0:
		animated_sprite.flip_h = input_direction.x < 0

	var animation_name := "walk" if state == State.WALKING else "idle"
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
