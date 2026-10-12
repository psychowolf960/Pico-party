extends RigidBody2D

const POWER = 230.0
@onready var sprite = $Sprite


func _physics_process(_delta):
	for body in $Top.get_overlapping_bodies():
		if can_bounce(body):
			body.bounce(POWER)
			squish()


func can_bounce(body):
	if not body.has_method("bounce"):
		return false
	if not body.is_physics_processing():
		return false
	return body.velocity.y >= 0


func squish():
	Sfx.play("spring", randf_range(1.2, 1.4))
	sprite.scale = Vector2(1.5, 0.5)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.4)
