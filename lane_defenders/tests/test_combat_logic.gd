extends TestCase
## Tests für die Kampf- und Einheitenlogik von Lane Defenders.


func test_cost_and_cooldown() -> void:
	var model := GameModel.new()
	var shooter: UnitData = model.unit_catalog.get("shooter")
	assert_true(shooter != null, "Schütze im Katalog vorhanden")

	# Genug Energie zu Beginn (150)
	assert_true(model.can_afford(shooter), "Kann Schützen bezahlen")
	assert_false(model.is_on_cooldown(shooter), "Schütze nicht auf Abklingzeit")

	# Platzieren
	var ok := model.try_place_unit(2, 2, shooter)
	assert_true(ok, "Schütze platziert")
	assert_eq(model.energy, 50, "Energie von 150 auf 50 reduziert")
	assert_true(model.is_on_cooldown(shooter), "Schütze jetzt auf Abklingzeit")
	assert_false(model.can_afford(shooter), "Nicht mehr genug Energie für zweiten Schützen")

	# Abklingzeit läuft ab
	model.step(shooter.cooldown + 0.1)
	assert_false(model.is_on_cooldown(shooter), "Abklingzeit beendet")


func test_energy_drop_and_collection() -> void:
	var model := GameModel.new()
	var initial_energy := model.energy
	# Erzeuge Energie-Drop
	var drop := model._spawn_energy(Vector2(500, 500), 25, false)
	assert_eq(model.energy_drops.size(), 1, "Ein Energie-Drop vorhanden")

	# Einsammeln
	var collected := model.collect_energy(drop.id)
	assert_true(collected, "Drop eingesammelt")
	assert_eq(model.energy, initial_energy + 25, "Energie um 25 erhöht")
	assert_eq(model.energy_drops.size(), 0, "Keine Drops mehr vorhanden")


func test_shield_bearer_damage_reduction() -> void:
	var model := GameModel.new()
	var shield_enemy := model._spawn_enemy(2, "shield")
	var initial_hp := shield_enemy.current_hp

	# Normaler Schuss (Geradeaus, 20 Schaden) -> Schild halbiert Schaden auf 10
	var proj := model._spawn_projectile(2, shield_enemy.x - 30.0, model.unit_catalog.get("shooter"))
	model.step(0.1)
	assert_eq(shield_enemy.current_hp, initial_hp - 10, "Schild reduziert Schaden auf 50 %")

	# Flächenschuss (Flächenwerfer, 40 Schaden) -> Schild schützt NICHT gegen Fläche
	var area_proj := model._spawn_projectile(2, shield_enemy.x - 30.0, model.unit_catalog.get("area_launcher"))
	model.step(0.1)
	assert_eq(shield_enemy.current_hp, initial_hp - 10 - 40, "Flächenschuss macht vollen Schaden gegen Schild")


func test_frost_tower_slow() -> void:
	var model := GameModel.new()
	var runner := model._spawn_enemy(1, "runner")
	var frost_unit: UnitData = model.unit_catalog.get("frost")

	var proj := model._spawn_projectile(1, runner.x - 30.0, frost_unit)
	model.step(0.1)
	assert_true(runner.slow_timer > 0.0, "Gegner verlangsamt")
	assert_almost(runner.slow_factor, 0.5, "Verlangsamungsfaktor 0.5")


func test_mine_detonation() -> void:
	var model := GameModel.new()
	var mine_data: UnitData = model.unit_catalog.get("mine")
	# Mine auf (2, 4) platzieren
	model.grid.place_unit(2, 4, mine_data)
	var mine := model.grid.get_unit(2, 4)
	assert_false(mine.is_armed, "Mine anfangs ungeschärft")

	# Scharfstellen nach 12s
	model.step(12.5)
	assert_true(mine.is_armed, "Mine nach 12s geschärft")

	# Gegner nähert sich Zelle 4
	var enemy := model._spawn_enemy(2, "tank")
	enemy.x = model.grid.get_cell_center(2, 4).x + 20.0
	var hp_before := enemy.current_hp

	model.step(0.1)
	assert_eq(enemy.current_hp, hp_before - 1200, "Mine fügt 1200 Schaden zu")
	assert_true(model.grid.is_cell_empty(2, 4), "Mine nach Explosion entfernt")


func test_jumper_hops_over_first_unit() -> void:
	var model := GameModel.new()
	var wall: UnitData = model.unit_catalog.get("wall")
	model.grid.place_unit(2, 4, wall)

	var jumper := model._spawn_enemy(2, "jumper")
	jumper.x = model.grid.get_cell_center(2, 4).x + 30.0
	assert_false(jumper.has_jumped, "Jumper noch nicht gesprungen")

	model.step(0.1)
	assert_true(jumper.has_jumped, "Jumper ist über Mauer gesprungen")
	assert_eq(model.grid.get_unit(2, 4).current_hp, 4000, "Mauer unbeschädigt beim Sprung")


func test_base_life_loss() -> void:
	var model := GameModel.new()
	assert_eq(model.lives, 3, "Startleben ist 3")
	var runner := model._spawn_enemy(2, "runner")
	runner.x = LaneDefendersConfig.BASE_X - 10.0 # Basis erreicht
	model.step(0.1)
	assert_eq(model.lives, 2, "Leben auf 2 gesunken")
