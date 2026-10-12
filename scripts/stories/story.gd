class_name Story
extends Control

const SPEED = 30.0
const MIN_TIME = 6.0

static var tests = []

@export var pages: Array[StoryPage] = []
@export_file("*.tscn") var next_scene = ""

var page = 0
var shown = 0.0
var waited = 0.0
var leaving = false


func _ready():
	show_page()


func show_page():
	%Picture.texture = pages[page].image
	for group in %Actors.get_children():
		if group.get_index() == page:
			group.show()
		else:
			group.hide()
	%Text.text = pages[page].text
	%Text.visible_characters = 0
	shown = 0.0
	waited = 0.0
	%Help.hide()


func _process(delta):
	waited += delta
	if is_written():
		return
	shown += SPEED * delta
	var count = int(shown)
	if count > %Text.visible_characters:
		%Text.visible_characters = count
		if count % 3 == 0:
			Sfx.play("tick", 2.0, -14.0)


func is_written():
	return %Text.visible_characters >= %Text.get_total_character_count()


func can_continue():
	return waited >= MIN_TIME


func _on_blink_timeout():
	if is_written() and can_continue():
		%Help.visible = not %Help.visible


func _unhandled_input(event):
	if leaving or Transition.busy:
		return
	if event.is_action_pressed("p8_menu"):
		leaving = true
		tests = []
		CouchParty.quit()
	elif event.is_action_pressed("ui_accept"):
		if can_continue():
			press()


func press():
	if not is_written():
		%Text.visible_characters = %Text.get_total_character_count()
	elif page < pages.size() - 1:
		page += 1
		Sfx.play("select")
		show_page()
	else:
		leave()


func leave():
	leaving = true
	Sfx.play("start")
	if tests.size() > 0:
		Transition.change_scene(tests.pop_front())
	elif next_scene == "":
		CouchParty.quit()
	else:
		Transition.change_scene(next_scene)
