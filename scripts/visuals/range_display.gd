extends Node2D

# Clipped by the parent Control so range markers never spill into HUD gutters.
func _draw() -> void:
	var board: Battlefield = get_parent().get_parent()
	if board.selected_slot < 0 or board.selected_range <= 0.0:
		return
	var center: Vector2 = board.slot_position(board.selected_slot) - get_parent().position
	draw_circle(center, board.selected_range, Color(0.48, 0.68, 0.61, 0.055))
	draw_arc(center, board.selected_range, 0, TAU, 128, Color(0.63, 0.84, 0.73, 0.6), 1.5, true)
