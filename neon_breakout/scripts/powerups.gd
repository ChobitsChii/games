class_name PowerUps
extends RefCounted
## Regeln für Power-Ups und Combos (reine Logik ohne Nodes, daher testbar).

enum Kind { WIDE, MULTI, LASER, STICKY, SLOW, LIFE }

## Wahrscheinlichkeit, dass ein zerstörter Block ein Item fallen lässt.
const DROP_CHANCE := 0.12
const FALL_SPEED := 220.0

## Gewichte für die Auswahl: Extraleben ist selten.
const WEIGHTS := {
	Kind.WIDE: 22,
	Kind.MULTI: 20,
	Kind.LASER: 16,
	Kind.STICKY: 14,
	Kind.SLOW: 18,
	Kind.LIFE: 4,
}

## Dauer in Sekunden (WIDE, STICKY, SLOW) bzw. Schüsse (LASER). MULTI und LIFE wirken sofort.
const AMOUNTS := {
	Kind.WIDE: 15.0,
	Kind.LASER: 10.0,
	Kind.STICKY: 15.0,
	Kind.SLOW: 10.0,
}

const WIDE_FACTOR := 1.5
const SLOW_FACTOR := 0.7
const MULTI_ANGLE_DEGREES := 20.0
const MAX_BALLS := 8
const MAX_LIVES := 9
const COMBO_STEP := 0.25
const MAX_COMBO_MULTIPLIER := 4.0

## Übersetzungsschlüssel für Meldungen und Anzeige.
const NAME_KEYS := {
	Kind.WIDE: "PU_WIDE",
	Kind.MULTI: "PU_MULTI",
	Kind.LASER: "PU_LASER",
	Kind.STICKY: "PU_STICKY",
	Kind.SLOW: "PU_SLOW",
	Kind.LIFE: "PU_LIFE",
}

const COLORS := {
	Kind.WIDE: Color("00e5ff"),
	Kind.MULTI: Color("ff2bd6"),
	Kind.LASER: Color("ff4d4d"),
	Kind.STICKY: Color("7dff6b"),
	Kind.SLOW: Color("ffd23f"),
	Kind.LIFE: Color("ff7a9c"),
}


## Würfelt, ob ein Block ein Item fallen lässt. `chance` überschreibt für Tests.
static func should_drop(rng: RandomNumberGenerator, chance: float = DROP_CHANCE) -> bool:
	return rng.randf() < chance


## Wählt eine Art nach Gewichten.
static func pick(rng: RandomNumberGenerator) -> Kind:
	var total := 0
	for kind in WEIGHTS:
		total += WEIGHTS[kind]
	var roll := rng.randi_range(0, total - 1)
	for kind in WEIGHTS:
		roll -= WEIGHTS[kind]
		if roll < 0:
			return kind
	return Kind.WIDE


## Punkte-Multiplikator für `combo` zerstörte Blöcke seit dem letzten Schlägerkontakt.
## Der erste Block zählt einfach, danach +0,25 je Block bis zum Maximum.
static func combo_multiplier(combo: int) -> float:
	if combo <= 1:
		return 1.0
	return minf(1.0 + COMBO_STEP * (combo - 1), MAX_COMBO_MULTIPLIER)


## Zeitlich begrenzt (läuft ab) oder nicht (Laser zählt Schüsse)?
static func is_timed(kind: Kind) -> bool:
	return kind != Kind.LASER


## Hat die Art einen Zustand, der in der Effektliste angezeigt wird?
static func has_duration(kind: Kind) -> bool:
	return AMOUNTS.has(kind)


## Neue Richtung für einen Zusatzball: die Flugrichtung um `degrees` gedreht.
static func rotated_direction(velocity: Vector2, degrees: float) -> Vector2:
	return velocity.rotated(deg_to_rad(degrees))
