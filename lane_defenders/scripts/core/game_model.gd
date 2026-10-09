class_name GameModel
extends RefCounted
## Reine Simulations- und Spiellogik für Lane Defenders.
## Enthält keine Szenen oder Engine-Rendering und ist vollständig unit-testbar.

enum State { PRE_WAVE, RUNNING, WON, LOST }

class SimEnemy:
	extends RefCounted
	var id: int = 0
	var data: EnemyData
	var lane: int = 0
	var x: float = 0.0
	var current_hp: int = 200
	var max_hp: int = 200
	var slow_timer: float = 0.0
	var slow_factor: float = 1.0
	var has_jumped: bool = false
	var is_jumping: bool = false
	var jump_progress: float = 0.0

class SimProjectile:
	extends RefCounted
	var id: int = 0
	var lane: int = 0
	var x: float = 0.0
	var damage: int = 20
	var slow_duration: float = 0.0
	var slow_factor: float = 1.0
	var is_area: bool = false
	var color: Color = Color.WHITE

class SimEnergyDrop:
	extends RefCounted
	var id: int = 0
	var position: Vector2 = Vector2.ZERO
	var target_position: Vector2 = Vector2.ZERO
	var amount: int = 25
	var lifetime: float = 8.0
	var is_from_sky: bool = false
	var is_falling: bool = false

var state: State = State.PRE_WAVE
var energy: int = LaneDefendersConfig.INITIAL_ENERGY
var lives: int = LaneDefendersConfig.INITIAL_LIVES
var level_data: LevelData
var grid: GridModel
var wave_director: WaveDirector

var enemies: Array[SimEnemy] = []
var projectiles: Array[SimProjectile] = []
var energy_drops: Array[SimEnergyDrop] = []

var cooldowns: Dictionary = {} # unit_id: String -> float
var sky_energy_timer: float = 0.0
var auto_collect_energy: bool = false

var unit_catalog: Dictionary = {} # id -> UnitData
var enemy_catalog: Dictionary = {} # id -> EnemyData

var _next_entity_id: int = 1
var rng: RandomNumberGenerator

# Ereignisse / Benachrichtigungen
var on_unit_placed: Callable
var on_unit_removed: Callable
var on_unit_damaged: Callable
var on_enemy_spawned: Callable
var on_enemy_damaged: Callable
var on_enemy_died: Callable
var on_enemy_reached_base: Callable
var on_projectile_spawned: Callable
var on_projectile_hit: Callable
var on_energy_dropped: Callable
var on_energy_collected: Callable
var on_energy_expired: Callable
var on_final_wave: Callable
var on_state_changed: Callable


func _init(p_level: LevelData = null, p_seed: int = 42) -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = p_seed
	grid = GridModel.new()
	wave_director = WaveDirector.new()
	_load_catalogs()
	if p_level != null:
		start_level(p_level)


func _load_catalogs() -> void:
	var unit_ids := ["generator", "shooter", "double_shooter", "frost", "wall", "mine", "area_launcher"]
	for u_id in unit_ids:
		var path := "res://data/units/%s.tres" % u_id
		if ResourceLoader.exists(path):
			unit_catalog[u_id] = load(path)

	var enemy_ids := ["runner", "fast_runner", "tank", "jumper", "shield", "boss"]
	for e_id in enemy_ids:
		var path := "res://data/enemies/%s.tres" % e_id
		if ResourceLoader.exists(path):
			enemy_catalog[e_id] = load(path)


func start_level(p_level: LevelData) -> void:
	level_data = p_level
	state = State.PRE_WAVE
	energy = LaneDefendersConfig.INITIAL_ENERGY
	lives = LaneDefendersConfig.INITIAL_LIVES
	sky_energy_timer = 2.0 # Erste Himmelsenergie nach 2s
	grid.clear()
	enemies.clear()
	projectiles.clear()
	energy_drops.clear()
	cooldowns.clear()
	wave_director.set_level(p_level)
	if on_state_changed.is_valid():
		on_state_changed.call(state)


func can_afford(data: UnitData) -> bool:
	if data == null:
		return false
	return energy >= data.cost


func is_on_cooldown(data: UnitData) -> bool:
	if data == null:
		return false
	return float(cooldowns.get(data.id, 0.0)) > 0.0


func get_cooldown_progress(data: UnitData) -> float:
	if data == null or data.cooldown <= 0.0:
		return 0.0
	var remaining := float(cooldowns.get(data.id, 0.0))
	return clampf(remaining / data.cooldown, 0.0, 1.0)


