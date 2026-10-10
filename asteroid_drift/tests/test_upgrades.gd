extends TestCase
## Testet das Upgrade-System, Auswahl und Stat-Berechnung.


func test_all_upgrades_have_translations() -> void:
	for u in UpgradeSystem.UPGRADES:
		assert_true(u.has("name_key") and u["name_key"] != "", "Hat name_key")
		assert_true(u.has("desc_key") and u["desc_key"] != "", "Hat desc_key")
		assert_true(int(u["max_stacks"]) >= 1, "max_stacks >= 1")


func test_available_pool_filters_max_stacks() -> void:
	var counts := {"double_shot": 1} # double_shot max is 1
	var available := UpgradeSystem.get_available_upgrades(counts)
	for u in available:
		assert_true(u["id"] != "double_shot", "Max-Stack-Upgrade nicht im Pool")


func test_roll_random_upgrades() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var counts := {}
	var rolled := UpgradeSystem.roll_random_upgrades(counts, 3, rng)
	assert_true(rolled.size() == 3, "Genau 3 Upgrades gezogen")

	# Keine Duplikate in derselben Ziehung
	var ids := []
	for u in rolled:
		assert_true(not ids.has(u["id"]), "Keine Duplikate in Auswahl: " + u["id"])
		ids.append(u["id"])


func test_stat_calculation() -> void:
	var base := 10.0
	var adds: Array[float] = [2.0, 3.0]
	var muls: Array[float] = [1.2, 0.5]
	# (10 + 2 + 3) * (1.2 * 0.5) = 15 * 0.6 = 9.0
	var res := UpgradeSystem.calculate_effective_stat(base, adds, muls)
	assert_true(is_equal_approx(res, 9.0), "Berechnung (10+5)*0.6 = 9: %f" % res)
