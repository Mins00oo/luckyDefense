class_name GameSession
extends Node

signal changed
signal notice(message: String)
signal summoned(tower: Tower)
signal restarted

enum State { PREPARATION, COMBAT, PAUSED, GAME_OVER }
const STARTING_GOLD: int = 100
const SUMMON_COST: int = 50
const SELL_VALUE: int = SUMMON_COST / 2
const PREPARATION_DURATION: float = 10.0
const ENEMY_LIMIT: int = 60
const WAVE_DURATION: float = 18.0
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const TOWER_SCENE: PackedScene = preload("res://scenes/tower.tscn")
@export var catalog: UnitCatalog
@export var grade_catalog: GradeCatalog = preload("res://data/grade_catalog.tres")
@export var wave_director: WaveDirector = preload("res://data/waves.tres")
@onready var board: Battlefield = $"../Board"
@onready var actors: Node2D = $"../Actors"
@onready var combat: CombatSystem = $"../Combat"
var state: State = State.PREPARATION
var resume_state: State = State.PREPARATION
var preparation_remaining: float = PREPARATION_DURATION
var selected_tower: Tower
var pending_sale: Tower
var gold: int = STARTING_GOLD
var kills: int = 0
var wave: int = 0
var wave_remaining: float = WAVE_DURATION
var spawn_remaining: int = 0
var spawn_clock: float = 0.0
var spawn_queue: Array[EnemyDefinition] = []
var enemies: Array[Enemy] = []
var towers: Array[Tower] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	board.slot_selected.connect(handle_slot)
	board.background_clicked.connect(clear_selection)

func _physics_process(delta: float) -> void:
	if state == State.PREPARATION:
		preparation_remaining = maxf(0.0, preparation_remaining - delta)
		if preparation_remaining <= 0.0:
			state = State.COMBAT
			_next_wave()
		changed.emit()
		return
	if state != State.COMBAT:
		return
	wave_remaining -= delta
	if wave_remaining <= 0.0:
		_next_wave()
	spawn_clock -= delta
	if spawn_remaining > 0 and spawn_clock <= 0.0:
		var definition: EnemyDefinition = spawn_queue.pop_front()
		spawn_remaining -= 1
		spawn_clock += wave_director.spawn_interval(wave, definition)
		spawn_enemy(definition)
	if state == State.COMBAT:
		combat.tick(delta, towers, enemies)
	changed.emit()

func _next_wave() -> void:
	if wave > 0:
		gold += wave_director.wave_reward
	wave += 1
	wave_remaining = WAVE_DURATION
	spawn_queue = wave_director.build_wave(wave)
	spawn_remaining = spawn_queue.size()
	spawn_clock = 0.0
	notice.emit("WAVE %02d — 적 %d기 진입 / 생존 적은 계속 누적됩니다." % [wave, spawn_remaining])
	changed.emit()

func spawn_enemy(definition: EnemyDefinition = null) -> Enemy:
	if state != State.COMBAT:
		return null
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	actors.add_child(enemy)
	if definition == null:
		definition = wave_director.enemy_types[0]
	enemy.setup(board, maxi(wave, 1), definition, wave_director)
	enemy.died.connect(_on_enemy_died)
	enemies.append(enemy)
	if enemies.size() >= ENEMY_LIMIT:
		state = State.GAME_OVER
		pending_sale = null
		get_tree().paused = true
		notice.emit("방어선 붕괴 — 재시작하여 다시 도전하세요.")
	changed.emit()
	return enemy

func _on_enemy_died(enemy: Enemy) -> void:
	enemies.erase(enemy)
	gold += enemy.reward
	kills += 1
	changed.emit()

