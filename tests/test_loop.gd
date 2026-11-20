extends SceneTree

var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		push_error("Main scene is missing")
		quit(1)
		return
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	var session = game.get_node("Session")
	var rng := RandomNumberGenerator.new()
	rng.seed = 771
	var counts: Dictionary = {}
	var total_weight: float = 0.0
	for data in session.catalog.units:
		counts[data.id] = 0
		total_weight += data.weight
	for index in 10000:
		counts[session.catalog.roll(rng).id] += 1
	for data in session.catalog.units:
		check(absf(counts[data.id] / 10000.0 - data.weight / total_weight) < 0.025, "Type distribution " + data.id)
	var empty_catalog := UnitCatalog.new()
	check(empty_catalog.roll(rng) == null, "Empty catalog must be safe")
	check(session.state == session.State.PREPARATION, "Must start in preparation")
	session._physics_process(session.PREPARATION_DURATION)
	check(session.gold == 100 and session.wave == 1, "Starting resources and wave")
	check(session.summon(0), "Summon into empty slot")
	check(session.gold == 50 and session.towers.size() == 1, "Deduct summon cost exactly once")
	check(not session.summon(0) and session.gold == 50, "Occupied slot must not charge")
	check(session.summon(1), "Spend remaining gold")
	check(not session.summon(3) and session.gold == 0, "Reject insufficient gold")
	var enemy = session.spawn_enemy()
	var reward = enemy.reward
	enemy.take_damage(99999.0)
	enemy.take_damage(99999.0)
	check(session.gold == reward and session.kills == 1, "Death reward must happen once")
	var board = game.get_node("Board")
	check(board.point_at(0).distance_to(board.point_at(board.route_length)) < 0.1, "Route must loop")
	var moving = session.spawn_enemy()
	moving.advance(board.route_length / moving.speed + 0.5)
	check(moving.distance < board.route_length, "Enemy distance wraps")
	session.toggle_pause()
	var before = moving.distance
	await process_frame
	await process_frame
	check(moving.distance == before, "Pause freezes movement")
	check(not session.summon(3), "Paused summon rejected")
	session.toggle_pause()
	# Exercise each attack against a controlled formation without frame progression.
	for definition in session.catalog.units:
		if definition.attack_kind > 2:
			continue # Additional attack types are covered by test_phase4.gd.
		for old in session.enemies.duplicate():
			old.take_damage(99999.0)
		var a = session.spawn_enemy()
		var b = session.spawn_enemy()
		var c = session.spawn_enemy()
		a.position = Vector2(500, 180)
		b.position = Vector2(500, 160)
		c.position = Vector2(700, 180)
		a.health = 1000.0
		b.health = 1000.0
		c.health = 1000.0
		var tower = session.towers[0]
		tower.definition = definition
		tower.position = Vector2(500, 300)
		session.combat.fire(tower, a, session.enemies.duplicate())
		check(a.health < 1000.0, "Primary hit: " + definition.id)
		check(c.health == 1000.0, "Off-axis/outside splash untouched: " + definition.id)
		if definition.attack_kind == 0:
			check(b.health == 1000.0, "Rapid fire is single-target")
		else:
			check(b.health < 1000.0, "Splash/penetration hits second target")
	session.gold = 10000
	for index in range(2, 24):
		check(session.summon(index), "Fill grid slot %d" % index)
	var remaining_gold = session.gold
	check(not session.summon() and session.gold == remaining_gold, "Full grid must not charge")
	session.restart_game()
	check(session.state == session.State.PREPARATION and session.gold == 100, "Restart resets state")
	check(session.enemies.is_empty() and session.towers.is_empty(), "Restart clears entities")
	session._physics_process(session.PREPARATION_DURATION)
	var old_wave = session.wave
	session._physics_process(session.WAVE_DURATION)
	check(session.wave == old_wave + 1, "Wave progression")
	while session.state == session.State.COMBAT:
		session.spawn_enemy()
	check(session.state == session.State.GAME_OVER, "Enemy cap ends game")
	check(not session.summon(0), "Cannot summon after defeat")
	session.restart_game()
	check(not paused, "Restart unpauses tree")
	game.queue_free()
	await process_frame
	print("TEST RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
