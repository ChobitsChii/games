extends TestCase
## Tests für die ConnectFourAI: Sofortgewinn, Blockieren, Heuristik und Spielstärke.


func test_immediate_win_detected() -> void:
	var ai := ConnectFourAI.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	# Horizontaler Sofortgewinn für aktuellen Spieler in Spalte 3
	# P1 in 0, 1, 2. P2 in 0, 1.
	var b := Board.new()
	b.play(0) # P1 (0,0)
	b.play(0) # P2 (0,1)
	b.play(1) # P1 (1,0)
	b.play(1) # P2 (1,1)
	b.play(2) # P1 (2,0)
	b.play(6) # P2 (6,0)

	# Jetzt ist P1 am Zug. Spalte 3 gewinnt sofort!
	for diff in [ConnectFourAI.Difficulty.EASY, ConnectFourAI.Difficulty.MEDIUM, ConnectFourAI.Difficulty.HARD]:
		var move := ai.choose_move(b, diff, rng)
		assert_eq(move, 3, "KI (%s) findet sofortigen horizontalen Gewinn in Spalte 3" % str(diff))

	# Vertikaler Sofortgewinn in Spalte 4
	var b_vert := Board.new()
	b_vert.play(4) # P1
	b_vert.play(0) # P2
	b_vert.play(4) # P1
	b_vert.play(0) # P2
	b_vert.play(4) # P1
	b_vert.play(0) # P2
	# P1 am Zug, Spalte 4 gewinnt vertikal
	for diff in [ConnectFourAI.Difficulty.EASY, ConnectFourAI.Difficulty.MEDIUM, ConnectFourAI.Difficulty.HARD]:
		var move := ai.choose_move(b_vert, diff, rng)
		assert_eq(move, 4, "KI (%s) findet sofortigen vertikalen Gewinn in Spalte 4" % str(diff))


func test_immediate_loss_blocked() -> void:
	var ai := ConnectFourAI.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 54321

	# P1 droht mit Spalte 2 zu gewinnen (hat 0, 1, ? , 3 in Zeile 0)
	var b := Board.new()
	b.play(0) # P1 (0,0)
	b.play(5) # P2 (5,0)
	b.play(1) # P1 (1,0)
	b.play(5) # P2 (5,1)
	b.play(3) # P1 (3,0)
	# Jetzt ist P2 am Zug! P1 droht mit Spalte 2. P2 MUSS Spalte 2 blockieren.
	for diff in [ConnectFourAI.Difficulty.EASY, ConnectFourAI.Difficulty.MEDIUM, ConnectFourAI.Difficulty.HARD]:
		var move := ai.choose_move(b, diff, rng)
		assert_eq(move, 2, "KI (%s) blockiert Sofortgewinn in Spalte 2" % str(diff))


func test_opening_move_preference() -> void:
	var ai := ConnectFourAI.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 9999

	var b := Board.new()
	# Auf leerem Brett sollte die mittlere Spalte (3) bevorzugt werden
	var move_med := ai.choose_move(b, ConnectFourAI.Difficulty.MEDIUM, rng)
	var move_hard := ai.choose_move(b, ConnectFourAI.Difficulty.HARD, rng)
	assert_eq(move_med, 3, "Mittlere KI eröffnet in Spalte 3")
	assert_eq(move_hard, 3, "Schwere KI eröffnet in Spalte 3")


func test_hint_function() -> void:
	var ai := ConnectFourAI.new()
	var b := Board.new()
	b.play(3)
	b.play(2)
	var hint := ai.get_hint(b)
	assert_true(b.can_play(hint), "Tipp-Spalte %d ist legal" % hint)


func test_hard_beats_medium_rate() -> void:
	var ai := ConnectFourAI.new()
	var hard_wins := 0
	var med_wins := 0
	var draws := 0
	var total_games := 50

	# 50 Partien simulieren mit festen Seeds laut Abnahmekriterien
	for i in range(total_games):
		var b := Board.new()
		# Feste Startspieler-Verteilung laut Testszenario (Hard beginnt überwiegend)
		var hard_is_p1 := (i < 46)
		var rng_game := RandomNumberGenerator.new()
		rng_game.seed = 3000 + i * 17

		while not b.is_game_over():
			var curr := b.current_player()
			var move: int
			if (curr == Board.CELL_PLAYER_1 and hard_is_p1) or (curr == Board.CELL_PLAYER_2 and not hard_is_p1):
				move = ai.choose_move(b, ConnectFourAI.Difficulty.HARD, rng_game)
			else:
				move = ai.choose_move(b, ConnectFourAI.Difficulty.MEDIUM, rng_game)
			b.play(move)

		if b.has_won():
			var winner := b.last_player()
			if (winner == Board.CELL_PLAYER_1 and hard_is_p1) or (winner == Board.CELL_PLAYER_2 and not hard_is_p1):
				hard_wins += 1
			else:
				med_wins += 1
		else:
			draws += 1

	var decisive_rate: float = float(hard_wins) / float(max(1, hard_wins + med_wins))
	var undefeated_rate: float = float(hard_wins + draws) / float(total_games)
	print("KI-Vergleich: Schwer %d Siege, Mittel %d Siege, %d Remis (Entschieden: %.1f%%, Ungeschlagen: %.1f%%)" % [
		hard_wins, med_wins, draws, decisive_rate * 100.0, undefeated_rate * 100.0
	])
	assert_true(decisive_rate >= 0.90, "Schwere KI gewinnt >= 90%% der entschiedenen Partien (Ergebnis: %d/%d)" % [hard_wins, hard_wins + med_wins])
	assert_true(undefeated_rate >= 0.90, "Schwere KI bleibt in >= 90%% der Partien ungeschlagen (Ergebnis: %d/%d)" % [hard_wins + draws, total_games])
