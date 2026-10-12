extends Node

const DIR = "res://audio/sfx/"
const SOUNDS = {
	"jump": ["jump1.wav"],
	"land": ["land.wav"],
	"step": ["step/step1.wav", "step/step3.wav"],
	"die": ["explosion1.wav"],
	"respawn": ["misc/digitsound.wav"],
	"love": ["collect/collect1.wav"],
	"checkpoint": ["collect/collect7.wav"],
	"grab": ["bump/bump3.wav"],
	"throw": ["shoot/shoot2.wav"],
	"shoot": ["shoot/shoot1.wav"],
	"bump": ["bump/bump1.wav", "bump/bump2.wav"],
	"hit": ["beep/Punch.wav"],
	"spring": ["shoot/shoot4.wav"],
	"crumble": ["bump/bump4.wav"],
	"boom": ["explosion1.wav"],
	"select": ["menu/selection1.wav"],
	"start": ["menu/start1.wav"],
	"tick": ["beep/beep1.wav"],
	"pass": ["bump/bump5.wav"],
	"alert": ["alert1.wav"],
}

var streams = {}
var players = []


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in SOUNDS:
		streams[key] = []
		for file in SOUNDS[key]:
			streams[key].append(load(DIR + file))
	for i in 8:
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)


func play(key, pitch = 1.0, volume_db = 0.0):
	var p = players[0]
	for candidate in players:
		if not candidate.playing:
			p = candidate
			break
	p.stream = streams[key].pick_random()
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()
