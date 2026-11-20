extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var s: GameSession = game.get_node("Session")
	s.set_physics_process(false)
	s.actors.process_mode = Node.PROCESS_MODE_DISABLED
	s.combat.set_block_signals(true)
	s._physics_process(10.0)
	s.summon(0)
	var tower: Tower = s.towers[0]
	tower.grade = s.grade_catalog.grades[0]
	var enemy: Enemy = s.spawn_enemy()
	enemy.position = tower.position + Vector2(20, 0)
	enemy.max_health = 1000000000.0
	var results: Array[Dictionary] = []
	for data in s.catalog.units:
		tower.definition = data
		for armor_value in [0.0, 6.0]:
			enemy.armor = armor_value
			enemy.health = enemy.max_health
			enemy.burns.clear()
			enemy.slows.clear()
			tower.cooldown = 0.0
			for tick in 3600:
				# Keep a stationary in-range target while integrating timed damage.
				enemy.advance(1.0 / 60.0)
				enemy.position = tower.position + Vector2(20, 0)
				s.combat.tick(1.0 / 60.0, s.towers, s.enemies)
			print("DPS ", data.id, " armor=", armor_value, " nominal=", data.damage / data.attack_interval, " measured_60s=", (enemy.max_health - enemy.health) / 60.0)
			results.append({"unit": data.id, "armor": armor_value, "nominal_dps": data.damage / data.attack_interval, "measured_dps": (enemy.max_health - enemy.health) / 60.0})
	var file := FileAccess.open("res://docs/phase4-dps-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	file.close()
	game.queue_free()
	await process_frame
	quit()
