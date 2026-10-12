extends Control

const PLAYER = preload("res://scripts/player/player.gd")
const DELAY = 0.8
const START_PAUSE = 0.5
const STEP = 0.15
const RISE = 6.0
const LINE_LENGTH = 32
const ENDING = "res://scenes/stories/ending.tscn"

var wait = DELAY
var leaving = false
var counting = true
var totals = {}
var gains = {}


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
		var name_label = Label.new()
		name_label.text = "j" + str(i + 1)
		name_label.add_theme_color_override("font_color", Minigame.color(i))
		row.add_child(name_label)
		var gain_box = Control.new()
		gain_box.custom_minimum_size = Vector2(12, 6)
		gain_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(gain_box)
		var gain = Label.new()
		gain.text = "+" + str(CouchParty.gained[i])
		gain.add_theme_color_override("font_color", Minigame.color(i))
		gain_box.add_child(gain)
		gains[i] = gain
		var total = Label.new()
		total.text = str(CouchParty.scores[i] - CouchParty.gained[i]).lpad(2)
		total.add_theme_color_override("font_color", Minigame.color(i))
		row.add_child(total)
		totals[i] = total
		%Rows.add_child(row)
	if not CouchParty.is_over():
		%Title.text = "scores"
		var line = "suivant: " + CouchParty.upcoming().name
		if line.length() > LINE_LENGTH:
			line = "> " + CouchParty.upcoming().name
		%Next.text = line
	else:
		var winners = ranking[0]
		if winners.size() > 1:
			%Title.text = "egalite !"
		else:
			%Title.text = Minigame.win_title(winners[0])
			%Title.add_theme_color_override("font_color", Minigame.color(winners[0]))
		%Next.text = "suivant: la signature"
	count_points()


func count_points():
	await get_tree().create_timer(START_PAUSE).timeout
	var most = 0
	for i in gains:
		var gain = gains[i]
		var tween = create_tween().set_parallel()
		tween.tween_property(gain, "position:y", -RISE, 0.6)
		tween.tween_property(gain, "modulate:a", 0.0, 0.6).set_delay(0.3)
		if CouchParty.gained[i] > most:
			most = CouchParty.gained[i]
	for step in range(1, most + 1):
		for i in totals:
			if CouchParty.gained[i] >= step:
				var shown = CouchParty.scores[i] - CouchParty.gained[i] + step
				totals[i].text = str(shown).lpad(2)
		Sfx.play("tick", 1.0 + step * 0.1)
		await get_tree().create_timer(STEP).timeout
	counting = false
	if CouchParty.is_over():
		Sfx.play("start")


func _process(delta):
	if not counting:
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
		if CouchParty.is_over():
			Transition.change_scene(ENDING)
		else:
			CouchParty.next()
