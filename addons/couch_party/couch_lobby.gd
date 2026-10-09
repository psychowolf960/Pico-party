@icon("res://addons/couch_party/icon.svg")
class_name CouchLobby
extends Node


signal joined(seat)
signal left(seat)
signal skin_changed(seat)
signal readied(seat)
signal unreadied(seat)
signal confirmed
signal changed

@export var skin_count = 4
@export var min_players = 1

var seats = []
var sticks = {}


func _ready():
	for seat in CouchPlayers.seats:
		seat.ready = false
		seats.append(seat)
	CouchPlayers.seats = []
	CouchPlayers.players = 0


func _input(event):
	var from = source(event)
	if from == null:
		return
	var button = stick(event) if event is InputEventJoypadMotion else CouchPlayers.button_of(event, from.keys)
	if button == "":
		return
	get_viewport().set_input_as_handled()
	var seat = find_seat(from)
	if seat == null:
		if button == "o":
			join(from)
	else:
		press(seat, button)


func commit():
	CouchPlayers.seats = seats
	CouchPlayers.players = seats.size()


func source(event):
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return {"pad": event.device, "keys": -1}
	var keys = CouchPlayers.layout_of(event)
	if keys >= 0:
		return {"pad": -1, "keys": keys}
	return null


func stick(event):
	if event.axis != JOY_AXIS_LEFT_X:
		return ""
	var dir = 0
	if event.axis_value > 0.5:
		dir = 1
	elif event.axis_value < -0.5:
		dir = -1
	var before = sticks.get(event.device, 0)
	sticks[event.device] = dir
	if dir == before or dir == 0:
		return ""
	return "right" if dir > 0 else "left"


func find_seat(from):
	for seat in seats:
		if seat.pad == from.pad and seat.keys == from.keys:
			return seat
	return null


func join(from):
	if seats.size() >= CouchPlayers.MAX_PLAYERS:
		return
	from.skin = free_skin(-1, 1)
	from.ready = false
	seats.append(from)
	joined.emit(from)
	changed.emit()


func press(seat, button):
	if seat.ready:
		if button == "o" and everyone_ready():
			confirmed.emit()
		elif button == "x":
			seat.ready = false
			unreadied.emit(seat)
	elif button == "left" or button == "right":
		seat.skin = free_skin(seat.skin, -1 if button == "left" else 1)
		skin_changed.emit(seat)
	elif button == "o":
		seat.ready = true
		readied.emit(seat)
	elif button == "x":
		seats.erase(seat)
		left.emit(seat)
	changed.emit()


func free_skin(skin, step):
	for i in skin_count:
		skin = wrapi(skin + step, 0, skin_count)
		if not is_taken(skin):
			return skin
	return skin


func is_taken(skin):
	for seat in seats:
		if seat.skin == skin:
			return true
	return false


func everyone_ready():
	if seats.size() < min_players:
		return false
	for seat in seats:
		if not seat.ready:
			return false
	return true
