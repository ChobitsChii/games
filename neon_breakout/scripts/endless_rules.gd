class_name EndlessRules
extends RefCounted
## Regeln des Endlos-Modus (reine Logik): Alle paar Sekunden rückt eine neue Blockreihe
## von oben nach. Erreichen die Blöcke den Schläger, ist das Spiel vorbei.

const START_ROWS := 5
const START_INTERVAL := 11.0
const MIN_INTERVAL := 4.0
const INTERVAL_STEP := 0.35
## Alle so viele Reihen steigt das Level (und damit das Balltempo).
const ROWS_PER_LEVEL := 8
## Ab dieser Reihe kommen unzerstörbare Blöcke vor.
const INDESTRUCTIBLE_FROM_ROW := 6
## Wird eine Reihe leergeräumt, gibt es diesen Bonus.
const CLEAR_BONUS := 200


## Sekunden bis zur nächsten Reihe, abhängig von den bisher erzeugten Reihen.
static func interval(rows_spawned: int) -> float:
	return maxf(START_INTERVAL - INTERVAL_STEP * rows_spawned, MIN_INTERVAL)


static func level_for(rows_spawned: int) -> int:
	return 1 + rows_spawned / ROWS_PER_LEVEL


## Eine Reihe als Text im Level-Format (`1`-`3`, `X`, `.`). Mindestens ein Block ist
## zerstörbar, höchstens ein Drittel unzerstörbar, immer mindestens eine Lücke oder
## ein zerstörbarer Block, damit sich jede Reihe räumen lässt.
static func generate_row(rng: RandomNumberGenerator, rows_spawned: int) -> String:
	var columns := BreakoutConfig.BRICK_COLUMNS
	var hard := clampf(0.1 + 0.03 * rows_spawned, 0.1, 0.6)
	var row := ""
	var destructible := 0
	for i in columns:
		if rng.randf() < 0.18:
			row += "."
			continue
		var roll := rng.randf()
		if rows_spawned >= INDESTRUCTIBLE_FROM_ROW and roll < 0.07:
			row += "X"
		elif roll < hard * 0.5:
			row += "3"
			destructible += 1
		elif roll < hard + 0.25:
			row += "2"
			destructible += 1
		else:
			row += "1"
			destructible += 1
	if destructible == 0:
		var index := rng.randi() % columns
		row = row.substr(0, index) + "1" + row.substr(index + 1)
	return row


## Ist das unterste Blockende (y der Blockmitte) so tief, dass der Schläger bedroht ist?
static func is_overrun(lowest_brick_y: float, limit_y: float) -> bool:
	return lowest_brick_y >= limit_y
