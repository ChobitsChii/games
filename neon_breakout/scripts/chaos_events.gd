class_name ChaosEvents
extends RefCounted
## Zufällige Ereignisse im Chaos-Modus (reine Logik, testbar). Alle paar Sekunden
## löst ein Ereignis aus. Manche wirken eine Weile, `RAIN` wirkt sofort.

enum Kind { REVERSE, GHOST, FAST, SHRINK, RAIN, DOUBLE }

## Dauer in Sekunden. 0 = wirkt sofort.
const DURATIONS := {
	Kind.REVERSE: 8.0,
	Kind.GHOST: 8.0,
	Kind.FAST: 7.0,
	Kind.SHRINK: 9.0,
	Kind.RAIN: 0.0,
	Kind.DOUBLE: 10.0,
}
const NAME_KEYS := {
	Kind.REVERSE: "CH_REVERSE",
	Kind.GHOST: "CH_GHOST",
	Kind.FAST: "CH_FAST",
	Kind.SHRINK: "CH_SHRINK",
	Kind.RAIN: "CH_RAIN",
	Kind.DOUBLE: "CH_DOUBLE",
}
## Gute Ereignisse leuchten grün/gelb, schlechte magenta/rot.
const GOOD := [Kind.RAIN, Kind.DOUBLE]
const FAST_FACTOR := 1.4
const SHRINK_FACTOR := 0.6
const DOUBLE_FACTOR := 2
const RAIN_ITEMS := 4
const MIN_DELAY := 9.0
const MAX_DELAY := 15.0
## Erstes Ereignis kommt etwas früher, damit man den Modus gleich erlebt.
const FIRST_DELAY := 6.0

var _active: Dictionary = {}
var _timer := FIRST_DELAY


static func is_timed(kind: int) -> bool:
	return DURATIONS[kind] > 0.0


static func color_for(kind: int) -> Color:
	return Color("ffd23f") if kind in GOOD else Color("ff2bd6")


func is_active(kind: int) -> bool:
	return _active.has(kind)


func remaining(kind: int) -> float:
	return _active.get(kind, 0.0)


func active_kinds() -> Array:
	return _active.keys()


func clear() -> void:
	_active.clear()


## Setzt das Ereignis in Gang. Erneutes Auslösen setzt die Zeit zurück (verlängert nicht).
func trigger(kind: int) -> void:
	if is_timed(kind):
		_active[kind] = DURATIONS[kind]


## Wählt ein Ereignis, das gerade nicht läuft.
func pick(rng: RandomNumberGenerator) -> int:
	var options: Array = []
	for kind in DURATIONS:
		if not _active.has(kind):
			options.append(kind)
	if options.is_empty():
		options = DURATIONS.keys()
	return options[rng.randi() % options.size()]


## Zählt die Zeit weiter. Gibt das Ereignis zurück, das jetzt auslösen soll, sonst -1.
func advance(delta: float, rng: RandomNumberGenerator) -> int:
	_timer -= delta
	if _timer > 0.0:
		return -1
	_timer = rng.randf_range(MIN_DELAY, MAX_DELAY)
	var kind := pick(rng)
	trigger(kind)
	return kind


## Zählt laufende Ereignisse herunter. Gibt die abgelaufenen zurück.
func tick(delta: float) -> Array:
	var expired: Array = []
	for kind in _active.keys():
		_active[kind] -= delta
		if _active[kind] <= 0.0:
			_active.erase(kind)
			expired.append(kind)
	return expired
