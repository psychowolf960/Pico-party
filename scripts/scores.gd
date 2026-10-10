extends Control

const PLAYER = preload("res://scripts/player.gd")
const DELAY = 0.8

var wait = DELAY
var leaving = false


func _ready():
	var ranking = CouchParty.rank(CouchParty.scores)
	var order = []
	for group in ranking:
		order.append_array(group)
	for i in order:
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 4)
		var portrait = TextureRect.new()
		portrait.texture = PLAYER.SKINS[CouchPlayers.skin(i)].get_frame_texture("portrait", 0)
		row.add_child(portrait)
		var label = Label.new()
		label.text = "j" + str(i + 1) + "   +" + str(CouchParty.gained[i]) + "   " + str(CouchParty.scores[i]).lpad(2)
		label.add_theme_color_override("font_color", Minigame.color(i))
		row.add_child(label)
		%Rows.add_child(row)
	if not CouchParty.is_over():
		%Title.text = "scores"
		%Next.text = "suivant: " + CouchParty.upcoming().name
	else:
		var winners = ranking[0]
		if winners.size() > 1:
			%Title.text = "egalite !"
		else:
			%Title.text = Minigame.win_title(winners[0])
			%Title.add_theme_color_override("font_color", Minigame.color(winners[0]))
		%Next.text = "retour au menu"
	if CouchParty.is_over():
		Sfx.play("start")


func _process(delta):
	wait -= delta


func _unhandled_input(event):
	if leaving:
		return
	if event.is_action_pressed("p8_menu"):
		leaving = true
		CouchParty.quit()
	elif wait <= 0 and event.is_action_pressed("ui_accept"):
		leaving = true
		Sfx.play("start")
		CouchParty.next()
