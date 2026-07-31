extends Objective
class_name KeyDoorObjective
## Completed when the player picks up `key_item_id`; on completion the
## LevelObjectives owner unlocks the LockedDoor at `door_path`.

@export var key_item_id: StringName = &"key"
@export var door_path: NodePath
