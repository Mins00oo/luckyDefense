extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func click(at: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)

func run() -> void:
	root.size = Vector2i(1280, 720)
	InputMap.load_from_project_settings()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	click(Vector2(633, 413))
	await process_frame
	click(Vector2(1100, 570))
	await process_frame
	var session: GameSession = game.get_node("Session")
	click(Vector2(633, 413))
	var selection_ok: bool = session.selected_tower == session.towers[0]
	click(Vector2(633, 413))
	selection_ok = selection_ok and session.selected_tower == null
	click(Vector2(633, 413))
	var right := InputEventMouseButton.new()
	right.position = Vector2(1200, 200)
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	root.push_input(right, true)
	selection_ok = selection_ok and session.selected_tower == null
	click(Vector2(633, 413))
	click(Vector2(1200, 200))
	selection_ok = selection_ok and session.selected_tower == null
	print("INPUT deployed: state=", session.state, " selected=", game.get_node("Board").selected_slot, " slot=", session.towers[0].slot if not session.towers.is_empty() else -1)
	var previous_gold: int = session.gold
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.physical_keycode = KEY_SPACE
	key.unicode = 32
	key.pressed = true
	root.push_input(key, true)
	await process_frame
	print("INPUT pause: state=", session.state, " gold=", session.gold, " before=", previous_gold)
	var success: bool = selection_ok and session.state == GameSession.State.PAUSED and session.gold == previous_gold and session.towers.size() == 1 and session.towers[0].slot == 16
	click(Vector2(1000, 655))
	success = success and session.state == GameSession.State.PREPARATION
	click(Vector2(1160, 655))
	success = success and session.state == GameSession.State.PREPARATION and session.gold == 100 and session.towers.is_empty()
	print("INPUT TEST: ", "PASS" if success else "FAIL", " state=", session.state, " gold=", session.gold)
	session.restart_game()
	game.queue_free()
	await process_frame
	quit(0 if success else 1)
