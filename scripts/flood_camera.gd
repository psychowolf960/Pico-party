extends Camera2D

const FOLLOW = 8.0

@export var lead = 0.6
var target: Node2D
var bounds = Rect2(0, 0, 128, 128)


func _ready():
	anchor_mode = ANCHOR_MODE_FIXED_TOP_LEFT


func _process(delta):
	var weight = 1.0 - exp(-FOLLOW * delta)
	global_position = global_position.lerp(aim(), weight)


func snap():
	global_position = aim()


func aim():
	var size = get_viewport_rect().size
	var point = target.global_position - size * Vector2(0.5, lead)
	return point.clamp(bounds.position, bounds.end - size)
