class_name Game
extends Node2D
## Haupt-Spielszene für Lane Defenders.
## Verbindet die Spiellogik (GameModel) mit visueller Darstellung, Sound und Steuerung.

@export var autoplay: bool = false

var model: GameModel
var selected_unit_data: UnitData = null
var current_level: LevelData

var _unit_views: Dictionary = {} # "lane_col" -> UnitView
var _enemy_views: Dictionary = {} # int id -> EnemyView
var _proj_views: Dictionary = {} # int id -> ProjectileView
var _drop_views: Dictionary = {} # int id -> EnergyDropView

var _hover_lane: int = -1
var _hover_col: int = -1
var _cursor_lane: int = 2
var _cursor_col: int = 0
var _using_gamepad_cursor: bool = false
var _shake_amount: float = 0.0

@onready var hud: GameHUD = $HUD
@onready var sfx: SoundEffects = $SoundEffects
@onready var _board_draw: Node2D = $BoardLayer
@onready var _units_container: Node2D = $UnitsContainer
@onready var _enemies_container: Node2D = $EnemiesContainer
@onready var _proj_container: Node2D = $ProjectilesContainer
@onready var _drops_container: Node2D = $DropsContainer
@onready var _effects_container: Node2D = $EffectsContainer
@onready var _ghost_layer: Node2D = $GhostLayer

var _ghost_sprite: Sprite2D


func _ready() -> void:
	var seed_val := randi()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seed_val = int(arg.trim_prefix("--seed="))
	print("Lane Defenders – Seed: %d" % seed_val)

	var level_id: String = SaveService.get_value("session", "selected_level", "1-1")
	var level_path := "res://data/levels/level_%s.tres" % level_id.replace("-", "_")
	if ResourceLoader.exists(level_path):
		current_level = load(level_path)
	else:
		current_level = load("res://data/levels/level_1_1.tres")

	model = GameModel.new(current_level, seed_val)
	_setup_model_callbacks()

	var bg_path := "res://assets/battlefield_world_%d.png" % current_level.world
	if ResourceLoader.exists(bg_path):
		$Background.texture = load(bg_path)

	_ghost_sprite = Sprite2D.new()
	_ghost_sprite.visible = false
	_ghost_layer.add_child(_ghost_sprite)

	# HUD Initialisierung
	var avail_units: Array[UnitData] = []
	for u_id in current_level.available_units:
		if model.unit_catalog.has(u_id):
			avail_units.append(model.unit_catalog[u_id])
	hud.setup_cards(avail_units)
	hud.set_level_name(current_level.level_id)

	# HUD Signale verbinden
	hud.card_selected.connect(_on_card_selected)
	hud.card_blocked.connect(_on_card_blocked)
	hud.shovel_toggled.connect(_on_shovel_toggled)
	hud.pause_requested.connect(_toggle_pause)
	hud.resume_requested.connect(_toggle_pause)
	hud.retry_requested.connect(_restart_level)
	hud.next_level_requested.connect(_load_next_level)
	hud.main_menu_requested.connect(_go_to_menu)

	if current_level.is_tutorial and not autoplay:
		hud.show_tutorial_step("TUTORIAL_STEP_1")

	# Board Layer Redraw verbinden
	_board_draw.draw.connect(_draw_board)


