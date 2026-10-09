extends Node2D

const STARTS = [Vector2(0, 0), Vector2(48, 0), Vector2(-12, 0), Vector2(60, 0)]
const PULL = 2.0
const LIMIT = 20.0
const SMOOTH = 12.0
const TEAM_NAMES = ["gauche", "droite"]

var views = []
var players = []
var homes = []
var rope = 0.0
var shown = 0.0
var running = true
@onready var rope_x = %Rope.position.x


func _ready():
	views = CouchPlayers.shared_screen(self, STARTS)
	for view in views:
		players.append(view.player)
	for player in players:
		player.set_physics_process(false)
		player.sprite.flip_h = team(player) == 1
		player.sprite.play("run")
		homes.append(player.position.x)


func team(player):
	return player.index % 2


func team_size(t):
	var count = 0
	for player in players:
		if team(player) == t:
			count += 1
	return count


func _physics_process(delta):
	shown = lerp(shown, rope, 1.0 - exp(-SMOOTH * delta))
	for i in players.size():
		players[i].position.x = homes[i] + shown
	%Rope.position.x = rope_x + shown
	if not running:
		return
	for player in players:
		if Input.is_action_just_pressed(CouchPlayers.action(player.index, "o")):
			pull(player)
	if rope <= -LIMIT:
		win(0)
	elif rope >= LIMIT:
		win(1)


func pull(player):
	var force = PULL / team_size(team(player))
	if team(player) == 0:
		rope -= force
	else:
		rope += force
	Sfx.play("step", randf_range(0.9, 1.1))


func win(winning_team):
	running = false
	var winners = []
	var losers = []
	for player in players:
		if team(player) == winning_team:
			winners.append(player.index)
		else:
			losers.append(player.index)
			player.sprite.play("idle")
	Minigame.show_banner(views, TEAM_NAMES[winning_team] + " gagne !")
	Sfx.play("start")
	await get_tree().create_timer(3.0).timeout
	CouchParty.finish([winners, losers])


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
