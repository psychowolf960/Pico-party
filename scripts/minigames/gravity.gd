extends Node2D

const STARTS = [Vector2(0, 0), Vector2(16, 0), Vector2(32, 0), Vector2(48, 0)]
const SCREEN = Vector2i(256, 144)
const START_SPEED = 32.0
const RAMP = 1.0
const MAX_SPEED = 56.0
const LEAD = 128.0
const SHOW = 12.0
const MARGIN = 8.0
const GRAVITY = 800.0
const FALL = 240.0
const COYOTE = 0.1
const FEET = Vector2(0, 4)
const HEAD = Vector2(0, -9)
const SPRITE_UP = -4.0
const SPRITE_DOWN = -1.0

var views = []
var players = []
var alive = []
var scores = []
var flipped = []
var deaths = 0
var scroll = 0.0
var water = 0.0
var elapsed = 0.0
var bounds = Rect2()
var running = false


func _ready():
	CouchPlayers.resize(SCREEN)
	bounds = Minigame.level_bounds(%Level)
	water = %Water.position.x
	views = CouchPlayers.shared_screen(self, STARTS)
	for view in views:
		players.append(view.player)
	for player in players:
		player.respawns = false
		player.floor_block_on_wall = false
		player.died.connect(_on_player_died.bind(player))
		player.set_physics_process(false)
		alive.append(player)
		scores.append(0)
		flipped.append(false)
	await Minigame.count_down(self, views)
	%Hint.hide()
	running = true


func _physics_process(delta):
	if not running:
		return
	elapsed += delta
	var speed = minf(START_SPEED + RAMP * elapsed, MAX_SPEED)
	water += speed * delta
	var leader = alive[0]
	for player in alive:
		if player.global_position.x > leader.global_position.x:
			leader = player
	water = maxf(water, leader.global_position.x - LEAD + SHOW)
	scroll = minf(water - SHOW, bounds.end.x - SCREEN.x)
	%Camera.position.x = scroll
	%Water.position.x = water
	for player in alive.duplicate():
		if running:
			move(player, delta)
		if running and is_lost(player):
			player.die()


func move(player, delta):
	var dir = signf(Input.get_axis(player.act("left"), player.act("right")))
	var was_grounded = player.is_on_floor()
	if was_grounded:
		player.coyote = COYOTE
	else:
		player.coyote -= delta
	player.velocity.x = move_toward(player.velocity.x, dir * player.speed, 900 * delta)
	if flipped[player.index]:
		player.velocity.y = maxf(player.velocity.y - GRAVITY * delta, -FALL)
	else:
		player.velocity.y = minf(player.velocity.y + GRAVITY * delta, FALL)
	if player.coyote > 0 and Input.is_action_just_pressed(player.act("o")):
		flip(player)
	var fall_speed = absf(player.velocity.y)
	player.move_and_slide()
	var grounded = player.is_on_floor()
	if grounded and not was_grounded and fall_speed > 60:
		Sfx.play("land", 1.0, -4.0)
	player.animate(false, dir, 0.0, grounded)


func flip(player):
	var i = player.index
	flipped[i] = not flipped[i]
	player.coyote = 0
	player.velocity.y = 0
	if flipped[i]:
		player.up_direction = Vector2.DOWN
		player.sprite.scale.y = -1
		player.sprite.position.y = SPRITE_DOWN
		player.puff(FEET, 5, Vector2(0, -20), 1.4)
	else:
		player.up_direction = Vector2.UP
		player.sprite.scale.y = 1
		player.sprite.position.y = SPRITE_UP
		player.puff(HEAD, 5, Vector2(0, 20), 1.4)
	Sfx.play("jump", 1.4)


func is_lost(player):
	var point = player.global_position
	if point.x - 2 < water:
		return true
	if point.y < bounds.position.y - MARGIN:
		return true
	if point.y > bounds.end.y + MARGIN:
		return true
	return false


func _on_player_died(player):
	if not player in alive:
		return
	alive.erase(player)
	scores[player.index] = deaths
	deaths += 1
	if running and alive.size() < 2:
		if alive:
			end_game(alive[0])
		else:
			end_game(null)


func _on_goal_reached(body):
	if running:
		end_game(body)


func end_game(winner):
	running = false
	for player in alive:
		scores[player.index] = deaths
	if winner:
		scores[winner.index] = deaths + 1
		Minigame.show_winner(views, winner.index)
	else:
		Minigame.show_banner(views, "egalite !")
	await get_tree().create_timer(3.0).timeout
	CouchParty.finish(CouchParty.rank(scores))


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
