extends TestCase
## Tests für den Wellen-Director von Lane Defenders.


func test_spawns_match_level_data() -> void:
	var l := LevelData.new()
	l.level_id = "test"
	l.spawns = [
		{"time": 5.0, "lane": 2, "enemy_id": "runner"},
		{"time": 10.0, "lane": 1, "enemy_id": "tank"},
	]
	var wd := WaveDirector.new(l)
	assert_false(wd.is_all_spawns_dispatched(), "Noch nicht alle Spawns abgearbeitet")

	# Update vor Spawn
	var spawned_0 := wd.update(4.0)
	assert_eq(spawned_0.size(), 0, "Kein Spawn vor Zeit")

	# Update zu Zeit 5.0
	var spawned_1 := wd.update(1.0)
	assert_eq(spawned_1.size(), 1, "Erster Spawn ausgelöst")
	assert_eq(spawned_1[0].get("enemy_id"), "runner", "Richtiger Gegnertyp")

	# Update zu Zeit 10.0
	var spawned_2 := wd.update(5.0)
	assert_eq(spawned_2.size(), 1, "Zweiter Spawn ausgelöst")
	assert_eq(spawned_2[0].get("enemy_id"), "tank", "Richtiger Gegnertyp")
	assert_true(wd.is_all_spawns_dispatched(), "Alle Spawns abgearbeitet")


func test_final_wave_signal() -> void:
	var l := LevelData.new()
	l.level_id = "test"
	l.spawns = [
		{"time": 100.0, "lane": 0, "enemy_id": "runner"},
	]
	var wd := WaveDirector.new(l)
	# 85% von 100 ist 85s
	wd.update(80.0)
	assert_false(wd.check_final_wave_trigger(), "Keine Schlusswelle vor 85%")
	wd.update(6.0) # t = 86
	assert_true(wd.check_final_wave_trigger(), "Schlusswelle signalisiert bei >= 85%")
	assert_false(wd.check_final_wave_trigger(), "Schlusswelle nur einmal signalisiert")
