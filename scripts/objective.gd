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
