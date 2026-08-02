extends Resource
class_name Objective
## Base type for a single per-level objective. Concrete objective types
## (key/door, and future ones) extend this; LevelObjectives wires each
## instance to its gameplay trigger by type, so adding a new objective
## kind never requires per-level branching logic.

@export var id: StringName
@export var label: String

var is_complete: bool = false


func complete() -> void:
	is_complete = true


## Called once by LevelObjectives for every objective in its list. Override
## to wire this objective's own completion trigger (e.g. connecting to
## EventBus, locking a door) — call on_complete when the condition is met,
## rather than LevelObjectives branching on the objective's concrete type.
func setup(_level_objectives: Node, _on_complete: Callable) -> void:
	pass
