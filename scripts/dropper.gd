extends Node2D

const STARTS = [Vector2(0, 0), Vector2(8, 0), Vector2(-8, 0), Vector2(16, 0)]
const MAX_FALL = 170.0

var hearts = 0
var views = []
var players = []
var checkpoints = []
var top = 0.0
var depth = 1.0


func _ready():
	hearts = get_tree().get_nodes_in_group("love").size()
	checkpoints = %Checkpoints.get_children()
	var bounds = Minigame.level_bounds(%Level)
	views = CouchPlayers.split(self, STARTS)
	for view in views:
		players.append(view.player)
		view.camera.target = view.player
		view.camera.bounds = bounds
		view.camera.snap()
	for player in players:
		player.fall_limit = bounds.end.y
		player.max_fall = MAX_FALL
		player.set_physics_process(false)
	top = %Player.global_position.y
	depth = %Goal.global_position.y - top
	count_down()


func count_down():
	await Minigame.count_down(self, views)
	%Trapdoor.enabled = false
	for player in players:
		player.set_physics_process(true)


func _physics_process(_delta):
	for player in players:
		if player.is_physics_processing():
			reach_checkpoint(player)


func reach_checkpoint(player):
	var best = null
	for point in checkpoints:
		var p = point.global_position
		if p.y > player.global_position.y or p.y <= player.spawn.y:
			continue
		if best == null or p.y > best.y or (p.y == best.y and absf(p.x - player.global_position.x) < absf(best.x - player.global_position.x)):
			best = p
	if best != null:
		player.spawn = best
		Sfx.play("checkpoint")


func _process(_delta):
	for view in views:
		view.hud.get_node("Hearts").text = str(view.player.love_points) + "/" + str(hearts)
		var bar = view.hud.get_node("Depth")
		var progress = clampf((view.player.global_position.y - top) / depth, 0, 1)
		bar.get_node("Marker").position.y = progress * (bar.size.y - 2)


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
