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
const MAX_SLOW: float = 0.5
const MAX_BURNS: int = 3
var burns: Dictionary = {}
var slows: Dictionary = {}

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
	if not alive:
		return
	# Integrate status effects over their remaining lifetime, not per-frame hits.
	var movement_time: float = delta
	var points: Array[float] = [0.0, delta]
	for status in slows.values():
		points.append(minf(delta, status.remaining))
	points.sort()
	for index in range(points.size() - 1):
		var strongest: float = 0.0
		for status in slows.values():
			if status.remaining > points[index]:
				strongest = maxf(strongest, status.strength)
		movement_time -= (points[index + 1] - points[index]) * strongest
	for source in slows.keys():
		slows[source].remaining -= delta
		if slows[source].remaining <= 0.0:
			slows.erase(source)
	var burn_damage: float = 0.0
	for source in burns.keys():
		var status: Dictionary = burns[source]
		burn_damage += minf(delta, status.remaining) * status.dps / (1.0 + armor * 0.15)
		status.remaining -= delta
		if status.remaining <= 0.0:
			burns.erase(source)
	if burn_damage > 0.0:
		_lose_health(burn_damage)
	if not alive:
		return
	distance = fposmod(distance + speed * movement_time, board.route_length)
	position = board.point_at(distance)
	visual.rotation = (board.point_at(distance + 2.0) - position).angle()

func take_damage(amount: float, armor_penetration: float = 0.0) -> void:
	if not alive or amount <= 0.0:
		return
	_lose_health(maxf(1.0, amount - maxf(0.0, armor - armor_penetration)))

func _lose_health(amount: float) -> void:
	if not alive:
		return
	health = maxf(0.0, health - amount)
	queue_redraw()
	if health <= 0.0:
		alive = false
		died.emit(self)
		queue_free()

func apply_burn(source: int, dps: float, duration: float) -> void:
	if not alive or dps <= 0.0 or duration <= 0.0:
		return
	if not burns.has(source) and burns.size() >= MAX_BURNS:
		var weakest = burns.keys()[0]
		for key in burns:
			if burns[key].dps < burns[weakest].dps:
				weakest = key
		if burns[weakest].dps >= dps:
			return
		burns.erase(weakest)
	burns[source] = {"dps": minf(dps, 30.0), "remaining": minf(duration, 3.0)}

func apply_slow(source: int, strength: float, duration: float) -> void:
	if not alive or duration <= 0.0:
		return
	if not slows.has(source) and slows.size() >= 24:
		return
	slows[source] = {"strength": clampf(strength, 0.0, MAX_SLOW), "remaining": minf(duration, 3.0)}

func movement_multiplier() -> float:
	var strongest: float = 0.0
	for status in slows.values():
		strongest = maxf(strongest, status.strength)
	return 1.0 - strongest

func _draw() -> void:
	draw_rect(Rect2(-14, -22, 28, 4), Color("080b0c"))
	draw_rect(Rect2(-14, -22, 28 * clampf(health / max_health, 0.0, 1.0), 4), definition.accent)
