extends AnimatableBody2D

@export var travel = Vector2(24, 0)
@export var duration = 2.0
var time = 0.0
@onready var start = position


func _physics_process(delta):
	time += delta
	var progress = smoothstep(0.0, 1.0, pingpong(time / duration, 1.0))
	position = start + travel * progress
