extends Node
class_name LevelObjectives
## Data-driven objective tracker for a level. Drop Objective resources
## (KeyDoorObjective, or future types) into `objectives` in the editor; each
## one wires its own gameplay trigger via Objective.setup() and reports
## progress through EventBus.objective_completed / all_objectives_completed.
## Adding a level with a different objective set means adding resources
## here, not new code — and adding a new objective *type* means overriding
## setup() on it, not branching here.

@export var objectives: Array[Objective] = []

var completed_count: int = 0


func _ready() -> void:
	add_to_group("level_objectives")
	for objective in objectives:
		objective.setup(self, func() -> void: _complete(objective))

	if _all_complete():
		EventBus.all_objectives_completed.emit()


func total() -> int:
	return objectives.size()


func _complete(objective: Objective) -> void:
	objective.complete()
	completed_count += 1
	EventBus.objective_completed.emit(objective.id)

	if _all_complete():
		EventBus.all_objectives_completed.emit()


func _all_complete() -> bool:
	return completed_count >= total()
