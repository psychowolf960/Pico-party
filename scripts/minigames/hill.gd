extends Node2D

const STARTS = [Vector2(0, 0), Vector2(224, 0), Vector2(16, 0), Vector2(208, 0)]
const SCREEN = Vector2i(256, 144)
const WARN = 1.0
const LAST_SECONDS = 5
const CROWN_Y = -27.0
const EMPTY = Color.WHITE
const FIGHT = Color("9aacb6")

var views = []
var players = []
var scores = []
var spots = []
var seconds = 0
var bob = 0.0
var running = false


func _ready():
	CouchPlayers.resize(SCREEN)
	spots = %Spots.get_children()
	var bounds = Minigame.level_bounds(%Level)
	for barrel in %Barrels.get_children():
		barrel.fall_limit = bounds.end.y
	views = CouchPlayers.shared_screen(self, STARTS)
	for view in views:
		players.append(view.player)
	for player in players:
		player.fall_limit = bounds.end.y
		player.set_physics_process(false)
		scores.append(0.0)
	seconds = int(%Clock.wait_time)
	show_time()
	show_scores()
	await Minigame.count_down(self, views)
	%Hint.hide()
	for player in players:
		player.set_physics_process(true)
	running = true
	%Clock.start()
	%Move.start()


func _physics_process(delta):
	if not running:
		return
	var inside = holders()
	if inside.size() == 1:
		gain(inside[0], delta)
	paint_zone(inside)


func holders():
	var list = []
	for body in %Zone.get_overlapping_bodies():
		if players.has(body) and body.is_physics_processing() and not body.is_dazed():
			list.append(body)
	return list


func gain(player, delta):
	var before = int(scores[player.index])
	scores[player.index] += delta
	if int(scores[player.index]) > before:
		Sfx.play("love", 1.0, -6.0)
		show_scores()


func paint_zone(inside):
	if inside.size() == 0:
		%Glow.modulate = EMPTY
		%Recruiter.play("idle")
	elif inside.size() == 1:
		%Glow.modulate = Minigame.color(inside[0].index)
		%Recruiter.play("listen")
		%Recruiter.flip_h = inside[0].global_position.x < %Zone.global_position.x
	else:
		%Glow.modulate = FIGHT
		%Recruiter.play("fight")


func _process(delta):
	bob += delta
	%Crown.position.y = CROWN_Y + roundf(sin(bob * 4))
	if not running:
		return
	blink()
	tick_clock()


func blink():
	if %Move.time_left < WARN:
		%Glow.visible = fmod(bob, 0.2) < 0.1
	else:
		%Glow.visible = true


func tick_clock():
	var left = ceili(%Clock.time_left)
	if left == seconds:
		return
	seconds = left
	show_time()
	if seconds <= LAST_SECONDS:
		Sfx.play("tick", 1.5)


func show_time():
	$HUD/Time.text = str(seconds)


func show_scores():
	$HUD/Scores.text = Minigame.score_line(whole_scores())


func whole_scores():
	var list = []
	for value in scores:
		list.append(int(value))
	return list


func _on_move_timeout():
	if not running:
		return
	var choices = []
	for spot in spots:
		if spot.position != %Zone.position:
			choices.append(spot)
	%Zone.position = choices.pick_random().position
	%Glow.visible = true
	Sfx.play("pass")


func _on_clock_timeout():
	running = false
	%Move.stop()
	%Glow.visible = true
	seconds = 0
	show_time()
	for player in players:
		player.set_physics_process(false)
	for platform in %Platforms.get_children():
		platform.set_physics_process(false)
	var ranking = CouchParty.rank(whole_scores())
	var line = Minigame.score_line(whole_scores())
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
