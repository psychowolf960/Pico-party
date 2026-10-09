extends Node2D
#magie noire de particules, je sais pas comment ca marche
var parts = []


func _ready():
	top_level = true


func puff(pos, count, dir, spread = 1.0):
	for i in count:
		var life = randf_range(0.2, 0.45)
		parts.append({
			"pos": pos + Vector2(randf_range(-1.5, 1.5), 0),
			"vel": dir.rotated(randf_range(-spread, spread)) * randf_range(0.5, 1.0),
			"life": life,
			"max": life,
			"color": Pico.PAL[randi_range(3, 4)],
		})


func _process(delta):
	for p in parts:
		p.vel.y += 60 * delta
		p.vel -= p.vel * 4 * delta
		p.pos += p.vel * delta
		p.life -= delta
	var still_alive = []
	for p in parts:
		if p.life > 0:
			still_alive.append(p)
	parts = still_alive
	queue_redraw()


func _draw():
	for p in parts:
		var c = p.color
		c.a = clampf(p.life / p.max * 2, 0, 1)
		draw_rect(Rect2(p.pos.round(), Vector2.ONE), c)
