extends TestCase
## Testet den 7-Bag Zufallsgenerator.


func test_7_bag_permutation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var bag := Bag.new(rng)

	for b in range(50): # 50 Bags testen = 350 Steine
		var set := {}
		for i in range(7):
			var piece := bag.pop()
			assert_true(Piece.TYPES.has(piece), "Gültiger Stein-Typ: " + piece)
			assert_false(set.has(piece), "Stein darf im gleichen 7-Bag nicht doppelt sein: " + piece)
			set[piece] = true
		assert_eq(set.size(), 7, "Jeder 7-Bag muss genau alle 7 Typen enthalten")


func test_peek_matches_pop() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9999
	var bag := Bag.new(rng)

	var peeked := bag.peek(5)
	assert_eq(peeked.size(), 5)
	for i in range(5):
		var piece := bag.pop()
		assert_eq(piece, peeked[i], "Pop muss mit zuvor gepeektem Stein übereinstimmen")
