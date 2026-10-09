extends Node2D

const STARTS = [Vector2(0, 0), Vector2(16, 0), Vector2(-16, 0), Vector2(32, 0)]
const BARREL = preload("res://scenes/kong_barrel.tscn")
const FIRE_BARREL = preload("res://scenes/fire_barrel.tscn")
const FIRST_WAIT = 2.5
const SPEEDUP = 0.93
const FIRE_CHANCE = 0.25

var views = []
var players = []
var alive = []
var scores = []
var deaths = 0
var running = false


func _ready():
	var bounds = Minigame.level_bounds(%Level)
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
	await Minigame.count_down(self, views)
	for player in players:
		player.set_physics_process(true)
	running = true
	%Spawn.wait_time = FIRST_WAIT
	%Spawn.start()
	throw(BARREL)


func _on_spawn_timeout():
	if randf() < FIRE_CHANCE:
		throw(FIRE_BARREL)
	else:
		throw(BARREL)
	%Spawn.wait_time = %Spawn.wait_time * SPEEDUP


func throw(scene):
	var barrel = scene.instantiate()
	barrel.position = %Thrower.position
	for player in players:
		barrel.add_collision_exception_with(player)
	%Barrels.add_child(barrel)
	Sfx.play("throw", randf_range(0.7, 0.8), -4.0)


func _on_bin_body_entered(body):
	body.queue_free()


func _on_player_died(player):
	alive.erase(player)
	scores[player.index] = deaths
	deaths += 1
	if running and alive.size() < 2:
		end_game()


func end_game():
	running = false
	%Spawn.stop()
	var title = "egalite !"
	if alive:
		var winner = alive[0]
		winner.set_physics_process(false)
		scores[winner.index] = deaths
		title = Minigame.win_title(winner.index)
	Minigame.show_banner(views, title)
	await get_tree().create_timer(3.0).timeout
	CouchParty.finish(CouchParty.rank(scores))


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
