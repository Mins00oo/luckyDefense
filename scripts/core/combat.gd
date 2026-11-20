class_name CombatSystem
extends Node

signal shot(origin: Vector2, destination: Vector2, kind: int, tint: Color, radius: float)

func tick(delta: float, towers: Array[Tower], enemies: Array[Enemy]) -> void:
	for tower in towers:
		tower.cooldown -= delta
		if tower.cooldown > 0.0:
			continue
		var target: Enemy = null
		var nearest: float = tower.reach() * tower.reach()
		var best_armor: float = -1.0
		for enemy in enemies:
			if not enemy.alive:
				continue
			var distance: float = tower.position.distance_squared_to(enemy.position)
			if tower.definition.attack_kind == UnitDefinition.AttackKind.SNIPER:
				if distance <= tower.reach() * tower.reach() and (enemy.armor > best_armor or (enemy.armor == best_armor and distance < nearest)):
					best_armor = enemy.armor
					nearest = distance
					target = enemy
				continue
			if distance <= nearest:
				nearest = distance
				target = enemy
		if target:
			tower.aim(target.position)
			fire(tower, target, enemies.duplicate())
			# Preserve fractional frame overshoot so grade speed bonuses are real.
			# Bound recovery after an unusually large delta; never bank idle shots.
			tower.cooldown = maxf(tower.cooldown, -minf(delta, tower.interval())) + tower.interval()
		else:
			tower.cooldown = 0.0

func fire(tower: Tower, target: Enemy, enemies: Array[Enemy]) -> void:
	tower.notify_attack()
	var data: UnitDefinition = tower.definition
	var impact: Vector2 = target.position
	var endpoint: Vector2 = impact
	match data.attack_kind:
		UnitDefinition.AttackKind.RAPID, UnitDefinition.AttackKind.ASSAULT, UnitDefinition.AttackKind.SNIPER:
			target.take_damage(tower.damage(), tower.penetration())
		UnitDefinition.AttackKind.ARTILLERY:
			for enemy in enemies:
				if enemy.alive and enemy.position.distance_to(impact) <= data.splash_radius * tower.special():
					enemy.take_damage(tower.damage(), tower.penetration())
		UnitDefinition.AttackKind.PIERCE:
			var direction: Vector2 = (impact - tower.position).normalized()
			endpoint = tower.position + direction * tower.reach()
			for enemy in enemies:
				if not enemy.alive:
					continue
				var offset: Vector2 = enemy.position - tower.position
				var along: float = offset.dot(direction)
				if along >= 0.0 and along <= tower.reach() and absf(offset.cross(direction)) <= data.beam_width * tower.special():
					enemy.take_damage(tower.damage(), tower.penetration())
		UnitDefinition.AttackKind.FLAME:
			var direction: Vector2 = (impact - tower.position).normalized()
			var candidates: Array[Enemy] = []
			for enemy in enemies:
				var offset: Vector2 = enemy.position - tower.position
				if enemy.alive and offset.length() <= tower.reach() and direction.dot(offset.normalized()) >= cos(data.cone_half_angle):
					candidates.append(enemy)
			candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool: return tower.position.distance_squared_to(a.position) < tower.position.distance_squared_to(b.position))
			for index in mini(candidates.size(), data.max_targets + tower.grade.extra_targets):
				var enemy: Enemy = candidates[index]
				enemy.take_damage(tower.damage(), tower.penetration())
				enemy.apply_burn(tower.get_instance_id(), data.burn_dps * tower.special(), data.burn_duration * tower.special())
			endpoint = tower.position + direction * tower.reach()
		UnitDefinition.AttackKind.SLOW:
			target.take_damage(tower.damage(), tower.penetration())
			target.apply_slow(tower.get_instance_id(), data.slow_strength * tower.special(), data.slow_duration * tower.special())
	shot.emit(tower.position, endpoint, data.attack_kind, data.accent, data.splash_radius * tower.special())
