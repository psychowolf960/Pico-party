extends CharacterBody2D

signal died

const FEET = Vector2(0, 4)
const HOLD = Vector2(0, -13)
const PLATFORMS = 4
const DROP_TIME = 0.2
const WOOD = 1
const SKINS = [
	preload("res://art/player_frames.tres"),
	preload("res://art/player2_frames.tres"),
	preload("res://art/player3_frames.tres"),
	preload("res://art/player4_frames.tres"),
]

@export var index = 0
@export var respawns = true
@export var fall_limit = 200.0
@export var speed = 60.0
@export var max_fall = INF
var love_points = 0
var coyote = 0.0
var can_wall_jump = true
var dust_timer = 0.0
var step_timer = 0.0
var blink
var held = null
var stunned = 0.0
var sprung = false
var dropping = 0.0
var dust = preload("res://scripts/dust.gd").new()
@onready var sprite = $Sprite
@onready var stars = $Stars
@onready var spawn = global_position


func _ready():
	sprite.sprite_frames = SKINS[CouchPlayers.skin(index)]
	add_child(dust, false, INTERNAL_MODE_FRONT)
	for barrel in get_tree().get_nodes_in_group("barrel"):
		barrel.add_collision_exception_with(self)


func _physics_process(delta):
	stunned = maxf(stunned - delta, 0)
	dropping = maxf(dropping - delta, 0)
	set_collision_mask_value(PLATFORMS, dropping == 0)
	var dazed = is_dazed()
	var dir = 0.0 if dazed else signf(Input.get_axis(act("left"), act("right")))
	var was_grounded = is_on_floor()
	var wall = 0.0 if was_grounded else wall_side()

	coyote = 0.1 if was_grounded else coyote - delta
	if was_grounded:
		can_wall_jump = true

	var accel = 400
	if was_grounded:
		accel = 900
	velocity.x = move_toward(velocity.x, dir * speed, accel * delta)
	if wall and not held and not dazed and Input.is_action_pressed(act("x")):
		velocity.y = 0
	else:
		velocity.y += 500 * delta
		if wall and dir == wall:
			velocity.y = minf(velocity.y, 25)
	velocity.y = minf(velocity.y, max_fall)

	if not dazed:
		handle_buttons(dir, wall)
	if velocity.y >= 0:
		sprung = false
	if Input.is_action_just_released(act("o")) and velocity.y < 0 and not sprung:
		velocity.y /= 2

	var fall_speed = velocity.y
	if velocity.x and not is_on_floor():
		stop_at_platform_end(signf(velocity.x), absf(velocity.x) * delta)
	move_and_slide()
	if held:
		held.global_position = global_position + HOLD

	var grounded = is_on_floor()
	kick_dust(delta, dir, wall, grounded, grounded and not was_grounded and fall_speed > 60)
	if position.y > fall_limit:
		die()
	animate(dazed, dir, wall, grounded)


func handle_buttons(dir, wall):
	if Input.is_action_just_pressed(act("x")):
		if held:
			throw(dir)
		elif not wall:
			pick_up()

	if Input.is_action_just_pressed(act("o")):
		if Input.is_action_pressed(act("down")) and drop_through():
			coyote = 0
		elif coyote > 0:
			velocity.y = -150
			coyote = 0
			Sfx.play("jump")
			puff(FEET, 5, Vector2(0, -20), 1.4)
		elif wall and can_wall_jump:
			can_wall_jump = false
			velocity = Vector2(-wall * 75, -140)
			Sfx.play("jump", 1.2)
			puff(Vector2(wall * 3, 0), 5, Vector2(-wall * 25, -10), 0.6)


func kick_dust(delta, dir, wall, grounded, landed):
	dust_timer -= delta
	step_timer -= delta
	if landed:
		Sfx.play("land", 1.0, -4.0)
		step_timer = 0.22
	elif grounded and dir and step_timer <= 0:
		Sfx.play("step", randf_range(0.9, 1.1), -8.0)
		step_timer = 0.22
		puff(FEET + Vector2(-2, 0), 3, Vector2(-25, -8), 0.4)
		puff(FEET + Vector2(2, 0), 3, Vector2(25, -8), 0.4)
	elif grounded and dir and dust_timer <= 0:
		puff(FEET - Vector2(dir * 2, 0), 1, Vector2(-dir * 15, -12), 0.5)
		dust_timer = 0.12
	elif wall and velocity.y > 0 and dust_timer <= 0:
		puff(Vector2(wall * 3, -4), 1, Vector2(-wall * 8, -15), 0.4)
		dust_timer = 0.1


func animate(dazed, dir, wall, grounded):
	stars.visible = dazed
	if dazed:
		stars.position.x = sin(stunned * 10) * 4

	if dir:
		sprite.flip_h = dir < 0
	if held and sprite.sprite_frames.has_animation("carry"):
		sprite.play("carry")
	elif grounded:
		sprite.play("run" if dir else "idle")
	elif wall:
		sprite.flip_h = wall < 0
		sprite.play("wall")
	else:
		sprite.play("jump" if velocity.y < 0 else "fall")


func puff(offset, amount, vel, life):
	dust.puff(global_position + offset, amount, vel, life)


func act(button):
	return CouchPlayers.action(index, button)


