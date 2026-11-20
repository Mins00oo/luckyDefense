class_name Tower
extends Node2D

var definition: UnitDefinition
var cooldown: float = 0.0
var slot: int = -1
var visual: Node2D
var selected: bool = false

func setup(data: UnitDefinition, index: int) -> void:
	definition = data
	slot = index
	visual = data.visual_scene.instantiate()
	add_child(visual)
	if visual.has_method("configure"):
		visual.configure(data)

func aim(at: Vector2) -> void:
	visual.rotation = (at - position).angle()

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func _draw() -> void:
	if selected:
		draw_rect(Rect2(-37, -27, 74, 54), Color("c2d5a6"), false, 2.0)
