extends Control

const GAMES = [
	{"name": "salon de l'alternance", "scene": "res://scenes/stories/intro.tscn"},
	{"name": "l'afterwork", "scene": "res://scenes/minigames/hearts.tscn"},
	{"name": "le recruteur", "scene": "res://scenes/minigames/hill.tscn"},
	{"name": "la salle d'attente", "scene": "res://scenes/minigames/sun.tscn"},
	{"name": "l'ascenseur social", "scene": "res://scenes/minigames/dropper.tscn"},
	{"name": "team building partie 1", "scene": "res://scenes/stories/trial.tscn"},
	{"name": "team building partie 2", "scene": "res://scenes/minigames/paint.tscn"},
	{"name": "stage non remunere", "scene": "res://scenes/minigames/conveyor.tscn"},
	{"name": "la patate chaude", "scene": "res://scenes/minigames/tag.tscn"},
	{"name": "degat des eaux", "scene": "res://scenes/stories/offices.tscn"},
	{"name": "le plancher pourri", "scene": "res://scenes/minigames/spleef.tscn"},
	{"name": "retourner sa veste", "scene": "res://scenes/minigames/gravity.tscn"},
	{"name": "le plafond de verre", "scene": "res://scenes/minigames/crusher.tscn"},
	{"name": "survis au rh", "scene": "res://scenes/stories/direction.tscn"},
	{"name": "rejoins la grande famille", "scene": "res://scenes/minigames/bullet_hell.tscn"},
]

const STORIES = [
	"res://scenes/stories/intro.tscn",
	"res://scenes/stories/trial.tscn",
	"res://scenes/stories/offices.tscn",
	"res://scenes/stories/direction.tscn",
	"res://scenes/stories/ending.tscn",
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


func _on_test_pressed():
	if Transition.busy:
		return
	Sfx.play("start")
	Story.tests = STORIES.slice(1)
	Transition.change_scene(STORIES[0])


func _on_quit_pressed():
	get_tree().quit()