func get_cooldown_remaining(data: UnitData) -> float:
	if data == null:
		return 0.0
	return maxf(0.0, float(cooldowns.get(data.id, 0.0)))


func can_place_unit(lane: int, col: int, data: UnitData) -> String:
	if state != State.RUNNING and state != State.PRE_WAVE:
		return "HUD_PAUSE"
	if data == null:
		return "MSG_INVALID_UNIT"
	if not grid.is_valid_cell(lane, col):
		return "MSG_INVALID_CELL"
	if not grid.is_cell_empty(lane, col):
		return "MSG_CELL_OCCUPIED"
	if not can_afford(data):
		return "MSG_NOT_ENOUGH_ENERGY"
	if is_on_cooldown(data):
		return "MSG_COOLDOWN"
	return ""


func try_place_unit(lane: int, col: int, data: UnitData) -> bool:
	var err := can_place_unit(lane, col, data)
	if err != "":
		return false
	var placed := grid.place_unit(lane, col, data)
	if placed == null:
		return false

	# Sofort angriffsbereit machen, falls Gegner bereits in der Lane sind
	if data.attack_damage > 0:
		placed.attack_timer = data.attack_interval

	energy -= data.cost
	cooldowns[data.id] = data.cooldown
	if on_unit_placed.is_valid():
		on_unit_placed.call(placed)
	return true


func try_remove_unit(lane: int, col: int) -> bool:
	var u := grid.get_unit(lane, col)
	if u == null:
		return false
	var refund := int(float(u.unit_data.cost) * 0.5)
	energy += refund
	grid.remove_unit(lane, col)
	if on_unit_removed.is_valid():
		on_unit_removed.call(lane, col)
	return true


func collect_energy(drop_id: int) -> bool:
	for i in range(energy_drops.size()):
		var d := energy_drops[i]
		if d.id == drop_id:
			energy += d.amount
			energy_drops.remove_at(i)
			if on_energy_collected.is_valid():
				on_energy_collected.call(d)
			return true
	return false


func collect_all_energy() -> void:
	while not energy_drops.is_empty():
		var d: SimEnergyDrop = energy_drops.pop_back()
		energy += d.amount
		if on_energy_collected.is_valid():
			on_energy_collected.call(d)


func step(delta: float) -> void:
	if state == State.PRE_WAVE:
		state = State.RUNNING
		if on_state_changed.is_valid():
			on_state_changed.call(state)

	if state != State.RUNNING:
		return

	# 1. Abklingzeiten reduzieren
	for k: String in cooldowns.keys():
		var remaining := float(cooldowns[k]) - delta
		if remaining <= 0.0:
			cooldowns.erase(k)
		else:
			cooldowns[k] = remaining

	# 2. Himmelsenergie erzeugen
	sky_energy_timer -= delta
	if sky_energy_timer <= 0.0:
		sky_energy_timer = LaneDefendersConfig.SKY_ENERGY_INTERVAL
		var drop_x := rng.randf_range(LaneDefendersConfig.GRID_ORIGIN.x + 50.0, LaneDefendersConfig.GRID_ORIGIN.x + LaneDefendersConfig.COLS * LaneDefendersConfig.CELL_WIDTH - 50.0)
		var drop_y := rng.randf_range(LaneDefendersConfig.GRID_ORIGIN.y + 50.0, LaneDefendersConfig.GRID_ORIGIN.y + LaneDefendersConfig.LANES * LaneDefendersConfig.CELL_HEIGHT - 50.0)
		_spawn_energy(Vector2(drop_x, drop_y), LaneDefendersConfig.SKY_ENERGY_AMOUNT, true)

	# 3. Energie-Drops aktualisieren
	var drop_idx := energy_drops.size() - 1
	while drop_idx >= 0:
		var d := energy_drops[drop_idx]
		if d.is_falling:
			if d.position.y < d.target_position.y:
				d.position.y = minf(d.target_position.y, d.position.y + delta * 240.0)
				d.position.x = d.target_position.x + sin(d.position.y * 0.03) * 12.0
			else:
				d.position = d.target_position
				d.is_falling = false
		d.lifetime -= delta
		if auto_collect_energy:
			collect_energy(d.id)
		elif d.lifetime <= 0.0:
			energy_drops.remove_at(drop_idx)
			if on_energy_expired.is_valid():
				on_energy_expired.call(d)
		drop_idx -= 1

	# 4. Wellen-Director updaten
	var spawns := wave_director.update(delta)
	for s in spawns:
		_spawn_enemy(int(s.get("lane", 0)), str(s.get("enemy_id", "runner")))

	if wave_director.check_final_wave_trigger():
		if on_final_wave.is_valid():
			on_final_wave.call()

	# 5. Einheiten auf dem Raster updaten
	_update_grid_units(delta)

	# 6. Projektile updaten
	_update_projectiles(delta)

	# 7. Gegner updaten
	_update_enemies(delta)

	# 8. Spielstatus prüfen
	if lives <= 0:
		state = State.LOST
		if on_state_changed.is_valid():
			on_state_changed.call(state)
	elif level_data != null and wave_director.is_all_spawns_dispatched() and enemies.is_empty() and lives > 0:
		state = State.WON
		if on_state_changed.is_valid():
			on_state_changed.call(state)


