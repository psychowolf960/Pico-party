extends Node2D

const STARTS = [Vector2(0, 0), Vector2(96, 0), Vector2(32, 0), Vector2(64, 0)]
const CRATE = preload("res://scenes/objects/crate.tscn")
const BARREL = preload("res://scenes/objects/belt_barrel.tscn")
const BALL = preload("res://scenes/objects/ball.tscn")
const JELLY = preload("res://scenes/objects/jelly.tscn")
const BOMB = preload("res://scenes/objects/bomb.tscn")
const ANVIL = preload("res://scenes/objects/anvil.tscn")
const SPIKE_BALL = preload("res://scenes/objects/spike_ball.tscn")
const OBJECTS = 6
const START_SPEED = 18.0
const RAMP = 0.4
const MAX_SPEED = 42.0
const FIRST_WARNING = 2.0
const WARNING_DROP = 0.85
const MIN_WARNING = 0.25
const FIRST_DROP = 2.2
const DROP_SPEEDUP = 0.97
const MIN_DROP = 0.6
const MAX_JUNK = 14
const OPEN_TIME = 0.5
const HOPPER = Vector2(0, 4)
const PAIR_CHANCE = 0.35
const PAIR_GAP = 6.5
const ROLLER_STEP = 6.0
const CALM = Color("fbf236")
const ALARM = Color("e8475c")

var views = []
var players = []
var alive = []
var scores = []
var deaths = 0
var dir = 1.0
var speed = 0.0
var warning = FIRST_WARNING
var warned = false
var scroll = 0.0
var elapsed = 0.0
var running = false


func _ready():
	views = CouchPlayers.shared_screen(self, STARTS)
	for view in views:
		players.append(view.player)
	for player in players:
		player.respawns = false
		player.fall_limit = %Belt.position.y - 6
		player.set_collision_mask_value(OBJECTS, true)
		player.died.connect(_on_player_died.bind(player))
		player.set_physics_process(false)
		alive.append(player)
		scores.append(0)
	show_arrows(dir, CALM)
	await Minigame.count_down(self, views)
	%Hint.hide()
	for player in players:
		player.set_physics_process(true)
	running = true
	%Drop.wait_time = FIRST_DROP
	%Drop.start()
	%Flip.start(randf_range(3.0, 5.0))
	drop()


func _physics_process(delta):
	if not running:
		return
	elapsed += delta
	speed = minf(START_SPEED + RAMP * elapsed, MAX_SPEED)
	%Belt.constant_linear_velocity = Vector2(speed * dir, 0)
	scroll = fposmod(scroll + speed * dir * delta, ROLLER_STEP * 4)
	%Tread.region_rect.position.x = -scroll
	%RollerLeft.frame = floori(scroll / ROLLER_STEP)
	%RollerRight.frame = %RollerLeft.frame
	if warned:
		%Arrows.visible = fmod(elapsed, 0.2) < 0.1


func _on_flip_timeout():
	if not running:
		return
	if warned:
		flip()
	else:
		warn()


func warn():
	warned = true
	show_arrows(-dir, ALARM)
	Sfx.play("alert")
	%Flip.start(warning)


func flip():
	warned = false
	dir = -dir
	warning = maxf(warning * WARNING_DROP, MIN_WARNING)
	show_arrows(dir, CALM)
	Sfx.play("crumble", 0.6, -4.0)
	%Flip.start(randf_range(2.5, 5.0))


func show_arrows(side, color):
	%Arrows.show()
	%Arrows.modulate = color
	for arrow in %Arrows.get_children():
		arrow.flip_h = side < 0


func _on_drop_timeout():
	%Drop.wait_time = maxf(%Drop.wait_time * DROP_SPEEDUP, MIN_DROP)
	if %Junk.get_child_count() < MAX_JUNK:
		drop()


func drop():
	var closed = []
	for pipe in %Pipes.get_children():
		if pipe.frame == 0:
			closed.append(pipe)
	if closed.is_empty():
		return
	var pipe = closed.pick_random()
	var scene = pick_junk()
	pipe.frame = 1
	Sfx.play("pass", 1.4, -8.0)
	await get_tree().create_timer(OPEN_TIME).timeout
	pipe.frame = 0
	if not running:
		return
	var spot = pipe.position + HOPPER
	if scene == CRATE and randf() < PAIR_CHANCE:
		spawn(CRATE, spot + Vector2(-PAIR_GAP, 0))
		spawn(CRATE, spot + Vector2(PAIR_GAP, 0))
	else:
		spawn(scene, spot)


func spawn(scene, spot):
	var junk = scene.instantiate()
	junk.position = spot
	if scene == BARREL:
		junk.dir = [-1.0, 1.0].pick_random()
	%Junk.add_child(junk)


func pick_junk():
	var choices = [CRATE, CRATE, CRATE, CRATE, BALL, BALL, BARREL]
	if elapsed > 15:
		choices.append(JELLY)
		choices.append(BOMB)
	if elapsed > 30:
		choices.append(ANVIL)
		choices.append(BOMB)
	if elapsed > 45:
		choices.append(SPIKE_BALL)
		choices.append(SPIKE_BALL)
		choices.append(ANVIL)
	return choices.pick_random()


func _on_bin_body_entered(body):
	body.queue_free()


func _on_player_died(player):
	if not player in alive:
		return
	alive.erase(player)
	scores[player.index] = deaths
	deaths += 1
	if running and alive.size() < 2:
		end_game()


func end_game():
	running = false
	%Drop.stop()
	%Flip.stop()
	%Belt.constant_linear_velocity = Vector2.ZERO
	show_arrows(dir, CALM)
	if alive:
		var winner = alive[0]
		winner.set_physics_process(false)
		scores[winner.index] = deaths
		Minigame.show_winner(views, winner.index)
	else:
		Minigame.show_banner(views, "egalite !")
	await get_tree().create_timer(3.0).timeout
	CouchParty.finish(CouchParty.rank(scores))


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
