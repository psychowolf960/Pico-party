extends Sprite2D

const BLINK = 0.08
const BREAK_TIME = 0.5

@export var index = 0
@export var life: Control
@export var speed = 70.0
@export var gravity = 320.0
@export var jump = 125.0
@export var short_jump = 40.0
@export var max_hp = 5
@export var safe_time = 1.0

var hp = 0
var safe = 0.0
var fall = 0.0


func _ready():
	hp = max_hp
	modulate = Minigame.color(index)
	life.get_node("Name").add_theme_color_override("font_color", modulate)
	life.get_node("Bar").max_value = max_hp
	life.get_node("Bar").value = hp


func _process(delta):
	if hp <= 0:
		return
	safe = maxf(safe - delta, 0.0)
	if safe > 0 and int(safe / BLINK) % 2 == 0:
		self_modulate.a = 0.0
	else:
		self_modulate.a = 1.0


func move(delta, field, blue):
	if blue:
		var x = Input.get_axis(act("left"), act("right"))
		var jumping = Input.is_action_pressed(act("o")) or Input.is_action_pressed(act("up"))
		fall += gravity * delta
		if fall < -short_jump and not jumping:
			fall = -short_jump
		position.x += x * speed * delta
		position.y += fall * delta
		if position.y >= field.end.y:
			fall = 0.0
			if jumping:
				fall = -jump
				Sfx.play("jump", 1.3, -6.0)
	else:
		var dir = Input.get_vector(act("left"), act("right"), act("up"), act("down"))
		position += dir * speed * delta
	position.x = clampf(position.x, field.position.x, field.end.x)
	position.y = clampf(position.y, field.position.y, field.end.y)


func act(button):
	return CouchPlayers.action(index, button)


func is_safe():
	return safe > 0 or hp <= 0


func hurt():
	hp -= 1
	safe = safe_time
	life.get_node("Bar").value = hp
	if hp > 0:
		Sfx.play("hit")
	else:
		shatter()


func shatter():
	frame = 1
	self_modulate.a = 1.0
	Sfx.play("hit", 0.7)
	await get_tree().create_timer(BREAK_TIME).timeout
	self_modulate.a = 0.0
	$Shards.restart()
	Sfx.play("die")
