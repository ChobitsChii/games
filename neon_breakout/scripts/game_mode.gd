class_name GameMode
extends RefCounted
## Spielmodi von Neon Breakout (reine Daten und Regeln, ohne Nodes). Der Standardmodus
## ist `CLASSIC` und bleibt unverändert; alle anderen sind optionale Extras.

enum Id { CLASSIC, TIME_ATTACK, ENDLESS, CHAOS, BOSS, ZEN, DEMO }

## Reihenfolge im Auswahlbildschirm.
const ORDER: Array[int] = [Id.CLASSIC, Id.TIME_ATTACK, Id.ENDLESS, Id.CHAOS, Id.BOSS, Id.ZEN, Id.DEMO]

const NAME_KEYS := {
	Id.CLASSIC: "MODE_CLASSIC",
	Id.TIME_ATTACK: "MODE_TIME_ATTACK",
	Id.ENDLESS: "MODE_ENDLESS",
	Id.CHAOS: "MODE_CHAOS",
	Id.BOSS: "MODE_BOSS",
	Id.ZEN: "MODE_ZEN",
	Id.DEMO: "MODE_DEMO",
}
const DESC_KEYS := {
	Id.CLASSIC: "MODE_CLASSIC_DESC",
	Id.TIME_ATTACK: "MODE_TIME_ATTACK_DESC",
	Id.ENDLESS: "MODE_ENDLESS_DESC",
	Id.CHAOS: "MODE_CHAOS_DESC",
	Id.BOSS: "MODE_BOSS_DESC",
	Id.ZEN: "MODE_ZEN_DESC",
	Id.DEMO: "MODE_DEMO_DESC",
}
## Kürzel für Speicherstände ("" beim Standardmodus, damit alte Rekorde erhalten bleiben).
const SAVE_IDS := {
	Id.CLASSIC: "",
	Id.TIME_ATTACK: "time_attack",
	Id.ENDLESS: "endless",
	Id.CHAOS: "chaos",
	Id.BOSS: "boss",
	Id.ZEN: "zen",
}

## Zen: Der Ball ist etwas langsamer, Power-Ups fallen häufiger.
const ZEN_SPEED_FACTOR := 0.8
const ZEN_DROP_CHANCE := 0.22
const CHAOS_DROP_CHANCE := 0.2

## Der im Menü gewählte Modus (bleibt über Szenenwechsel erhalten).
static var selected: int = Id.CLASSIC


static func is_valid(mode: int) -> bool:
	return NAME_KEYS.has(mode)


## Schlüssel für den Rekord im Spielstand. Leer: dieser Modus speichert keinen Rekord.
static func best_key(mode: int) -> String:
	if not SAVE_IDS.has(mode):
		return ""
	var id: String = SAVE_IDS[mode]
	return "best" if id == "" else "best_" + id


static func has_lives(mode: int) -> bool:
	return mode != Id.ZEN


## Kurzer Weg: Der Autopilot spielt, der Spieler schaut zu.
static func is_demo(mode: int) -> bool:
	return mode == Id.DEMO


static func speed_factor(mode: int) -> float:
	return ZEN_SPEED_FACTOR if mode == Id.ZEN else 1.0


static func drop_chance(mode: int) -> float:
	match mode:
		Id.ZEN:
			return ZEN_DROP_CHANCE
		Id.CHAOS:
			return CHAOS_DROP_CHANCE
	return PowerUps.DROP_CHANCE
