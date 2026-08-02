extends Control
class_name BaseScreen
## Shared full-screen shell (dark background + centered title) used by
## MainMenu, InstructionsScreen, and — via BaseEndScreen — the end-of-run
## screens. Owns only the visual shell; callers add their own buttons/
## content as extra children and set the exports below.

const TITLE_FONT_SIZE := 32

@export var title_text: String = "":
	set(value):
		title_text = value
		if is_node_ready():
			title.text = value

@export var background_color: Color = Color(0.08, 0.09, 0.12, 1.0):
	set(value):
		background_color = value
		if is_node_ready():
			background.color = value

## Vertical anchor (0..1) the title is centered on — varies per screen
## (main menu's title sits lower than instructions' near-top title).
@export var title_anchor_top: float = 0.35:
	set(value):
		title_anchor_top = value
		if is_node_ready():
			_apply_title_anchor()

@onready var background: ColorRect = $Background
@onready var title: Label = $Title


func _ready() -> void:
	background.color = background_color
	title.text = title_text
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	_apply_title_anchor()


func _apply_title_anchor() -> void:
	title.anchor_top = title_anchor_top
	title.anchor_bottom = title_anchor_top