func summon(requested_slot: int = -1) -> bool:
	if not can_manage_units():
		return false
	var index: int = requested_slot if requested_slot >= 0 else board.first_empty()
	if index < 0 or index >= Battlefield.COLUMNS * Battlefield.ROWS or board.occupied.has(index):
		notice.emit("배치 가능한 빈 칸을 선택하세요.")
		return false
	if gold < SUMMON_COST:
		notice.emit("골드 부족 — 적을 처치하면 보급됩니다.")
		return false
	var definition: UnitDefinition = catalog.roll(rng)
	var rarity: UnitGrade = grade_catalog.roll(rng)
	if definition == null or rarity == null:
		notice.emit("소환 목록의 가중치를 확인하세요.")
		return false
	var tower: Tower = TOWER_SCENE.instantiate()
	actors.add_child(tower)
	tower.position = board.slot_position(index)
	tower.setup(definition, index, rarity)
	towers.append(tower)
	board.occupied[index] = tower
	clear_selection()
	board.selected_slot = index
	board.queue_redraw()
	gold -= SUMMON_COST
	notice.emit("증원: %s / %s" % [definition.display_name, rarity.display_name])
	summoned.emit(tower)
	changed.emit()
	return true

func toggle_pause() -> void:
	pending_sale = null
	if can_manage_units():
		resume_state = state
		state = State.PAUSED
		get_tree().paused = true
	elif state == State.PAUSED:
		state = resume_state
		get_tree().paused = false
	changed.emit()

func restart_game() -> void:
	get_tree().paused = false
	clear_selection()
	for actor in actors.get_children():
		actors.remove_child(actor)
		actor.queue_free()
	enemies.clear()
	towers.clear()
	board.reset()
	gold = STARTING_GOLD
	kills = 0
	wave = 0
	wave_remaining = WAVE_DURATION
	spawn_remaining = 0
	spawn_queue.clear()
	spawn_clock = 0.0
	preparation_remaining = PREPARATION_DURATION
	state = State.PREPARATION
	resume_state = State.PREPARATION
	restarted.emit()
	notice.emit("작전 준비 — 10초 후 적이 진입합니다. 유닛을 배치하세요.")
	changed.emit()

func can_manage_units() -> bool:
	return state in [State.PREPARATION, State.COMBAT]

func clear_selection() -> void:
	if is_instance_valid(selected_tower):
		selected_tower.set_selected(false)
	selected_tower = null
	pending_sale = null
	board.selected_slot = -1
	board.selected_range = 0.0
	board.queue_redraw()
	changed.emit()

func handle_slot(index: int) -> void:
	if not can_manage_units() or index < 0 or index >= Battlefield.COLUMNS * Battlefield.ROWS:
		return
	pending_sale = null
	if is_instance_valid(selected_tower):
		if selected_tower.slot == index:
			clear_selection()
		else:
			move_selected(index)
	else:
		selected_tower = board.occupied.get(index) as Tower
		board.selected_slot = index
		if selected_tower:
			selected_tower.set_selected(true)
			board.selected_range = selected_tower.reach()
		board.queue_redraw()
		changed.emit()

func move_selected(destination: int) -> bool:
	if not can_manage_units() or not is_instance_valid(selected_tower) or not towers.has(selected_tower):
		return false
	if destination < 0 or destination >= Battlefield.COLUMNS * Battlefield.ROWS:
		return false
	pending_sale = null
	var source: int = selected_tower.slot
	var other: Tower = board.occupied.get(destination) as Tower
	board.occupied.erase(source)
	if other and other != selected_tower:
		other.slot = source
		other.position = board.slot_position(source)
		board.occupied[source] = other
	selected_tower.slot = destination
	selected_tower.position = board.slot_position(destination)
	board.occupied[destination] = selected_tower
	board.selected_slot = destination
	board.queue_redraw()
	changed.emit()
	return true

func request_sale() -> bool:
	if not can_manage_units() or not is_instance_valid(selected_tower) or not towers.has(selected_tower):
		return false
	pending_sale = selected_tower
	changed.emit()
	return true

func cancel_sale() -> void:
	pending_sale = null
	changed.emit()

func confirm_sale() -> bool:
	if not can_manage_units() or not is_instance_valid(pending_sale) or pending_sale != selected_tower:
		return false
	var tower: Tower = pending_sale
	if not towers.has(tower) or board.occupied.get(tower.slot) != tower:
		return false
	# Remove every gameplay reference before refunding, so repeated confirms are inert.
	towers.erase(tower)
	board.occupied.erase(tower.slot)
	clear_selection()
	actors.remove_child(tower)
	tower.queue_free()
	gold += SELL_VALUE
	notice.emit("유닛 판매 완료 — %d G 환불" % SELL_VALUE)
	changed.emit()
	return true
