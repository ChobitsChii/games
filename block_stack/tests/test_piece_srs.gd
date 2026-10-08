extends TestCase
## Testet alle Formen, 4 Rotationen und SRS-Wall-Kicks.


func test_all_shapes_have_four_blocks() -> void:
	for type in Piece.TYPES:
		for rot in range(4):
			var cells := Piece.get_cells(type, rot)
			assert_eq(cells.size(), 4, "%s bei Rot %d muss 4 Blöcke haben" % [type, rot])


func test_blocks_within_bounding_box() -> void:
	for type in Piece.TYPES:
		var max_coord := 3 if type == "I" else (1 if type == "O" else 2)
		for rot in range(4):
			var cells := Piece.get_cells(type, rot)
			for c in cells:
				assert_true(c.x >= 0 and c.x <= max_coord, "%s rot %d x außerhalb: %d" % [type, rot, c.x])
				assert_true(c.y >= 0 and c.y <= max_coord, "%s rot %d y außerhalb: %d" % [type, rot, c.y])


func test_o_piece_does_not_rotate() -> void:
	var r0 := Piece.get_cells("O", 0)
	for rot in range(1, 4):
		var r := Piece.get_cells("O", rot)
		assert_eq(r, r0, "O-Block soll in allen Drehungen identisch sein")
	var kicks := Piece.get_kicks("O", 0, 1)
	assert_eq(kicks, [Vector2i.ZERO], "O-Block hat keine Wall Kicks")


func test_srs_wall_kicks_standard() -> void:
	# Test 0 > 1 (CW von Spawn): [ (0,0), (-1,0), (-1,-1), (0,2), (-1,2) ]
	var k01 := Piece.get_kicks("T", 0, 1)
	assert_eq(k01.size(), 5, "5 Kick-Tests")
	assert_eq(k01[0], Vector2i(0, 0))
	assert_eq(k01[1], Vector2i(-1, 0))
	assert_eq(k01[2], Vector2i(-1, -1))
	assert_eq(k01[3], Vector2i(0, 2))
	assert_eq(k01[4], Vector2i(-1, 2))

	# Test 1 > 0 (CCW zurück nach 0): [ (0,0), (1,0), (1,1), (0,-2), (1,-2) ]
	var k10 := Piece.get_kicks("T", 1, 0)
	assert_eq(k10[0], Vector2i(0, 0))
	assert_eq(k10[1], Vector2i(1, 0))
	assert_eq(k10[2], Vector2i(1, 1))
	assert_eq(k10[3], Vector2i(0, -2))
	assert_eq(k10[4], Vector2i(1, -2))

	# Test 0 > 3 (CCW von 0 nach L): [ (0,0), (1,0), (1,-1), (0,2), (1,2) ]
	var k03 := Piece.get_kicks("J", 0, 3)
	assert_eq(k03[0], Vector2i(0, 0))
	assert_eq(k03[1], Vector2i(1, 0))
	assert_eq(k03[2], Vector2i(1, -1))
	assert_eq(k03[3], Vector2i(0, 2))
	assert_eq(k03[4], Vector2i(1, 2))


func test_srs_wall_kicks_i() -> void:
	# Test I-Block 0 > 1: [ (0,0), (-2,0), (1,0), (-2,1), (1,-2) ]
	var ki01 := Piece.get_kicks("I", 0, 1)
	assert_eq(ki01.size(), 5, "I hat 5 Kick-Tests")
	assert_eq(ki01[0], Vector2i(0, 0))
	assert_eq(ki01[1], Vector2i(-2, 0))
	assert_eq(ki01[2], Vector2i(1, 0))
	assert_eq(ki01[3], Vector2i(-2, 1))
	assert_eq(ki01[4], Vector2i(1, -2))

	# Test I-Block 1 > 0: [ (0,0), (2,0), (-1,0), (2,-1), (-1,2) ]
	var ki10 := Piece.get_kicks("I", 1, 0)
	assert_eq(ki10[0], Vector2i(0, 0))
	assert_eq(ki10[1], Vector2i(2, 0))
	assert_eq(ki10[2], Vector2i(-1, 0))
	assert_eq(ki10[3], Vector2i(2, -1))
	assert_eq(ki10[4], Vector2i(-1, 2))
