extends TestCase
## Bot-Test gemäß Plan 05:
## Der Bot baut zuerst 3 Generatoren in Spalte 0, danach Schützen in der Lane,
## in der gerade ein Gegner ist. Er muss Level 1–3 gewinnen.


func test_bot_wins_levels_1_to_3() -> void:
	for lvl_id in ["1-1", "1-2", "1-3"]:
		var level_path := "res://data/levels/level_%s.tres" % lvl_id.replace("-", "_")
		assert_true(ResourceLoader.exists(level_path), "Level %s existiert" % lvl_id)
		var lvl: LevelData = load(level_path)

		var model := GameModel.new(lvl, 1337)
		model.auto_collect_energy = true

		var generator: UnitData = model.unit_catalog.get("generator")
		var shooter: UnitData = model.unit_catalog.get("shooter")
		var double_shooter: UnitData = model.unit_catalog.get("double_shooter")

		var max_sim_time := 220.0
		var sim_time := 0.0
		var dt := 0.05

		while sim_time < max_sim_time and (model.state == GameModel.State.RUNNING or model.state == GameModel.State.PRE_WAVE):
			model.step(dt)
			sim_time += dt

			# Bot-Aktionen:
			# 1. Zuerst 3 Generatoren in Spalte 0
			var generator_count := 0
			for l in range(LaneDefendersConfig.LANES):
				var u := model.grid.get_unit(l, 0)
				if u != null and u.unit_data.id == "generator":
					generator_count += 1

			if generator_count < 3:
				for l in range(LaneDefendersConfig.LANES):
					if model.grid.is_cell_empty(l, 0) and model.can_afford(generator) and not model.is_on_cooldown(generator):
						model.try_place_unit(l, 0, generator)
						break

			# 2. Schützen in der Lane bauen, in der sich ein Gegner befindet
			# Priorisiere Lanes mit den wenigsten Verteidigern zuerst
			var threatened_lanes: Array[int] = []
			for enemy in model.enemies:
				if not threatened_lanes.has(enemy.lane):
					threatened_lanes.append(enemy.lane)

			threatened_lanes.sort_custom(func(a: int, b: int) -> bool:
				var ca := 0
				var cb := 0
				for c in range(1, LaneDefendersConfig.COLS):
					var ua := model.grid.get_unit(a, c)
					if ua != null and (ua.unit_data.id == "shooter" or ua.unit_data.id == "double_shooter"):
						ca += 1
					var ub := model.grid.get_unit(b, c)
					if ub != null and (ub.unit_data.id == "shooter" or ub.unit_data.id == "double_shooter"):
						cb += 1
				return ca < cb
			)

			var placed := false
			for e_lane in threatened_lanes:
				if placed:
					break
				var shooters_in_lane := 0
				for c in range(1, LaneDefendersConfig.COLS):
					var u := model.grid.get_unit(e_lane, c)
					if u != null and (u.unit_data.id == "shooter" or u.unit_data.id == "double_shooter"):
						shooters_in_lane += 1

				if shooters_in_lane < 2:
					var chosen_unit := shooter
					if double_shooter != null and lvl.available_units.has("double_shooter") and model.can_afford(double_shooter) and not model.is_on_cooldown(double_shooter):
						chosen_unit = double_shooter

					if model.can_afford(chosen_unit) and not model.is_on_cooldown(chosen_unit):
						for c in range(1, 4):
							if model.grid.is_cell_empty(e_lane, c):
								if model.try_place_unit(e_lane, c, chosen_unit):
									placed = true
									break

			# Wenn alle bedrohten Lanes verteidigt sind und Überschuss-Energie da ist: verbleibende Lanes sichern
			if not placed and generator_count >= 3 and model.can_afford(shooter) and not model.is_on_cooldown(shooter):
				for l in range(LaneDefendersConfig.LANES):
					var count := 0
					for c in range(1, LaneDefendersConfig.COLS):
						var u := model.grid.get_unit(l, c)
						if u != null and (u.unit_data.id == "shooter" or u.unit_data.id == "double_shooter"):
							count += 1
					if count == 0:
						for c in range(1, 4):
							if model.grid.is_cell_empty(l, c):
								if model.try_place_unit(l, c, shooter):
									placed = true
									break
						if placed:
							break

		assert_eq(model.state, GameModel.State.WON, "Bot muss Level %s gewinnen (Leben: %d)" % [lvl_id, model.lives])
		assert_true(model.lives > 0, "Bot hat Leben übrig in Level %s" % lvl_id)
