extends Node
## Global signal hub. No state, no logic — just decoupled communication
## between systems (guards, UI, level flow, etc).


signal player_detected(guard: Node2D)
signal player_lost(guard: Node2D)
signal objective_completed(objective_id: String)
signal level_exited()
signal level_completed()
signal player_captured(guard: Node2D)
