extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var s: GameSession = game.get_node("Session")
	s._physics_process(s.PREPARATION_DURATION)
	# Explicit dense rendering fixture, not a balance result: long-lived enemies
	# keep 59 bodies active while all 24 towers exercise the real targeting loop.
	s.gold = 1200
	for slot in 24:
		s.summon(slot)
	for index in 59:
		var enemy: Enemy = s.spawn_enemy(s.wave_director.enemy_types[index % 4])
		enemy.max_health = 100000000.0
		enemy.health = enemy.max_health
		enemy.advance(index * enemy.board.route_length / 59.0 / enemy.speed)
	s.spawn_remaining = 0
	s.spawn_queue.clear()
	# Performance monitors update at intervals; exclude scene/shader startup.
	await create_timer(2.0).timeout
	var frames: int = 0
	var physics_max: float = 0.0
	var physics_total: float = 0.0
	var started: int = Time.get_ticks_msec()
	var previous_frame: int = Time.get_ticks_usec()
	var frame_times: Array[float] = []
	while Time.get_ticks_msec() - started < 3000:
		await process_frame
		var now: int = Time.get_ticks_usec()
		frame_times.append((now - previous_frame) / 1000.0)
		previous_frame = now
		var cost: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		physics_max = maxf(physics_max, cost)
		physics_total += cost
		frames += 1
	await RenderingServer.frame_post_draw
	var saved: Error = root.get_texture().get_image().save_png("res://docs/phase3-pressure.png")
	var ok: bool = saved == OK and s.enemies.size() == 59 and s.towers.size() == 24 and s.state == s.State.COMBAT
	frame_times.sort()
	var metrics: Dictionary = {"warmup_seconds": 2, "sample_frames": frames, "physics_mean_ms": physics_total / maxf(frames, 1), "physics_max_ms": physics_max, "frame_p95_ms": frame_times[int(frames * 0.95)], "active_enemies": s.enemies.size(), "towers": s.towers.size(), "effects": game.get_node("Effects").flashes.size()}
	var file := FileAccess.open("res://docs/phase3-performance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics, "\t"))
	file.close()
	print("WINDOWS DENSE FIXTURE: ", JSON.stringify(metrics))
	s.spawn_enemy()
	ok = ok and s.state == s.State.GAME_OVER and s.enemies.size() == 60
	print("WINDOWS PHASE 3: ", "PASS" if ok else "FAIL")
	s.restart_game()
	game.queue_free()
	await process_frame
	quit(0 if ok else 1)
