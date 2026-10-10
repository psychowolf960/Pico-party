extends Node2D


const STARTS = [Vector2(0, 0), Vector2(56, 0), Vector2(16, 0), Vector2(40, 0)]
const SKY_BARREL = preload("res://scenes/barrel.tscn")
const SKY_SPEED = 120.0

var views = []
var alive = []
var scores = []
var deaths = 0
var bottom = 0.0
var running = false


func _ready():
	var bounds = Minigame.level_bounds(%Level)
	bottom = bounds.end.y
	for barrel in $Barrels.get_children():
		barrel.fall_limit = bottom
	views = CouchPlayers.split(self, STARTS)
	for view in views:
		var player = view.player
		view.camera.target = player
		view.camera.bounds = bounds
		player.respawns = false
		player.fall_limit = bottom
		player.died.connect(_on_player_died.bind(player))
		player.set_physics_process(false)
		alive.append(player)
		scores.append(0)
	await Minigame.count_down(self, views)
	for player in alive:
		player.set_physics_process(true)
	running = true
	%Sky.start()


func _on_sky_timeout():
	var barrel = SKY_BARREL.instantiate()
	barrel.position = Vector2(randf_range(12, 116), 4)
	barrel.respawns = false
	barrel.fall_limit = bottom
	for player in alive:
		barrel.add_collision_exception_with(player)
	$Barrels.add_child(barrel)
	if randf() < 0.5:
		barrel.launch(Vector2(-SKY_SPEED, 0))
	else:
		barrel.launch(Vector2(SKY_SPEED, 0))


func _on_player_died(player):
	alive.erase(player)
	scores[player.index] = deaths
	deaths += 1
	if running and alive.size() < 2:
		end_game()


func end_game():
	running = false
	%Sky.stop()
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
