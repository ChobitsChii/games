class_name EffectTracker
extends RefCounted
## Verwaltet aktive Power-Up-Effekte. Zeitbasierte Effekte laufen in Spielzeit ab
## (tick mit delta), der Laser zählt Schüsse. Ein erneut eingesammelter Effekt
## verlängert sich, höchstens auf das Doppelte der Grundmenge.

## Art (PowerUps.Kind) -> verbleibende Sekunden bzw. Schüsse.
var _remaining: Dictionary = {}


func activate(kind: PowerUps.Kind, amount: float) -> void:
	var cap := amount * 2.0
	_remaining[kind] = minf(float(_remaining.get(kind, 0.0)) + amount, cap)


func is_active(kind: PowerUps.Kind) -> bool:
	return _remaining.get(kind, 0.0) > 0.0


func remaining(kind: PowerUps.Kind) -> float:
	return _remaining.get(kind, 0.0)


## Lässt zeitbasierte Effekte ablaufen. Gibt die Arten zurück, die dabei geendet haben.
func tick(delta: float) -> Array[PowerUps.Kind]:
	var expired: Array[PowerUps.Kind] = []
	for kind: PowerUps.Kind in _remaining.keys():
		if not PowerUps.is_timed(kind):
			continue
		_remaining[kind] -= delta
		if _remaining[kind] <= 0.0:
			_remaining.erase(kind)
			expired.append(kind)
	return expired


## Verbraucht Laser-Schüsse. Gibt false zurück, wenn nicht genug da sind.
func consume(kind: PowerUps.Kind, count: int = 1) -> bool:
	if remaining(kind) < count:
		return false
	_remaining[kind] -= count
	if _remaining[kind] <= 0.0:
		_remaining.erase(kind)
	return true


func clear() -> void:
	_remaining.clear()


## Aktive Arten in fester Reihenfolge (für die Anzeige).
func active_kinds() -> Array[PowerUps.Kind]:
	var result: Array[PowerUps.Kind] = []
	for kind in PowerUps.Kind.values():
		if is_active(kind):
			result.append(kind)
	return result