func _setup_model_callbacks() -> void:
	model.on_unit_placed = func(u: GridModel.GridUnit) -> void:
		var key := "%d_%d" % [u.lane, u.col]
		var view := UnitView.new()
		view.position = model.grid.get_cell_center(u.lane, u.col)
		view.setup(u)
		_units_container.add_child(view)
		_unit_views[key] = view
		sfx.play_place()

	model.on_unit_removed = func(lane: int, col: int) -> void:
		var key := "%d_%d" % [lane, col]
		if _unit_views.has(key):
			var view: UnitView = _unit_views[key]
			_unit_views.erase(key)
			view.queue_free()

	model.on_unit_damaged = func(u: GridModel.GridUnit, _dmg: int) -> void:
		var key := "%d_%d" % [u.lane, u.col]
		if _unit_views.has(key):
			var view: UnitView = _unit_views[key]
			view.queue_redraw()

	model.on_enemy_spawned = func(e: GameModel.SimEnemy) -> void:
		var view := EnemyView.new()
		view.position = Vector2(e.x, LaneDefendersConfig.GRID_ORIGIN.y + (float(e.lane) + 0.5) * LaneDefendersConfig.CELL_HEIGHT)
		view.setup(e)
		_enemies_container.add_child(view)
		_enemy_views[e.id] = view

	model.on_enemy_damaged = func(e: GameModel.SimEnemy, dmg: int) -> void:
		if _enemy_views.has(e.id):
			var view: EnemyView = _enemy_views[e.id]
			view.play_hit_flash()
		_spawn_damage_number(Vector2(e.x, LaneDefendersConfig.GRID_ORIGIN.y + (float(e.lane) + 0.5) * LaneDefendersConfig.CELL_HEIGHT - 30.0), dmg)

	model.on_enemy_died = func(e: GameModel.SimEnemy) -> void:
		if _enemy_views.has(e.id):
			var view: EnemyView = _enemy_views[e.id]
			_enemy_views.erase(e.id)
			view.queue_free()

	model.on_enemy_reached_base = func(e: GameModel.SimEnemy) -> void:
		if _enemy_views.has(e.id):
			var view: EnemyView = _enemy_views[e.id]
			_enemy_views.erase(e.id)
			view.queue_free()
		_shake_amount = 16.0
		sfx.play_hit()

	model.on_projectile_spawned = func(p: GameModel.SimProjectile) -> void:
		var view := ProjectileView.new()
		view.position = Vector2(p.x, LaneDefendersConfig.GRID_ORIGIN.y + (float(p.lane) + 0.5) * LaneDefendersConfig.CELL_HEIGHT)
		view.setup(p)
		_proj_container.add_child(view)
		_proj_views[p.id] = view

		for c in range(LaneDefendersConfig.COLS):
			var u_key := "%d_%d" % [p.lane, c]
			if _unit_views.has(u_key):
				var uview: UnitView = _unit_views[u_key]
				if uview.unit.unit_data.attack_damage > 0:
					uview.play_attack_animation()
					break
		sfx.play_shoot(p.damage >= 30, p.slow_duration > 0.0)

	model.on_projectile_hit = func(_p: GameModel.SimProjectile, target: GameModel.SimEnemy, _dmg: int) -> void:
		sfx.play_hit(target.data.has_shield)

	model.on_energy_dropped = func(d: GameModel.SimEnergyDrop) -> void:
		var view := EnergyDropView.new()
		view.position = d.position
		view.setup(d)
		_drops_container.add_child(view)
		_drop_views[d.id] = view

	model.on_energy_collected = func(d: GameModel.SimEnergyDrop) -> void:
		_spawn_floating_text(d.position, "+25 ☀️", Color("ffe600"))
		if _drop_views.has(d.id):
			var view: EnergyDropView = _drop_views[d.id]
			_drop_views.erase(d.id)
			view.fly_to_hud_and_free(Vector2(100, 50))
		sfx.play_sun_collect()

	model.on_energy_expired = func(d: GameModel.SimEnergyDrop) -> void:
		if _drop_views.has(d.id):
			var view: EnergyDropView = _drop_views[d.id]
			_drop_views.erase(d.id)
			view.fade_out_and_free()

	model.on_final_wave = func() -> void:
		hud.show_final_wave_banner()
		_shake_amount = 12.0
		sfx.play_final_wave()

	model.on_state_changed = func(new_state: GameModel.State) -> void:
		if new_state == GameModel.State.WON:
			var stars := clampi(model.lives, 1, 3)
			SaveService.set_value("lane_defenders", "stars_" + current_level.level_id, stars)
			_unlock_next_level()
			SaveService.save()
			sfx.play_win()
			hud.show_victory(stars, _has_next_level())
		elif new_state == GameModel.State.LOST:
			sfx.play_lose()
			hud.show_defeat()


