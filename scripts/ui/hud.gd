extends CanvasLayer

const TEXT := Color("d3ddd7")
const MUTED := Color("83968f")
const ACCENT := Color("b9c391")
var session: GameSession
var board: Battlefield
var root_control: Control
var gold_label: Label
var wave_label: Label
var enemy_label: Label
var kills_label: Label
var status_label: Label
var selection_label: Label
var info_label: Label
var countdown: ColorRect
var pressure_bar: ColorRect
var pressure_label: Label
var summon_button: Button
var clear_button: Button
var sell_button: Button
var confirm_button: Button
var cancel_button: Button
var sale_label: Label
var catalog_controls: Array[Control] = []
var pause_button: Button
var overlay: Panel
var overlay_title: Label
var overlay_body: Label
var font := SystemFont.new()
var arrival_label: Label
var arrival_time: float = 0.0

func _ready() -> void:
	font.font_names = PackedStringArray(["Malgun Gothic", "Apple SD Gothic Neo", "Noto Sans CJK KR", "sans-serif"])
	root_control = Control.new()
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	_panel(Rect2(24, 20, 1232, 84))
	_label("IRON PERIMETER", Rect2(44, 30, 360, 36), 29, TEXT)
	_label("TACTICAL DEFENSE  /  FRONTIER COMMAND", Rect2(46, 72, 410, 22), 12, MUTED)
	wave_label = _label("", Rect2(478, 34, 185, 30), 20, TEXT)
	_label("WAVE / 작전 단계", Rect2(480, 72, 170, 20), 12, MUTED)
	gold_label = _label("", Rect2(670, 34, 170, 30), 24, ACCENT)
	_label("GOLD / 보급 자원", Rect2(672, 72, 170, 20), 12, MUTED)
	enemy_label = _label("", Rect2(870, 34, 190, 30), 24, TEXT)
	pressure_label = _label("생존 적 / 한도 60", Rect2(872, 72, 200, 20), 12, MUTED)
	pressure_bar = ColorRect.new()
	pressure_bar.position = Vector2(872, 96)
	pressure_bar.size = Vector2(0, 3)
	pressure_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(pressure_bar)
	kills_label = _label("", Rect2(1100, 34, 140, 30), 24, TEXT)
	_label("CONFIRMED / 처치", Rect2(1100, 72, 140, 20), 12, MUTED)
	_panel(Rect2(984, 124, 272, 482))
	_label("REINFORCEMENTS", Rect2(1002, 139, 240, 28), 20, TEXT)
	_label("랜덤 증원 / 가중치 기반 소환", Rect2(1002, 172, 240, 24), 13, MUTED)
	arrival_label = _label("", Rect2(270, 130, 670, 30), 18, TEXT)
	selection_label = _label("", Rect2(1002, 435, 240, 26), 16, ACCENT)
	info_label = _label("", Rect2(1002, 468, 232, 78), 13, TEXT)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summon_button = _button("유닛 소환  /  %d G" % GameSession.SUMMON_COST, Rect2(1000, 548, 240, 44), _summon)
	sell_button = _button("판매  /  +%d G" % GameSession.SELL_VALUE, Rect2(1000, 490, 240, 44), _sell)
	sale_label = _label("", Rect2(1002, 395, 234, 34), 14, ACCENT)
	confirm_button = _button("판매 확정", Rect2(1000, 438, 115, 44), _confirm_sale)
	cancel_button = _button("취소", Rect2(1125, 438, 115, 44), _cancel_sale)
	_panel(Rect2(24, 622, 1232, 74))
	status_label = _label("작전 준비 — 10초 후 적이 진입합니다. 유닛을 배치하세요.", Rect2(42, 630, 750, 26), 15, TEXT)
	_label("재클릭 / 우클릭 / ESC 해제   ·   슬롯 클릭 이동·교환   ·   Q 소환   ·   SPACE 정지", Rect2(42, 663, 750, 22), 12, MUTED)
	clear_button = _button("선택 해제", Rect2(800, 636, 130, 46), _clear_selection)
	pause_button = _button("일시정지", Rect2(944, 636, 130, 46), _pause)
	_button("재시작", Rect2(1088, 636, 150, 46), _restart)
	_panel(Rect2(36, 611, 930, 4))
	countdown = ColorRect.new()
	countdown.position = Vector2(36, 611)
	countdown.size = Vector2(930, 4)
	countdown.color = Color("799688")
	countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(countdown)
	overlay = _panel(Rect2(285, 290, 428, 170))
	overlay_title = _label("", Rect2(309, 310, 380, 40), 27, TEXT)
	overlay_body = _label("", Rect2(309, 361, 380, 76), 15, MUTED)
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func bind_session(game: GameSession, field: Battlefield) -> void:
	session = game
	board = field
	session.changed.connect(refresh)
	session.notice.connect(func(message: String) -> void: status_label.text = message)
	session.summoned.connect(_on_summoned)
	session.restarted.connect(func() -> void: arrival_time = 0.0; arrival_label.text = "")
	for kind in session.wave_director.enemy_types.size():
		var enemy_type: EnemyDefinition = session.wave_director.enemy_types[kind]
		_label(enemy_type.display_name, Rect2(50 + kind * 105, 584, 100, 18), 11, enemy_type.accent)
	for index in session.grade_catalog.grades.size():
		var grade: UnitGrade = session.grade_catalog.grades[index]
		var y: float = 212 + index * 36
		catalog_controls.append(_panel(Rect2(1000, y, 240, 31)))
		catalog_controls.append(_label(grade.display_name + " / " + grade.id, Rect2(1008, y + 3, 182, 24), 13, grade.color))
		catalog_controls.append(_label("%.1f%%" % (grade.weight * 100.0 / session.grade_catalog.total_weight()), Rect2(1190, y + 3, 50, 24), 13, grade.color))
	catalog_controls.append(_label("7종 유형 × 5등급 / 독립 추첨", Rect2(1002, 400, 240, 24), 12, MUTED))
	refresh()

