extends TestCase
## Prüft Level-Loader und alle Level-Dateien.


func test_there_are_ten_levels() -> void:
	BreakoutLevels.reload()
	assert_eq(BreakoutLevels.count(), 10, "Anzahl Level")


func test_every_level_file_is_valid() -> void:
	for level in range(1, BreakoutLevels.MAX_LEVELS + 1):
		var path := BreakoutLevels.path_for(level)
		if not FileAccess.file_exists(path):
			break
		var rows := BreakoutLevels.parse_text(FileAccess.get_file_as_string(path))
		assert_true(BreakoutLevels.is_valid(rows), "%s ist gültig" % path)
		assert_true(BreakoutLevels.breakable_count(rows) > 0, "%s hat zerstörbare Blöcke" % path)


func test_level_files_are_gapless() -> void:
	# Eine Lücke (z. B. level_04 fehlt) würde alle späteren Level verstecken.
	var count := BreakoutLevels.count()
	for level in range(count + 1, BreakoutLevels.MAX_LEVELS + 1):
		assert_true(not FileAccess.file_exists(BreakoutLevels.path_for(level)), "level_%02d.txt liegt hinter einer Lücke" % level)


func test_levels_get_harder_on_average() -> void:
	# Mehr Trefferpunkte insgesamt, wenn man die ersten mit den letzten Leveln vergleicht.
	var count := BreakoutLevels.count()
	var early := 0
	var late := 0
	for i in 3:
		early += _total_hits(BreakoutLevels.get_level(i + 1))
		late += _total_hits(BreakoutLevels.get_level(count - i))
	assert_true(late > early, "späte Level (%d) brauchen mehr Treffer als frühe (%d)" % [late, early])


func test_level_lookup_wraps_around() -> void:
	var count := BreakoutLevels.count()
	assert_eq(BreakoutLevels.get_level(1), BreakoutLevels.get_level(count + 1))
	assert_eq(BreakoutLevels.get_level(count), BreakoutLevels.get_level(count * 2))


func test_level_below_one_uses_first() -> void:
	assert_eq(BreakoutLevels.get_level(0), BreakoutLevels.get_level(1))


func test_parse_ignores_comments_and_blank_lines() -> void:
	var rows := BreakoutLevels.parse_text("# Titel\n\n1111111111\r\n  2222222222  \n# Ende\n")
	assert_eq(rows, ["1111111111", "2222222222"] as Array)


func test_invalid_levels_are_rejected() -> void:
	assert_true(not BreakoutLevels.is_valid([]), "leer")
	assert_true(not BreakoutLevels.is_valid(["111"]), "falsche Länge")
	assert_true(not BreakoutLevels.is_valid(["11111111Z1"]), "ungültiges Zeichen")
	var too_many: Array = []
	for i in BreakoutLevels.MAX_ROWS + 1:
		too_many.append("1111111111")
	assert_true(not BreakoutLevels.is_valid(too_many), "zu viele Reihen")


func test_breakable_count_ignores_unbreakable_and_empty() -> void:
	assert_eq(BreakoutLevels.breakable_count(["1X.2......", "3........."]), 3)


func _total_hits(rows: Array) -> int:
	var total := 0
	for row: String in rows:
		for ch in row:
			if ch in "123":
				total += int(ch)
	return total