func _process(delta: float) -> void:
	if _shake_amount > 0.0:
		_shake_amount = maxf(0.0, _shake_amount - delta * 30.0)
		position = Vector2(randf_range(-_shake_amount, _shake_amount), randf_range(-_shake_amount, _shake_amount))
	else:
		position = Vector2.ZERO

	var mpos := get_global_mouse_position()

	# Hover-Einsammeln von Energie
	if not get_tree().paused:
		for d in model.energy_drops:
			if mpos.distance_to(d.position) <= 65.0:
				model.collect_energy(d.id)
				break

	_update_ghost_view(mpos)


func _update_ghost_view(mpos: Vector2) -> void:
	if selected_unit_data != null:
		var tex_path := "res://assets/units/%s.png" % selected_unit_data.id
		if ResourceLoader.exists(tex_path):
			_ghost_sprite.texture = load(tex_path)
			var max_dim := maxf(float(_ghost_sprite.texture.get_width()), float(_ghost_sprite.texture.get_height()))
			var s := 105.0 / max_dim
			_ghost_sprite.scale = Vector2(s, s)
		_ghost_sprite.visible = true

		if _hover_lane >= 0 and _hover_col >= 0 and _hover_lane < LaneDefendersConfig.LANES and _hover_col < LaneDefendersConfig.COLS:
			_ghost_sprite.position = model.grid.get_cell_center(_hover_lane, _hover_col) + Vector2(0, -6.0)
			if model.grid.is_cell_empty(_hover_lane, _hover_col):
				_ghost_sprite.modulate = Color(0.8, 1.2, 0.8, 0.85)
			else:
				_ghost_sprite.modulate = Color(1.5, 0.4, 0.4, 0.75)
		else:
			_ghost_sprite.position = mpos
			_ghost_sprite.modulate = Color(1.0, 1.0, 1.0, 0.7)

	elif hud.is_shovel_active:
		if ResourceLoader.exists("res://assets/ui/shovel.png"):
			_ghost_sprite.texture = load("res://assets/ui/shovel.png")
			var max_dim := maxf(float(_ghost_sprite.texture.get_width()), float(_ghost_sprite.texture.get_height()))
			var s := 65.0 / max_dim
			_ghost_sprite.scale = Vector2(s, s)
		_ghost_sprite.visible = true
		_ghost_sprite.position = mpos + Vector2(20, -20)
		_ghost_sprite.modulate = Color.WHITE
	else:
		_ghost_sprite.visible = false


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return

	if autoplay:
		_run_autoplay_tick()

	model.step(delta)
	hud.update_hud(model, selected_unit_data)

	# Synchronisiere Projektil-Positionen
	for p in model.projectiles:
		if _proj_views.has(p.id):
			var pv: ProjectileView = _proj_views[p.id]
			pv.position.x = p.x
	# Entferne zerstörte Projektile
	var active_proj_ids := {}
	for p in model.projectiles:
		active_proj_ids[p.id] = true
	for p_id in _proj_views.keys():
		if not active_proj_ids.has(p_id):
			_proj_views[p_id].queue_free()
			_proj_views.erase(p_id)

	# Synchronisiere Gegner-Positionen
	for e in model.enemies:
		if _enemy_views.has(e.id):
			var ev: EnemyView = _enemy_views[e.id]
			ev.position.x = e.x
	# Synchronisiere / Bereinige Energie-Drop Views
	var active_drop_ids := {}
	for d in model.energy_drops:
		active_drop_ids[d.id] = true
	for d_id in _drop_views.keys():
		if not active_drop_ids.has(d_id):
			var dv: EnergyDropView = _drop_views[d_id]
			_drop_views.erase(d_id)
			if is_instance_valid(dv):
				dv.fade_out_and_free()

	_board_draw.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("cursor_cancel"):
		if selected_unit_data != null or hud.is_shovel_active:
			selected_unit_data = null
			hud.set_shovel_active(false)
			sfx.play_click()
			_board_draw.queue_redraw()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("shovel"):
		hud.set_shovel_active(not hud.is_shovel_active)
		get_viewport().set_input_as_handled()
		return

	# Slot-Tasten 1 bis 7
	for i in range(1, 8):
		if event.is_action_pressed("select_slot_%d" % i):
			hud.select_slot(i)
			get_viewport().set_input_as_handled()
			return

	# Gamepad / Tastatur Cursor
	if event.is_action_pressed("cursor_left"):
		_using_gamepad_cursor = true
		_cursor_col = clampi(_cursor_col - 1, 0, LaneDefendersConfig.COLS - 1)
		_board_draw.queue_redraw()
	elif event.is_action_pressed("cursor_right"):
		_using_gamepad_cursor = true
		_cursor_col = clampi(_cursor_col + 1, 0, LaneDefendersConfig.COLS - 1)
		_board_draw.queue_redraw()
	elif event.is_action_pressed("cursor_up"):
		_using_gamepad_cursor = true
		_cursor_lane = clampi(_cursor_lane - 1, 0, LaneDefendersConfig.LANES - 1)
		_board_draw.queue_redraw()
	elif event.is_action_pressed("cursor_down"):
		_using_gamepad_cursor = true
		_cursor_lane = clampi(_cursor_lane + 1, 0, LaneDefendersConfig.LANES - 1)
		_board_draw.queue_redraw()
	elif event.is_action_pressed("cursor_confirm") and not (event is InputEventMouseButton):
		_handle_cell_interaction(_cursor_lane, _cursor_col)
		get_viewport().set_input_as_handled()
		return

	# Maus-Eingabe
	if event is InputEventMouseMotion:
		_using_gamepad_cursor = false
		var mm := event as InputEventMouseMotion
		var mpos: Vector2 = mm.position
		_hover_lane = model.grid.get_lane_for_y(mpos.y)
		_hover_col = model.grid.get_col_for_x(mpos.x)
		if _hover_lane >= 0 and _hover_col >= 0 and _hover_lane < LaneDefendersConfig.LANES and _hover_col < LaneDefendersConfig.COLS:
			_cursor_lane = _hover_lane
			_cursor_col = _hover_col
		_board_draw.queue_redraw()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var mpos: Vector2 = mb.position
			var l := model.grid.get_lane_for_y(mpos.y)
			var c := model.grid.get_col_for_x(mpos.x)
			var on_board := (l >= 0 and c >= 0 and l < LaneDefendersConfig.LANES and c < LaneDefendersConfig.COLS)

			if on_board:
				_handle_cell_interaction(l, c)
				# Falls am Klickort auch eine Sonnenenergie lag, diese zusätzlich einsammeln
				for d in model.energy_drops:
					if mpos.distance_to(d.position) <= 65.0:
						model.collect_energy(d.id)
						break
			else:
				for d in model.energy_drops:
					if mpos.distance_to(d.position) <= 65.0:
						model.collect_energy(d.id)
						break
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if selected_unit_data != null or hud.is_shovel_active:
				selected_unit_data = null
				hud.set_shovel_active(false)
				sfx.play_click()
				_board_draw.queue_redraw()