func _spawn_energy(pos: Vector2, amount: int, is_sky: bool) -> SimEnergyDrop:
	var drop := SimEnergyDrop.new()
	drop.id = _next_entity_id
	_next_entity_id += 1
	drop.target_position = pos
	drop.position = Vector2(pos.x, -50.0) if is_sky else pos
	drop.amount = amount
	drop.lifetime = LaneDefendersConfig.SKY_ENERGY_LIFETIME
	drop.is_from_sky = is_sky
	drop.is_falling = is_sky
	energy_drops.append(drop)
	if on_energy_dropped.is_valid():
		on_energy_dropped.call(drop)
	return drop


func _spawn_enemy(lane: int, enemy_id: String) -> SimEnemy:
	var edata: EnemyData = enemy_catalog.get(enemy_id)
	if edata == null:
		return null
	var enemy := SimEnemy.new()
	enemy.id = _next_entity_id
	_next_entity_id += 1
	enemy.data = edata
	enemy.lane = clampi(lane, 0, LaneDefendersConfig.LANES - 1)
	enemy.x = LaneDefendersConfig.SPAWN_X
	enemy.max_hp = edata.hp
	enemy.current_hp = edata.hp
	enemies.append(enemy)
	if on_enemy_spawned.is_valid():
		on_enemy_spawned.call(enemy)
	return enemy


func _spawn_projectile(lane: int, start_x: float, udata: UnitData) -> SimProjectile:
	var proj := SimProjectile.new()
	proj.id = _next_entity_id
	_next_entity_id += 1
	proj.lane = lane
	proj.x = start_x
	proj.damage = udata.attack_damage
	proj.slow_duration = udata.slow_duration
	proj.slow_factor = udata.slow_factor
	proj.is_area = udata.hits_adjacent_lanes
	proj.color = udata.color
	projectiles.append(proj)
	if on_projectile_spawned.is_valid():
		on_projectile_spawned.call(proj)
	return proj


func _update_grid_units(delta: float) -> void:
	for u: GridModel.GridUnit in grid.get_all_units():
		var udata := u.unit_data
		# Energie-Erzeugung
		if udata.produces_energy:
			u.produce_timer += delta
			if u.produce_timer >= udata.energy_interval:
				u.produce_timer = 0.0
				var center := grid.get_cell_center(u.lane, u.col)
				_spawn_energy(center + Vector2(0.0, -10.0), udata.energy_amount, false)

		# Minen-Scharfstellung
		if udata.arm_time > 0.0 and not u.is_armed:
			u.arm_timer += delta
			if u.arm_timer >= udata.arm_time:
				u.is_armed = true

		# Angriff
		if udata.attack_damage > 0 and udata.attack_interval > 0.0:
			var unit_x := grid.get_cell_center(u.lane, u.col).x
			var has_target := false

			# Gibt es einen Gegner vor der Einheit?
			for e in enemies:
				if e.x > unit_x:
					if udata.hits_adjacent_lanes:
						if absi(e.lane - u.lane) <= 1:
							has_target = true
							break
					else:
						if e.lane == u.lane:
							has_target = true
							break

			if has_target:
				u.attack_timer += delta
				if u.attack_timer >= udata.attack_interval:
					u.attack_timer -= udata.attack_interval
					for _s in range(udata.shots_per_attack):
						_spawn_projectile(u.lane, unit_x + 30.0, udata)
			else:
				# Timer fast abgelaufen lassen, damit sofort geschossen wird, sobald ein Gegner auftaucht
				u.attack_timer = minf(u.attack_timer, udata.attack_interval * 0.9)


