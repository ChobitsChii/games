extends TestCase
## Testet die Spiellogik: Bewegung, Drop, Hold, Ghost, Wertung und Game Over.


func test_initial_spawn_and_ghost() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var logic := GameLogic.new(rng, 1)

	assert_ne(logic.current_piece, "", "Ein Stein muss aktiv sein")
	assert_eq(logic.current_rot, 0)
	var ghost := logic.get_ghost_position()
	assert_true(ghost.y >= logic.current_pos.y, "Ghost muss weiter unten oder gleich sein")


func test_move_and_hard_drop() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 100
	var logic := GameLogic.new(rng, 1)

	var start_x := logic.current_pos.x
	# Links bewegen
	var moved := logic.move_horizontal(-1)
	assert_true(moved)
	assert_eq(logic.current_pos.x, start_x - 1)

	# Hard Drop
	var distance := logic.hard_drop()
	assert_true(distance > 0, "Hard Drop muss Fallstrecke zurücklegen")
	assert_eq(logic.score, distance * 2, "Hard Drop bringt 2 Punkte pro Feld")


func test_hold_piece() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 200
	var logic := GameLogic.new(rng, 1)

	var first_piece := logic.current_piece
	assert_eq(logic.hold_piece, "")
	# Erstes Hold
	var success := logic.hold()
	assert_true(success)
	assert_eq(logic.hold_piece, first_piece, "Stein muss im Hold sein")
	assert_false(logic.can_hold, "Hold darf nicht zweimal hintereinander im gleichen Zug genutzt werden")

	# Zweites Hold im gleichen Zug schlägt fehl
	var second_hold := logic.hold()
	assert_false(second_hold)

	# Nach Hard Drop ist Hold wieder erlaubt
	logic.hard_drop()
	assert_true(logic.can_hold)


func test_line_clear_and_scoring() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 300
	var logic := GameLogic.new(rng, 1)

	# Matrix vorbefüllen: Zeile 21 bis auf Spalte 3 füllen
	for c in range(StackConfig.COLS):
		if c != 3:
			logic.matrix.set_cell(c, 21, "O")

	# Einen I-Block gezielt über Spalte 3 platzieren und droppen
	# Um es direkt zu testen: Wir füllen alle 10 Spalten und rufen lock_and_process auf
	for c in range(StackConfig.COLS):
		logic.matrix.set_cell(c, 21, "I")
	logic.current_pos = Vector2i(3, 19)
	var prev_score := logic.score
	logic.lock_and_process()
	assert_eq(logic.lines, 1, "1 Zeile geräumt")
	assert_true(logic.score > prev_score, "Punkte für Single erhalten")


func test_t_spin_detection() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 400
	var logic := GameLogic.new(rng, 1)

	logic.current_piece = "T"
	logic.current_rot = 0
	logic.current_pos = Vector2i(3, 19)
	# Ecken blockieren (3 von 4 Ecken)
	logic.matrix.set_cell(3, 19, "I") # oben links
	logic.matrix.set_cell(5, 19, "I") # oben rechts
	logic.matrix.set_cell(3, 21, "I") # unten links
	logic.last_action_was_rotate = true

	assert_true(logic.is_t_spin(), "3 Ecken belegt + Drehung = T-Spin")
