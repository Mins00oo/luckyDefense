extends SceneTree

var failures: int = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(path) == OK, "Save " + path)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var s: GameSession = game.get_node("Session")
	var hud = game.get_node("HUD")
	s.set_physics_process(false)
	s.restart_game()
	var catalog: UnitCatalog = s.catalog
	var grades: GradeCatalog = s.grade_catalog
	var slots: Array[int] = [0, 2, 4, 6, 8, 10, 14]
	for index in 7:
		var forced := UnitCatalog.new()
		forced.units.append(catalog.units[index])
		s.catalog = forced
		var rarity := GradeCatalog.new()
		rarity.grades.append(grades.grades[[0, 1, 2, 3, 4, 2, 4][index]])
		s.grade_catalog = rarity
		s.gold = s.SUMMON_COST
		check(s.summon(slots[index]), "Summon showcase unit")
	s.catalog = catalog
	s.grade_catalog = grades
	await create_timer(0.2).timeout
	check(hud.arrival_label.text.contains("LEGENDARY"), "Legendary banner visible")
	check(not paused and game.get_node("Effects").arrivals.size() > 0, "Summon effects do not pause game")
	await capture("res://docs/phase4-roster.png")
	s.handle_slot(10)
	await capture("res://docs/phase4-flame-info.png")
	check(hud.info_label.text.contains("연소") and hud.info_label.text.contains("판매 25"), "Ability and sale info")
	await create_timer(2.2).timeout
	s.clear_selection()
	await capture("res://docs/phase4-silhouettes.png")
	s.clear_selection()
	s.handle_slot(14)
	await capture("res://docs/phase4-drone-info.png")
	s._physics_process(10.0)
	for index in 28:
		var enemy: Enemy = s.spawn_enemy(s.wave_director.enemy_types[index % 4])
		enemy.advance(index * enemy.board.route_length / 28.0 / enemy.speed)
	s.set_physics_process(true)
	await create_timer(2.0).timeout
	check(s.state == s.State.COMBAT and (s.kills > 0 or not s.enemies.is_empty()), "Mixed roster fights without pausing")
	await capture("res://docs/phase4-combat.png")
	s.restart_game()
	check(game.get_node("Effects").arrivals.is_empty() and hud.arrival_label.text.is_empty(), "Restart clears arrival effects")
	print("WINDOWS PHASE 4: ", failures, " failures")
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
