extends Node

var playlist = []
var current = -1
var scores = []
var gained = []

var change_scene = func(path):
	CouchPlayers.reset_screen()
	get_tree().change_scene_to_file(path)


static func setting(key):
	return ProjectSettings.get_setting("couch_party/" + key, "")


func go_to(key):
	var path = setting(key)
	if path == "":
		push_error("Couch Party: set couch_party/" + key + " in the project settings.")
		return
	change_scene.call(path)


func zeros():
	var list = []
	for i in CouchPlayers.players:
		list.append(0)
	return list


func choose(games):
	playlist = games
	go_to("party/lobby_scene")


func start(players, games):
	CouchPlayers.players = players
	playlist = games
	current = 0
	scores = zeros()
	change_scene.call(playlist[0].scene)


func finish(ranking):
	if scores.size() != CouchPlayers.players:
		scores = zeros()
	gained = zeros()
	var beaten = CouchPlayers.players
	for group in ranking:
		beaten -= group.size()
		for i in group:
			gained[i] = beaten
			scores[i] += beaten
	go_to("party/scores_scene")


func next():
	if is_over():
		quit()
	else:
		current += 1
		change_scene.call(playlist[current].scene)


func quit():
	playlist = []
	current = -1
	go_to("party/menu_scene")


func is_over():
	return current >= playlist.size() - 1


func upcoming():
	return playlist[current + 1]


func rank(values):
	var left = range(values.size())
	var ranking = []
	while left.size() > 0:
		var best = values[left[0]]
		for i in left:
			if values[i] > best:
				best = values[i]
		var group = []
		for i in left:
			if values[i] == best:
				group.append(i)
		for i in group:
			left.erase(i)
		ranking.append(group)
	return ranking
