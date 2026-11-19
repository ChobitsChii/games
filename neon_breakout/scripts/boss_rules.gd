class_name BossRules
extends RefCounted
## Regeln der Bosskämpfe (reine Logik). Pro Stufe wird der Boss zäher und schneller.
## Je weniger Leben er hat, desto aggressiver wird er (drei Phasen).

const BASE_HP := 40
const HP_PER_TIER := 16
const MAX_PHASE := 2
const PHASE_THRESHOLDS := [0.66, 0.33]
const BASE_INTERVAL := 3.4
const MIN_INTERVAL := 1.1
const BASE_SHOT_SPEED := 340.0
const SHOT_SPEED_PER_TIER := 30.0
const BASE_MOVE_SPEED := 0.55
const HIT_SCORE := 20
const SHOT_SPREAD := 70.0


static func hp_for(tier: int) -> int:
	return BASE_HP + HP_PER_TIER * (maxi(tier, 1) - 1)


## 0 = ruhig, 1 = wütend, 2 = Raserei. `hp_fraction` ist 0..1.
static func phase_for(hp_fraction: float) -> int:
	if hp_fraction > PHASE_THRESHOLDS[0]:
		return 0
	if hp_fraction > PHASE_THRESHOLDS[1]:
		return 1
	return MAX_PHASE


static func attack_interval(tier: int, phase: int) -> float:
	return maxf(BASE_INTERVAL - 0.25 * (maxi(tier, 1) - 1) - 0.6 * phase, MIN_INTERVAL)


static func shots_for(phase: int) -> int:
	return clampi(phase + 1, 1, MAX_PHASE + 1)


static func shot_speed(tier: int) -> float:
	return BASE_SHOT_SPEED + SHOT_SPEED_PER_TIER * (maxi(tier, 1) - 1)


## Bewegungstempo in Schwingungen pro Sekunde.
static func move_speed(tier: int, phase: int) -> float:
	return BASE_MOVE_SPEED + 0.06 * (maxi(tier, 1) - 1) + 0.12 * phase


## Seitliche Versätze der Schüsse (x) für `count` Schüsse, mittig verteilt.
static func shot_offsets(count: int) -> Array[float]:
	var result: Array[float] = []
	for i in count:
		result.append((i - (count - 1) * 0.5) * SHOT_SPREAD)
	return result
