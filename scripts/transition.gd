extends CanvasLayer

var busy = false


func _ready():
	CouchParty.change_scene = change_scene


func change_scene(path):
	if busy:
		return
	busy = true
	await fade(-0.1)
	CouchPlayers.reset_screen()
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	await fade(2.5)
	busy = false


func fade(to):
	var tween = create_tween()
	tween.tween_property($Rect.material, "shader_parameter/progress", to, 0.25)
	await tween.finished
