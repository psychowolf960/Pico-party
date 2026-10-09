extends Control

const PLAYER = preload("res://scripts/player.gd")
const KEY_NAMES = ["zqsd", "fleches", "ijkl"]

var blink = true
@onready var lobby = $Lobby


func _ready():
	lobby.skin_count = PLAYER.SKINS.size()
	lobby.min_players = 2
	lobby.joined.connect(Sfx.play.bind("select").unbind(1))
	lobby.skin_changed.connect(Sfx.play.bind("select").unbind(1))
	lobby.unreadied.connect(Sfx.play.bind("select").unbind(1))
	lobby.readied.connect(Sfx.play.bind("checkpoint").unbind(1))
	lobby.left.connect(Sfx.play.bind("bump").unbind(1))
	lobby.confirmed.connect(go)
	lobby.changed.connect(show_seats)
	show_seats()


func _on_blink_timeout():
	blink = not blink
	show_seats()


func _input(event):
	if event.is_action_pressed("p8_menu"):
		lobby.commit()
		CouchParty.quit()


func go():
	if Transition.busy:
		return
	Sfx.play("start")
	lobby.commit()
	if CouchParty.playlist.is_empty():
		CouchParty.quit()
	else:
		CouchParty.start(lobby.seats.size(), CouchParty.playlist)


func show_seats():
	var seats = lobby.seats
	for i in CouchPlayers.MAX_PLAYERS:
		var item = %Items.get_child(i)
		var state = %States.get_child(i)
		var where = %Sources.get_child(i)
		if i >= seats.size():
			item.icon = null
			item.modulate.a = 0.4
			state.text = "o" if blink else ""
			where.text = ""
			continue
		var seat = seats[i]
		item.icon = PLAYER.SKINS[seat.skin].get_frame_texture("idle", 0)
		item.modulate.a = 1.0
		if seat.ready:
			state.text = "pret"
		elif blink:
			state.text = "< >"
		else:
			state.text = ""
		where.text = source_name(seat)
	if lobby.everyone_ready():
		%Help.text = "o: go !"
	elif seats.is_empty():
		%Help.text = "o: rejoindre"
	elif seats.size() < 2:
		%Help.text = "il faut 2 joueurs"
	else:
		%Help.text = "o: pret  x: retour"


func source_name(seat):
	if seat.pad >= 0:
		return "pad" + str(seat.pad + 1)
	return KEY_NAMES[seat.keys]
