extends Node2D
class_name ExitDoor
## Level exit trigger. Unlocked by default so levels without a key/door
## objective just complete the level on touch. A KeyDoorObjective that
## targets this door locks it during its own setup(), then calls unlock()
## once its key is picked up. While locked the door blocks line of sight
## like cover (Vision Blockers layer only) but never blocks movement — the
## area stays walkable for player and knights alike.
## Reaching the door only advances the stage once EventBus.
## all_objectives_completed has fired for the level's LevelObjectives,
## checked independently of this door's own lock state so future objective
## types that never touch a door still gate the exit.

const CLOSED_TEXTURE := preload("res://sprites/assets/door/door-closed.png")
const OPEN_TEXTURE := preload("res://sprites/assets/door/door-open.png")

@export var open_label: String = "[som: abrir porta]"

@onready var vision_blocker_shape: CollisionShape2D = $VisionBlocker/CollisionShape2D
@onready var door_sprite: Sprite2D = $Sprite2D
@onready var next_stage_void: ColorRect = $NextStageVoid
@onready var open_sound: AudioStreamPlayer2D = $OpenSound

var _locked: bool = false
var _objectives_complete: bool = false


func _ready() -> void:
	_update_visual()
	EventBus.all_objectives_completed.connect(_on_all_objectives_completed)

	# Deferred so this runs after every node in the scene (including
	# LevelObjectives, wherever it sits in sibling order) has finished its
	# own _ready() — a same-frame group lookup here would race
	# LevelObjectives.add_to_group() and could see it as empty even when a
	# real objective exists.
	call_deferred("_snapshot_initial_objectives_state")


# Snapshot the initial state so a level with zero objectives (or one whose
# LevelObjectives already completed before this ran) still opens — the
# signal above only catches completions from here on.
func _snapshot_initial_objectives_state() -> void:
	var level_objectives := get_tree().get_first_node_in_group("level_objectives") as LevelObjectives
	if level_objectives == null or level_objectives.completed_count >= level_objectives.total():
		_objectives_complete = true


func set_locked(locked: bool) -> void:
	_locked = locked
	vision_blocker_shape.set_deferred("disabled", not locked)
	_update_visual()


func unlock() -> void:
	set_locked(false)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or not _objectives_complete:
		return
	_play_open_placeholder()
	GameManager.complete_stage()


func _on_all_objectives_completed() -> void:
	_objectives_complete = true


func _update_visual() -> void:
	door_sprite.texture = CLOSED_TEXTURE if _locked else OPEN_TEXTURE
	next_stage_void.visible = not _locked


func _play_open_placeholder() -> void:
	print(open_label)
	if open_sound.stream != null:
		open_sound.play()
