extends SceneTree

var failures: int = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var s = game.get_node("Session")
	if not "grade_catalog" in s:
		push_error("Independent grade catalog missing")
		quit(1)
		return
	s.set_physics_process(false)
	s.actors.process_mode = Node.PROCESS_MODE_DISABLED
	check(s.catalog.units.size() == 7 and s.grade_catalog.grades.size() == 5, "Seven types and five grades")
	var catalog = s.catalog
	var grades = s.grade_catalog
	for data in catalog.units:
		for rarity in grades.grades:
			s.restart_game()
			s.catalog = catalog.duplicate()
			s.catalog.units.assign([data])
			s.grade_catalog = grades.duplicate()
			s.grade_catalog.grades.assign([rarity])
			check(s.summon(0) and s.summon(1), "Summon " + data.id + "/" + rarity.id)
			var a = s.towers[0]
			var b = s.towers[1]
			check(a.definition == data and a.grade == rarity, "Independent data references")
			s.handle_slot(0)
			s.handle_slot(12)
			s.handle_slot(1)
			check(a.slot == 1 and b.slot == 12, "All types move and swap")
			s.request_sale()
			check(s.confirm_sale() and s.gold == 25 and not s.confirm_sale(), "All grades sell once at fixed25G")
	s.catalog = catalog
	s.grade_catalog = grades
	s.restart_game()
	s._physics_process(10.0)
	s.summon(0)
	var tower = s.towers[0]
	tower.grade = grades.grades[0]
	tower.position = Vector2(500, 300)
	for data in catalog.units:
		for old in s.enemies.duplicate():
			old.take_damage(999999.0, 999.0)
		var a = s.spawn_enemy()
		var b = s.spawn_enemy()
		var c = s.spawn_enemy()
		a.position = Vector2(600, 300)
		b.position = Vector2(620, 300)
		c.position = Vector2(500, 100)
		for enemy in [a, b, c]:
			enemy.health = 1000.0
			enemy.max_health = 1000.0
		tower.definition = data
		s.combat.fire(tower, a, s.enemies.duplicate())
		check(a.health < 1000.0 or not a.burns.is_empty(), "Primary damage " + data.id)
		check(c.health == 1000.0 and c.burns.is_empty(), "Off-axis unaffected " + data.id)
		if data.id in ["artillery", "pierce", "incinerator"]:
			check(b.health < 1000.0 or not b.burns.is_empty(), "Multiple targets " + data.id)
		else:
			check(b.health == 1000.0, "Single target " + data.id)
		if data.id == "incinerator":
			var before = a.health
			a.advance(0.5)
			check(a.health < before, "Damage continues after flame application")
		if data.id == "disruptor":
			check(a.movement_multiplier() < 1.0, "Disruptor slow applied")
	var target = s.spawn_enemy()
	for index in 30:
		target.apply_slow(index, 0.9, 8.0)
		target.apply_burn(index, 10.0, 1.0)
	check(target.movement_multiplier() == 0.5 and target.burns.size() <= 3, "Status caps")
	target.health = 100000.0
	target.advance(4.0)
	check(target.movement_multiplier() == 1.0 and target.burns.is_empty(), "Statuses expire")
	# Equal elapsed time must give equal DoT, without per-frame minimum damage.
	var x = s.spawn_enemy()
	var y = s.spawn_enemy()
	x.health = 1000.0
	y.health = 1000.0
	x.apply_burn(1, 12.0, 1.0)
	y.apply_burn(1, 12.0, 1.0)
	x.advance(1.0)
	for tick in 60:
		y.advance(1.0 / 60.0)
	check(absf(x.health - y.health) < 0.001, "DoT independent of timestep")
	var slow_target = s.spawn_enemy()
	slow_target.apply_slow(1, 0.5, 0.5)
	slow_target.apply_slow(2, 0.25, 1.5)
	slow_target.advance(0.75)
	check(slow_target.movement_multiplier() == 0.75, "Weaker slow does not prolong strongest slow")
	slow_target.advance(0.75)
	check(slow_target.movement_multiplier() == 1.0, "Weaker slow also expires")
	var victim = s.spawn_enemy()
	victim.health = 1.0
	victim.apply_burn(1, 12.0, 1.0)
	var gold_before = s.gold
	victim.advance(1.0)
	victim.advance(1.0)
	check(s.gold == gold_before + victim.reward, "DoT death pays once")
	# Automatic sniper targeting prioritizes armor over a closer soft target.
	for old in s.enemies.duplicate():
		old.take_damage(999999.0, 999.0)
	var soft = s.spawn_enemy()
	var armored = s.spawn_enemy(s.wave_director.enemy_types[2])
	soft.position = tower.position + Vector2(20, 0)
	armored.position = tower.position + Vector2(200, 0)
	soft.health = 1000.0
	armored.health = 1000.0
	tower.definition = catalog.units[4]
	tower.grade = grades.grades[0]
	tower.cooldown = 0.0
	s.combat.tick(0.01, s.towers, s.enemies)
	check(soft.health == 1000.0 and is_equal_approx(armored.health, 1000.0 - tower.damage()), "Marksman prioritizes armor and penetrates6")
	var base_damage = tower.definition.damage
	var base_range = tower.reach()
	tower.grade = grades.grades[4]
	check(tower.damage() > base_damage and tower.reach() > base_range and tower.interval() < tower.definition.attack_interval and tower.special() > 1.0, "Grade changes more than damage")
	check(tower.definition.damage == base_damage, "Grade does not mutate shared definition")
	armored.apply_burn(22, 12.0, 1.0)
	armored.apply_slow(22, 0.25, 1.0)
	s.actors.process_mode = Node.PROCESS_MODE_INHERIT
	s.toggle_pause()
	var paused_health = armored.health
	var paused_duration = armored.slows[22].remaining
	await process_frame
	await process_frame
	check(armored.health == paused_health and armored.slows[22].remaining == paused_duration, "Pause freezes statuses")
	s.toggle_pause()
	s.actors.process_mode = Node.PROCESS_MODE_DISABLED
	s.restart_game()
	game.queue_free()
	await process_frame
	print("PHASE 4 TEST: ", failures, " failures")
	quit(0 if failures == 0 else 1)
