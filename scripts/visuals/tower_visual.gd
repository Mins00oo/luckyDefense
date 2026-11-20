extends Node2D

var kind: int = 0
var tint := Color("9db5a8")

func configure(definition: UnitDefinition) -> void:
	kind = definition.attack_kind
	tint = definition.accent
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(2, 3), 23.0, Color(0, 0, 0, 0.45))
	draw_rect(Rect2(-19, -20, 36, 9), Color("0b1117"))
	draw_rect(Rect2(-19, 11, 36, 9), Color("0b1117"))
	for x in range(-16, 16, 6):
		draw_line(Vector2(x, -19), Vector2(x, -12), Color("506064"), 2)
		draw_line(Vector2(x, 12), Vector2(x, 19), Color("506064"), 2)
	draw_colored_polygon(PackedVector2Array([Vector2(-19, -10), Vector2(-11, -17), Vector2(13, -14), Vector2(21, 0), Vector2(13, 14), Vector2(-11, 17), Vector2(-19, 10)]), Color("36474c"))
	draw_rect(Rect2(-12, -10, 24, 20), Color("56655f"))
	draw_rect(Rect2(-9, -8, 18, 16), Color("27373b"))
	match kind:
		0:
			for y in [-6, 5]:
				draw_rect(Rect2(3, y, 30, 4), Color("93a39c"))
		1:
			draw_rect(Rect2(-3, -8, 34, 16), Color("7d8374"))
			draw_rect(Rect2(24, -10, 10, 20), Color("323d40"))
			draw_rect(Rect2(33, -6, 3, 12), tint)
		2:
			draw_rect(Rect2(-1, -4, 39, 8), Color("a2b8b4"))
			for x in [8, 16, 24]:
				draw_rect(Rect2(x, -7, 4, 14), tint)
	draw_rect(Rect2(-12, -5, 4, 10), tint)
