extends Node2D

const STARTS = [Vector2(0, 0), Vector2(344, 0), Vector2(0, 160), Vector2(344, 160)]
const LOVE = preload("res://scenes/objects/love.tscn")
const MAX_HEARTS = 7
const LAST_SECONDS = 5

var views = []
var players = []
var spots = []
var seconds = 0
var running = false


func _ready():
	spots = %Spots.get_children()
	var bounds = Minigame.level_bounds(%Level)
	views = CouchPlayers.split(self, STARTS)
	for view in views:
		players.append(view.player)
		view.camera.target = view.player
		view.camera.bounds = bounds
		view.camera.snap()
	for player in players:
		player.fall_limit = bounds.end.y
		player.set_physics_process(false)
	seconds = int(%Clock.wait_time)
	show_time()
	show_scores()
	await Minigame.count_down(self, views)
	for view in views:
		view.hud.get_node("Hint").hide()
	for player in players:
		player.set_physics_process(true)
	running = true
	%Clock.start()
	%Spawn.start()
	for i in 3:
		_on_spawn_timeout()


func _process(_delta):
	if not running:
		return
	show_scores()
	tick_clock()


func _on_spawn_timeout():
	if %Hearts.get_child_count() >= MAX_HEARTS:
		return
	var choices = []
	for spot in spots:
		if is_free(spot):
			choices.append(spot)
	var heart = LOVE.instantiate()
	heart.position = choices.pick_random().position
	%Hearts.add_child(heart)


func is_free(spot):
	for heart in %Hearts.get_children():
		if heart.position == spot.position:
			return false
	return true


func tick_clock():
	var left = ceili(%Clock.time_left)
	if left == seconds:
		return
	seconds = left
	show_time()
	if seconds <= LAST_SECONDS:
		Sfx.play("tick", 1.5)


func show_time():
	for view in views:
		view.hud.get_node("Time").text = str(seconds)


func show_scores():
	var line = Minigame.score_line(scores())
	for view in views:
		view.hud.get_node("Scores").text = line


func scores():
	var list = []
	for player in players:
		list.append(player.love_points)
	return list


func _on_clock_timeout():
	running = false
	%Spawn.stop()
	for heart in %Hearts.get_children():
		heart.queue_free()
	seconds = 0
	show_time()
	show_scores()
	for player in players:
		player.set_physics_process(false)
	var ranking = CouchParty.rank(scores())
	var line = Minigame.score_line(scores())
	if ranking[0].size() > 1:
		Minigame.show_banner(views, "egalite !", line)
	else:
		Minigame.show_winner(views, ranking[0][0], line)
	Sfx.play("start")
	await get_tree().create_timer(3.0).timeout
	CouchParty.finish(ranking)


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
