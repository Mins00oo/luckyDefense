extends Node2D

var flashes: Array[Dictionary] = []
var arrivals: Array[Dictionary] = []

func add_summon(tower: Tower) -> void:
	if arrivals.size() >= 24:
		arrivals.pop_front()
	arrivals.append({"at": tower.position, "color": tower.grade.color, "rank": tower.grade.rank, "life": 0.8 + tower.grade.rank * 0.35, "total": 0.8 + tower.grade.rank * 0.35})

func add_shot(origin: Vector2, destination: Vector2, kind: int, tint: Color, radius: float) -> void:
	if flashes.size() >= 128:
		flashes.pop_front()
	flashes.append({"from": origin, "to": destination, "kind": kind, "tint": tint, "radius": radius, "life": 0.22})

func clear() -> void:
	flashes.clear()
	arrivals.clear()
	queue_redraw()

func _process(delta: float) -> void:
	for index in range(arrivals.size() - 1, -1, -1):
		arrivals[index].life -= delta
		if arrivals[index].life <= 0.0:
			arrivals.remove_at(index)
	for index in range(flashes.size() - 1, -1, -1):
		flashes[index]["life"] -= delta
		if flashes[index]["life"] <= 0.0:
			flashes.remove_at(index)
	queue_redraw()

func _draw() -> void:
	for arrival in arrivals:
		var tint: Color = arrival.color
		tint.a = arrival.life / arrival.total
		var radius: float = 22.0 + (1.0 - tint.a) * 25.0
		draw_arc(arrival.at, radius, 0, TAU, 40, tint, 1.5 + arrival.rank * 0.3, true)
		if arrival.rank >= 3:
			draw_arc(arrival.at, radius * 0.72, 0, TAU, 40, tint, 2, true)
		if arrival.rank == 4:
			draw_line(arrival.at - Vector2(0, 46), arrival.at + Vector2(0, 46), tint, 2, true)
	for flash in flashes:
		var tint: Color = flash.tint
		tint.a = flash.life / 0.22
		if flash.kind == 4:
			var direction: Vector2 = (flash.to - flash.from).normalized()
			var length: float = (flash.to - flash.from).length() * (0.7 + tint.a * 0.3)
			for spread in [-0.45, -0.22, 0.0, 0.22, 0.45]:
				draw_line(flash.from, flash.from + direction.rotated(spread) * length, Color(tint, tint.a * 0.4), 8.0 * tint.a, true)
		elif flash.kind == 5:
			draw_dashed_line(flash.from, flash.to, tint, 2.0, 8.0)
			draw_arc(flash.to, 8 + 15 * (1 - tint.a), 0, TAU, 24, tint, 1.5)
		else:
			draw_line(flash.from, flash.to, tint, 3.0 if flash.kind in [2, 3] else 1.5, true)
			if flash.kind == 0:
				draw_line(flash.from + Vector2(0, 3), flash.to + Vector2(0, 3), Color(tint, tint.a * 0.4), 1.0, true)
		draw_circle(flash.from, 5.0 * tint.a, tint)
		if flash.kind == 1:
			draw_arc(flash.to, flash.radius * (1.0 - tint.a * 0.7), 0, TAU, 32, tint, 2, true)
		else:
			draw_circle(flash.to, 4.0 * tint.a, tint)