func _handle_cell_interaction(lane: int, col: int) -> void:
	if hud.is_shovel_active:
		var u := model.grid.get_unit(lane, col)
		if u != null:
			var refund := int(float(u.unit_data.cost) * 0.5)
			model.try_remove_unit(lane, col)
			sfx.play_dig()
			_spawn_floating_text(model.grid.get_cell_center(lane, col), "+%d ☀️" % refund, Color("ffe600"))
			hud.set_shovel_active(false)
		else:
			hud.set_shovel_active(false)
		_board_draw.queue_redraw()
	elif selected_unit_data != null:
		var err := model.can_place_unit(lane, col, selected_unit_data)
		if err == "":
			model.try_place_unit(lane, col, selected_unit_data)
			_spawn_floating_text(model.grid.get_cell_center(lane, col), "🌱", Color.GREEN)
			if not Input.is_key_pressed(KEY_SHIFT) or not model.can_afford(selected_unit_data):
				selected_unit_data = null
		else:
			sfx.play_error()
			if err == "MSG_CELL_OCCUPIED":
				_spawn_floating_text(model.grid.get_cell_center(lane, col), tr("MSG_CELL_OCCUPIED"), Color("ff5252"))
			elif err == "MSG_NOT_ENOUGH_ENERGY":
				_spawn_floating_text(model.grid.get_cell_center(lane, col), tr("MSG_NEED_ENERGY") % [selected_unit_data.cost, model.energy], Color("ff5252"))
				selected_unit_data = null
			elif err == "MSG_COOLDOWN":
				var rem := model.get_cooldown_remaining(selected_unit_data)
				_spawn_floating_text(model.grid.get_cell_center(lane, col), tr("MSG_COOLDOWN_TIME") % rem, Color("ff5252"))
				selected_unit_data = null
			else:
				_spawn_floating_text(model.grid.get_cell_center(lane, col), tr(err), Color("ff5252"))
				selected_unit_data = null
		_board_draw.queue_redraw()
	else:
		var u := model.grid.get_unit(lane, col)
		if u == null:
			_spawn_floating_text(model.grid.get_cell_center(lane, col), tr("MSG_SELECT_UNIT_FIRST"), Color("a8e6cf"))


