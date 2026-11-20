extends Node2D

var flashes: Array[Dictionary] = []

func add_shot(origin: Vector2, destination: Vector2, kind: int, tint: Color, radius: float) -> void:
	if flashes.size() >= 128:
		flashes.pop_front()
	flashes.append({"from": origin, "to": destination, "kind": kind, "tint": tint, "radius": radius, "life": 0.22})

func clear() -> void:
	flashes.clear()
	queue_redraw()

func _process(delta: float) -> void:
	for index in range(flashes.size() - 1, -1, -1):
		flashes[index]["life"] -= delta
		if flashes[index]["life"] <= 0.0:
			flashes.remove_at(index)
	queue_redraw()

func _draw() -> void:
	for flash in flashes:
		var tint: Color = flash.tint
		tint.a = flash.life / 0.22
		draw_line(flash.from, flash.to, tint, 3.0 if flash.kind == 2 else 1.5, true)
		draw_circle(flash.from, 5.0 * tint.a, tint)
		if flash.kind == 1:
			draw_arc(flash.to, flash.radius * (1.0 - tint.a * 0.7), 0, TAU, 32, tint, 2, true)
		else:
			draw_circle(flash.to, 4.0 * tint.a, tint)
