extends Area2D


func _on_body_entered(body):
	if is_queued_for_deletion():
		return
	body.love_points += 1
	Sfx.play("love")
	queue_free()