func wall_side():
	if test_move(transform, Vector2.RIGHT) or not is_nan(platform_end(1, 1)):
		return 1.0
	if test_move(transform, Vector2.LEFT) or not is_nan(platform_end(-1, 1)):
		return -1.0
	return 0.0


# Les plateformes en bois se traversent par le dessous, mais leurs côtés font mur.
# Renvoie la position x du côté de plateforme situé devant le joueur
# (vers side, à moins de dist pixels), ou NAN s'il n'y en a pas.
func platform_end(side, dist):
	var level = platform_layer_ahead(side, dist)
	if level == null:
		return NAN
	var box = $Hitbox.shape.size
	var center = $Hitbox.global_position
	var front = center.x + side * box.x / 2
	var first = cell_at(level, Vector2(front, center.y - box.y / 2 + 1))
	var last = cell_at(level, Vector2(front + side * dist, center.y + box.y / 2 - 1))
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + side, side):
			var cell = Vector2i(x, y)
			if not is_platform_start(level, cell, side):
				continue
			var edge = cell_edge(level, cell, side)
			if (edge - front) * side >= -0.01:
				return edge
	return NAN


# Le calque de plateformes s'il touche la zone de dist pixels devant le joueur.
func platform_layer_ahead(side, dist):
	var box = $Hitbox.shape.size
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = RectangleShape2D.new()
	query.shape.size = Vector2(dist, box.y - 2)
	query.transform = Transform2D(0, $Hitbox.global_position + Vector2(side * (box.x + dist) / 2, 0))
	query.collision_mask = 1 << (PLATFORMS - 1)
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 1):
		if hit.collider is TileMapLayer:
			return hit.collider
	return null


func cell_at(level, point):
	return level.local_to_map(level.to_local(point))


# Vrai si cette case est la première d'une plateforme en venant de side.
func is_platform_start(level, cell, side):
	if level.get_cell_source_id(cell) != WOOD:
		return false
	var behind = cell - Vector2i(side, 0)
	return level.get_cell_source_id(behind) != WOOD


# Position x du côté de la case tourné vers le joueur.
func cell_edge(level, cell, side):
	var middle = level.to_global(level.map_to_local(cell)).x
	return middle - side * level.tile_set.tile_size.x / 2.0


func stop_at_platform_end(side, dist):
	var edge = platform_end(side, dist + 1)
	if not is_nan(edge):
		global_position.x = edge - side * $Hitbox.shape.size.x / 2 - $Hitbox.position.x
		velocity.x = 0


func drop_through():
	if not is_on_floor():
		return false
	set_collision_mask_value(PLATFORMS, false)
	if test_move(transform, Vector2.DOWN):
		set_collision_mask_value(PLATFORMS, true)
		return false
	dropping = DROP_TIME
	return true


func pick_up():
	for barrel in get_tree().get_nodes_in_group("barrel"):
		if barrel.can_grab() and global_position.distance_to(barrel.global_position) < 12:
			held = barrel
			barrel.grab(self)
			Sfx.play("grab")
			return


func throw(dir):
	var facing = dir
	if dir == 0:
		facing = -1.0 if sprite.flip_h else 1.0
	if Input.is_action_pressed(act("down")):
		held.release(Vector2(facing * 20, 0))
	elif Input.is_action_pressed(act("up")):
		held.release(Vector2(velocity.x * 0.5, -190))
		Sfx.play("throw")
	else:
		held.release(Vector2(facing * 130 + velocity.x * 0.5, -30))
		Sfx.play("throw")
	held = null


func drop():
	if held:
		held.release(Vector2.ZERO)
		held = null


func bounce(power):
	velocity.y = -power
	sprung = true
	coyote = 0
	can_wall_jump = true
	puff(FEET, 6, Vector2(0, 200), 0.6)


func is_dazed():
	return stunned > 0


func stun(push):
	stunned = 1.2
	velocity = Vector2(push * 80, -100)
	drop()
	Sfx.play("hit")


func die():
	if blink:
		blink.kill()
	drop()
	stunned = 0
	stars.hide()
	sprite.hide()
	set_physics_process(false)
	$Hitbox.set_deferred("disabled", true)
	Sfx.play("die")
	var frame = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var particles = $Explosion.process_material
	particles.set_shader_parameter("sprite", frame.atlas)
	particles.set_shader_parameter("sprite_frame", int(frame.region.position.x / 16))
	particles.set_shader_parameter("sprite_hframes", frame.atlas.get_width() / 16)
	$Explosion.scale.x = -1 if sprite.flip_h else 1
	$Explosion.restart()
	died.emit()
	if not respawns:
		return
	await get_tree().create_timer(1.0).timeout
	revive()


func revive():
	if blink:
		blink.kill()
	global_position = spawn
	velocity = Vector2.ZERO
	stunned = 0
	dropping = 0.0
	set_collision_mask_value(PLATFORMS, true)
	can_wall_jump = true
	stars.hide()
	$Hitbox.set_deferred("disabled", false)
	sprite.show()
	set_physics_process(true)
	Sfx.play("respawn")
	blink = create_tween().set_loops(5)
	blink.tween_callback(sprite.hide).set_delay(0.08)
	blink.tween_callback(sprite.show).set_delay(0.08)


func _on_danger_zone_body_entered(_body):
	die.call_deferred()