func refresh() -> void:
	gold_label.text = "%04d" % session.gold
	var preparing: bool = session.state == GameSession.State.PREPARATION or (session.state == GameSession.State.PAUSED and session.resume_state == GameSession.State.PREPARATION)
	wave_label.text = "작전 준비  %02ds" % ceili(session.preparation_remaining) if preparing else "%02d   /  %.0fs" % [session.wave, session.wave_remaining]
	enemy_label.text = "%02d / %02d" % [session.enemies.size(), session.ENEMY_LIMIT]
	var alive_count: int = session.enemies.size()
	var pressure_color: Color = Color("ed8a6b") if alive_count >= 45 else (Color("d8b476") if alive_count >= 30 else TEXT)
	enemy_label.modulate = pressure_color
	pressure_bar.color = pressure_color
	pressure_bar.size.x = 180.0 * alive_count / session.ENEMY_LIMIT
	var warning: String = "붕괴 임박" if alive_count >= 54 else ("누적 위험" if alive_count >= 45 else ("누적 주의" if alive_count >= 30 else "생존 적"))
	pressure_label.text = "%s / 한도 60" % warning
	pressure_label.modulate = pressure_color
	kills_label.text = "%04d" % session.kills
	var ratio: float = session.preparation_remaining / session.PREPARATION_DURATION if preparing else session.wave_remaining / session.WAVE_DURATION
	countdown.size.x = 930.0 * clampf(ratio, 0.0, 1.0)
	pause_button.disabled = session.state == GameSession.State.GAME_OVER
	pause_button.text = "계속" if session.state == GameSession.State.PAUSED else "일시정지"
	var selected: int = board.selected_slot
	var has_unit: bool = is_instance_valid(session.selected_tower)
	var confirming: bool = is_instance_valid(session.pending_sale)
	for control in catalog_controls:
		control.visible = not has_unit
	selection_label.position.y = 212 if has_unit else 435
	info_label.position.y = 246 if has_unit else 468
	info_label.size.y = 144 if has_unit else 78
	info_label.add_theme_font_size_override("font_size", 12 if has_unit else 13)
	selection_label.text = "AUTO DEPLOY / 자동 배치" if selected < 0 else "SLOT %02d / 배치 슬롯" % (selected + 1)
	info_label.text = "빈 칸 선택 → 소환\n유닛 선택 → 다른 슬롯 이동 / 교환"
	if has_unit:
		var tower: Tower = session.selected_tower
		var data: UnitDefinition = tower.definition
		selection_label.text = data.display_name
		selection_label.add_theme_color_override("font_color", tower.grade.color)
		info_label.text = "%s / %s\n공격력 %.1f / 공격속도 %.2f회/초\n사거리 %.0f / 방어 관통 %.1f\n%s\n판매 %d G" % [data.category, tower.grade.id, tower.damage(), 1.0 / tower.interval(), tower.reach(), tower.penetration(), _ability(tower), session.SELL_VALUE]
	else:
		selection_label.add_theme_color_override("font_color", ACCENT)
	clear_button.disabled = selected < 0
	sell_button.visible = has_unit and not confirming
	sell_button.disabled = not session.can_manage_units()
	confirm_button.visible = confirming
	cancel_button.visible = confirming
	sale_label.visible = confirming
	sale_label.text = "판매 확인 / +%d G\n선택한 유닛이 제거됩니다." % session.SELL_VALUE
	summon_button.disabled = not session.can_manage_units() or confirming or session.gold < session.SUMMON_COST or board.first_empty() < 0
	overlay.visible = session.state in [GameSession.State.PAUSED, GameSession.State.GAME_OVER]
	overlay_title.visible = overlay.visible
	overlay_body.visible = overlay.visible
	match session.state:
		GameSession.State.PAUSED:
			overlay_title.text = "작전 일시정지"
			overlay_body.text = "[계속] 또는 SPACE로 전투를 재개합니다."
		GameSession.State.GAME_OVER:
			overlay_title.text = "방어선 붕괴"
			overlay_body.text = "WAVE %02d / %d기 처치\n[재시작]으로 새 작전을 준비하세요." % [session.wave, session.kills]

