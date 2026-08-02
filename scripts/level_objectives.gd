extends Node
class_name LevelObjectives
## Data-driven objective tracker for a level. Drop Objective resources
## (KeyDoorObjective, or future types) into `objectives` in the editor;
## this node wires each one to its gameplay trigger by type and reports
## progress through EventBus.objective_completed. Adding a level with a
## different objective set means adding resources here, not new code.

@export var objectives: Array[Objective] = []

var completed_count: int = 0


func _ready() -> void:
	add_to_group("level_objectives")
	for objective in objectives:
		if objective is KeyDoorObjective:
			_setup_key_door_objective(objective)


func total() -> int:
	return objectives.size()


func _setup_key_door_objective(objective: KeyDoorObjective) -> void:
	var door := get_node_or_null(objective.door_path) as ExitDoor
	if door:
		door.set_locked(true)

	EventBus.item_picked_up.connect(func(item_id: StringName, _pickup_message: String, _instructions: String) -> void:
		_on_key_picked_up(objective, door, item_id)
	)


func _on_key_picked_up(objective: KeyDoorObjective, door: ExitDoor, item_id: StringName) -> void:
	if objective.is_complete or item_id != objective.key_item_id:
		return

	_complete(objective)
	if door:
		door.unlock()


func _complete(objective: Objective) -> void:
	objective.complete()
	completed_count += 1
	EventBus.objective_completed.emit(objective.id)
