class_name Battlefield
extends Node2D

signal slot_selected(index: int)
signal background_clicked

const COLUMNS: int = 6
const ROWS: int = 4
const GRID_ORIGIN := Vector2(228, 248)
const CELL := Vector2(90, 66)
var selected_slot: int = -1
var selected_range: float = 0.0
var occupied: Dictionary = {}
var curve := Curve2D.new()
var route_length: float = 0.0
var route := PackedVector2Array([
	Vector2(146, 178), Vector2(856, 178), Vector2(916, 238),
	Vector2(916, 502), Vector2(856, 562), Vector2(146, 562),
	Vector2(86, 502), Vector2(86, 238), Vector2(146, 178)])

func _ready() -> void:
	for point in route:
		curve.add_point(point)
	route_length = curve.get_baked_length()
	queue_redraw()

func point_at(distance: float) -> Vector2:
	return curve.sample_baked(fposmod(distance, route_length))

func slot_position(index: int) -> Vector2:
	return GRID_ORIGIN + Vector2(index % COLUMNS, index / COLUMNS) * CELL + CELL * 0.5

func first_empty() -> int:
	for index in COLUMNS * ROWS:
		if not occupied.has(index):
			return index
	return -1

func reset() -> void:
	occupied.clear()
	selected_slot = -1
	selected_range = 0.0
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		background_clicked.emit()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position - GRID_ORIGIN
		if Rect2(Vector2.ZERO, CELL * Vector2(COLUMNS, ROWS)).has_point(local):
			slot_selected.emit(int(local.y / CELL.y) * COLUMNS + int(local.x / CELL.x))
		else:
			background_clicked.emit()

func _draw() -> void:
	draw_rect(Rect2(36, 124, 930, 482), Color("101a20"))
	for x in range(42, 965, 30):
		draw_line(Vector2(x, 130), Vector2(x, 600), Color("142127"))
	for y in range(130, 600, 30):
		draw_line(Vector2(42, y), Vector2(960, y), Color("142127"))
	draw_polyline(route, Color("080e12"), 52.0, true)
	draw_polyline(route, Color("354049"), 46.0, true)
	draw_polyline(route, Color("202a30"), 40.0, true)
	draw_polyline(route, Color("586252"), 1.0, true)
	for x in range(200, 850, 100):
		_arrow(Vector2(x, 178), 1)
		_arrow(Vector2(x, 562), -1)
	draw_rect(Rect2(214, 234, 568, 292), Color("080f14"))
	draw_rect(Rect2(214, 234, 568, 292), Color("485453"), false, 2.0)
	for index in COLUMNS * ROWS:
		var rect := Rect2(slot_position(index) - CELL * 0.5 + Vector2(3, 3), CELL - Vector2(6, 6))
		draw_rect(rect, Color("1b292f") if occupied.has(index) else Color("142127"))
		draw_rect(rect, Color("799688") if index == selected_slot else Color("2c3c42"), false, 2.0)
		if not occupied.has(index):
			var center: Vector2 = slot_position(index)
			draw_line(center - Vector2(5, 0), center + Vector2(5, 0), Color("415056"))
			draw_line(center - Vector2(0, 5), center + Vector2(0, 5), Color("415056"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(230, 225), "DEPLOYMENT MATRIX  /  SECTOR 07", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("71877f"))
	draw_string(font, Vector2(48, 147), "HOSTILE ENTRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d8a071"))
	draw_circle(route[0], 7, Color("d8a071"))
	for point in [Vector2(50, 590), Vector2(950, 590), Vector2(950, 138)]:
		draw_circle(point, 3, Color("8d9a8d"))
	$RangeClip/RangeDisplay.queue_redraw()

func _arrow(at: Vector2, direction: int) -> void:
	draw_polyline(PackedVector2Array([at + Vector2(-5 * direction, -5), at + Vector2(3 * direction, 0), at + Vector2(-5 * direction, 5)]), Color("8b8a65"), 2.0)
