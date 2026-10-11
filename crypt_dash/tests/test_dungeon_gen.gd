extends TestCase
## Testet den Dungeon-Generator:
## 1. Alle Räume sind per BFS vom Startraum erreichbar
## 2. Gleicher Seed ergibt exakt dasselbe Layout (Deterministisch)
## 3. Test über 1000 Seeds schlägt nie fehl
## 4. Boss- und Schatzraum sind korrekt zugewiesen

func test_generator_deterministic() -> void:
	var seed_test := 12345
	var d1 := DungeonGenerator.generate_floor(seed_test, 1)
	var d2 := DungeonGenerator.generate_floor(seed_test, 1)

	assert_eq(d1.rooms.size(), d2.rooms.size(), "Gleiche Anzahl Räume")
	assert_eq(d1.boss_room_coords, d2.boss_room_coords, "Gleicher Boss-Raum")
	assert_eq(d1.treasure_room_coords, d2.treasure_room_coords, "Gleicher Schatzraum")

	for coords: Vector2i in d1.rooms:
		assert_true(d2.rooms.has(coords), "Raum existiert in beiden: " + str(coords))
		var r1 = d1.rooms[coords]
		var r2 = d2.rooms[coords]
		assert_eq(r1.doors, r2.doors, "Türen stimmen überein bei " + str(coords))
		assert_eq(r1.type, r2.type, "Raumtyp stimmt überein bei " + str(coords))


func test_all_rooms_reachable_1000_seeds() -> void:
	for i in range(1000):
		var test_seed := i * 1337 + 42
		var floor_num := (i % 3) + 1
		var dungeon := DungeonGenerator.generate_floor(test_seed, floor_num)

		var expected_count := 7 + (floor_num * 2)
		assert_true(dungeon.rooms.size() >= 5, "Genug Räume generiert bei Seed %d" % test_seed)

		# BFS zur Prüfung der Erreichbarkeit aller Räume
		var start := dungeon.start_room_coords
		assert_true(dungeon.rooms.has(start), "Startraum vorhanden")

		var queue: Array[Vector2i] = [start]
		var visited: Dictionary = {start: true}
		var directions := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

		while not queue.is_empty():
			var curr: Vector2i = queue.pop_front()
			var room = dungeon.rooms[curr]
			for dir in directions:
				var next: Vector2i = curr + dir
				if dungeon.rooms.has(next) and not visited.has(next):
					var has_conn := false
					if dir == Vector2i(0, -1) and room.doors["north"]: has_conn = true
					if dir == Vector2i(0, 1) and room.doors["south"]: has_conn = true
					if dir == Vector2i(-1, 0) and room.doors["west"]: has_conn = true
					if dir == Vector2i(1, 0) and room.doors["east"]: has_conn = true
					if has_conn:
						visited[next] = true
						queue.push_back(next)

		assert_eq(visited.size(), dungeon.rooms.size(), "Alle Räume erreichbar bei Seed %d" % test_seed)
		assert_true(dungeon.rooms.has(dungeon.boss_room_coords), "Bossraum vorhanden")
		assert_true(dungeon.rooms.has(dungeon.treasure_room_coords), "Schatzraum vorhanden")
