extends Node


const MAX_PLAYERS = 4

var keyboards = [
	{"left": [KEY_A], "right": [KEY_D], "up": [KEY_W], "down": [KEY_S], "o": [KEY_C, KEY_SPACE], "x": [KEY_V]},
	{"left": [KEY_LEFT], "right": [KEY_RIGHT], "up": [KEY_UP], "down": [KEY_DOWN], "o": [KEY_ENTER, KEY_KP_1], "x": [[KEY_SHIFT, KEY_LOCATION_RIGHT], KEY_KP_2]},
	{"left": [KEY_J], "right": [KEY_L], "up": [KEY_I], "down": [KEY_K], "o": [KEY_N], "x": [KEY_M]},
	{},
]

var pad = {
	"left": [JOY_BUTTON_DPAD_LEFT, [JOY_AXIS_LEFT_X, -1.0]],
	"right": [JOY_BUTTON_DPAD_RIGHT, [JOY_AXIS_LEFT_X, 1.0]],
	"up": [JOY_BUTTON_DPAD_UP, [JOY_AXIS_LEFT_Y, -1.0]],
	"down": [JOY_BUTTON_DPAD_DOWN, [JOY_AXIS_LEFT_Y, 1.0]],
	"o": [JOY_BUTTON_A],
	"x": [JOY_BUTTON_X, JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER, [JOY_AXIS_TRIGGER_RIGHT, 1.0]],
}

var shared = {
	"left": {"keys": [KEY_LEFT, KEY_A], "ui": "ui_left"},
	"right": {"keys": [KEY_RIGHT, KEY_D], "ui": "ui_right"},
	"up": {"keys": [KEY_UP, KEY_W], "ui": "ui_up"},
	"down": {"keys": [KEY_DOWN, KEY_S], "ui": "ui_down"},
	"o": {"keys": [KEY_Z, KEY_C, KEY_N, KEY_SPACE], "ui": "ui_accept"},
	"x": {"keys": [KEY_X, KEY_V, KEY_M, KEY_ENTER], "ui": "ui_accept"},
}
var menu_keys = [KEY_ESCAPE]
var menu_pad = [JOY_BUTTON_START]

var seats = []
var players = 1:
	set(count):
		players = count
		bind_players()

var player_prefix = setting("input/player_prefix", "p")
var shared_prefix = setting("input/shared_prefix", "any")
var view = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))


static func setting(key, default):
	return ProjectSettings.get_setting("couch_party/" + key, default)


func _ready():
	bind_shared()
	bind_players()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _on_joy_connection_changed(_id, _connected):
	bind_players()


func rebind():
	bind_shared()
	bind_players()


func bind_shared():
	for button in shared:
		var action = shared_action(button)
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.5)
		InputMap.action_erase_events(action)
		for key in shared[button].keys:
			add_key(action, key)
			if shared[button].has("ui"):
				add_key(shared[button].ui, key)
		add_pad(action, pad.get(button, []), -1)
	add_pad("ui_accept", [JOY_BUTTON_A], -1)
	var menu = shared_action("menu")
	if not InputMap.has_action(menu):
		InputMap.add_action(menu)
	InputMap.action_erase_events(menu)
	for key in menu_keys:
		add_key(menu, key)
	add_pad(menu, menu_pad, -1)


func bind_players():
	var pads = Input.get_connected_joypads()
	for i in MAX_PLAYERS:
		var device = i - maxi(0, players - pads.size())
		for button in pad:
			var action = player_prefix + str(i + 1) + "_" + button
			if not InputMap.has_action(action):
				InputMap.add_action(action, 0.5)
			InputMap.action_erase_events(action)
			if i < seats.size():
				bind_seat(action, button, seats[i])
				continue
			if i < keyboards.size():
				for key in keyboards[i].get(button, []):
					add_key(action, key)
			if i < players and device >= 0:
				add_pad(action, pad[button], pads[device])


func bind_seat(action, button, seat):
	if seat.pad >= 0:
		add_pad(action, pad[button], seat.pad)
	else:
		for key in keyboards[seat.keys].get(button, []):
			add_key(action, key)


func controls(index):
	if players == 1:
		return shared_prefix
	return player_prefix + str(index + 1)


func action(index, button):
	return controls(index) + "_" + button


func shared_action(button):
	return shared_prefix + "_" + button


