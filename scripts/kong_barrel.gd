extends CharacterBody2D

const RADIUS = 4.0
const FRAMES = 8
const ROLL = 45.0
const GRAVITY = 500.0
const BLAST = 16.0
const BOOM = preload("res://scenes/barrel_boom.tscn")

@export var dir = 1.0
@export var fire = false
var spin = 0.0
@onready var sprite = $Sprite


func _physics_process(delta):
	if on_spikes():
		explode()
		return
	velocity.x = dir * ROLL
	velocity.y += GRAVITY * delta
	var falling = velocity.y
	move_and_slide()
	if is_on_wall():
		dir = -dir
		Sfx.play("bump", randf_range(0.9, 1.1), -8.0)
	if is_on_floor() and falling > 120:
		Sfx.play("land", randf_range(0.8, 1.0), -10.0)

	spin += velocity.x * delta / RADIUS
	sprite.frame = posmod(roundi(spin / PI * FRAMES), FRAMES)

	for body in $Hit.get_overlapping_bodies():
		if body.has_method("stun") and body.is_physics_processing():
			explode()
			return

	if position.y > 1000:
		queue_free()


func on_spikes():
	return not overlap(RADIUS + 0.5, 4).is_empty()


func explode():
	Sfx.play("boom")
	var boom = BOOM.instantiate()
	boom.position = position
	get_parent().add_child(boom)
	for hit in overlap(BLAST, 2):
		blast(hit.collider)
	queue_free()


func blast(body):
	if not body.has_method("stun"):
		return
	if not body.is_physics_processing():
		return
	if fire:
		body.die()
	elif body.global_position.x >= global_position.x:
		body.stun(1.0)
	else:
		body.stun(-1.0)


func overlap(radius, mask):
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = CircleShape2D.new()
	query.shape.radius = radius
	query.transform = global_transform
	query.collision_mask = mask
	return get_world_2d().direct_space_state.intersect_shape(query)
