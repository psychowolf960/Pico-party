extends Node2D

const STACK = 13.0

var opened = false
var blink = 0.0


func _process(delta):
	blink += delta
	if opened and not is_taken():
		$Arrow.visible = fmod(blink, 0.5) < 0.3
	else:
		$Arrow.visible = false


func _physics_process(_delta):
	var bodies = $Shaft.get_overlapping_bodies()
	if bodies.size() < 2:
		return
	var lowest = bodies[0]
	for body in bodies:
		if body.global_position.y > lowest.global_position.y:
			lowest = body
	var head = lowest.global_position.y - STACK
	for body in bodies:
		if body != lowest and body.global_position.y > head:
			body.global_position.y = head
			body.velocity.y = 0


func open():
	opened = true
	$Lid.hide()
	$Lid/Shape.set_deferred("disabled", true)


func close():
	opened = false
	$Lid.show()
	$Lid/Shape.set_deferred("disabled", false)


func is_taken():
	return $Inside.has_overlapping_bodies()
