extends TestCase
## Unit-Tests für die Board-Klasse (Bitboards, Spielregeln, Gewinnerkennung).


func test_initial_board() -> void:
	var b := Board.new()
	assert_eq(b.moves, 0, "Anfangs 0 Züge")
	assert_eq(b.current_player(), Board.CELL_PLAYER_1, "Spieler 1 beginnt")
	assert_false(b.has_won(), "Kein Gewinn zu Beginn")
	assert_false(b.is_draw(), "Kein Unentschieden zu Beginn")
	assert_false(b.is_game_over(), "Spiel nicht beendet")
	for c in range(Board.WIDTH):
		assert_true(b.can_play(c), "Spalte %d ist bespielbar" % c)
		assert_eq(b.get_column_height(c), 0, "Spalte %d ist leer" % c)
		for r in range(Board.HEIGHT):
			assert_eq(b.get_cell(c, r), Board.CELL_EMPTY, "Zelle (%d,%d) ist leer" % [c, r])


func test_play_and_cell_occupancy() -> void:
	var b := Board.new()
	# Spieler 1 in Spalte 3
	assert_true(b.play(3), "Zug in Spalte 3 gültig")
	assert_eq(b.moves, 1, "1 Zug gespielt")
	assert_eq(b.get_column_height(3), 1, "Höhe Spalte 3 ist 1")
	assert_eq(b.get_cell(3, 0), Board.CELL_PLAYER_1, "Zelle (3,0) ist Spieler 1")
	assert_eq(b.last_move(), 3, "Letzter Zug war Spalte 3")
	assert_eq(b.last_move_row(), 0, "Letzter Zug war Zeile 0")
	assert_eq(b.current_player(), Board.CELL_PLAYER_2, "Jetzt ist Spieler 2 am Zug")

	# Spieler 2 ebenfalls in Spalte 3
	assert_true(b.play(3), "Zweiter Zug in Spalte 3")
	assert_eq(b.moves, 2, "2 Züge gespielt")
	assert_eq(b.get_column_height(3), 2, "Höhe Spalte 3 ist 2")
	assert_eq(b.get_cell(3, 1), Board.CELL_PLAYER_2, "Zelle (3,1) ist Spieler 2")
	assert_eq(b.current_player(), Board.CELL_PLAYER_1, "Wieder Spieler 1 am Zug")


func test_column_full_rejection() -> void:
	var b := Board.new()
	# 6 Steine in Spalte 0 einwerfen
	for i in range(6):
		assert_true(b.can_play(0), "Spalte 0 vor Zug %d frei" % i)
		assert_true(b.play(0), "Zug %d in Spalte 0 erfolgreich" % i)

	assert_eq(b.get_column_height(0), 6, "Spalte 0 voll")
	assert_false(b.can_play(0), "Spalte 0 nicht mehr bespielbar")
	assert_false(b.play(0), "7. Zug in Spalte 0 abgewiesen")

	# Ungültige Indizes
	assert_false(b.can_play(-1), "Spalte -1 ungültig")
	assert_false(b.can_play(7), "Spalte 7 ungültig")
	assert_false(b.play(-1), "Zug -1 ungültig")
	assert_false(b.play(7), "Zug 7 ungültig")


func test_horizontal_win() -> void:
	var b := Board.new()
	# Spieler 1: cols 0, 1, 2, 3 in Zeile 0
	# Spieler 2: cols 0, 1, 2 in Zeile 1
	var moves_seq := [0, 0, 1, 1, 2, 2, 3] # P1:0, P2:0, P1:1, P2:1, P1:2, P2:2, P1:3
	for col in moves_seq:
		b.play(col)

	assert_true(b.has_won(), "Spieler 1 hat horizontal gewonnen")
	assert_true(b.is_game_over(), "Spiel beendet")
	assert_eq(b.last_player(), Board.CELL_PLAYER_1, "Spieler 1 war letzter Spieler")

	var winning := b.get_winning_cells()
	assert_eq(winning.size(), 4, "4 Gewinner-Zellen ermittelt")
	for i in range(4):
		assert_true(winning.has(Vector2i(i, 0)), "Gewinner-Zelle (%d, 0) vorhanden" % i)


func test_vertical_win() -> void:
	var b := Board.new()
	# Spieler 1: Spalte 5 (4 Steine)
	# Spieler 2: Spalte 4 (3 Steine)
	var moves_seq := [5, 4, 5, 4, 5, 4, 5]
	for col in moves_seq:
		b.play(col)

	assert_true(b.has_won(), "Spieler 1 hat vertikal gewonnen")
	var winning := b.get_winning_cells()
	assert_eq(winning.size(), 4, "4 Gewinner-Zellen ermittelt")
	for r in range(4):
		assert_true(winning.has(Vector2i(5, r)), "Gewinner-Zelle (5, %d) vorhanden" % r)


