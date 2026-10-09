class_name Minigame
# Petits outils partagés par les mini-jeux.


# Rectangle (en pixels) occupé par les tuiles du niveau.
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
static func show_banner(views, title, line = ""):
	for view in views:
		var banner = view.hud.get_node("Banner")
		banner.show()
		banner.get_node("Bravo").text = title
		if banner.has_node("Score"):
			banner.get_node("Score").text = line


static func hide_banner(views):
	for view in views:
		view.hud.get_node("Banner").hide()
