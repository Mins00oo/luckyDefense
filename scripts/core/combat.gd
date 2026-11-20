class_name CombatSystem
extends Node

signal shot(origin: Vector2, destination: Vector2, kind: int, tint: Color, radius: float)

func tick(delta: float, towers: Array[Tower], enemies: Array[Enemy]) -> void:
	for tower in towers:
		tower.cooldown = maxf(0.0, tower.cooldown - delta)
		if tower.cooldown > 0.0:
			continue
		var target: Enemy = null
		var nearest: float = tower.definition.attack_range * tower.definition.attack_range
		for enemy in enemies:
			if not enemy.alive:
				continue
			var distance: float = tower.position.distance_squared_to(enemy.position)
			if distance <= nearest:
				nearest = distance
				target = enemy
		if target:
			tower.aim(target.position)
			fire(tower, target, enemies.duplicate())
			tower.cooldown = tower.definition.attack_interval

func fire(tower: Tower, target: Enemy, enemies: Array[Enemy]) -> void:
	var data: UnitDefinition = tower.definition
	var impact: Vector2 = target.position
	var endpoint: Vector2 = impact
	match data.attack_kind:
		UnitDefinition.AttackKind.RAPID:
			target.take_damage(data.damage)
		UnitDefinition.AttackKind.ARTILLERY:
			for enemy in enemies:
				if enemy.alive and enemy.position.distance_to(impact) <= data.splash_radius:
					enemy.take_damage(data.damage)
		UnitDefinition.AttackKind.PIERCE:
			var direction: Vector2 = (impact - tower.position).normalized()
			endpoint = tower.position + direction * data.attack_range
			for enemy in enemies:
				if not enemy.alive:
					continue
				var offset: Vector2 = enemy.position - tower.position
				var along: float = offset.dot(direction)
				if along >= 0.0 and along <= data.attack_range and absf(offset.cross(direction)) <= data.beam_width:
					enemy.take_damage(data.damage)
	shot.emit(tower.position, endpoint, data.attack_kind, data.accent, data.splash_radius)
