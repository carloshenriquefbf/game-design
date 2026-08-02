extends Objective
class_name KeyDoorObjective
## Completed when the player picks up `key_item_id`; on completion the
## LevelObjectives owner unlocks the LockedDoor at `door_path`.

@export var key_item_id: StringName = &"key"
@export var door_path: NodePath

var _door: ExitDoor = null


func setup(level_objectives: Node, on_complete: Callable) -> void:
	_door = level_objectives.get_node_or_null(door_path) as ExitDoor
	if _door:
		_door.set_locked(true)

	EventBus.item_picked_up.connect(func(item_id: StringName, _pickup_message: String, _instructions: String) -> void:
		_on_item_picked_up(item_id, on_complete)
	)


func _on_item_picked_up(item_id: StringName, on_complete: Callable) -> void:
	if is_complete or item_id != key_item_id:
		return

	on_complete.call()
	if _door:
		_door.unlock()
