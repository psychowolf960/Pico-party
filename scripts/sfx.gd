extends Node

const DIR = "res://8 bit sound effects/"
const SOUNDS = {
	"jump": ["jump1.wav"],
	"land": ["drop1.wav"],
	"step": ["step sound/step1.wav", "step sound/step3.wav"],
	"die": ["explosion1.wav"],
	"respawn": ["Misc/digitsound.wav"],
	"love": ["collect sounds/collect1.wav"],
	"checkpoint": ["collect sounds/collect7.wav"],
	"grab": ["bump sounds/bump3.wav"],
	"throw": ["shoot sounds/shoot2.wav"],
	"bump": ["bump sounds/bump1.wav", "bump sounds/bump2.wav"],
	"hit": ["beep sounds/Punch.wav"],
	"spring": ["shoot sounds/shoot4.wav"],
	"crumble": ["bump sounds/bump4.wav"],
	"boom": ["explosion1.wav"],
	"select": ["Mainmenu sound/selection1.wav"],
	"start": ["Mainmenu sound/start1.wav"],
	"tick": ["beep sounds/beep1.wav"],
	"pass": ["bump sounds/bump5.wav"],
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
