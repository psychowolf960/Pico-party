extends Node2D

const STARTS = [Vector2(0, 0), Vector2(16, 0), Vector2(32, 0), Vector2(48, 0)]
const SCREEN = Vector2i(256, 144)
const BOTTOM = 120.0
const HEAD = 9.0
const WARN = 1.0
const START_SPEED = 20.0
const SPEED_STEP = 4.0
const RUSH_SPEED = 90.0
const HOLD = 0.6
const LIFT = 0.8
const BREAK = 1.2

var views = []
var players = []
var alive = []
var scores = []
var holes = []
var cycle = 1
var speed = START_SPEED
var warning = 0.0
var falling = false
var running = false
@onready var top = %Ceiling.position.y


func _ready():
	CouchPlayers.resize(SCREEN)
	holes = %Holes.get_children()
	views = CouchPlayers.shared_screen(self, STARTS)
	for view in views:
		players.append(view.player)
	for player in players:
		player.respawns = false
		player.died.connect(_on_player_died.bind(player))
		player.set_physics_process(false)
		alive.append(player)
		scores.append(0)
	open_holes()
	await Minigame.count_down(self, views)
	%Hint.hide()
	for player in players:
		player.set_physics_process(true)
	running = true
	start_cycle()


func _physics_process(delta):
	if not running:
		return
	if warning > 0:
		warning -= delta
		%Ceiling.position.x = randi_range(-1, 1)
		if warning <= 0:
			%Ceiling.position.x = 0
			falling = true
	elif falling:
		descend(delta)
	crush()


func start_cycle():
	speed = START_SPEED + SPEED_STEP * (cycle - 1)
	warning = WARN
	Sfx.play("alert")


func descend(delta):
	if holes_full():
		speed = RUSH_SPEED
	%Ceiling.position.y = minf(%Ceiling.position.y + speed * delta, BOTTOM)
	if %Ceiling.position.y >= BOTTOM:
		falling = false
		slam()


func holes_full():
	var opened = 0
	var taken = 0
	for hole in holes:
		if hole.opened:
			opened += 1
			if hole.is_taken():
				taken += 1
	return taken >= opened or taken >= alive.size()


func crush():
	var crushed = []
	for player in alive:
		if player.global_position.y - HEAD < %Ceiling.position.y:
			crushed.append(player)
	for player in crushed:
		player.die()


func slam():
	Sfx.play("boom")
	shake_screen()
	await get_tree().create_timer(HOLD).timeout
	if not running:
		return
	for player in alive:
		player.set_physics_process(false)
	var lift = create_tween()
	lift.tween_property(%Ceiling, "position:y", top, LIFT)
	await lift.finished
	if not running:
		return
	next_cycle()


func next_cycle():
	cycle += 1
	for player in alive:
		player.global_position = player.spawn
		player.velocity = Vector2.ZERO
		player.stunned = 0.0
	Sfx.play("respawn")
	open_holes()
	Minigame.show_countdown(views, "manche " + str(cycle))
	await get_tree().create_timer(BREAK).timeout
	if not running:
		return
	Minigame.show_countdown(views, "go !")
	Sfx.play("start")
	for player in alive:
		player.set_physics_process(true)
	start_cycle()
	await get_tree().create_timer(0.6).timeout
	Minigame.show_countdown(views, "")


func open_holes():
	var count = maxi(alive.size() - 1, 1)
	var slots = holes.duplicate()
	slots.shuffle()
	for i in slots.size():
		if i < count:
			slots[i].open()
		else:
			slots[i].close()
	Sfx.play("pass")


func shake_screen():
	var tween = create_tween()
	tween.tween_property(%Camera, "offset", Vector2(0, 2), 0.05)
	tween.tween_property(%Camera, "offset", Vector2(0, -1), 0.05)
	tween.tween_property(%Camera, "offset", Vector2.ZERO, 0.05)


func _on_player_died(player):
	alive.erase(player)
	scores[player.index] = cycle
	if running and alive.size() < 2:
		end_game.call_deferred()


func end_game():
	if not running:
		return
	running = false
	if alive:
		var winner = alive[0]
		winner.set_physics_process(false)
		scores[winner.index] = cycle + 1
		Minigame.show_winner(views, winner.index)
	else:
		Minigame.show_banner(views, "egalite !")
	await get_tree().create_timer(3.0).timeout
	CouchParty.finish(CouchParty.rank(scores))


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