func _summon() -> void:
	if is_instance_valid(session.pending_sale):
		return
	var target: int = board.selected_slot
	if board.occupied.has(target):
		target = -1
	session.summon(target)

func _ability(tower: Tower) -> String:
	var d: UnitDefinition = tower.definition
	match d.attack_kind:
		UnitDefinition.AttackKind.ARTILLERY:
			return "광역 포격 / 반경 %.0f" % (d.splash_radius * tower.special())
		UnitDefinition.AttackKind.PIERCE:
			return "직선 관통 / 폭 %.0f" % (d.beam_width * tower.special() * 2.0)
		UnitDefinition.AttackKind.FLAME:
			return "원뿔 %d대상 / 연소 %.1f DPS\n지속 %.2fs / 최대 3출처 중첩" % [d.max_targets + tower.grade.extra_targets, d.burn_dps * tower.special(), d.burn_duration * tower.special()]
		UnitDefinition.AttackKind.SLOW:
			return "감속 %.0f%% / %.2fs\n가장 강한 효과만, 최대 50%%" % [minf(0.5, d.slow_strength * tower.special()) * 100, minf(3, d.slow_duration * tower.special())]
		_:
			return d.description

func _on_summoned(tower: Tower) -> void:
	if tower.grade.rank >= 2:
		arrival_label.text = "%s 증원  /  %s" % [tower.grade.id, tower.definition.display_name]
		arrival_label.add_theme_color_override("font_color", tower.grade.color)
		arrival_label.add_theme_font_size_override("font_size", 22 if tower.grade.rank == 4 else 18)
		arrival_time = 3.5 if tower.grade.rank >= 3 else 2.2

func _process(delta: float) -> void:
	if arrival_time > 0.0:
		arrival_time = maxf(0.0, arrival_time - delta)
		arrival_label.modulate.a = minf(arrival_time, 1.0)
		if arrival_time == 0.0:
			arrival_label.text = ""

func _clear_selection() -> void:
	session.clear_selection()

func _sell() -> void:
	session.request_sale()

func _confirm_sale() -> void:
	session.confirm_sale()

func _cancel_sale() -> void:
	session.cancel_sale()

func _pause() -> void:
	session.toggle_pause()

func _restart() -> void:
	session.restart_game()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and session:
		match event.keycode:
			KEY_Q:
				_summon()
			KEY_SPACE:
				_pause()
			KEY_ESCAPE:
				_clear_selection()

func _input(event: InputEvent) -> void:
	# Right-click is a global deselect action, including over non-interactive HUD.
	if session and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_clear_selection()
		get_viewport().set_input_as_handled()

func _style(color: Color, border: Color = Color("344449")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	return style

func _panel(rect: Rect2) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	# Background panels are not controls: clicks pass to Board for deselection.
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(Color("111b21")))
	root_control.add_child(panel)
	return panel

func _label(text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(label)
	return label

func _button(text: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	# Global Q/Space/Enter shortcuts must not activate the last clicked button.
	button.focus_mode = Control.FOCUS_NONE
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_disabled_color", Color("586665"))
	button.add_theme_stylebox_override("normal", _style(Color("2c3b38"), Color("6d8273")))
	button.add_theme_stylebox_override("hover", _style(Color("40534a"), ACCENT))
	button.add_theme_stylebox_override("pressed", _style(Color("1b2925"), ACCENT))
	button.add_theme_stylebox_override("disabled", _style(Color("192329")))
	button.pressed.connect(callback)
	root_control.add_child(button)
	return button
