extends ColorRect
## Shared bottom-left inventory slot (potion/wind bag/key). Icon, HintLabel,
## ActiveFill and TimerLabel are always present so every slot has the same
## shape — per-instance exports decide what's actually shown, the same way
## base_illumination_asset.tscn's leaf scenes differ by export rather than
## by structure. hud.gd still drives Icon/ActiveFill/TimerLabel visibility
## directly for the slots that need runtime state (inventory, potion timer).

@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		if is_node_ready():
			icon.texture = value

## Key hint shown in the corner (e.g. "Q"). Empty hides the label — KeySlot
## has no activation key, so it leaves this blank.
@export var hint_key: String = "":
	set(value):
		hint_key = value
		if is_node_ready():
			_apply_hint_key()

@onready var icon: TextureRect = $Icon
@onready var hint_label: Label = $HintLabel


func _ready() -> void:
	icon.texture = icon_texture
	_apply_hint_key()


func _apply_hint_key() -> void:
	hint_label.visible = hint_key != ""
	hint_label.text = hint_key
