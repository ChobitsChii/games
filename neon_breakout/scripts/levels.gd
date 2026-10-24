class_name BreakoutLevels
extends RefCounted
## Lädt Level aus Textdateien (res://data/levels/level_NN.txt).
##
## Zeichen: 1-3 = Block mit so vielen Trefferpunkten, X = unzerstörbar, . = leer.
## Jede Zeile hat BreakoutConfig.BRICK_COLUMNS Zeichen. Leere Zeilen und Zeilen,
## die mit # beginnen, werden ignoriert (Kommentare). Ein Level kann leere Reihen
## am Anfang haben, dafür eine Zeile mit nur Punkten verwenden.

const LEVEL_DIR := "res://data/levels"
## Obergrenze, damit ein Fehler beim Zählen nie endlos sucht.
const MAX_LEVELS := 99
## Mehr Reihen passen nicht ins Spielfeld.
const MAX_ROWS := 12

static var _cache: Array = []


## Anzahl der vorhandenen Level (lückenlos ab level_01.txt).
static func count() -> int:
	_ensure_loaded()
	return _cache.size()


## Level-Zeilen für die Levelnummer (ab 1). Danach beginnt die Liste von vorn.
static func get_level(level: int) -> Array:
	_ensure_loaded()
	if _cache.is_empty():
		push_error("BreakoutLevels: Keine Level in %s gefunden" % LEVEL_DIR)
		return ["1111111111"]
	return _cache[(maxi(level, 1) - 1) % _cache.size()]


## Pfad der Levelnummer (ab 1), z. B. res://data/levels/level_03.txt.
static func path_for(level: int) -> String:
	return "%s/level_%02d.txt" % [LEVEL_DIR, level]


## Zerlegt Dateitext in Zeilen. Kommentare und Leerzeilen fallen weg.
static func parse_text(text: String) -> Array:
	var rows: Array = []
	for line in text.split("\n"):
		var row := line.strip_edges()
		if row == "" or row.begins_with("#"):
			continue
		rows.append(row)
	return rows


static func is_valid(rows: Array) -> bool:
	if rows.is_empty() or rows.size() > MAX_ROWS:
		return false
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


## Erzwingt erneutes Laden (für Tests).
static func reload() -> void:
	_cache.clear()
	_ensure_loaded()


static func _ensure_loaded() -> void:
	if not _cache.is_empty():
		return
	for level in range(1, MAX_LEVELS + 1):
		var path := path_for(level)
		if not FileAccess.file_exists(path):
			break
		var rows := parse_text(FileAccess.get_file_as_string(path))
		if not is_valid(rows):
			push_error("BreakoutLevels: %s ist ungültig und wird übersprungen" % path)
			continue
		_cache.append(rows)
