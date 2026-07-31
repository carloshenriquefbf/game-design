extends Node
## Global suspicion tracker. Rises while ANY guard currently sees the
## player and only drains once no guard sees them — moving between
## vision cones does not reset progress, since watchers are aggregated
## rather than tracked per-guard.

signal suspicion_changed(value: float)

@export var time_to_max: float = 2.0
@export var time_to_drain: float = 4.0

var suspicion: float = 0.0

var _watchers: Dictionary = {}
var _captured: bool = false


func report_visibility(guard: Node2D, sees_player: bool) -> void:
	if sees_player:
		_watchers[guard] = true
	else:
		_watchers.erase(guard)


func _process(delta: float) -> void:
	if _captured:
		return

	var seen := not _watchers.is_empty()
	var target := 1.0 if seen else 0.0
	var rate := (1.0 / time_to_max) if seen else (1.0 / time_to_drain)
	var new_value := move_toward(suspicion, target, rate * delta)

	if not is_equal_approx(new_value, suspicion):
		suspicion = new_value
		suspicion_changed.emit(suspicion)

	if suspicion >= 1.0:
		_captured = true
		EventBus.player_captured.emit(null)


func reset() -> void:
	_watchers.clear()
	suspicion = 0.0
	_captured = false
	suspicion_changed.emit(suspicion)
