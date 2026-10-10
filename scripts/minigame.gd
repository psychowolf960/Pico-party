class_name Minigame
# Petits outils partagés par les mini-jeux.

const COLORS = [Color("ff8a1e"), Color("4fd2ff"), Color("2ccf5a"), Color("e8475c")]


static func level_bounds(level):
	var cells = level.get_used_rect()
	var tile = Vector2(level.tile_set.tile_size)
	return Rect2(Vector2(cells.position) * tile, Vector2(cells.size) * tile)


# "j2 gagne !" pour le joueur d'index 1.
static func win_title(index):
	return "j" + str(index + 1) + " gagne !"


# "j1 3  j2 0  j3 1" : un score par joueur, dans l'ordre des index.
static func score_line(scores):
	var parts = []
	for i in scores.size():
		parts.append("j" + str(i + 1) + " " + str(scores[i]))
	return "  ".join(parts)


# Affiche HUD/Banner dans chaque vue. Score est optionnel dans la scène.
static func show_banner(views, title, line = "", tint = Color.WHITE):
	for view in views:
		var banner = view.hud.get_node("Banner")
		banner.show()
		banner.get_node("Bravo").text = title
		banner.get_node("Bravo").add_theme_color_override("font_color", tint)
		if banner.has_node("Score"):
			banner.get_node("Score").text = line


static func show_winner(views, index, line = ""):
	show_banner(views, win_title(index), line, color(index))


static func color(index):
	return COLORS[CouchPlayers.skin(index) % COLORS.size()]


static func is_leader(index):
	var scores = CouchParty.scores
	if scores.size() != CouchPlayers.players:
		return false
	if index >= scores.size():
		return false
	if scores[index] <= 0:
		return false
	for score in scores:
		if score > scores[index]:
			return false
	return true


static func hide_banner(views):
	for view in views:
		view.hud.get_node("Banner").hide()


static func count_down(node, views):
	color_countdown(views)
	show_names(views, true)
	for n in range(3, 0, -1):
		show_countdown(views, str(n))
		Sfx.play("tick")
		await node.get_tree().create_timer(0.7).timeout
	show_countdown(views, "go !")
	show_names(views, false)
	Sfx.play("start")
	hide_countdown_later(node, views)


static func hide_countdown_later(node, views):
	await node.get_tree().create_timer(0.8).timeout
	show_countdown(views, "")


static func show_countdown(views, text):
	for view in views:
		view.hud.get_node("Countdown").text = text


static func color_countdown(views):
	var shared = false
	if views.size() > 1 and views[0].hud == views[1].hud:
		shared = true
	for view in views:
		var label = view.hud.get_node("Countdown")
		if shared:
			label.add_theme_color_override("font_color", Color.WHITE)
		else:
			label.add_theme_color_override("font_color", color(view.player.index))


static func show_names(views, shown):
	for view in views:
		view.player.get_node("Name").visible = shown
