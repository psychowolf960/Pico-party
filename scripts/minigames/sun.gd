extends Node2D

const STARTS = [Vector2(0, 0), Vector2(10, 0), Vector2(20, 0), Vector2(30, 0)]
const SCREEN = Vector2i(256, 144)
const GRACE = 0.8

var views = []
var players = []
var watching = true
var grace = 0.0
var running = false


func _ready():
	CouchPlayers.resize(SCREEN)
	views = CouchPlayers.shared_screen(self, STARTS)
	for view in views:
		players.append(view.player)
		view.player.set_physics_process(false)
	await Minigame.count_down(self, views)
	for player in players:
		player.set_physics_process(true)
	running = true
	sleep()


func _physics_process(delta):
	if not running:
		return
	if not watching:
		return
	grace -= delta
	if grace > 0:
		return
	for player in players:
		if player.is_physics_processing() and player.velocity.length() > 4:
			player.die()


func sleep():
	watching = false
	%Sun.frame = 0
	%Red.hide()
	%Timer.start(randf_range(1.0, 2.5))


func watch():
	watching = true
	grace = GRACE
	%Sun.frame = 1
	%Red.show()
	Sfx.play("alert")
	%Timer.start(randf_range(1.5, 3.0))


func _on_timer_timeout():
	if not running:
		return
	if watching:
		sleep()
	else:
		watch()


func _on_goal_reached(body):
	if not running:
		return
	running = false
	%Timer.stop()
	var scores = []
	for player in players:
		scores.append(player.global_position.x)
	scores[body.index] += 1000
	Minigame.show_winner(views, body.index)
	await get_tree().create_timer(3.0).timeout
	CouchParty.finish(CouchParty.rank(scores))


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
