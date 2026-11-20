extends Node2D

var tint := Color("866658")
var kind: String = "normal"

func configure(data: EnemyDefinition) -> void:
	tint = data.accent
	kind = data.id
	scale = Vector2.ONE * data.visual_scale
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(2, 3), 14, Color(0, 0, 0, 0.5))
	draw_rect(Rect2(-12, -12, 23, 6), Color("303235"))
	draw_rect(Rect2(-12, 6, 23, 6), Color("303235"))
	draw_colored_polygon(PackedVector2Array([Vector2(-13, -7), Vector2(3, -10), Vector2(16, 0), Vector2(3, 10), Vector2(-13, 7)]), tint.darkened(0.25))
	draw_line(Vector2(-9, -5), Vector2(7, -3), Color("bd9880"), 2)
	draw_rect(Rect2(5, -3, 6, 6), Color("e3aa73"))
	if kind == "armored":
		draw_rect(Rect2(-10, -10, 20, 20), tint, false, 3)
	elif kind == "runner":
		draw_polyline(PackedVector2Array([Vector2(-10, -6), Vector2(0, 0), Vector2(-10, 6)]), tint, 3)
	elif kind == "swarm":
		draw_line(Vector2(-8, 0), Vector2(6, 0), tint, 3)