func _on_card_blocked(message: String) -> void:
	sfx.play_error()
	var mpos := get_global_mouse_position()
	var text := tr(message) if message.begins_with("MSG_") else message
	_spawn_floating_text(mpos, text, Color("ff5252"))


func _on_card_selected(udata: UnitData) -> void:
	if selected_unit_data == udata:
		selected_unit_data = null
		sfx.play_click()
	else:
		selected_unit_data = udata
		sfx.play_card_select()
	_board_draw.queue_redraw()


func _on_shovel_toggled(active: bool) -> void:
	if active:
		selected_unit_data = null
		sfx.play_click()
	_board_draw.queue_redraw()


func _toggle_pause() -> void:
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	hud.set_paused(is_paused)


func _restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _load_next_level() -> void:
	get_tree().paused = false
	var next_id := _get_next_level_id()
	if next_id != "":
		SaveService.set_value("session", "selected_level", next_id)
		get_tree().reload_current_scene()
	else:
		_go_to_menu()


func _go_to_menu() -> void:
	SaveService.save()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _has_next_level() -> bool:
	return _get_next_level_id() != ""


func _get_next_level_id() -> String:
	var parts := current_level.level_id.split("-")
	if parts.size() < 2:
		return ""
	var w := int(parts[0])
	var n := int(parts[1])
	if n < 5:
		return "%d-%d" % [w, n + 1]
	elif w < 4:
		return "%d-1" % [w + 1]
	return ""


func _unlock_next_level() -> void:
	var next_id := _get_next_level_id()
	if next_id != "":
		SaveService.set_value("lane_defenders", "unlocked_" + next_id, true)


