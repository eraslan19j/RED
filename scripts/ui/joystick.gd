class_name Joystick
extends Control
## Sanal joystick (sol alt köşe): dokunmatik hareket girişi.

var value := Vector2.ZERO
var radius := 70.0

func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.6, radius * 2.6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_value(v: Vector2) -> void:
	value = v
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	draw_circle(c, radius, Color(0.1, 0.12, 0.18, 0.45))
	draw_arc(c, radius, 0, TAU, 48, Color(0.7, 0.75, 0.85, 0.7), 3.0)
	var k := c + value * radius * 0.7
	draw_circle(k, radius * 0.42, Color(0.85, 0.88, 0.95, 0.65))
