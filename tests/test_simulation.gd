extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var session: GameSession = game.get_node("Session")
	session.rng.seed = 47291
	for index in 5400:
		if session.gold >= session.SUMMON_COST:
			session.summon()
		await physics_frame
		if session.state == GameSession.State.GAME_OVER:
			break
	print("SIMULATION: wave=", session.wave, " kills=", session.kills, " towers=", session.towers.size(), " enemies=", session.enemies.size())
	var success: bool = session.wave >= 3 and session.kills >= 20 and session.towers.size() > 3
	session.restart_game()
	game.queue_free()
	await process_frame
	quit(0 if success else 1)
