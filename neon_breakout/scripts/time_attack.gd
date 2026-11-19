class_name TimeAttack
extends RefCounted
## Regeln des Zeitangriffs (reine Logik): Zeitformat, Zeitbonus und Rekorde.

## Pro Block (zerstörbar) rechnen wir mit dieser Richtzeit in Sekunden.
const PAR_PER_BRICK := 1.6
const PAR_BASE := 6.0
const BONUS_PER_SECOND := 10


## "m:ss.cc" für Sekunden.
static func format_time(seconds: float) -> String:
	var total := maxf(seconds, 0.0)
	var minutes := int(total) / 60
	var rest := total - minutes * 60
	return "%d:%05.2f" % [minutes, rest]


## Richtzeit für ein Level mit `bricks` zerstörbaren Blöcken.
static func par_time(bricks: int) -> float:
	return PAR_BASE + PAR_PER_BRICK * bricks


## Bonuspunkte: Für jede Sekunde unter der Richtzeit gibt es Punkte.
static func bonus(seconds: float, bricks: int) -> int:
	return int(maxf(par_time(bricks) - seconds, 0.0)) * BONUS_PER_SECOND


## Ist `seconds` eine neue Bestzeit? (`best` <= 0: noch keine gespeichert)
static func is_record(seconds: float, best: float) -> bool:
	return best <= 0.0 or seconds < best
