extends StaticBody2D

@export var rebuild_delay = 3.0
var timer = 0.0
var broken = false
@onready var sprite = $Sprite
@onready var touch = $Touch


func _physics_process(delta):
	if broken:
		timer -= delta
		if timer <= 0 and not touched_by_player():
			rebuild()
	elif sprite.animation == "crack":
		sprite.position.x = randi_range(-1, 1)
	elif touched_by_player() or touched_by_barrel():
		shake()


func touched_by_player():
	for body in touch.get_overlapping_bodies():
		if body.has_method("stun"):
			return true
	return false


func touched_by_barrel():
	for body in touch.get_overlapping_bodies():
		if body.is_in_group("barrel") and body.dangerous():
			return true
	return false


func shake():
	sprite.play("crack")
	Sfx.play("bump", 0.7, -6.0)


func _on_animation_finished():
	if sprite.animation == "crack":
		crumble()


func crumble():
	broken = true
	timer = rebuild_delay
	sprite.position = Vector2.ZERO
	sprite.play("idle")
	sprite.hide()
	$Shape.set_deferred("disabled", true)
	$Debris.restart()
	Sfx.play("crumble", randf_range(0.9, 1.1), -4.0)


func rebuild():
	broken = false
	sprite.modulate.a = 0.0
	sprite.show()
	$Shape.set_deferred("disabled", false)
	var fade = create_tween()
	fade.tween_property(sprite, "modulate:a", 1.0, 0.3)
