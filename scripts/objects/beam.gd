extends ColorRect

const BLINK = 0.1
const HIT = 1.5

@export var warn = 0.7
@export var fire = 0.35
@export var width = 9.0
@export var warn_color = Color("e8475c")
@export var fire_color = Color.WHITE

var vertical = true
var line = 0.0
var time = 0.0
var hot = false


func _ready():
	color = warn_color
	place(1.0)
	Sfx.play("tick", 0.8, -6.0)


func _physics_process(delta):
	time += delta
	if time < warn:
		visible = int(time / BLINK) % 2 == 0
	elif time < warn + fire:
		if not hot:
			hot = true
			show()
			color = fire_color
			place(width)
			Sfx.play("shoot", 0.5)
	else:
		queue_free()


func place(thickness):
	var area = get_parent().size
	var start = roundf(line - thickness / 2)
	if vertical:
		position = Vector2(start, 0)
		size = Vector2(thickness, area.y)
	else:
		position = Vector2(0, start)
		size = Vector2(area.x, thickness)


func hits(spot):
	return hot and get_rect().grow(HIT).has_point(spot)
