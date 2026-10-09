extends Node2D

const STARTS = [Vector2(0, 0), Vector2(16, 0), Vector2(32, 0), Vector2(48, 0)]
const GOAL = 10

var views = []
var players = []
var scores = []
var running = true


func _ready():
	views = CouchPlayers.shared_screen(self, STARTS)
	for view in views:
		players.append(view.player)
		scores.append(0)
	show_scores()


func _physics_process(_delta):
	if not running:
		return
	for player in players:
		if Input.is_action_just_pressed(CouchPlayers.action(player.index, "o")):
			scores[player.index] += 1
			show_scores()
			if scores[player.index] >= GOAL:
				win(player)


func show_scores():
	$HUD/Scores.text = Minigame.score_line(scores)


func win(player):
	running = false
	Minigame.show_banner(views, Minigame.win_title(player.index))
	Sfx.play("start")
	await get_tree().create_timer(2.0).timeout
	CouchParty.finish(CouchParty.rank(scores))


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
