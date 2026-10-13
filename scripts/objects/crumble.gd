extends StaticBody2D
# Bloc qui s'effrite. Les variantes (crumble_retro.tscn...) héritent de crumble.tscn
# et ne changent que la planche du Sprite et la couleur des Debris.

## Désactivé, le bloc reste détruit une fois tombé.
@export var respawns = true
@export var rebuild_delay = 3.0
## Durée de l'animation de fissure avant que le bloc tombe.
@export var crack_time = 0.5
var timer = 0.0
var broken = false
var cracking = false
@onready var sprite = $Sprite
@onready var touch = $Touch


func _physics_process(delta):
	if broken:
		if not respawns:
			return
		timer -= delta
		if timer <= 0 and not touched_by_player():
			rebuild()
	elif cracking:
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
	cracking = true
	Sfx.play("bump", 0.7, -6.0)
	var crack = create_tween()
	crack.tween_method(show_crack, 1.0, float(sprite.hframes), crack_time)
	crack.tween_callback(crumble)


# Frame 0 = intact, frames 1..hframes-1 = fissures.
func show_crack(step):
	sprite.frame = mini(int(step), sprite.hframes - 1)


func crumble():
	broken = true
	cracking = false
	timer = rebuild_delay
	sprite.position = Vector2.ZERO
	sprite.frame = 0
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
