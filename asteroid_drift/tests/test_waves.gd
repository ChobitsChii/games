extends TestCase
## Testet die Wellen-Steuerung und Schwierigkeitsskalierung.


func test_wave_scaling_and_monotony() -> void:
	var prev_difficulty := 0.0
	for w in range(1, 15):
		var cfg := WaveDirectorLogic.get_wave_config(w)
		assert_true(cfg["large_asteroids"] >= 4, "Welle 1 hat min 4 Asteroiden")
		assert_true(cfg["large_asteroids"] <= 12, "Cap bei 12 Großasteroiden")
		assert_true(cfg["speed_multiplier"] >= 1.0, "Geschwindigkeitsfaktor >= 1")

		var difficulty := WaveDirectorLogic.compute_difficulty_score(w)
		assert_true(difficulty >= prev_difficulty, "Schwierigkeit steigt monoton: Welle %d (%.2f >= %.2f)" % [w, difficulty, prev_difficulty])
		prev_difficulty = difficulty


func test_enemy_unlock_waves() -> void:
	var w1 := WaveDirectorLogic.get_wave_config(1)
	assert_true(not w1["spawn_large_ufo"], "Welle 1: kein UFO")
	assert_true(not w1["spawn_small_ufo"], "Welle 1: kein kleines UFO")
	assert_true(not w1["spawn_mine"], "Welle 1: keine Mine")

	var w2 := WaveDirectorLogic.get_wave_config(2)
	assert_true(w2["spawn_large_ufo"], "Welle 2: großes UFO freigeschaltet")

	var w3 := WaveDirectorLogic.get_wave_config(3)
	assert_true(w3["spawn_small_ufo"], "Welle 3: kleines UFO freigeschaltet")
	assert_true(w3["is_upgrade_wave"], "Welle 3 ist Upgrade-Welle")

	var w5 := WaveDirectorLogic.get_wave_config(5)
	assert_true(w5["spawn_mine"], "Welle 5: Mine freigeschaltet")


func test_spawn_position_distance() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var player_pos := Vector2(960.0, 540.0)
	var bounds := Rect2(0.0, 0.0, 1920.0, 1080.0)
	var min_dist := 300.0

	for _i in range(30):
		var spawn_pos := WaveDirectorLogic.get_spawn_position_outside_player(player_pos, bounds, min_dist, rng)
		var dist := spawn_pos.distance_to(player_pos)
		assert_true(dist >= min_dist - 0.01, "Spawnabstand %f >= %f" % [dist, min_dist])
