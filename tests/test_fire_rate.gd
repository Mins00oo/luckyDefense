extends SceneTree

var shots: int = 0
var failures: int = 0

func count_shot(_a: Vector2, _b: Vector2, _c: int, _d: Color, _e: float) -> void:
	shots += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var s: GameSession = game.get_node("Session")
	s.set_physics_process(false)
	s.actors.process_mode = Node.PROCESS_MODE_DISABLED
	s._physics_process(10.0)
	s.summon(0)
	var tower: Tower = s.towers[0]
	tower.definition = s.catalog.units[0]
	var enemy: Enemy = s.spawn_enemy()
	enemy.health = 1e9
	enemy.position = tower.position + Vector2(30, 0)
	s.combat.shot.connect(count_shot)
	var report: Array[Dictionary] = []
	for grade in s.grade_catalog.grades:
		tower.grade = grade
		tower.cooldown = 0.0
		shots = 0
		for tick in 3600:
			s.combat.tick(1.0 / 60.0, s.towers, s.enemies)
		var expected: float = 1.0 / tower.interval()
		var actual: float = shots / 60.0
		if absf(actual - expected) > 0.03:
			failures += 1
			push_error("Delivered fire rate mismatch: " + grade.id)
		report.append({"grade": grade.id, "expected_shots_per_second": expected, "actual_shots_per_second": actual})
		print(grade.id, " fire rate expected=", expected, " actual=", actual)
	# Long idle must not accumulate a burst of delayed shots.
	var no_enemies: Array[Enemy] = []
	for tick in 3600:
		s.combat.tick(1.0 / 60.0, s.towers, no_enemies)
	shots = 0
	s.combat.tick(1.0 / 60.0, s.towers, s.enemies)
	s.combat.tick(1.0 / 60.0, s.towers, s.enemies)
	if shots != 1:
		failures += 1
		push_error("Idle accumulated attack debt")
	var file := FileAccess.open("res://docs/phase4-fire-rates.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "measurements": report}, "\t"))
	file.close()
	game.queue_free()
	await process_frame
	print("FIRE RATE TEST: ", failures, " failures")
	quit(0 if failures == 0 else 1)
