@tool
extends EditorPlugin

const AUTOLOADS = {
	"CouchPlayers": "res://addons/couch_party/couch_players.gd",
	"CouchParty": "res://addons/couch_party/couch_party.gd",
}

var settings = {
	"input/player_prefix": ["p", TYPE_STRING, PROPERTY_HINT_NONE, ""],
	"input/shared_prefix": ["any", TYPE_STRING, PROPERTY_HINT_NONE, ""],
	"split_screen/divider_color": [Color.BLACK, TYPE_COLOR, PROPERTY_HINT_NONE, ""],
	"split_screen/filler_color": [Color.BLACK, TYPE_COLOR, PROPERTY_HINT_NONE, ""],
	"party/lobby_scene": ["", TYPE_STRING, PROPERTY_HINT_FILE, "*.tscn,*.scn"],
	"party/menu_scene": ["", TYPE_STRING, PROPERTY_HINT_FILE, "*.tscn,*.scn"],
	"party/scores_scene": ["", TYPE_STRING, PROPERTY_HINT_FILE, "*.tscn,*.scn"],
}


func _enter_tree():
	for key in settings:
		var spec = settings[key]
		var name = "couch_party/" + key
		if not ProjectSettings.has_setting(name):
			ProjectSettings.set_setting(name, spec[0])
		ProjectSettings.set_initial_value(name, spec[0])
		ProjectSettings.set_as_basic(name, true)
		ProjectSettings.add_property_info({"name": name, "type": spec[1], "hint": spec[2], "hint_string": spec[3]})


func _enable_plugin():
	for name in AUTOLOADS:
		add_autoload_singleton(name, AUTOLOADS[name])


func _disable_plugin():
	for name in AUTOLOADS:
		remove_autoload_singleton(name)
