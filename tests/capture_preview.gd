extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var session: GameSession = game.get_node("Session")
	session.rng.seed = 239
	session._physics_process(session.PREPARATION_DURATION)
	for index in 9:
		session.gold = session.SUMMON_COST
		session.summon([0, 2, 5, 6, 11, 18, 20, 22, 23][index])
	for index in 32:
		var enemy: Enemy = session.spawn_enemy()
		enemy.advance(index * 0.8)
	for index in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png("res://docs/preview.png")
	print("Preview capture: ", error)
	quit(error)
