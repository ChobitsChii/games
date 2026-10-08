extends TestCase
## Testet Kollision, Platzierung, Reihen löschen und Müllreihen.


func test_empty_matrix_bounds() -> void:
	var m := Matrix.new()
	assert_true(m.is_empty_board(), "Neues Spielfeld ist leer")
	# Passt im Spielfeld
	assert_true(m.can_fit("T", 0, Vector2i(3, 10)))
	# Wand links
	assert_false(m.can_fit("T", 0, Vector2i(-2, 10)), "Kollision links")
	# Wand rechts
	assert_false(m.can_fit("T", 0, Vector2i(9, 10)), "Kollision rechts")
	# Boden
	assert_false(m.can_fit("T", 0, Vector2i(3, StackConfig.TOTAL_ROWS)), "Kollision Boden")


func test_lock_and_collision() -> void:
	var m := Matrix.new()
	var spawn := Vector2i(3, 19)
	assert_true(m.can_fit("O", 0, spawn))
	m.lock_piece("O", 0, spawn)
	# An den gleichen Koordinaten kann kein neuer Block platziert werden
	assert_false(m.can_fit("O", 0, spawn), "Soll kollidieren")
	# Zellen sind gesetzt (3+0=3, 3+1=4)
	assert_eq(m.get_cell(3, 19), "O")
	assert_eq(m.get_cell(4, 19), "O")
	assert_eq(m.get_cell(3, 20), "O")
	assert_eq(m.get_cell(4, 20), "O")


func test_clear_single_and_quad() -> void:
	var m := Matrix.new()
	# Eine Zeile füllen (Zeile 21)
	for c in range(StackConfig.COLS):
		m.set_cell(c, 21, "I")
	var full := m.find_full_lines()
	assert_eq(full, [21])
	var cleared := m.clear_lines(full)
	assert_eq(cleared, 1)
	assert_true(m.is_empty_board(), "Nach Löschen wieder leer")

	# 4 Zeilen füllen (Quad / Tetris)
	for r in range(18, 22):
		for c in range(StackConfig.COLS):
			m.set_cell(c, r, "I")
	var full_quad := m.find_full_lines()
	assert_eq(full_quad.size(), 4)
	var cleared_quad := m.clear_lines(full_quad)
	assert_eq(cleared_quad, 4)
	assert_true(m.is_empty_board())


func test_add_garbage() -> void:
	var m := Matrix.new()
	# Einen Block in der untersten Zeile setzen
	m.set_cell(0, 21, "T")
	m.add_garbage(2, 4) # 2 Müllreihen mit Loch bei Spalte 4
	# Der alte Block muss 2 Reihen nach oben gerutscht sein (Zeile 19)
	assert_eq(m.get_cell(0, 19), "T")
	# Zeile 20 und 21 sind Müll, Loch bei 4
	assert_eq(m.get_cell(4, 20), "")
	assert_eq(m.get_cell(0, 20), "GARBAGE")
	assert_eq(m.get_cell(4, 21), "")
	assert_eq(m.get_cell(9, 21), "GARBAGE")


func test_heuristics() -> void:
	var m := Matrix.new()
	# Spalte 0 hat 3 Blöcke, Spalte 1 hat 1 Block mit einem Loch darunter
	m.set_cell(0, 21, "I")
	m.set_cell(0, 20, "I")
	m.set_cell(0, 19, "I")
	m.set_cell(1, 20, "I") # Loch bei (1, 21)

	assert_eq(m.get_column_height(0), 3)
	assert_eq(m.get_column_height(1), 2)
	assert_eq(m.count_holes(), 1)
	assert_eq(m.get_bumpiness(), 1 + 2) # |3-2| + |2-0| = 3
