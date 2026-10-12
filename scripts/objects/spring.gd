extends Area2D

const POWER = 260.0
const RELEASE = 3
@onready var sprite = $Sprite


func _physics_process(_delta):
	if sprite.is_playing():
		return
	for body in get_overlapping_bodies():
		if can_bounce(body):
			sprite.play("boing")
			return


func can_bounce(body):
	return body.has_method("bounce") and body.velocity.y >= 0


func _on_frame_changed():
	if sprite.animation != "boing" or sprite.frame != RELEASE:
		return
	Sfx.play("spring", randf_range(0.95, 1.05))
	for body in get_overlapping_bodies():
		if can_bounce(body):
			body.bounce(POWER)
