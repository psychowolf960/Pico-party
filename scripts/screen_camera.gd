extends Camera2D

enum Screen { TILEMAP, SQUARE, WIDE }

const SQUARE_SIZE = Vector2i(128, 128)
const WIDE_SIZE = Vector2i(256, 144)

@export var screen: Screen = Screen.TILEMAP
@export var level: TileMapLayer


func _ready():
	anchor_mode = ANCHOR_MODE_FIXED_TOP_LEFT
	var bounds = Minigame.level_bounds(level)
	var size = Vector2i(bounds.size)
	if screen == Screen.SQUARE:
		size = SQUARE_SIZE
	elif screen == Screen.WIDE:
		size = WIDE_SIZE
	CouchPlayers.resize(size)
	position = bounds.get_center() - Vector2(size) / 2
