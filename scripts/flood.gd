extends Node2D


const STARTS = [Vector2(0, 0), Vector2(16, 0), Vector2(-16, 0), Vector2(32, 0)]
const RISE = 6.0
const RAMP = 0.5
const ROUNDS = 3

var views = []
var players = []
var alive = []
var scores = []
var rounds = 0
var water = 0.0
var elapsed = 0.0
var running = false
@onready var start = %Water.position.y


func _ready():
	var bounds = Minigame.level_bounds(%Level)
	%Water.size.y = bounds.size.y + CouchPlayers.view.y
	views = CouchPlayers.split(self, STARTS)
	for view in views:
		players.append(view.player)
		view.camera.bounds = bounds
	for player in players:
		player.respawns = false
		player.fall_limit = bounds.end.y
		player.died.connect(_on_player_died.bind(player))
		scores.append(0)
	new_round()


func new_round():
	rounds += 1
	water = start
	elapsed = 0.0
	alive.clear()
	for player in players:
		player.revive()
		alive.append(player)
	for view in views:
		view.camera.target = view.player
		view.camera.snap()
		view.hud.get_node("Round").text = "manche " + str(rounds) + "/" + str(ROUNDS)
	running = true


func _physics_process(delta):
	if not running:
		return
	elapsed += delta
	water -= (RISE + RAMP * elapsed) * delta
	%Water.position.y = water
	for player in alive.duplicate():
		if player.global_position.y - 6 > water:
			player.die()
	if alive.size() < 2:
		end_round()


func _process(_delta):
	if not alive:
		return
	var leader = alive[0]
	for player in alive:
		if player.global_position.y < leader.global_position.y:
			leader = player
	for view in views:
		if view.player not in alive:
			view.camera.target = leader


func _on_player_died(player):
	alive.erase(player)


func end_round():
	running = false
	var title = "egalite !"
	if alive:
		var winner = alive[0]
		winner.set_physics_process(false)
		scores[winner.index] += 1
		title = Minigame.win_title(winner.index)
	Minigame.show_banner(views, title, Minigame.score_line(scores))
	await get_tree().create_timer(3.0).timeout
	if rounds >= ROUNDS:
		CouchParty.finish(CouchParty.rank(scores))
		return
	Minigame.hide_banner(views)
	new_round()


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
