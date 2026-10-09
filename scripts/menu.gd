extends Control

const GAMES = [
	{"name": "corde", "scene": "res://scenes/tug.tscn"},
	{"name": "tag", "scene": "res://scenes/tag.tscn"},
	{"name": "course", "scene": "res://scenes/game.tscn"},
	{"name": "inondation", "scene": "res://scenes/flood.tscn"},
	{"name": "dropper", "scene": "res://scenes/dropper.tscn"},
]

var quiet = true


func _ready():
	for b in $Items.get_children():
		b.focus_entered.connect(_on_focus_entered.bind(b))
	%Party.grab_focus.call_deferred()


func _on_focus_entered(b):
	if not quiet:
		Sfx.play("select")
	quiet = false
	place_cursor(b)


func place_cursor(b):
	%Cursor.global_position = b.global_position - Vector2(8, 0)


func _on_blink_timeout():
	%Cursor.visible = not %Cursor.visible


func _on_party_pressed():
	if Transition.busy:
		return
	Sfx.play("start")
	if CouchPlayers.seats.size() < 2:
		CouchParty.choose(GAMES)
	else:
		CouchParty.start(CouchPlayers.seats.size(), GAMES)


func _on_characters_pressed():
	if Transition.busy:
		return
	Sfx.play("start")
	CouchParty.choose([])


func _on_quit_pressed():
	get_tree().quit()