func _update_projectiles(delta: float) -> void:
	var proj_idx := projectiles.size() - 1
	while proj_idx >= 0:
		var p := projectiles[proj_idx]
		p.x += LaneDefendersConfig.PROJECTILE_SPEED * delta
		var hit_enemy: SimEnemy = null

		if p.is_area:
			# Flächenwerfer: Trifft ersten Gegner in Lane oder Nachbarlanes
			for e in enemies:
				if absi(e.lane - p.lane) <= 1 and absf(e.x - p.x) <= 40.0:
					hit_enemy = e
					break
		else:
			for e in enemies:
				if e.lane == p.lane and (p.x >= e.x - 20.0 and p.x <= e.x + 40.0):
					hit_enemy = e
					break

		if hit_enemy != null:
			_apply_projectile_hit(p, hit_enemy)
			projectiles.remove_at(proj_idx)
		elif p.x > LaneDefendersConfig.SPAWN_X + 100.0:
			projectiles.remove_at(proj_idx)

		proj_idx -= 1


func _apply_projectile_hit(p: SimProjectile, primary_target: SimEnemy) -> void:
	var affected_targets: Array[SimEnemy] = []
	if p.is_area:
		for e in enemies:
			if absi(e.lane - p.lane) <= 1 and absf(e.x - primary_target.x) <= 120.0:
				affected_targets.append(e)
	else:
		affected_targets.append(primary_target)

	for target in affected_targets:
		var dmg := p.damage
		# Schild-Träger halbiert Schaden von Geradeaus-Schüssen
		if target.data.has_shield and not p.is_area:
			dmg = int(round(float(dmg) * 0.5))

		target.current_hp -= dmg
		if p.slow_duration > 0.0:
			target.slow_timer = p.slow_duration
			target.slow_factor = p.slow_factor

		if on_projectile_hit.is_valid():
			on_projectile_hit.call(p, target, dmg)

		if on_enemy_damaged.is_valid():
			on_enemy_damaged.call(target, dmg)


func _update_enemies(delta: float) -> void:
	var enemy_idx := enemies.size() - 1
	while enemy_idx >= 0:
		var e := enemies[enemy_idx]

		# Lebenspunkte prüfen
		if e.current_hp <= 0:
			if on_enemy_died.is_valid():
				on_enemy_died.call(e)
			enemies.remove_at(enemy_idx)
			enemy_idx -= 1
			continue

		# Frost-Verlangsamung
		var current_speed := e.data.speed
		if e.slow_timer > 0.0:
			e.slow_timer -= delta
			current_speed *= e.slow_factor

		# Kollision mit Einheit auf dem Raster prüfen
		var cell_col := grid.get_col_for_x(e.x)
		var obstacle: GridModel.GridUnit = null
		if cell_col >= 0 and cell_col < LaneDefendersConfig.COLS:
			obstacle = grid.get_unit(e.lane, cell_col)

		if obstacle != null:
			# Mine detoniert sofort!
			if obstacle.unit_data.id == "mine" and obstacle.is_armed:
				e.current_hp -= obstacle.unit_data.attack_damage
				grid.remove_unit(obstacle.lane, obstacle.col)
				if on_unit_removed.is_valid():
					on_unit_removed.call(obstacle.lane, obstacle.col)
			# Springer überspringt die erste Einheit einmalig
			elif e.data.is_jumper and not e.has_jumped:
				e.has_jumped = true
				e.is_jumping = true
				e.jump_progress = 1.0
				e.x -= LaneDefendersConfig.CELL_WIDTH * 1.1 # Über Einheit hinweg
			else:
				# Einheit angreifen
				var dmg := int(ceil(e.data.damage_per_second * delta))
				obstacle.current_hp -= dmg
				if on_unit_damaged.is_valid():
					on_unit_damaged.call(obstacle, dmg)
				if obstacle.current_hp <= 0:
					grid.remove_unit(obstacle.lane, obstacle.col)
					if on_unit_removed.is_valid():
						on_unit_removed.call(obstacle.lane, obstacle.col)
		else:
			# Frei vorwärts bewegen
			e.x -= current_speed * delta

		# Basis erreicht?
		if e.x <= LaneDefendersConfig.BASE_X:
			lives -= 1
			if on_enemy_reached_base.is_valid():
				on_enemy_reached_base.call(e)
			enemies.remove_at(enemy_idx)

		enemy_idx -= 1