func test_diagonal_positive_win() -> void:
	var b := Board.new()
	# Diagonale von (0,0) bis (3,3)
	# (0,0) P1, (1,1) P1, (2,2) P1, (3,3) P1
	# Aufbau:
	# c0: P1 (r0)
	# c1: P2 (r0), P1 (r1)
	# c2: P2 (r0), P2 (r1), P1 (r2)
	# c3: P2 (r0), P1 (r1), P2 (r2), P1 (r3)
	b.play(0) # P1: (0,0)
	b.play(1) # P2: (1,0)
	b.play(1) # P1: (1,1)
	b.play(2) # P2: (2,0)
	b.play(2) # P1: (2,1)
	b.play(3) # P2: (3,0)
	b.play(2) # P1: (2,2)
	b.play(3) # P2: (3,1)
	b.play(4) # P1: (4,0)
	b.play(3) # P2: (3,2)
	b.play(3) # P1: (3,3) - Gewinn!

	assert_true(b.has_won(), "Spieler 1 hat diagonal / gewonnen")
	var winning := b.get_winning_cells()
	assert_eq(winning.size(), 4, "4 Gewinner-Zellen")
	for i in range(4):
		assert_true(winning.has(Vector2i(i, i)), "Zelle (%d, %d) in Gewinnreihe" % [i, i])


func test_diagonal_negative_win() -> void:
	var b := Board.new()
	# Diagonale von (3,3) nach (6,0)
	# (3,3) P1, (4,2) P1, (5,1) P1, (6,0) P1
	b.play(6) # P1: (6,0)
	b.play(5) # P2: (5,0)
	b.play(5) # P1: (5,1)
	b.play(4) # P2: (4,0)
	b.play(4) # P1: (4,1)
	b.play(3) # P2: (3,0)
	b.play(4) # P1: (4,2)
	b.play(3) # P2: (3,1)
	b.play(2) # P1: (2,0)
	b.play(3) # P2: (3,2)
	b.play(3) # P1: (3,3) - Gewinn!

	assert_true(b.has_won(), "Spieler 1 hat diagonal \\ gewonnen")
	var winning := b.get_winning_cells()
	assert_eq(winning.size(), 4, "4 Gewinner-Zellen")
	for i in range(4):
		assert_true(winning.has(Vector2i(3 + i, 3 - i)), "Zelle (%d, %d) in Gewinnreihe" % [3 + i, 3 - i])


func test_undo() -> void:
	var b := Board.new()
	b.play(3)
	b.play(3)
	b.play(2)
	assert_eq(b.moves, 3, "3 Züge gespielt")
	assert_eq(b.get_column_height(3), 2, "Höhe 3 ist 2")

	assert_true(b.undo(), "Undo 1 erfolgreich")
	assert_eq(b.moves, 2, "2 Züge verbleibend")
	assert_eq(b.get_cell(2, 0), Board.CELL_EMPTY, "Zelle (2,0) wieder leer")
	assert_eq(b.current_player(), Board.CELL_PLAYER_1, "Spieler 1 wieder am Zug")

	assert_true(b.undo(), "Undo 2 erfolgreich")
	assert_eq(b.moves, 1, "1 Zug verbleibend")
	assert_eq(b.get_column_height(3), 1, "Höhe 3 ist wieder 1")

	assert_true(b.undo(), "Undo 3 erfolgreich")
	assert_eq(b.moves, 0, "Zurück auf 0 Züge")
	assert_false(b.undo(), "Undo auf leerem Brett schlägt fehl")


func test_draw_game() -> void:
	var b := Board.new()
	# Bekannte 42-Züge-Partie ohne Sieger:
	# Spaltenabfolge für ein volles Brett ohne 4 in einer Reihe
	# Spaltenfolge:
	# 0,1, 0,1, 0,1, 1,0, 1,0, 1,0  (Cols 0 and 1 full)
	# 2,3, 2,3, 2,3, 3,2, 3,2, 3,2  (Cols 2 and 3 full)
	# 4,5, 4,5, 4,5, 5,4, 5,4, 5,4  (Cols 4 and 5 full)
	# Col 6: 6,6,6,6,6,6
	var draw_seq := [
		0, 1, 0, 1, 0, 1,
		2, 3, 2, 3, 2, 3,
		4, 5, 4, 5, 4, 5,
		1, 0, 1, 0, 1, 0,
		3, 2, 3, 2, 3, 2,
		5, 4, 5, 4, 5, 4,
		6, 6, 6, 6, 6, 6
	]
	for col in draw_seq:
		assert_true(b.play(col), "Zug in %d erfolgreich" % col)
		if b.has_won():
			break

	assert_false(b.has_won(), "Kein Gewinner in Remis-Partie")
	assert_true(b.is_draw(), "Brett voll und Remis")
	assert_true(b.is_game_over(), "Spiel beendet")


func test_scenes_instantiate() -> void:
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	assert_true(menu != null, "MainMenu instanziiert")
	menu.free()
	var game = load("res://scenes/game.tscn").instantiate()
	assert_true(game != null, "Game instanziiert")
	game.free()
