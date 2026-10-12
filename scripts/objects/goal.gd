extends Area2D

signal reached(body)

var done = false


func _on_body_entered(body):
	if done:
		return
	done = true
	body.set_physics_process(false)
	body.velocity = Vector2.ZERO
	$Victory.play()
	reached.emit(body)
