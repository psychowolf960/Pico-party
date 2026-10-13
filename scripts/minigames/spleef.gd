extends Node2D


const STARTS = [Vector2(0, 0), Vector2(160, 0), Vector2(48, 0), Vector2(112, 0)]
const SKY_BARREL = preload("res://scenes/objects/barrel.tscn")
const SKY_SPEED = 120.0

## Durée de fissure des blocs avant qu'ils tombent (0.5 par défaut ailleurs).
@export var crack_time = 1.0

var views = []
var alive = []
var scores = []
var deaths = 0
var bottom = 0.0
var width = 0.0
var floors = []
var running = false


func _ready():
	var bounds = Minigame.level_bounds(%Level)
	bottom = bounds.end.y
	width = bounds.size.x
	# Les blocs sont des tuiles-scènes, instanciées par la TileMapLayer : un bloc tombé ne revient pas.
	for crumble in %Crumbles.get_children():
		setup_crumble(crumble)
	%Crumbles.child_entered_tree.connect(setup_crumble)
	for cell in %Crumbles.get_used_cells():
		var top = %Crumbles.map_to_local(cell).y - %Crumbles.tile_set.tile_size.y / 2.0
		if not top in floors:
			floors.append(top)
	floors.sort()
	for barrel in $Barrels.get_children():
		barrel.fall_limit = bottom
	views = CouchPlayers.shared_screen(self, STARTS)
	for view in views:
		var player = view.player
		player.respawns = false
		player.fall_limit = bottom
		player.died.connect(_on_player_died.bind(player))
		player.set_physics_process(false)
		alive.append(player)
		scores.append(0)
	# La caméra suit le joueur vivant le plus bas, et remonte quand il meurt.
	%Camera.targets = alive
	%Camera.snap()
	await Minigame.count_down(self, views)
	for player in alive:
		player.set_physics_process(true)
	running = true
	%Sky.start()


func setup_crumble(crumble):
	crumble.respawns = false
	crumble.crack_time = crack_time


func _on_sky_timeout():
	var barrel = SKY_BARREL.instantiate()
	barrel.position = Vector2(randf_range(12, width - 12), sky_height())
	barrel.respawns = false
	barrel.fall_limit = bottom
	for player in alive:
		barrel.add_collision_exception_with(player)
	$Barrels.add_child(barrel)
	if randf() < 0.5:
		barrel.launch(Vector2(-SKY_SPEED, 0))
	else:
		barrel.launch(Vector2(SKY_SPEED, 0))


# Juste au-dessus du premier étage visible, pour que les tonneaux tombent à l'écran.
func sky_height():
	var top = %Camera.global_position.y
	for floor_top in floors:
		if floor_top >= top + 12:
			return floor_top - 6
	return top + 4


func _on_player_died(player):
	alive.erase(player)
	scores[player.index] = deaths
	deaths += 1
	if running and alive.size() < 2:
		end_game()


func end_game():
	running = false
	%Sky.stop()
	if alive:
		var winner = alive[0]
		winner.set_physics_process(false)
		scores[winner.index] = deaths
		Minigame.show_winner(views, winner.index)
	else:
		Minigame.show_banner(views, "egalite !")
	await get_tree().create_timer(3.0).timeout
	CouchParty.finish(CouchParty.rank(scores))


func _unhandled_input(event):
	if event.is_action_pressed("p8_menu"):
		CouchParty.quit()
