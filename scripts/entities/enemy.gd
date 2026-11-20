class_name Enemy
extends Node2D

signal died(enemy: Enemy)
var board: Battlefield
var distance: float = 0.0
var speed: float = 72.0
var max_health: float = 40.0
var health: float = 40.0
var reward: int = 10
var alive: bool = true
var armor: float = 0.0
var definition: EnemyDefinition
var visual: Node2D

func setup(field: Battlefield, wave: int, data: EnemyDefinition, director: WaveDirector) -> void:
	board = field
	definition = data
	max_health = data.base_health * director.health_multiplier(wave)
	health = max_health
	speed = data.base_speed * director.speed_multiplier(wave)
	armor = data.armor
	reward = data.reward
	visual = data.visual_scene.instantiate()
	add_child(visual)
	if visual.has_method("configure"):
		visual.configure(data)
	position = board.point_at(0)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if alive:
		advance(delta)

func advance(delta: float) -> void:
	distance = fposmod(distance + speed * delta, board.route_length)
	position = board.point_at(distance)
	visual.rotation = (board.point_at(distance + 2.0) - position).angle()

func take_damage(amount: float) -> void:
	if not alive or amount <= 0.0:
		return
	health = maxf(0.0, health - maxf(1.0, amount - armor))
	queue_redraw()
	if health <= 0.0:
		alive = false
		died.emit(self)
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(-14, -22, 28, 4), Color("080b0c"))
	draw_rect(Rect2(-14, -22, 28 * clampf(health / max_health, 0.0, 1.0), 4), definition.accent)
