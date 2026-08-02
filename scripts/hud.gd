extends CanvasLayer

@onready var suspicion_label: Label = $Root/TopLeft/SuspicionLabel
@onready var suspicion_bar: TextureProgressBar = $Root/TopLeft/SuspicionBar
@onready var power_up_icon: TextureRect = $Root/BottomLeft/PowerUpSlot/PowerUpIcon
@onready var power_up_timer_label: Label = $Root/BottomLeft/PowerUpSlot/PowerUpTimerLabel
@onready var inventory_icon: TextureRect = $Root/BottomLeft/InventorySlot/InventoryIcon
@onready var objective_title: Label = $Root/TopRight/ObjectiveTitle
@onready var objective_list: VBoxContainer = $Root/TopRight/ObjectiveList

var _level_objectives: LevelObjectives = null

var _power_up_icon_texture: Texture2D
var _player: Node2D = null


func _ready() -> void:
	SuspicionManager.suspicion_changed.connect(_on_suspicion_changed)
	_on_suspicion_changed(SuspicionManager.suspicion)

	_power_up_icon_texture = _make_placeholder_icon(Color(0.55, 0.2, 0.85))

	power_up_icon.visible = false
	power_up_timer_label.visible = false
	inventory_icon.visible = false

	_level_objectives = get_tree().get_first_node_in_group("level_objectives") as LevelObjectives
	if _level_objectives:
		EventBus.objective_completed.connect(_on_objective_completed)
	_render_objectives()

	_player = get_tree().get_first_node_in_group("player")
	EventBus.power_up_activated.connect(_on_power_up_activated)
	EventBus.power_up_expired.connect(_on_power_up_expired)


func _process(_delta: float) -> void:
	if not power_up_timer_label.visible or _player == null:
		return
	power_up_timer_label.text = "%.1fs" % _player.get_invisibility_time_left()


func _on_suspicion_changed(value: float) -> void:
	suspicion_bar.value = value * 100.0
	suspicion_label.visible = value > 0.0
	suspicion_bar.visible = value > 0.0


func _on_power_up_activated(item_id: StringName, _duration: float) -> void:
	if item_id != &"invisibility_potion":
		return
	set_active_power_up(_power_up_icon_texture)
	power_up_timer_label.visible = true


func _on_power_up_expired(item_id: StringName) -> void:
	if item_id != &"invisibility_potion":
		return
	clear_power_up()
	power_up_timer_label.visible = false


func _make_placeholder_icon(color: Color) -> ImageTexture:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func set_active_power_up(icon: Texture2D) -> void:
	power_up_icon.texture = icon
	power_up_icon.visible = icon != null


func clear_power_up() -> void:
	set_active_power_up(null)


func set_has_key(has_key: bool) -> void:
	inventory_icon.visible = has_key


func _on_objective_completed(_objective_id: StringName) -> void:
	_render_objectives()


func _render_objectives() -> void:
	for child in objective_list.get_children():
		child.queue_free()

	if _level_objectives == null:
		objective_title.text = "Objectives"
		return

	for objective in _level_objectives.objectives:
		var label := Label.new()
		label.text = ("[x] " if objective.is_complete else "[ ] ") + objective.label
		objective_list.add_child(label)

	objective_title.text = "Objectives (%d/%d)" % [_level_objectives.completed_count, _level_objectives.total()]
