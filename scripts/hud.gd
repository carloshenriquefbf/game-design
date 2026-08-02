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

var _inventory_items: Array[StringName] = []
var _toast_tween: Tween = null
var _suspicion_tween: Tween = null
var _last_suspicion_value: float = 0.0
var _shown_item_instructions: Dictionary = {}

## StringName item_id -> the TextureRect that shows it's in inventory. Data-
## driven so a new item only needs an entry here, not a new branch in
## _render_inventory().
var _item_slot_icons: Dictionary = {}

## Local countdown for the potion timer/fill UI, driven entirely by the
## duration EventBus.power_up_activated already carries — HUD has no need
## to reach into Player's own timer every frame for this.
var _potion_duration: float = 0.0
var _potion_time_left: float = 0.0


func _ready() -> void:
	SuspicionManager.suspicion_changed.connect(_on_suspicion_changed)
	_on_suspicion_changed(SuspicionManager.suspicion)

	_item_slot_icons = {
		&"invisibility_potion": potion_icon,
		&"wind_bag": wind_bag_icon,
		&"key": key_icon,
	}

	potion_timer_label.visible = false
	_render_inventory()

	EventBus.power_up_activated.connect(_on_power_up_activated)
	EventBus.power_up_expired.connect(_on_power_up_expired)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.item_consumed.connect(_on_item_consumed)


func _process(delta: float) -> void:
	if not potion_timer_label.visible:
		return

	_potion_time_left = maxf(_potion_time_left - delta, 0.0)
	potion_timer_label.text = "%.1fs" % _potion_time_left

	var fraction: float = clampf(_potion_time_left / _potion_duration, 0.0, 1.0) if _potion_duration > 0.0 else 0.0
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


func _on_power_up_activated(item_id: StringName, duration: float) -> void:
	if item_id != &"invisibility_potion":
		return
	potion_active_fill.visible = true
	potion_active_fill.size.y = SLOT_HEIGHT
	potion_active_fill.position.y = 0.0
	potion_timer_label.visible = true
	_potion_duration = duration
	_potion_time_left = duration


func _on_power_up_expired(item_id: StringName) -> void:
	if item_id != &"invisibility_potion":
		return
	potion_active_fill.visible = false
	potion_timer_label.visible = false


func _on_item_picked_up(item_id: StringName, pickup_message: String, instructions: String) -> void:
	_inventory_items.append(item_id)
	_render_inventory()

	var text := pickup_message
	if instructions != "" and _should_show_item_instructions(item_id):
		text = "%s %s" % [text, instructions] if text != "" else instructions

	if text != "":
		_show_pickup_toast(text)


func _on_item_consumed(item_id: StringName) -> void:
	var index := _inventory_items.find(item_id)
	if index != -1:
		_inventory_items.remove_at(index)
	_render_inventory()


func _render_inventory() -> void:
	for item_id: StringName in _item_slot_icons:
		_item_slot_icons[item_id].visible = _inventory_items.has(item_id)


## Returns true (and remembers it) the first time this item_id is passed in
## for the whole lifetime of the running game process, so pickup
## instructions only ever show once per playthrough, even across level
## restarts and retries.
func _should_show_item_instructions(item_id: StringName) -> bool:
	if _shown_item_instructions.has(item_id):
		return false
	_shown_item_instructions[item_id] = true
	return true


func _show_pickup_toast(text: String) -> void:
	if _toast_tween:
		_toast_tween.kill()

	pickup_toast.text = text
	pickup_toast.modulate.a = 0.0

	_toast_tween = create_tween()
	_toast_tween.tween_property(pickup_toast, "modulate:a", 1.0, 0.3)
	_toast_tween.tween_interval(1.5)
	_toast_tween.tween_property(pickup_toast, "modulate:a", 0.0, 0.5)
