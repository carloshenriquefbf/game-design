extends Node2D
class_name ExitDoor
## Level exit trigger. Unlocked by default so levels without a key/door
## objective just complete the level on touch. LevelObjectives locks it
## here when a KeyDoorObjective targets it, then calls unlock() once that
## objective's key is picked up. While locked the door blocks line of
## sight like cover (Vision Blockers layer only) but never blocks
## movement — the area stays walkable for player and knights alike.
## Reaching the door only advances the stage once every objective in the
## level's LevelObjectives is complete, checked independently of this
## door's own lock state so future objective types that never touch a
## door still gate the exit.

const CLOSED_TEXTURE := preload("res://sprites/assets/door/door-closed.png")
const OPEN_TEXTURE := preload("res://sprites/assets/door/door-open.png")

@export var open_label: String = "[som: abrir porta]"

@onready var vision_blocker_shape: CollisionShape2D = $VisionBlocker/CollisionShape2D
@onready var door_sprite: Sprite2D = $Sprite2D

var _locked: bool = false


func _ready() -> void:
	_update_visual()


func set_locked(locked: bool) -> void:
	_locked = locked
	vision_blocker_shape.set_deferred("disabled", not locked)
	_update_visual()


func unlock() -> void:
	set_locked(false)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or not _objectives_complete():
		return
	_play_open_placeholder()
	GameManager.complete_stage()


func _objectives_complete() -> bool:
	var level_objectives := get_tree().get_first_node_in_group("level_objectives") as LevelObjectives
	if level_objectives == null:
		return true
	return level_objectives.completed_count >= level_objectives.total()


func _update_visual() -> void:
	door_sprite.texture = CLOSED_TEXTURE if _locked else OPEN_TEXTURE


func _play_open_placeholder() -> void:
	print(open_label)
