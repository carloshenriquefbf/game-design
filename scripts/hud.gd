extends CanvasLayer

@onready var suspicion_bar: TextureProgressBar = $Root/SuspicionBar
@onready var potion_active_fill: ColorRect = $Root/BottomLeft/PotionSlot/ActiveFill
@onready var potion_icon: TextureRect = $Root/BottomLeft/PotionSlot/Icon
@onready var potion_timer_label: Label = $Root/BottomLeft/PotionSlot/TimerLabel
@onready var wind_bag_icon: TextureRect = $Root/BottomLeft/WindBagSlot/Icon
@onready var key_icon: TextureRect = $Root/BottomLeft/KeySlot/Icon
@onready var pickup_toast: Label = $Root/PickupToast

const SLOT_HEIGHT := 48.0

const SUSPICION_FADE_DURATION := 0.3
## Below this fraction, a decreasing suspicion bar fades out proportionally
## (1.0 alpha at the threshold, down to 0.0 at zero). Above it, a
## decreasing bar stays fully opaque — only the final stretch of the
## drain visibly fades.
const SUSPICION_FADE_THRESHOLD := 0.2

var _player: Node2D = null
var _inventory_items: Array[StringName] = []
var _toast_tween: Tween = null
var _suspicion_tween: Tween = null
var _last_suspicion_value: float = 0.0


func _ready() -> void:
	SuspicionManager.suspicion_changed.connect(_on_suspicion_changed)
	_on_suspicion_changed(SuspicionManager.suspicion)

	potion_timer_label.visible = false
	_render_inventory()

	_player = get_tree().get_first_node_in_group("player")
	EventBus.power_up_activated.connect(_on_power_up_activated)
	EventBus.power_up_expired.connect(_on_power_up_expired)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.item_consumed.connect(_on_item_consumed)


func _process(_delta: float) -> void:
	if not potion_timer_label.visible or _player == null:
		return

	var time_left: float = _player.get_invisibility_time_left()
	potion_timer_label.text = "%.1fs" % time_left

	var fraction: float = clampf(time_left / _player.invisibility_duration, 0.0, 1.0)
	var height := SLOT_HEIGHT * fraction
	potion_active_fill.position.y = SLOT_HEIGHT - height
	potion_active_fill.size.y = height


func _on_suspicion_changed(value: float) -> void:
	suspicion_bar.value = value * 100.0

	# SuspicionManager already emits a smoothly interpolated value every
	# frame while draining, so tracking alpha directly to it while
	# decreasing is already smooth on its own — a tween here would fight
	# a constantly-moving target. Rising still gets a deliberate tween so
	# the bar snaps to full attention quickly rather than fading in at
	# the same slow pace suspicion itself ramps up.
	if value <= 0.0:
		_set_suspicion_alpha(0.0)
	elif value > _last_suspicion_value:
		_fade_suspicion_bar_in()
	elif value > SUSPICION_FADE_THRESHOLD:
		_set_suspicion_alpha(1.0)
	else:
		_set_suspicion_alpha(value / SUSPICION_FADE_THRESHOLD)

	_last_suspicion_value = value


func _set_suspicion_alpha(alpha: float) -> void:
	if _suspicion_tween:
		_suspicion_tween.kill()
		_suspicion_tween = null
	suspicion_bar.modulate.a = alpha


func _fade_suspicion_bar_in() -> void:
	if is_equal_approx(suspicion_bar.modulate.a, 1.0):
		return

	if _suspicion_tween:
		_suspicion_tween.kill()

	_suspicion_tween = create_tween()
	_suspicion_tween.tween_property(suspicion_bar, "modulate:a", 1.0, SUSPICION_FADE_DURATION)


func _on_power_up_activated(item_id: StringName, _duration: float) -> void:
	if item_id != &"invisibility_potion":
		return
	potion_active_fill.visible = true
	potion_active_fill.size.y = SLOT_HEIGHT
	potion_active_fill.position.y = 0.0
	potion_timer_label.visible = true


func _on_power_up_expired(item_id: StringName) -> void:
	if item_id != &"invisibility_potion":
		return
	potion_active_fill.visible = false
	potion_timer_label.visible = false


func _on_item_picked_up(item_id: StringName, pickup_message: String, instructions: String) -> void:
	_inventory_items.append(item_id)
	_render_inventory()

	var text := pickup_message
	if instructions != "" and GameManager.should_show_item_instructions(item_id):
		text = "%s %s" % [text, instructions] if text != "" else instructions

	if text != "":
		_show_pickup_toast(text)


func _on_item_consumed(item_id: StringName) -> void:
	var index := _inventory_items.find(item_id)
	if index != -1:
		_inventory_items.remove_at(index)
	_render_inventory()


func _render_inventory() -> void:
	potion_icon.visible = _inventory_items.has(&"invisibility_potion")
	wind_bag_icon.visible = _inventory_items.has(&"wind_bag")
	key_icon.visible = _inventory_items.has(&"key")


func _show_pickup_toast(text: String) -> void:
	if _toast_tween:
		_toast_tween.kill()

	pickup_toast.text = text
	pickup_toast.modulate.a = 0.0

	_toast_tween = create_tween()
	_toast_tween.tween_property(pickup_toast, "modulate:a", 1.0, 0.3)
	_toast_tween.tween_interval(1.5)
	_toast_tween.tween_property(pickup_toast, "modulate:a", 0.0, 0.5)
