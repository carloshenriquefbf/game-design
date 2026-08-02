extends Node2D

@export var item_id: StringName
@export var pickup_label: String = "[som: pegar item]"
## Shown in the on-screen toast every time this item is picked up.
@export var pickup_message: String = ""
## Appended to pickup_message, but only the first time this item_id is
## ever picked up in the running game (see GameManager.should_show_item_instructions).
@export var instructions: String = ""

@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not body.add_item(item_id, pickup_message, instructions):
		return

	_play_pickup_placeholder()
	queue_free()


func _play_pickup_placeholder() -> void:
	print(pickup_label)
	if pickup_sound.stream != null:
		pickup_sound.play()
