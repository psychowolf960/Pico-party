class_name GameCamera
extends Camera2D
# Caméra commune à tous les mini-jeux : instancier scenes/camera.tscn.

enum Mode { FIXED, FOLLOW, ROOMS }
enum Screen { KEEP, LEVEL, SQUARE, WIDE, CUSTOM }
enum Focus { TARGET, LOWEST, HIGHEST, MIDDLE }

const SQUARE_SIZE = Vector2i(128, 128)
const WIDE_SIZE = Vector2i(256, 144)

## FIXED : immobile. FOLLOW : suit target en douceur. ROOMS : glisse d'écran en écran.
@export var mode: Mode = Mode.FIXED
## Nœud suivi en FOLLOW / ROOMS (peut aussi être donné par le script du mini-jeu).
@export var target: Node2D
## Niveau qui donne les limites de la caméra.
@export var level: TileMapLayer

@export_group("Screen")
## Taille de fenêtre imposée au démarrage. KEEP n'y touche pas (obligatoire en split screen).
@export var screen: Screen = Screen.KEEP
## Taille utilisée quand screen vaut CUSTOM.
@export var custom_size = Vector2i(128, 128)
## En FIXED, centre la caméra sur le niveau (si level est défini).
@export var center_on_level = true

@export_group("Follow")
## TARGET suit target. LOWEST / HIGHEST / MIDDLE suivent le nœud le plus bas / le plus haut /
## le milieu de la liste targets (donnée par le script, ex. les joueurs encore en vie).
@export var focus: Focus = Focus.TARGET
@export var follow_speed = 8.0
## Hauteur de la cible à l'écran : 0 = en haut, 1 = en bas.
@export_range(0.0, 1.0) var lead = 0.5
## Se place directement sur la cible au démarrage.
@export var snap_on_start = true

@export_group("Rooms")
@export var slide_time = 0.4
## Fige la cible pendant la glissade d'un écran à l'autre.
@export var freeze_target = true

@export_group("Shake")
@export var shake_strength = 2.0
@export var shake_duration = 0.15

var targets = []
var bounds = Rect2(0, 0, 128, 128)
var room = Vector2.ZERO
var sliding = false


func _ready():
	anchor_mode = ANCHOR_MODE_FIXED_TOP_LEFT
	if level:
		bounds = Minigame.level_bounds(level)
	var size = screen_size()
	if screen != Screen.KEEP:
		CouchPlayers.resize(size)
	match mode:
		Mode.FIXED:
			if level and center_on_level:
				position = bounds.get_center() - Vector2(size) / 2
		Mode.FOLLOW:
			if snap_on_start:
				snap()
		Mode.ROOMS:
			if target:
				room = room_of(target.global_position)
				global_position = room


func _process(delta):
	if mode == Mode.FOLLOW:
		var point = focus_point()
		if point != null:
			var weight = 1.0 - exp(-follow_speed * delta)
			global_position = global_position.lerp(aim(point), weight)
	elif mode == Mode.ROOMS and target:
		change_room()


# Point suivi selon focus, ou null s'il n'y a rien à suivre.
func focus_point():
	if focus == Focus.TARGET:
		return target.global_position if target else null
	var valid = targets.filter(func(node): return is_instance_valid(node))
	if valid.is_empty():
		return null
	var low = valid[0].global_position
	var high = low
	for node in valid:
		low = low if low.y >= node.global_position.y else node.global_position
		high = high if high.y <= node.global_position.y else node.global_position
	match focus:
		Focus.LOWEST:
			return low
		Focus.HIGHEST:
			return high
	return (low + high) / 2


func screen_size():
	match screen:
		Screen.LEVEL:
			return Vector2i(bounds.size)
		Screen.SQUARE:
			return SQUARE_SIZE
		Screen.WIDE:
			return WIDE_SIZE
		Screen.CUSTOM:
			return custom_size
	return Vector2i(get_viewport_rect().size)


func snap():
	var point = focus_point()
	if point != null:
		global_position = aim(point)


func aim(point):
	var size = Vector2(screen_size())
	var corner = point - size * Vector2(0.5, lead)
	return corner.clamp(bounds.position, bounds.end - size)


func change_room():
	var next = room_of(target.global_position)
	if sliding or next == room:
		return
	room = next
	sliding = true
	if freeze_target:
		target.set_physics_process(false)
	var slide = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide.tween_property(self, "global_position", room, slide_time)
	await slide.finished
	if freeze_target:
		target.set_physics_process(true)
	sliding = false


func room_of(point):
	var size = get_viewport_rect().size
	var corner = (point / size).floor() * size
	return corner.clamp(bounds.position, bounds.end - size)


func shake(strength = shake_strength, duration = shake_duration):
	var step = duration / 3.0
	var tween = create_tween()
	tween.tween_property(self, "offset", Vector2(0, strength), step)
	tween.tween_property(self, "offset", Vector2(0, -strength / 2), step)
	tween.tween_property(self, "offset", Vector2.ZERO, step)
