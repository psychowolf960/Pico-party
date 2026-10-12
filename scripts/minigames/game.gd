extends Node2D

const STARTS = [Vector2(0, 0), Vector2(-8, 0), Vector2(0, -16), Vector2(-8, -16)]

var hearts = 0
var views = []
var players = []


func _ready():
	hearts = get_tree().get_nodes_in_group("love").size()
	views = CouchPlayers.split(self, STARTS)
	for view in views:
		players.append(view.player)
	for player in players:
		player.set_physics_process(false)
	await Minigame.count_down(self, views)
	for player in players:
		player.set_physics_process(true)


func _process(_delta):
	for view in views:
		view.hud.get_node("Hearts").text = str(view.player.love_points) + "/" + str(hearts)


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()


func _on_goal_reached(body):
	var hearts_won = []
	for player in players:
		hearts_won.append(player.love_points)
	Minigame.show_winner(views, body.index, Minigame.score_line(hearts_won))
	await get_tree().create_timer(3.0).timeout
	hearts_won[body.index] += 1000
	CouchParty.finish(CouchParty.rank(hearts_won))
