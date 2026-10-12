extends RigidBody2D

const FUSE = 3.0
const BLAST = 28.0
const KILL = 10.0
const PUSH = 220.0
const PLAYERS = 2
const OBJECTS = 32
const BOOM = preload("res://scenes/objects/barrel_boom.tscn")

var fuse = FUSE
var blink = 0.0
@onready var sprite = $Sprite


func _physics_process(delta):
	fuse -= delta
	blink -= delta
	if fuse <= 0:
		explode()
		return
	if blink <= 0:
		blink = 0.05 + fuse * 0.08
		flash()


func flash():
	if sprite.frame == 0:
		sprite.frame = 1
		Sfx.play("tick", 1.6, -14.0)
	else:
		sprite.frame = 0


func explode():
	Sfx.play("boom")
	var boom = BOOM.instantiate()
	boom.position = position
	get_parent().add_child(boom)
	for hit in overlap():
		blast(hit.collider)
	queue_free()


func blast(body):
	if body == self:
		return
	if body.has_method("stun"):
		hurt(body)
	elif body is RigidBody2D:
		body.apply_central_impulse(global_position.direction_to(body.global_position) * PUSH)


func hurt(player):
	if not player.is_physics_processing():
		return
	if global_position.distance_to(player.global_position) < KILL:
		player.die()
	elif player.is_dazed():
		return
	elif player.global_position.x >= global_position.x:
		player.stun(1.0)
	else:
		player.stun(-1.0)


func overlap():
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = CircleShape2D.new()
	query.shape.radius = BLAST
	query.transform = global_transform
	query.collision_mask = PLAYERS + OBJECTS
	return get_world_2d().direct_space_state.intersect_shape(query)
