extends Node2D

var kind: String = "rapid"
var tint := Color("9db5a8")
var phase: float = 0.0

func configure(definition: UnitDefinition) -> void:
	kind = definition.id
	tint = definition.accent
	set_process(kind == "disruptor")
	queue_redraw()

func _process(delta: float) -> void:
	phase += delta * 2.8
	position.y = -4.0 + sin(phase) * 2.0

func _draw() -> void:
	match kind:
		"assault":
			_infantry(false, false)
		"marksman":
			_infantry(true, false)
		"incinerator":
			_infantry(false, true)
		"artillery":
			_shadow(24)
			for y in [-20, 12]:
				draw_rect(Rect2(-25, y, 46, 8), Color("0b1117"))
				for x in range(-22, 22, 6):
					draw_line(Vector2(x, y + 1), Vector2(x, y + 7), Color("58605b"), 2)
			draw_rect(Rect2(-23, -14, 44, 28), Color("4d5750"))
			draw_circle(Vector2(-2, 0), 14, Color("303b3c"))
			draw_rect(Rect2(-7, -8, 36, 16), Color("858371"))
			draw_rect(Rect2(25, -10, 10, 20), Color("333c3d"))
			draw_line(Vector2(34, -6), Vector2(34, 6), tint, 3)
		"rapid":
			_shadow(17)
			for end in [Vector2(-15, -17), Vector2(-15, 17), Vector2(13, 15), Vector2(13, -15)]:
				draw_line(Vector2.ZERO, end, Color("566560"), 5)
				draw_circle(end, 3, Color("263338"))
			draw_circle(Vector2.ZERO, 12, Color("38484b"))
			for y in [-6, 0, 6]:
				draw_rect(Rect2(4, y - 1, 24, 3), Color("9aa99c"))
			draw_rect(Rect2(-10, -5, 8, 10), tint.darkened(0.25))
		"pierce":
			_shadow(21)
			for y in [-15, 15]:
				draw_line(Vector2(-12, y), Vector2(14, y), Color("707e7c"), 7)
			_polygon([Vector2(-20, 0), Vector2(-9, -14), Vector2(13, -10), Vector2(20, 0), Vector2(13, 10), Vector2(-9, 14)], Color("35494c"))
			for y in [-5, 5]:
				draw_line(Vector2(-2, y), Vector2(33, y), Color("a4b9b1"), 4)
			draw_line(Vector2(0, 0), Vector2(30, 0), tint, 3)
			for x in [0, 9, 18]:
				draw_line(Vector2(x, -8), Vector2(x, 8), tint.darkened(0.25), 3)
		"disruptor":
			draw_circle(Vector2(0, 10), 16, Color(0, 0, 0, 0.35))
			for y in [-16, 16]:
				draw_line(Vector2(-10, y), Vector2(9, y), Color("76848a"), 5)
				draw_line(Vector2(-10, y), Vector2.ZERO, Color("3e515c"), 4)
			_polygon([Vector2(-15, 0), Vector2(-6, -10), Vector2(15, 0), Vector2(-6, 10)], Color("3e5059"))
			draw_circle(Vector2(-2, 0), 5, tint)
			draw_arc(Vector2(-2, 0), 10, -1.2, 1.2, 12, tint, 1.5)

func _shadow(radius: float) -> void:
	draw_circle(Vector2(2, 3), radius, Color(0, 0, 0, 0.45))

func _polygon(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _infantry(sniper: bool, flame: bool) -> void:
	_shadow(14 if not flame else 18)
	if sniper:
		_polygon([Vector2(-19, -12), Vector2(2, -8), Vector2(3, 8), Vector2(-19, 12)], Color("3d4942"))
	for y in [-7, 4]:
		draw_rect(Rect2(-15, y, 12, 5), Color("263338"))
		draw_rect(Rect2(-19, y, 6, 5), Color("111b20"))
	draw_rect(Rect2(-10, -8, 15, 16), Color("566355"))
	for y in [-9, 6]:
		draw_line(Vector2(-3, y), Vector2(11, y * 0.5), Color("7e8875"), 4)
	draw_circle(Vector2(-1, 0), 6, Color("9a9e87"))
	draw_rect(Rect2(1, -4, 4, 8), Color("202d32"))
	if flame:
		for y in [-11, 5]:
			draw_rect(Rect2(-16, y, 10, 6), Color("836d47"))
		draw_line(Vector2(-12, 8), Vector2(13, 7), Color("343c36"), 4)
		draw_rect(Rect2(8, -1, 17, 7), Color("7a8074"))
		draw_rect(Rect2(22, -2, 5, 9), tint)
	else:
		draw_line(Vector2(5, 4), Vector2(36 if sniper else 23, 4), Color("a0aba4"), 3)
		if sniper:
			draw_rect(Rect2(9, 0, 10, 3), Color("23333c"))
