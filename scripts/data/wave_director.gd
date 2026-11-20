class_name WaveDirector
extends Resource

@export var enemy_types: Array[EnemyDefinition] = []
# Components: normal, runner, armored, swarm. First five waves are authored.
@export var opening_counts: Array[Vector4i] = []
@export var opening_intervals: Array[float] = [0.85, 0.65, 0.42, 0.30, 0.26]
@export var health_growth: float = 1.13
@export var speed_growth: float = 0.018
@export var wave_reward: int = 8

func counts_for(wave: int) -> Vector4i:
	if wave <= opening_counts.size():
		return opening_counts[maxi(0, wave - 1)]
	var extra: int = wave - opening_counts.size()
	return opening_counts.back() + Vector4i(mini(extra, 6), mini(extra, 6), mini(extra, 8), mini(extra * 2, 14))

func build_wave(wave: int) -> Array[EnemyDefinition]:
	var remaining: Vector4i = counts_for(wave)
	var result: Array[EnemyDefinition] = []
	while remaining != Vector4i.ZERO:
		for kind in 4:
			# Swarms arrive in packs so splash/penetration can counter them.
			var batch: int = mini(remaining[kind], 4 if kind == 3 else 1)
			for index in batch:
				result.append(enemy_types[kind])
			remaining[kind] -= batch
	return result

func spawn_interval(wave: int, definition: EnemyDefinition) -> float:
	var base: float = opening_intervals[mini(wave - 1, opening_intervals.size() - 1)]
	return base * definition.spawn_gap_multiplier

func health_multiplier(wave: int) -> float:
	return pow(health_growth, wave - 1)

func speed_multiplier(wave: int) -> float:
	return minf(1.0 + speed_growth * (wave - 1), 1.45)