func _spawn_floating_text(pos: Vector2, text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos + Vector2(-30.0, -20.0)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", color)
	_effects_container.add_child(lbl)
	var t := create_tween()
	t.tween_property(lbl, "position:y", lbl.position.y - 45.0, 0.7)
	t.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
	t.finished.connect(lbl.queue_free)


func _spawn_damage_number(pos: Vector2, dmg: int) -> void:
	_spawn_floating_text(pos, "-%d" % dmg, Color("ffeb3b"))


func _draw_board() -> void:
	var origin := LaneDefendersConfig.GRID_ORIGIN
	var total_w := LaneDefendersConfig.COLS * LaneDefendersConfig.CELL_WIDTH
	var total_h := LaneDefendersConfig.LANES * LaneDefendersConfig.CELL_HEIGHT

	# Umrandung des gesamten Rasenfelds
	_board_draw.draw_rect(Rect2(origin.x - 3, origin.y - 3, total_w + 6, total_h + 6), Color(0.18, 0.45, 0.22, 0.65), false, 4.0)

	# Schachbrettartiges Rasen-Muster über alle 9 Spalten
	for l in range(LaneDefendersConfig.LANES):
		for c in range(LaneDefendersConfig.COLS):
			var r := model.grid.get_cell_rect(l, c)
			var cell_col := Color(0.12, 0.42, 0.18, 0.12) if (l + c) % 2 == 0 else Color(0.04, 0.22, 0.08, 0.18)
			_board_draw.draw_rect(r, cell_col)
			_board_draw.draw_rect(r, Color(0.18, 0.5, 0.22, 0.28), false, 1.0)

	# Wenn eine Einheit gewählt ist: Alle leeren Felder sanft hervorheben
	if selected_unit_data != null:
		for l in range(LaneDefendersConfig.LANES):
			for c in range(LaneDefendersConfig.COLS):
				if model.grid.is_cell_empty(l, c):
					var r := model.grid.get_cell_rect(l, c)
					_board_draw.draw_rect(r, Color(0.25, 0.9, 0.35, 0.08))
					_board_draw.draw_rect(r, Color(0.3, 0.95, 0.4, 0.24), false, 1.5)

	# Wenn die Schaufel aktiv ist: Alle belegten Felder markieren
	elif hud.is_shovel_active:
		for l in range(LaneDefendersConfig.LANES):
			for c in range(LaneDefendersConfig.COLS):
				if not model.grid.is_cell_empty(l, c):
					var r := model.grid.get_cell_rect(l, c)
					_board_draw.draw_rect(r, Color(1.0, 0.4, 0.1, 0.12))
					_board_draw.draw_rect(r, Color(1.0, 0.4, 0.1, 0.4), false, 2.0)

	# Spezifische Hover- oder Cursor-Hervorhebung
	var hl_lane := _cursor_lane if _using_gamepad_cursor else _hover_lane
	var hl_col := _cursor_col if _using_gamepad_cursor else _hover_col
	if hl_lane >= 0 and hl_col >= 0 and hl_lane < LaneDefendersConfig.LANES and hl_col < LaneDefendersConfig.COLS:
		var r := model.grid.get_cell_rect(hl_lane, hl_col)
		if selected_unit_data != null:
			if model.grid.is_cell_empty(hl_lane, hl_col):
				_board_draw.draw_rect(r, Color(0.2, 0.95, 0.3, 0.4))
				_board_draw.draw_rect(r, Color(0.3, 1.0, 0.4, 0.95), false, 4.0)
			else:
				_board_draw.draw_rect(r, Color(0.95, 0.2, 0.2, 0.4))
				_board_draw.draw_rect(r, Color(1.0, 0.3, 0.3, 0.95), false, 4.0)
		elif hud.is_shovel_active:
			if not model.grid.is_cell_empty(hl_lane, hl_col):
				_board_draw.draw_rect(r, Color(1.0, 0.3, 0.1, 0.45))
				_board_draw.draw_rect(r, Color(1.0, 0.4, 0.1, 1.0), false, 4.0)
		else:
			_board_draw.draw_rect(r, Color(1.0, 1.0, 1.0, 0.15))
			_board_draw.draw_rect(r, Color(1.0, 1.0, 0.8, 0.5), false, 2.5)


func _run_autoplay_tick() -> void:
	model.collect_all_energy()
	var generator: UnitData = model.unit_catalog.get("generator")
	var shooter: UnitData = model.unit_catalog.get("shooter")
	var double_shooter: UnitData = model.unit_catalog.get("double_shooter")

	# 1. 3 Generatoren in Spalte 0
	var gen_count := 0
	for l in range(LaneDefendersConfig.LANES):
		var u := model.grid.get_unit(l, 0)
		if u != null and u.unit_data.id == "generator":
			gen_count += 1

	if gen_count < 3:
		for l in range(LaneDefendersConfig.LANES):
			if model.grid.is_cell_empty(l, 0) and model.can_afford(generator) and not model.is_on_cooldown(generator):
				model.try_place_unit(l, 0, generator)
				return

	# 2. Bedrohte Lanes verteidigen
	for enemy in model.enemies:
		var e_lane := enemy.lane
		var shooters := 0
		for c in range(1, LaneDefendersConfig.COLS):
			var u := model.grid.get_unit(e_lane, c)
			if u != null and (u.unit_data.id == "shooter" or u.unit_data.id == "double_shooter"):
				shooters += 1

		if shooters < 2:
			var u_to_buy := shooter
			if double_shooter != null and current_level.available_units.has("double_shooter") and model.can_afford(double_shooter) and not model.is_on_cooldown(double_shooter):
				u_to_buy = double_shooter
			if model.can_afford(u_to_buy) and not model.is_on_cooldown(u_to_buy):
				for c in range(1, 4):
					if model.grid.is_cell_empty(e_lane, c):
						model.try_place_unit(e_lane, c, u_to_buy)
						return
