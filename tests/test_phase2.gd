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
	var board = game.get_node("Board")
	if not s.has_method("confirm_sale"):
		push_error("Phase 2 selection/movement/sale API missing")
		quit(1)
		return
	s.set_physics_process(false)
	s.restart_game()
	check(s.state == s.State.PREPARATION and s.gold == 100 and s.wave == 0, "Initial preparation / 100G")
	check(s.preparation_remaining == 10.0 and s.enemies.is_empty(), "10s with no enemies")
	s._physics_process(4.0)
	check(s.preparation_remaining == 6.0 and s.wave_remaining == s.WAVE_DURATION and s.wave == 0, "Only preparation timer advances")
	s.toggle_pause()
	s._physics_process(9.0)
	await physics_frame
	check(s.preparation_remaining == 6.0, "Paused preparation freezes")
	s.toggle_pause()
	check(s.state == s.State.PREPARATION, "Resume preparation phase")
	s._physics_process(6.0)
	check(s.state == s.State.COMBAT and s.wave == 1 and s.towers.is_empty(), "Wave starts with no units")
	check(s.wave_remaining == s.WAVE_DURATION, "First wave gets full duration")
	s._physics_process(0.1)
	check(not s.enemies.is_empty(), "First wave spawns enemies")
	s.restart_game()
	check(s.summon(0) and s.summon(1) and s.gold == 0, "Two summons during preparation at 50G")
	var a = s.towers[0]
	var b = s.towers[1]
	a.cooldown = 0.4
	s.handle_slot(0)
	check(s.selected_tower == a and a.selected and board.selected_range == a.reach(), "Select outline and range")
	s.handle_slot(12)
	check(a.slot == 12 and a.position == board.slot_position(12) and not board.occupied.has(0), "Move to empty slot")
	check(a.cooldown == 0.4 and s.gold == 0, "Move is free and preserves cooldown")
	s.handle_slot(1)
	check(a.slot == 1 and b.slot == 12 and board.occupied[1] == a and board.occupied[12] == b, "Swap occupied slots")
	check(s.selected_tower == a and s.gold == 0, "Selection follows moving unit; free swap")
	s.request_sale()
	check(s.gold == 0 and s.towers.size() == 2, "Request sale does not refund")
	s.cancel_sale()
	check(not s.confirm_sale() and s.gold == 0, "Cancel prevents sale")
	s.request_sale()
	check(s.confirm_sale() and s.gold == 25 and not board.occupied.has(1), "Confirmed sale refunds 25G and clears slot")
	check(s.selected_tower == null and not s.towers.has(a), "Sold unit deselected and removed from combat")
	check(not s.confirm_sale() and s.gold == 25, "Duplicate confirmation cannot refund")
	s.handle_slot(12)
	s.request_sale()
	s.confirm_sale()
	check(s.gold == 50 and s.summon(1) and s.gold == 0, "Resummon in sold slot")
	s.handle_slot(1)
	s.request_sale()
	s.clear_selection()
	check(not s.confirm_sale(), "Selection change invalidates sale")
	s.handle_slot(1)
	s.request_sale()
	s.toggle_pause()
	check(not s.confirm_sale() and not s.summon(2), "Pause blocks economy and cancels sale")
	s.toggle_pause()
	s._physics_process(10.0)
	var moved = s.towers[0]
	s.handle_slot(5)
	check(moved.slot == 5, "Combat move allowed")
	# This enemy is in range of the new position, outside the old position.
	moved.definition = s.catalog.units[0]
	moved.cooldown = 0.0
	var enemy = s.spawn_enemy()
	enemy.position = board.slot_position(5) + Vector2(200, 0)
	enemy.health = 1000.0
	s.combat.tick(0.01, s.towers, s.enemies)
	check(enemy.health < 1000.0, "Automatic attack uses moved position")
	s.request_sale()
	s.restart_game()
	check(s.state == s.State.PREPARATION and s.preparation_remaining == 10.0 and s.gold == 100, "Restart preparation and economy")
	check(s.towers.is_empty() and s.enemies.is_empty() and board.occupied.is_empty() and s.wave == 0, "Restart clears world and wave")
	check(not s.confirm_sale() and not paused, "Restart invalidates sale and unpauses")
	game.queue_free()
	await process_frame
	print("PHASE 2 TEST: ", failures, " failures")
	quit(0 if failures == 0 else 1)
