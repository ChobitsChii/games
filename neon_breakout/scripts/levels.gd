class_name BreakoutLevels
extends RefCounted
## Level als Textzeilen. Zeichen: 1-3 = Block mit so vielen Trefferpunkten,
## X = unzerstörbar, . = leer. Jede Zeile hat BreakoutConfig.BRICK_COLUMNS Zeichen.
## (Wird in einem späteren Meilenstein durch Level-Dateien ersetzt.)

const LEVELS: Array = [
	[
		"1111111111",
		"1222222221",
		"1233333321",
		"1222222221",
		"1111111111",
	],
	[
		"X........X",
		"1122332211",
		"1223333221",
		"X22....22X",
		"1111111111",
		"..........",
	],
]


## Level-Zeilen für die Levelnummer (ab 1). Danach beginnt die Liste von vorn.
static func get_level(level: int) -> Array:
	return LEVELS[(level - 1) % LEVELS.size()]


static func is_valid(rows: Array) -> bool:
	for row: String in rows:
		if row.length() != BreakoutConfig.BRICK_COLUMNS:
			return false
		for ch in row:
			if ch not in ".123X":
				return false
	return true


## Anzahl zerstörbarer Blöcke.
static func breakable_count(rows: Array) -> int:
	var count := 0
	for row: String in rows:
		for ch in row:
			if ch in "123":
				count += 1
	return count
