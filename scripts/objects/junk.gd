extends RigidBody2D

const FALL_SPEED = 80.0
const POP = 60.0
const THUD = 100.0

@export var deadly = false
@export var crushing = false
@export var knock_speed = 1000.0
@export var pitch = 1.0
var last_velocity = Vector2.ZERO


func _physics_process(_delta):
	for body in $Hit.get_overlapping_bodies():
		if body.has_method("stun") and body.is_physics_processing():
			touch(body)
	if last_velocity.y > THUD and linear_velocity.y < 20:
		Sfx.play("bump", pitch * randf_range(0.9, 1.1), -10.0)
	last_velocity = linear_velocity


func touch(player):
	if deadly:
		player.die()
	elif lands_on(player):
		if crushing:
			player.die()
		else:
			knock(player)
		linear_velocity.y = -POP
	elif impact() > knock_speed:
		knock(player)


func lands_on(player):
	if last_velocity.y < FALL_SPEED:
		return false
	return global_position.y < player.global_position.y - 8


func impact():
	return maxf(last_velocity.length(), linear_velocity.length())


func knock(player):
	if player.is_dazed():
		return
	if player.global_position.x >= global_position.x:
		player.stun(1.0)
	else:
		player.stun(-1.0)
