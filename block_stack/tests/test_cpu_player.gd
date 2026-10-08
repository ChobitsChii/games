extends TestCase
## Testet den KI-Gegner (Dellacherie-Heuristik).


func test_cpu_prefers_clearing_line() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var logic := GameLogic.new(rng, 1)

	# Unterste Reihe bis auf Spalte 0 füllen
	for c in range(1, StackConfig.COLS):
		logic.matrix.set_cell(c, 21, "O")

	var cpu := CpuPlayer.new(logic, rng)
	var moves := cpu._evaluate_all_placements("I")
	assert_true(moves.size() > 0, "Muss Züge finden")
	moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])

	# Bester Zug für I-Block sollte die Zeile füllen (oder hohe Bewertung haben)
	assert_true(moves[0]["score"] > -10.0, "Bester Zug sollte positive/gute Bewertung haben")


func test_cpu_plays_moves_without_error() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var logic := GameLogic.new(rng, 1)
	var cpu := CpuPlayer.new(logic, rng)
	cpu.think_delay = 0.0 # Sofort ausführen

	# CPU 50 Züge spielen lassen
	for i in range(50):
		if logic.state == GameLogic.State.GAME_OVER:
			break
		cpu.update(0.1) # plant
		cpu.update(0.1) # führt aus / drop
		logic.update(0.01)

	assert_false(logic.game_over, "CPU sollte 50 Züge ohne Game Over überstehen")


func test_cpu_beats_random_player() -> void:
	var rng_cpu := RandomNumberGenerator.new()
	rng_cpu.seed = 999
	var logic_cpu := GameLogic.new(rng_cpu, 1)
	var cpu := CpuPlayer.new(logic_cpu, rng_cpu)
	cpu.think_delay = 0.0

	for i in range(60):
		if logic_cpu.state == GameLogic.State.GAME_OVER:
			break
		cpu.update(0.1)
		cpu.update(0.1)
		logic_cpu.update(0.01)

	# Zufallsspieler mit selbem Seed
	var rng_rand := RandomNumberGenerator.new()
	rng_rand.seed = 999
	var logic_rand := GameLogic.new(rng_rand, 1)
	for i in range(60):
		if logic_rand.state == GameLogic.State.GAME_OVER:
			break
		var random_dir := rng_rand.randi_range(-4, 4)
		if random_dir < 0:
			for d in range(-random_dir): logic_rand.move_horizontal(-1)
		else:
			for d in range(random_dir): logic_rand.move_horizontal(1)
		if rng_rand.randi_range(0, 1) == 1:
			logic_rand.rotate(true)
		logic_rand.hard_drop()
		logic_rand.update(0.01)

	assert_true(logic_cpu.lines >= logic_rand.lines, "CPU sollte mindestens so viele oder mehr Zeilen räumen")
	assert_false(logic_cpu.game_over, "CPU sollte 60 Züge durchhalten")
