extends Control


const COLORS = [Color("ff8a1e"), Color("4fd2ff"), Color("2ccf5a"), Color("e8475c")]
const DELAY = 0.8

var wait = DELAY


func _ready():
	var ranking = CouchParty.rank(CouchParty.scores)
	var order = []
	for group in ranking:
		order.append_array(group)
	for i in order:
		var row = Label.new()
		row.text = "j" + str(i + 1) + "   +" + str(CouchParty.gained[i]) + "   " + str(CouchParty.scores[i]).lpad(2)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_color_override("font_color", COLORS[i])
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
		%Next.text = "retour au menu"
	if CouchParty.is_over():
		Sfx.play("start")


func _process(delta):
	wait -= delta


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
	elif wait <= 0 and event.is_action_pressed("ui_accept"):
		Sfx.play("start")
		CouchParty.next()
