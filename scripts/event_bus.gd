extends Node
## Global signal hub. No state, no logic — just decoupled communication
## between systems (guards, UI, level flow, etc).


signal player_detected(guard: Node2D)
signal player_lost(guard: Node2D)
signal objective_completed(objective_id: String)
signal level_exited()
signal level_completed()
signal player_captured(guard: Node2D)
signal item_picked_up(item_id: StringName, pickup_message: String, instructions: String)
signal item_consumed(item_id: StringName)
signal power_up_activated(item_id: StringName, duration: float)
signal power_up_expired(item_id: StringName)
signal candles_extinguished()
