extends Node2D
class_name ExitDoor
## Level exit trigger. Unlocked by default so levels without a key/door
## objective just complete the level on touch. LevelObjectives locks it
## here when a KeyDoorObjective targets it, then calls unlock() once that
## objective's key is picked up. While locked the door blocks line of
## sight like cover (Vision Blockers layer only) but never blocks
## movement — the area stays walkable for player and knights alike; only
## the player, and only once unlocked, advances the level.

const LOCKED_COLOR := Color(0.5, 0.35, 0.1, 1.0)
const UNLOCKED_COLOR := Color(0.8, 0.7, 0.25, 1.0)

@export var open_label: String = "[som: abrir porta]"

@onready var vision_blocker_shape: CollisionShape2D = $VisionBlocker/CollisionShape2D
@onready var door_visual: ColorRect = $ColorRect

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
	if _locked or not body.is_in_group("player"):
		return
	_play_open_placeholder()
	GameManager.trigger_victory()


func _update_visual() -> void:
	door_visual.color = LOCKED_COLOR if _locked else UNLOCKED_COLOR


func _play_open_placeholder() -> void:
	print(open_label)
