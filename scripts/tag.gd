extends Node2D


const STARTS = [Vector2(0, 0), Vector2(16, 0), Vector2(-16, 0), Vector2(32, 0)]
const ROUNDS = 3
const NORMAL_SPEED = 60.0
const CURSED_SPEED = 50.0
const TOUCH = 10.0
const NO_GIVE_BACK = 1.0
const FUSE = 15.0
const FLASH = 0.1
const SLOWEST_TICK = 1.0
const FASTEST_TICK = 0.1
const BOMB_FRAMES = 4

var views = []
var players = []
var alive = []
var scores = []
var rounds = 0

var elapsed = 0.0
var running = false
var cursed = null
var giver = null
var safe = 0.0
var fuse = 0.0
var tick = 0.0


func _ready():
	var bounds = Minigame.level_bounds(%Level)
	views = CouchPlayers.shared_screen(self, STARTS)
	CouchPlayers.resize(Vector2i(bounds.size))
	%Camera.position = bounds.position
	for view in views:
		players.append(view.player)
	for player in players:
		player.respawns = false
		player.fall_limit = bounds.end.y
		player.died.connect(_on_player_died.bind(player))
		scores.append(0)
	new_round()


func new_round():
	rounds += 1
	elapsed = 0.0
	alive.clear()
	cursed = null
	for player in players:
		player.revive()
		player.speed = NORMAL_SPEED
		player.get_node("Potatobomb").visible = false
		alive.append(player)
	$HUD/Round.text = "manche " + str(rounds) + "/" + str(ROUNDS)
	running = true


func _physics_process(delta):
	if not running:
		return
	elapsed += delta
	if alive.size() < 2:
		end_round()
		return
	if cursed == null:
		draw_bomber()
	safe -= delta
	fuse -= delta
	if fuse <= 0:
		cursed.die()
		return
	var bomb = cursed.get_node("Potatobomb")
	bomb.frame = mini(int((1.0 - fuse / FUSE) * BOMB_FRAMES), BOMB_FRAMES - 1)
	tick -= delta
	if tick <= 0:
		flash()
		tick = lerpf(FASTEST_TICK, SLOWEST_TICK, fuse / FUSE)
	for player in alive:
		if player == cursed:
			continue
		if player == giver and safe > 0:
			continue
		if cursed.global_position.distance_to(player.global_position) < TOUCH:
			curse(player, cursed)
			break


func _on_player_died(player):
	alive.erase(player)
	if player == cursed:
		player.get_node("Potatobomb").visible = false
		cursed = null


func draw_bomber():
	curse(alive.pick_random(), null)
	fuse = FUSE
	tick = SLOWEST_TICK
	Sfx.play("alert")


func flash():
	var bomb = cursed.get_node("Potatobomb")
	bomb.modulate = Color.BLACK
	Sfx.play("tick", 2.0 - fuse / FUSE, -6.0)
	await get_tree().create_timer(FLASH).timeout
	bomb.modulate = Color.WHITE


func curse(player, from):
	if cursed:
		cursed.speed = NORMAL_SPEED
		cursed.get_node("Potatobomb").visible = false
	cursed = player
	giver = from
	safe = NO_GIVE_BACK
	player.speed = CURSED_SPEED
	player.get_node("Potatobomb").visible = true
	if from:
		Sfx.play("pass")


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
