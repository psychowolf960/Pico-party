extends Node2D

const STARTS = [Vector2(0, 0), Vector2(16, 0), Vector2(-16, 0), Vector2(32, 0)]
const BULLET = preload("res://scenes/objects/bullet.tscn")
const BONE = preload("res://scenes/objects/bone.tscn")
const BEAM = preload("res://scenes/objects/beam.tscn")
const CHEST = Vector2(0, -4)
const BOSS_Y = 20.0
const RING = 12
const RADIUS = 30.0

@export var time_limit = 60.0
@export var ramp = 0.15
@export var gap = 24.0

var views = []
var players = []
var alive = []
var scores = []
var deaths = 0
var level = 0
var elapsed = 0.0
var wobble = 0.0
var blue = false
var running = false
var field = Rect2()


func _ready():
	field = Rect2(Vector2.ZERO, %Box.size).grow_individual(-3, -3, -4, -3)
	%Hearts.position = %Box.position
	views = CouchPlayers.shared_screen(self, STARTS)
	for view in views:
		players.append(view.player)
		view.player.set_physics_process(false)
		scores.append(0)
	for heart in %Hearts.get_children():
		if heart.index < players.size():
			heart.global_position = players[heart.index].global_position + CHEST
			alive.append(heart)
		else:
			heart.life.hide()
			heart.queue_free()
	show_time()
	await transform()
	await Minigame.count_down(self, views)
	%Intro.hide()
	running = true
	attacks()


func transform():
	await wait(0.8)
	for player in players:
		player.sprite.hide()
	for i in 3:
		%Hearts.show()
		Sfx.play("tick", 1.5)
		await wait(0.12)
		%Hearts.hide()
		await wait(0.12)
	%Hearts.show()
	Sfx.play("select")
	await wait(0.6)


func _physics_process(delta):
	wobble += delta
	%Boss.position.y = BOSS_Y + sin(wobble * 2.0) * 2.0
	if not running:
		return
	elapsed += delta
	show_time()
	var fallen = []
	for heart in alive:
		heart.move(delta, field, blue)
		if not heart.is_safe() and is_hit(heart.position):
			heart.hurt()
			if heart.hp <= 0:
				fallen.append(heart)
	for heart in fallen:
		alive.erase(heart)
		scores[heart.index] = deaths
	deaths += fallen.size()
	if fallen.size() > 0 and alive.size() < 2:
		end_game()
	elif elapsed >= time_limit:
		end_game()


func is_hit(spot):
	for hazard in %Box.get_children():
		if hazard.hits(spot):
			return true
	return false


func show_time():
	var left = ceili(time_limit - elapsed)
	%Time.text = str(maxi(left, 0))


func wait(time):
	await get_tree().create_timer(time).timeout


func pace():
	return 1.0 + level * ramp


func attacks():
	while running:
		await rain()
		await walls()
		await lasers()
		await circles()
		await bones()
		level += 1


func rain():
	for i in 26:
		if not running:
			return
		var x = randf_range(2, %Box.size.x - 2)
		var speed = randf_range(30, 42) * pace()
		pellet(Vector2(x, -3), Vector2(randf_range(-6, 6), speed))
		await wait(0.2)
	await wait(2.5)


func walls():
	var start = -3.0
	var speed = 38.0 * pace()
	if randf() < 0.5:
		start = %Box.size.x
		speed = -speed
	for i in 4:
		if not running:
			return
		var middle = randf_range(gap / 2 + 4, %Box.size.y - gap / 2 - 4)
		bone(Rect2(start, 0, 3, middle - gap / 2), Vector2(speed, 0))
		bone(Rect2(start, middle + gap / 2, 3, %Box.size.y - middle - gap / 2), Vector2(speed, 0))
		await wait(1.4)
	await wait(3.0)


func lasers():
	for i in 6:
		if not running:
			return
		var spot = alive.pick_random().position
		if i % 2 == 0:
			beam(true, spot.x)
		else:
			beam(false, spot.y)
		if level > 0:
			spot = alive.pick_random().position
			if i % 2 == 0:
				beam(false, spot.y)
			else:
				beam(true, spot.x)
		await wait(0.9 / pace())
	await wait(2.5)


func circles():
	for i in 4:
		if not running:
			return
		var center = alive.pick_random().position
		center.x = clampf(center.x, RADIUS + 2, %Box.size.x - RADIUS - 2)
		center.y = clampf(center.y, RADIUS + 2, %Box.size.y - RADIUS - 2)
		var hole = randi() % RING
		var turn = randf() * TAU
		for n in RING:
			if n != hole and n != (hole + 1) % RING:
				var dir = Vector2.from_angle(turn + TAU * n / RING)
				pellet(center + dir * RADIUS, -dir * 40.0 * pace(), 0.6)
		Sfx.play("tick")
		await wait(1.6 / pace())
	await wait(2.5)


func bones():
	if not running:
		return
	set_blue(true)
	await wait(1.0)
	var start = -3.0
	var speed = 50.0 * pace()
	if randf() < 0.5:
		start = %Box.size.x
		speed = -speed
	for i in 7:
		if not running:
			return
		var height = randf_range(6, 14)
		bone(Rect2(start, %Box.size.y - height, 3, height), Vector2(speed, 0))
		await wait(randf_range(0.8, 1.2) / pace())
	await wait(2.2)
	set_blue(false)
	await wait(1.0)


func set_blue(on):
	blue = on
	%BlueBorder.visible = on
	%JumpHint.visible = on
	for heart in alive:
		heart.fall = 0.0
	if on:
		Sfx.play("bump")


func pellet(spot, velocity, delay = 0.0):
	var bullet = BULLET.instantiate()
	bullet.position = spot
	bullet.velocity = velocity
	bullet.delay = delay
	%Box.add_child(bullet)


func bone(rect, velocity):
	var piece = BONE.instantiate()
	piece.position = rect.position
	piece.size = rect.size
	piece.velocity = velocity
	%Box.add_child(piece)


func beam(vertical, line):
	var ray = BEAM.instantiate()
	ray.vertical = vertical
	ray.line = line
	%Box.add_child(ray)


func end_game():
	running = false
	set_blue(false)
	for hazard in %Box.get_children():
		hazard.queue_free()
	var best = 0
	for heart in alive:
		scores[heart.index] = deaths + heart.hp
		best = maxi(best, heart.hp)
	var winners = []
	for heart in alive:
		if heart.hp == best:
			winners.append(heart)
	if winners.size() == 1:
		Minigame.show_winner(views, winners[0].index)
	elif winners.size() > 1:
		Minigame.show_banner(views, "survivants !")
	elif players.size() == 1:
		Minigame.show_banner(views, "perdu !")
	else:
		Minigame.show_banner(views, "egalite !")
	await wait(3.0)
	CouchParty.finish(CouchParty.rank(scores))


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
