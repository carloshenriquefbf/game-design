extends Node2D

@export var item_id: StringName
@export var pickup_label: String = "[som: pegar item]"

@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not body.add_item(item_id):
		return

	_play_pickup_placeholder()
	queue_free()


func _play_pickup_placeholder() -> void:
	print(pickup_label)
	if pickup_sound.stream != null:
		pickup_sound.play()
