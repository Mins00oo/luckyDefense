extends SceneTree

var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var s = game.get_node("Session")
	if not "wave_director" in s:
		push_error("Phase 3 enemy data and wave director missing")
		quit(1)
		return
	s.set_physics_process(false)
	s.restart_game()
	s._physics_process(10.0)
	var enemy = s.spawn_enemy()
	enemy.set_physics_process(false)
	enemy.advance(enemy.board.route_length / enemy.speed * 3.0)
	check(enemy.alive and s.enemies.has(enemy), "Survives three loops")
	var previous_gold = s.gold
	s._physics_process(s.WAVE_DURATION)
	check(s.enemies.has(enemy), "Old enemy survives wave boundary")
	check(s.gold == previous_gold + s.wave_director.wave_reward, "Survival supply exactly once")
	s._physics_process(0.01)
	check(s.gold == previous_gold + s.wave_director.wave_reward, "No repeated supply")
	var armored = s.spawn_enemy(s.wave_director.enemy_types[2])
	var before = armored.health
	armored.take_damage(9.0)
	check(is_equal_approx(before - armored.health, maxf(1.0, 9.0 - armored.armor)), "Flat armor reduction")
	var runner = s.spawn_enemy(s.wave_director.enemy_types[1])
	check(runner.speed > enemy.speed * 1.5, "Fast enemy is meaningfully faster")
	check(armored.speed < enemy.speed and armored.max_health > enemy.max_health, "Armored is slower and tougher")
	for w in range(1, 21):
		var schedule = s.wave_director.build_wave(w)
		var time: float = 0.0
		for definition in schedule:
			time += s.wave_director.spawn_interval(w, definition)
		check(time < s.WAVE_DURATION, "Wave %d schedule fits duration" % w)
	while s.state == s.State.COMBAT:
		s.spawn_enemy()
	check(s.enemies.size() == 60 and s.state == s.State.GAME_OVER, "Exactly 60 living enemies cause defeat")
	check(s.spawn_enemy() == null and s.enemies.size() == 60, "No growth beyond limit")
	s.restart_game()
	s.summon(0)
	s.handle_slot(0)
	s.request_sale()
	s.handle_slot(0)
	check(s.selected_tower == null and s.pending_sale == null, "Same-unit click deselects and cancels sale")
	game.queue_free()
	await process_frame
	print("PHASE 3 TEST: ", failures, " failures")
	quit(0 if failures == 0 else 1)
