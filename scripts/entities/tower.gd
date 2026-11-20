class_name Tower
extends Node2D

var definition: UnitDefinition
var grade: UnitGrade = preload("res://data/grades/common.tres")
var cooldown: float = 0.0
var slot: int = -1
var visual: Node2D
var selected: bool = false

func setup(data: UnitDefinition, index: int, rarity: UnitGrade = null) -> void:
	definition = data
	if rarity:
		grade = rarity
	slot = index
	visual = data.visual_scene.instantiate()
	add_child(visual)
	if visual.has_method("configure"):
		visual.configure(data)
	queue_redraw()

func damage() -> float:
	return definition.damage * grade.damage_multiplier

func interval() -> float:
	return maxf(0.06, definition.attack_interval * grade.interval_multiplier)

func reach() -> float:
	return definition.attack_range * grade.range_multiplier

func special() -> float:
	return grade.special_multiplier

func penetration() -> float:
	return definition.armor_penetration + grade.armor_penetration

func aim(at: Vector2) -> void:
	if visual.has_method("aim"):
		visual.aim(at - position)
	else:
		visual.rotation = (at - position).angle()

func notify_attack() -> void:
	if visual.has_method("play_attack"):
		visual.play_attack(interval())

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(-30, 27), Vector2(30, 27), grade.color, 2 if grade.rank < 2 else 3)
	for index in grade.rank + 1:
		draw_rect(Rect2(-29 + index * 7, 22, 4, 3), grade.color)
	if selected:
		draw_rect(Rect2(-37, -27, 74, 54), Color("c2d5a6"), false, 2.0)
