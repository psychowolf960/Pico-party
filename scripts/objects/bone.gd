extends NinePatchRect

const MARGIN = 8.0
const HIT = 1.5

var velocity = Vector2.ZERO


func _physics_process(delta):
	position += velocity * delta
	var area = Rect2(Vector2.ZERO, get_parent().size).grow(MARGIN)
	if not area.intersects(get_rect()):
		queue_free()


func hits(spot):
	return get_rect().grow(HIT).has_point(spot)
