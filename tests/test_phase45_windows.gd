extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func click(at: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(path) == OK, "Screenshot saved")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var s: GameSession = game.get_node("Session")
	s.set_physics_process(false)
	var original := s.catalog
	var forced := UnitCatalog.new()
	forced.units.append(load("res://data/units/assault.tres"))
	s.catalog = forced
	check(s.summon(0) and s.summon(1), "Two normal-cost summons")
	s.catalog = original
	var tower: Tower = s.towers[0]
	var other: Tower = s.towers[1]
	var sprite: AnimatedSprite2D = tower.visual.get_node("Sprite")
	check(tower.definition.damage == 9.0 and tower.definition.attack_interval == 0.26 and tower.definition.attack_range == 330.0, "Stats preserved")
	for action in [&"idle", &"walk", &"attack", &"hit"]:
		check(sprite.sprite_frames.get_frame_count(action) == 6, "Six frames for " + action)
	check(sprite.animation == &"idle" and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Idle / nearest filter")
	tower.aim(Vector2.ZERO)
	check(tower.visual.rotation == 0.0, "Single-direction art never rotates")
	click(tower.position + Vector2(0, -39))
	check(s.selected_tower == tower and s.board.selected_range == tower.reach(), "Selection and range")
	click(tower.position + Vector2(0, -39))
	check(s.selected_tower == null, "Helmet click toggles selection")
	click(tower.position + Vector2(0, -39))
	await capture("res://docs/phase45-idle.png")
	click(s.board.slot_position(6))
	check(tower.slot == 6 and tower.position == s.board.slot_position(6), "Empty slot movement")
	click(other.position + Vector2(0, -39))
	check(tower.slot == 1 and other.slot == 6, "Swap occupied slots")
	s._physics_process(10.0)
	check(s.wave == 1 and s.state == s.State.COMBAT, "Preparation starts first wave")
	var enemy := s.spawn_enemy()
	enemy.set_physics_process(false)
	enemy.position = tower.position + Vector2(100, 20)
	enemy.health = 10000.0
	var health_before := enemy.health
	tower.cooldown = 0.0
	s.combat.tick(0.016, s.towers, s.enemies)
	check(enemy.health < health_before and sprite.animation == &"attack", "Real damage and animation start together")
	await create_timer(0.08).timeout
	await capture("res://docs/phase45-attack.png")
	s.toggle_pause()
	var frame_before := sprite.frame
	await create_timer(0.15).timeout
	check(sprite.frame == frame_before, "Animation pauses with game")
	s.toggle_pause()
	await create_timer(0.3).timeout
	check(sprite.animation == &"idle", "Attack returns to idle")
	s.handle_slot(7)
	tower.cooldown = 0.0
	s.combat.tick(0.016, s.towers, s.enemies)
	check(tower.slot == 7 and sprite.animation == &"attack", "Attack after combat movement")
	for grade in s.grade_catalog.grades:
		tower.grade = grade
		s.combat.fire(tower, enemy, s.enemies)
		check(6.0 / sprite.sprite_frames.get_animation_speed(&"attack") < tower.interval(), "Animation fits grade fire interval")
		await create_timer(tower.interval()).timeout
		check(sprite.animation == &"idle", "Grade attack finishes")
	var gold_before := s.gold
	check(s.request_sale() and s.confirm_sale(), "Confirmed sale")
	check(s.gold == gold_before + 25 and not s.board.occupied.has(7), "Refund and free slot")
	check(not s.confirm_sale(), "No double refund")
	s.gold += 25
	s.catalog = forced
	check(s.summon(7), "Resummon sold slot")
	s.catalog = original
	s.restart_game()
	check(s.gold == 100 and s.towers.is_empty() and s.enemies.is_empty() and s.preparation_remaining == 10.0, "Restart resets all")
	print("WINDOWS PHASE 4.5: ", failures, " failures")
	if "--preview" in OS.get_cmdline_user_args():
		s.catalog = forced
		s.summon(0)
		s.summon(1)
		s.catalog = original
		s.set_physics_process(true)
		return
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
