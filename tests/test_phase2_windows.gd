extends SceneTree

# Real Windows rendering and wall-clock transition; no fixed FPS or time scaling.
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func click(at: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(path) == OK, "Save " + path)

func run() -> void:
	root.size = Vector2i(1280, 720)
	InputMap.load_from_project_settings()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var s = game.get_node("Session")
	var hud = game.get_node("HUD")
	var board = game.get_node("Board")
	s.set_physics_process(false)
	s.restart_game()
	click(Vector2(1100, 570))
	click(Vector2(1100, 570))
	check(s.towers.size() == 2 and s.gold == 0, "UI summons twice in preparation")
	var a = s.towers[0]
	var b = s.towers[1]
	click(board.slot_position(0))
	check(s.selected_tower == a and hud.sell_button.visible, "UI selection shows sale")
	click(board.slot_position(12))
	check(a.slot == 12, "UI move to empty slot")
	click(board.slot_position(1))
	check(a.slot == 1 and b.slot == 12, "UI swap")
	click(Vector2(180, 400))
	check(s.selected_tower == null, "Background deselects")
	click(board.slot_position(1))
	click(Vector2(1100, 512))
	check(s.pending_sale == a and s.gold == 0, "UI confirmation requested")
	await capture("res://docs/phase2-sale.png")
	click(Vector2(1180, 460))
	check(s.pending_sale == null and s.towers.size() == 2, "UI sale cancellation")
	click(Vector2(1100, 512))
	click(Vector2(1050, 460))
	check(s.gold == 25 and hud.gold_label.text == "0025" and not board.occupied.has(1), "UI sale and immediate HUD refund")
	click(board.slot_position(12))
	click(Vector2(1100, 512))
	click(Vector2(1050, 460))
	click(board.slot_position(1))
	click(Vector2(1100, 570))
	check(s.gold == 0 and board.occupied.has(1), "UI resummon into sold slot")
	click(board.slot_position(1))
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	root.push_input(key, true)
	check(s.selected_tower == null, "ESC deselects")
	# Restore the actual physics loop and measure a fresh game without shortcuts.
	s.restart_game()
	s.rng.seed = 239
	s.set_physics_process(true)
	var started: int = Time.get_ticks_msec()
	click(Vector2(1100, 570))
	click(board.slot_position(0))
	await capture("res://docs/phase2-preparation.png")
	while s.state == s.State.PREPARATION:
		check(s.enemies.is_empty() and s.wave == 0 and s.wave_remaining == s.WAVE_DURATION, "No enemies or wave timer during preparation")
		await physics_frame
		if Time.get_ticks_msec() - started > 15000:
			check(false, "Preparation timeout")
			break
	var elapsed: float = (Time.get_ticks_msec() - started) / 1000.0
	check(s.state == s.State.COMBAT and s.wave == 1 and elapsed >= 9.8, "Real-time 10s preparation to wave 1")
	print("REALTIME FIRST WAVE: ", elapsed, " seconds")
	click(board.slot_position(6))
	check(s.towers[0].slot == 6, "UI move during combat")
	await create_timer(2.0).timeout
	check(not s.enemies.is_empty() or s.kills > 0, "Actual wave enemies active")
	await capture("res://docs/phase2-combat.png")
	# Restart using the visible HUD button, including pending confirmation cleanup.
	click(Vector2(1160, 655))
	check(s.state == s.State.PREPARATION and s.gold == 100 and s.wave == 0 and s.towers.is_empty() and s.enemies.is_empty(), "UI restart to clean preparation")
	print("WINDOWS PHASE 2: ", failures, " failures")
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
