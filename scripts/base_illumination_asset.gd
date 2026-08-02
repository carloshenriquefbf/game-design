extends Node2D

const LIGHT_SEGMENTS := 24

@export var flip_h: bool = false:
	set(value):
		flip_h = value
		if is_node_ready():
			_apply_flip()

## Reach of the glow. Full circle when light_angle_degrees is 360, a wedge
## in front of the fixture's facing direction otherwise (see flip_h). Kept
## small and subtle on purpose — it must not read as a guard vision cone.
@export var light_radius: float = 60.0:
	set(value):
		light_radius = value
		if is_node_ready():
			_build_light_polygon()

## Alpha here is the glow's *center* opacity — the rim always fades to 0
## (see _build_light_polygon), so it reads as a soft falloff rather than
## the guard vision cone's flat, hard-edged fill.
@export var light_color: Color = Color(1.0, 0.85, 0.5, 0.15):
	set(value):
		light_color = value
		if is_node_ready():
			_build_light_polygon()

## 360 lights the full circle (candles, freestanding torches). Anything
## less is a wedge centered on the facing direction (wall-mounted torches).
@export var light_angle_degrees: float = 360.0:
	set(value):
		light_angle_degrees = value
		if is_node_ready():
			_build_light_polygon()

## Where the glow originates, in the sprite's UNFLIPPED local space
## (auto-mirrored in X alongside flip_h). Some sprite frames (e.g. the
## side torches) aren't centered on the node origin, so the flame can sit
## well off from local (0, 0) — this re-anchors the glow onto the actual
## flame instead of the frame's geometric center. Leave at ZERO for
## sprites that already are centered.
@export var light_origin: Vector2 = Vector2.ZERO:
	set(value):
		light_origin = value
		if is_node_ready():
			_build_light_polygon()

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var light: Polygon2D = $Light

var lit: bool = true


func _ready() -> void:
	_apply_flip()


func extinguish() -> void:
	if not lit:
		return

	lit = false
	sprite.play(&"blown")
	light.visible = false
	EventBus.candles_extinguished.emit()


func _apply_flip() -> void:
	sprite.flip_h = flip_h
	_build_light_polygon()


func _build_light_polygon() -> void:
	# Godot's default polygon auto-triangulation doesn't preserve a
	# center-out fan, so the vertex_colors gradient renders as uneven
	# blotches instead of a smooth radial falloff (and chokes entirely on
	# the duplicate wrap-around point a naive full circle would produce).
	# Building the triangle fan explicitly via `polygons` sidesteps both.
	var rim_color := Color(light_color.r, light_color.g, light_color.b, 0.0)
	var origin := light_origin
	if flip_h:
		origin.x = -origin.x
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var triangles: Array[PackedInt32Array] = []

	points.append(origin)
	colors.append(light_color)

	if light_angle_degrees >= 360.0:
		for i in range(LIGHT_SEGMENTS):
			var t := TAU * float(i) / float(LIGHT_SEGMENTS)
			points.append(origin + Vector2.RIGHT.rotated(t) * light_radius)
			colors.append(rim_color)
		for i in range(LIGHT_SEGMENTS):
			var next_i := (i + 1) % LIGHT_SEGMENTS
			triangles.append(PackedInt32Array([0, 1 + i, 1 + next_i]))
	else:
		var half_angle := deg_to_rad(light_angle_degrees) / 2.0
		var direction := Vector2.LEFT if flip_h else Vector2.RIGHT
		for i in range(LIGHT_SEGMENTS + 1):
			var t := lerpf(-half_angle, half_angle, float(i) / float(LIGHT_SEGMENTS))
			points.append(origin + direction.rotated(t) * light_radius)
			colors.append(rim_color)
		for i in range(LIGHT_SEGMENTS):
			triangles.append(PackedInt32Array([0, 1 + i, 2 + i]))

	light.polygon = points
	light.vertex_colors = colors
	light.polygons = triangles
