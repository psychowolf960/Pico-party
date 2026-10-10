extends CharacterBody2D

const RADIUS = 4.0
const FRAMES = 8
const STANDING = 8
const HARMLESS = 50.0
const BLAST = 16.0
const BOOM = preload("res://scenes/barrel_boom.tscn")
@export var respawn_time = 3.0
@export var respawns = true
@export var fall_limit = 200.0
var dead = false
var holder = null
var thrower = null
var grace = 0.0
var spin = 0.0
@onready var sprite = $Sprite
@onready var home = global_position


func _ready():
	sprite.frame = STANDING


func _physics_process(delta):
	if on_spikes():
		explode()
		return
	if holder:
		return
	grace -= delta
	velocity.y += 500 * delta
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, 25 * delta)

	var before = velocity
	move_and_slide()
	if is_on_wall():
		velocity.x = -before.x * 0.6
		bump(before.x)
	if is_on_floor() and before.y > 80:
		velocity.y = -before.y * 0.35
		bump(before.y)

	if sprite.frame != STANDING:
		spin += velocity.x * delta / RADIUS
		sprite.frame = posmod(roundi(spin / PI * FRAMES), FRAMES)

	if dangerous():
		for body in $Hit.get_overlapping_bodies():
			if body.has_method("stun") and not body.is_dazed() and not (body == thrower and grace > 0):
				var push = signf(velocity.x)
				if velocity.x == 0:
					push = signf(body.global_position.x - global_position.x)
				body.stun(push)
				velocity = Vector2(-velocity.x * 0.3, -80)
				break

	if position.y > fall_limit:
		vanish()


func dangerous():
	return velocity.length() > HARMLESS


func can_grab():
	return not dead and not holder and not dangerous()


func grab(by):
	holder = by
	velocity = Vector2.ZERO
	if sprite.frame == STANDING:
		sprite.frame = 0
	$Shape.disabled = true


func release(vel):
	thrower = holder
	holder = null
	grace = 0.3
	velocity = vel
	$Shape.disabled = false
	if test_move(transform, Vector2.ZERO):
		global_position = thrower.global_position


func launch(vel):
	velocity = vel
	sprite.frame = 0


func bounce(power):
	if not holder:
		velocity.y = -power


func on_spikes():
	return not overlap(RADIUS + 0.5, 4).is_empty()


func explode():
	Sfx.play("boom")
	var boom = BOOM.instantiate()
	boom.position = position
	get_parent().add_child(boom)
	for hit in overlap(BLAST, 2):
		var body = hit.collider
		if body.has_method("stun") and not body.is_dazed():
			body.stun(1.0 if body.global_position.x >= global_position.x else -1.0)
	vanish()


func vanish():
	dead = true
	if holder:
		holder.held = null
		holder = null
	hide()
	set_physics_process(false)
	$Shape.set_deferred("disabled", true)
	if not respawns:
		queue_free()
		return
	await get_tree().create_timer(respawn_time).timeout
	respawn()


func respawn():
	global_position = home
	velocity = Vector2.ZERO
	thrower = null
	grace = 0.0
	spin = 0.0
	sprite.frame = STANDING
	$Shape.set_deferred("disabled", false)
	show()
	set_physics_process(true)
	dead = false
	var blink = create_tween().set_loops(5)
	blink.tween_callback(sprite.hide).set_delay(0.08)
	blink.tween_callback(sprite.show).set_delay(0.08)


func overlap(radius, mask):
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = CircleShape2D.new()
	query.shape.radius = radius
	query.transform = global_transform
	query.collision_mask = mask
	return get_world_2d().direct_space_state.intersect_shape(query)


func bump(speed):
	if absf(speed) > 30:
		Sfx.play("bump", randf_range(0.9, 1.1), -6.0)
