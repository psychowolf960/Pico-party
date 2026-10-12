extends Node2D


const STARTS = [Vector2(0, 0), Vector2(16, 0), Vector2(-16, 0), Vector2(32, 0)]
const NORMAL_SPEED = 60.0
const CURSED_SPEED = 62.0
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
var deaths = 0

var running = false
var cursed = null
var giver = null
var safe = 0.0
var fuse = 0.0
var tick = 0.0


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


func _physics_process(delta):
	if not running:
		return
	if alive.size() < 2:
		end_game()
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
		if touching(cursed, player):
			curse(player, cursed)
			break


func touching(a, b):
	if a.global_position.distance_to(b.global_position) < TOUCH:
		return true
	if stands_on(a, b):
		return true
	if stands_on(b, a):
		return true
	return false


func stands_on(top, bottom):
	for i in top.get_slide_collision_count():
		if top.get_slide_collision(i).get_collider() == bottom:
			return true
	return false


func _on_player_died(player):
	alive.erase(player)
	scores[player.index] = deaths
	deaths += 1
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
		cursed.get_node("Sprite/Crown").visible = Minigame.is_leader(cursed.index)
	cursed = player
	giver = from
	safe = NO_GIVE_BACK
	player.speed = CURSED_SPEED
	player.get_node("Potatobomb").visible = true
	player.get_node("Sprite/Crown").visible = false
	if from:
		Sfx.play("pass")


func end_game():
	running = false
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
