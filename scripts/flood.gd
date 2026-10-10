extends Node2D


const STARTS = [Vector2(0, 0), Vector2(16, 0), Vector2(-16, 0), Vector2(32, 0)]
const SCREEN = Vector2i(256, 144)
const RISE = 8.0
const RAMP = 0.04
const CATCH_UP = 0.8
const LEEWAY = 48.0
const TOP_GAP = 92.0

var views = []
var players = []
var alive = []
var scores = []
var deaths = 0
var water = 0.0
var elapsed = 0.0
var running = false
@onready var start = %Water.position.y


func _ready():
	CouchPlayers.resize(SCREEN)
	var bounds = Minigame.level_bounds(%Level)
	%Water.size.y = bounds.size.y + SCREEN.y
	water = start
	views = CouchPlayers.shared_screen(self, STARTS)
	for view in views:
		players.append(view.player)
	for player in players:
		player.respawns = false
		player.fall_limit = bounds.end.y
		player.died.connect(_on_player_died.bind(player))
		player.set_physics_process(false)
		alive.append(player)
		scores.append(0)
	%Camera.bounds = bounds
	%Camera.target = %Focus
	follow_water()
	%Camera.snap()
	await Minigame.count_down(self, views)
	for player in players:
		player.set_physics_process(true)
	running = true


func _physics_process(delta):
	if not running:
		return
	elapsed += delta
	var speed = RISE + RAMP * elapsed * elapsed
	var lowest = alive[0]
	var highest = alive[0]
	for player in alive:
		if player.global_position.y > lowest.global_position.y:
			lowest = player
		if player.global_position.y < highest.global_position.y:
			highest = player
	var gap = water - lowest.global_position.y - LEEWAY
	if gap > 0:
		speed += gap * CATCH_UP
	var ahead = water - highest.global_position.y - TOP_GAP
	if ahead > 0:
		speed += ahead * CATCH_UP
	water -= speed * delta
	%Water.position.y = water
	for player in alive.duplicate():
		if player.global_position.y - 6 > water:
			player.die()
	if alive.size() < 2:
		end_game()


func _process(_delta):
	follow_water()


func follow_water():
	%Focus.global_position.y = water


func _on_player_died(player):
	alive.erase(player)
	scores[player.index] = deaths
	deaths += 1


func end_game():
	running = false
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