func skin(index):
	if index < seats.size():
		return seats[index].skin
	return index


func add_key(action, key):
	var ev = InputEventKey.new()
	if key is Array:
		ev.location = key[1]
		key = key[0]
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)


func add_pad(action, inputs, device):
	for input in inputs:
		var ev
		if input is Array:
			ev = InputEventJoypadMotion.new()
			ev.axis = input[0]
			ev.axis_value = input[1]
		else:
			ev = InputEventJoypadButton.new()
			ev.button_index = input
		ev.device = device
		InputMap.action_add_event(action, ev)


func layout_of(event):
	if not event is InputEventKey:
		return -1
	for k in keyboards.size():
		for button in keyboards[k]:
			if key_matches(event, keyboards[k][button]):
				return k
	return -1


func button_of(event, keys = -1):
	if event is InputEventKey and keys >= 0:
		if not event.pressed or event.echo:
			return ""
		for button in keyboards[keys]:
			if key_matches(event, keyboards[keys][button]):
				return button
	elif event is InputEventJoypadButton:
		if not event.pressed:
			return ""
		for button in pad:
			if event.button_index in pad[button]:
				return button
	return ""


func key_matches(event, keys):
	for key in keys:
		var location = KEY_LOCATION_UNSPECIFIED
		if key is Array:
			location = key[1]
			key = key[0]
		if event.physical_keycode == key and (location == KEY_LOCATION_UNSPECIFIED or event.location == location):
			return true
	return false


func resize(size):
	var window = get_window()
	window.content_scale_size = size
	if window.mode == Window.MODE_WINDOWED:
		window.size = size * window_scale()
		window.move_to_center()


func reset_screen():
	resize(view)


func window_scale():
	var width = ProjectSettings.get_setting("display/window/size/window_width_override", 0)
	if width <= 0 or view.x <= 0:
		return 1
	return maxi(1, width / view.x)


func spawn_players(game, offsets):
	var first = game.get_node("%Player")
	var scene = load(first.scene_file_path)
	var list = [first]
	for i in range(1, players):
		var player = scene.instantiate()
		player.index = i
		player.position = first.position + offsets[i]
		game.add_child(player)
		list.append(player)
	return list


func shared_screen(game, offsets):
	var camera = game.get_node("%Camera")
	var hud = game.get_node("HUD")
	var views = []
	for player in spawn_players(game, offsets):
		views.append({"player": player, "camera": camera, "hud": hud})
	return views


func split(game, offsets):
	var list = spawn_players(game, offsets)
	var camera = game.get_node("%Camera")
	var hud = game.get_node("HUD")
	if players == 1:
		return [{"player": list[0], "camera": camera, "hud": hud}]
	var size = view * Vector2i(mini(players, 2), ceili(players / 2.0))
	resize(size)
	var screen = CanvasLayer.new()
	game.add_child(screen)
	var views = []
	for i in players:
		var sub = SubViewport.new()
		sub.size = view
		sub.world_2d = game.get_viewport().world_2d
		sub.canvas_item_default_texture_filter = game.get_viewport().canvas_item_default_texture_filter
		sub.snap_2d_transforms_to_pixel = game.get_viewport().snap_2d_transforms_to_pixel
		sub.snap_2d_vertices_to_pixel = game.get_viewport().snap_2d_vertices_to_pixel
		var box = SubViewportContainer.new()
		box.position = view * Vector2i(i % 2, i / 2)
		box.add_child(sub)
		screen.add_child(box)
		if i == 0:
			camera.reparent(sub)
			hud.reparent(sub)
		else:
			camera = camera.duplicate()
			camera.target = list[i]
			sub.add_child(camera)
			hud = hud.duplicate()
			sub.add_child(hud)
		views.append({"player": list[i], "camera": camera, "hud": hud})
	var divider = setting("split_screen/divider_color", Color.BLACK)
	if players == 3:
		panel(screen, setting("split_screen/filler_color", Color.BLACK), Rect2(view, view))
	panel(screen, divider, Rect2(view.x - 1, 0, 2, size.y))
	if players > 2:
		panel(screen, divider, Rect2(0, view.y - 1, size.x, 2))
	return views


func panel(parent, color, rect):
	var r = ColorRect.new()
	r.color = color
	r.position = rect.position
	r.size = rect.size
	parent.add_child(r)
