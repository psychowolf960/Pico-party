extends Sprite2D

const MARGIN = 40.0
const HIT = 3.5

var velocity = Vector2.ZERO
var delay = 0.0


func _physics_process(delta):
	if delay > 0:
		delay -= delta
		return
	position += velocity * delta
	var area = Rect2(Vector2.ZERO, get_parent().size).grow(MARGIN)
	if not area.has_point(position):
		queue_free()


func hits(spot):
	return position.distance_to(spot) < HIT
