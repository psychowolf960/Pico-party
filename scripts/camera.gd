extends Camera2D

@export var target: Node2D
@export var level: TileMapLayer
var room = Vector2.ZERO
var bounds = Vector2(128, 128)
var sliding = false


func _ready():
	anchor_mode = ANCHOR_MODE_FIXED_TOP_LEFT
	bounds = Minigame.level_bounds(level).end
	room = room_of(target.global_position)
	global_position = room


func _process(_delta):
	var next = room_of(target.global_position)
	if sliding or next == room:
		return
	room = next
	sliding = true
	target.set_physics_process(false)
	var slide = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide.tween_property(self, "global_position", room, 0.4)
	await slide.finished
	target.set_physics_process(true)
	sliding = false


func room_of(point):
	var size = get_viewport_rect().size
	var corner = (point / size).floor() * size
	return corner.clamp(Vector2.ZERO, bounds - size)
