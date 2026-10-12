extends Node2D

const TEAM_STARTS = [Vector2(0, 0), Vector2(520, 0), Vector2(16, 0), Vector2(504, 0)]
const SOLO_STARTS = [Vector2(0, 0), Vector2(520, 0), Vector2(240, -144), Vector2(504, 0)]
const SIDES = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const BAR_WIDTH = 120.0
const LAST_SECONDS = 5

var views = []
var players = []
var teams = []
var counts = []
var inks = []
var owners = {}
var surface = {}
var seconds = 0
var running = false


func _ready():
	var bounds = Minigame.level_bounds(%Level)
	var starts = SOLO_STARTS
	if is_team_game():
		starts = TEAM_STARTS
	views = CouchPlayers.split(self, starts)
	for view in views:
		var player = view.player
		players.append(player)
		teams.append(team_of(player.index))
		view.camera.target = player
		view.camera.bounds = bounds
		view.camera.snap()
		player.fall_limit = bounds.end.y
		player.set_physics_process(false)
	for team in team_count():
		counts.append(0)
		inks.append(CouchPlayers.skin(team) % Minigame.COLORS.size())
	for player in players:
		player.get_node("Name").modulate = Minigame.color(teams[player.index])
	find_surface()
	color_bars()
	show_bars()
	seconds = int(%Clock.wait_time)
	show_time()
	await Minigame.count_down(self, views)
	for player in players:
		player.set_physics_process(true)
	running = true
	%Clock.start()


func is_team_game():
	return CouchPlayers.players % 2 == 0


func team_of(index):
	if is_team_game():
		return index % 2
	else:
		return index


func team_count():
	if is_team_game():
		return 2
	else:
		return CouchPlayers.players


func find_surface():
	var rect = %Level.get_used_rect()
	for cell in %Level.get_used_cells():
		if %Unreachable.get_cell_source_id(cell) != -1:
			continue
		for side in SIDES:
			var next = cell + side
			if rect.has_point(next) and %Level.get_cell_source_id(next) == -1:
				surface[cell] = true


func _physics_process(_delta):
	if not running:
		return
	for player in players:
		if player.is_physics_processing():
			paint_around(player)
	show_bars()


func paint_around(player):
	var box = player.get_node("Hitbox")
	var half = box.shape.size / 2 + Vector2(1, 1)
	var first = %Level.local_to_map(%Level.to_local(box.global_position - half))
	var last = %Level.local_to_map(%Level.to_local(box.global_position + half))
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			paint(Vector2i(x, y), teams[player.index])


func paint(cell, team):
	if not surface.has(cell):
		return
	if owners.has(cell):
		if owners[cell] == team:
			return
		counts[owners[cell]] -= 1
	owners[cell] = team
	counts[team] += 1
	var source = %Level.get_cell_source_id(cell)
	var coords = %Level.get_cell_atlas_coords(cell)
	%Ink.set_cell(cell, source, coords, inks[team])


func _process(_delta):
	if not running:
		return
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


func color_bars():
	for view in views:
		var bar = view.hud.get_node("Bar")
		for i in 4:
			var ink = bar.get_node("Ink" + str(i + 1))
			if i < team_count():
				ink.color = Minigame.color(i)
			else:
				ink.hide()


func show_bars():
	for view in views:
		var bar = view.hud.get_node("Bar")
		var x = 0.0
		for team in team_count():
			var ink = bar.get_node("Ink" + str(team + 1))
			var width = BAR_WIDTH * counts[team] / surface.size()
			ink.position.x = roundf(x)
			ink.size.x = roundf(x + width) - roundf(x)
			x += width


func _on_clock_timeout():
	running = false
	seconds = 0
	show_time()
	for player in players:
		player.set_physics_process(false)
	var scores = []
	for player in players:
		scores.append(counts[teams[player.index]])
	var ranking = CouchParty.rank(scores)
	show_result(ranking)
	Sfx.play("start")
	await get_tree().create_timer(3.0).timeout
	CouchParty.finish(ranking)


func show_result(ranking):
	var best = teams[ranking[0][0]]
	var line = ""
	for team in team_count():
		if line != "":
			line += "  "
		line += team_name(team) + " " + str(percent(team)) + "%"
	if ranking[0].size() > members(best).size():
		Minigame.show_banner(views, "egalite !", line)
	elif members(best).size() == 1:
		Minigame.show_banner(views, Minigame.win_title(best), line, Minigame.color(best))
	else:
		Minigame.show_banner(views, team_name(best) + " gagnent !", line, Minigame.color(best))


func members(team):
	var list = []
	for player in players:
		if teams[player.index] == team:
			list.append(player.index)
	return list


func team_name(team):
	var names = []
	for index in members(team):
		names.append("j" + str(index + 1))
	return " ".join(names)


func percent(team):
	return roundi(100.0 * counts[team] / surface.size())


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
