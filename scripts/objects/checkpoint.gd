extends Area2D


func _on_body_entered(body):
	if body.spawn != global_position:
		body.spawn = global_position
		Sfx.play("checkpoint")
