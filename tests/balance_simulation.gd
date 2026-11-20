extends SceneTree

# Uses the production scenes and the same 60 Hz update order (Enemies -> Session).
# Only rendering/signals are suppressed. Damage, RNG, gold, spawns, paths and defeat
# remain the production implementations. No frame skipping or alternate combat model.
const STEP: float = 1.0 / 60.0
const PLACEMENT: Array[int] = [0, 1, 6, 2, 12, 7, 18, 3, 13, 8, 19, 4, 14, 9, 20, 5, 15, 10, 21, 16, 11, 22, 17, 23]
var runs: int = 100
var max_wave: int = 13
var cohorts: Array[String] = ["random", "weak", "strong", "weak_no_growth", "strong_no_growth"]

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			runs = int(arg.get_slice("=", 1))
		if arg.begins_with("--cohorts="):
			cohorts.assign(arg.get_slice("=", 1).split(","))
	call_deferred("run")

func run() -> void:
	var started: int = Time.get_ticks_msec()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.get_node("HUD").free()
	game.get_node("Effects").set_process(false)
	var s: GameSession = game.get_node("Session")
	s.combat.shot.disconnect(game.get_node("Effects").add_shot)
	s.set_physics_process(false)
	s.set_block_signals(true)
	# The harness alone advances actors; yielding to flush deletion must never
	# give a freshly spawned enemy an extra automatic physics update.
	s.actors.process_mode = Node.PROCESS_MODE_DISABLED
	var full_catalog: UnitCatalog = s.catalog
	var full_grades: GradeCatalog = s.grade_catalog
	var reports: Dictionary = {}
	for cohort in cohorts:
		var outcomes: Array[Dictionary] = []
		# No-growth cohorts have no random choices after their forced opening.
		var solo: bool = cohort.begins_with("legendary_solo_")
		var cohort_runs: int = 1 if cohort.ends_with("no_growth") or solo else runs
		for seed_value in range(1, cohort_runs + 1):
			s.restart_game()
			s.rng.seed = seed_value
			for initial in (1 if solo else 2):
				if cohort != "random":
					var forced := UnitCatalog.new()
					var type_index: int = 3 if cohort.begins_with("weak") else initial + 1
					if solo:
						for index in full_catalog.units.size():
							if full_catalog.units[index].id == cohort.trim_prefix("legendary_solo_"):
								type_index = index
					forced.units.append(full_catalog.units[type_index])
					s.catalog = forced
					var forced_grades := GradeCatalog.new()
					forced_grades.grades.append(full_grades.grades[4 if solo else 0])
					s.grade_catalog = forced_grades
				s.summon(PLACEMENT[initial])
			s.catalog = full_catalog
			s.grade_catalog = full_grades
			var composition: Array[String] = []
			for tower in s.towers:
				composition.append(tower.definition.id + "/" + tower.grade.id)
			var samples: Dictionary = {}
			for tick in 18000:
				if s.gold >= s.SUMMON_COST and s.towers.size() < 24 and not cohort.ends_with("no_growth") and not solo:
					s.summon(PLACEMENT[s.towers.size()])
				var prior_wave: int = s.wave
				var prior_gold: int = s.gold
				var prior_count: int = s.enemies.size()
				for enemy in s.enemies.duplicate():
					enemy.advance(STEP)
				s._physics_process(STEP)
				if s.wave != prior_wave and prior_wave > 0:
					samples[str(prior_wave)] = {"gold": prior_gold, "alive": prior_count}
				if s.state == s.State.GAME_OVER:
					samples[str(s.wave)] = {"gold": s.gold, "alive": s.enemies.size()}
					break
				if s.wave > max_wave:
					break
				if tick % 120 == 0:
					# Flush queue_free without advancing production physics a second time.
					await process_frame
			var died: bool = s.state == s.State.GAME_OVER
			outcomes.append({"seed": seed_value, "initial": composition, "game_over": died, "wave": s.wave, "gold": s.gold, "kills": s.kills, "towers": s.towers.size(), "samples": samples})
			s.restart_game()
			await process_frame
			if seed_value % 20 == 0:
				print("BALANCE PROGRESS ", cohort, " ", seed_value, "/", runs)
		reports[cohort] = summarize(outcomes)
		print("COHORT ", cohort, ": ", JSON.stringify(reports[cohort].summary))
	var result: Dictionary = {"runs_per_randomized_cohort": runs, "seed_first": 1, "seed_last": runs, "max_wave": max_wave, "physics_hz": 60, "policy": "Spend whenever gold >= 50; fixed 24-slot order; no sales or moves. Forced cohorts only change first two draws, subsequent RNG sequence is paired.", "sample_definition": "At end of each wave before survival supply, or at defeat (60 alive); conditional on reaching that wave.", "seconds": (Time.get_ticks_msec() - started) / 1000.0, "cohorts": reports}
	var file := FileAccess.open("res://docs/phase4-balance-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("BALANCE SAVED: docs/phase4-balance-results.json / ", result.seconds, " seconds")
	game.queue_free()
	await process_frame
	quit()

func summarize(outcomes: Array[Dictionary]) -> Dictionary:
	var early: int = 0
	var reach10: int = 0
	var deaths: int = 0
	var wave_sum: float = 0.0
	var per_wave: Dictionary = {}
	for row in outcomes:
		if row.game_over:
			deaths += 1
			if row.wave <= 4:
				early += 1
		if row.wave >= 10:
			reach10 += 1
		wave_sum += mini(row.wave, max_wave + 1)
		for key in row.samples:
			if not per_wave.has(key):
				per_wave[key] = {"n": 0, "gold_sum": 0.0, "alive_sum": 0.0}
			per_wave[key].n += 1
			per_wave[key].gold_sum += row.samples[key].gold
			per_wave[key].alive_sum += row.samples[key].alive
	for key in per_wave:
		var stat: Dictionary = per_wave[key]
		per_wave[key] = {"n": stat.n, "mean_gold": stat.gold_sum / stat.n, "mean_alive": stat.alive_sum / stat.n}
	return {"summary": {"runs": outcomes.size(), "death_by_wave4_pct": early * 100.0 / outcomes.size(), "reach_wave10_pct": reach10 * 100.0 / outcomes.size(), "actual_game_overs": deaths, "mean_terminal_wave_capped14": wave_sum / outcomes.size()}, "per_wave": per_wave, "runs": outcomes}
