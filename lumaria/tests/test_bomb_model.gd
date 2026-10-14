extends TestCase
## Testet die reine Logik der Schall-Bombe (BombModel).

func test_bomb_initial_state_and_fuse_start() -> void:
	var bomb := BombModel.new()
	assert_eq(bomb.state, BombModel.State.IDLE, "Initial IDLE")
	assert_almost(bomb.remaining_fuse, BombModel.FUSE_DURATION, "Volle Zündzeit")

	bomb.start_fuse()
	assert_eq(bomb.state, BombModel.State.FUSING, "Nach Start FUSING")


func test_bomb_tick_and_explosion_trigger() -> void:
	var bomb := BombModel.new()
	bomb.start_fuse()

	var exploded_early := bomb.tick(1.0)
	assert_false(exploded_early, "Explodiert noch nicht nach 1.0s")
	assert_eq(bomb.state, BombModel.State.FUSING, "Immer noch FUSING")

	var exploded_now := bomb.tick(1.5) # Gesamt 2.5s > 2.4s
	assert_true(exploded_now, "Explodiert nach Ablauf der Zündschnur")
	assert_eq(bomb.state, BombModel.State.EXPLODING, "Im Zustand EXPLODING")

	bomb.finish_explosion()
	assert_eq(bomb.state, BombModel.State.DETONATED, "Nach Detonation DETONATED")


func test_bomb_pulse_frequency_acceleration() -> void:
	var bomb := BombModel.new()
	bomb.start_fuse()

	var freq_start := bomb.get_pulse_frequency()
	assert_almost(freq_start, 4.0, "Startfrequenz bei 4 Hz", 0.5)

	bomb.tick(2.3) # Kurz vor Blast
	var freq_end := bomb.get_pulse_frequency()
	assert_true(freq_end > 16.0, "Frequenz am Ende stark erhöht")


func test_bomb_blast_radius_distance_check() -> void:
	var bomb := BombModel.new()
	var origin := Vector2(200, 200)

	var in_range := Vector2(250, 260) # Distanz ~78px <= 130px
	var out_range := Vector2(350, 350) # Distanz ~212px > 130px

	assert_true(bomb.is_in_blast_radius(origin, in_range), "Innerhalb Explosionsradius")
	assert_false(bomb.is_in_blast_radius(origin, out_range), "Außerhalb Explosionsradius")


func test_bomb_obstacle_destruction_filter() -> void:
	var bomb := BombModel.new()
	assert_true(bomb.can_break_obstacle("cracked_wall"), "Zerstört rissige Wände")
	assert_true(bomb.can_break_obstacle("wind_shield"), "Bricht Windschilde")
	assert_true(bomb.can_break_obstacle("destructible_pot"), "Zerstört Krüge")
	assert_false(bomb.can_break_obstacle("solid_bedrock"), "Fester Fels unzerstörbar")
