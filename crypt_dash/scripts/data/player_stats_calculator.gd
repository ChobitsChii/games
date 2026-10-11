class_name PlayerStatsCalculator
extends RefCounted
## Berechnet die finalen Spieler-Werte aus Basiswerten, Meta-Upgrades und gesammelten Items.
## Formel laut Plan: Endwert = (Basis + Summe der Zuschläge) * Produkt der Faktoren.

const BASE_STATS := {
	"max_hp": 12.0,          # 12 halbe Herzen = 6 Herzen
	"speed": 420.0,          # 420 px/s
	"damage": 1.0,           # 1 Schaden pro Treffer
	"dash_duration": 0.18,   # 0.18s
	"dash_speed": 1400.0,    # 1400 px/s
	"dash_cooldown": 0.8,    # 0.8s
	"dash_charges": 1.0,     # 1 Dash
	"attack_rate": 3.33,     # ~0.3s Abklingzeit
	"crit_chance": 0.05,     # 5% Basis-Crit
	"shield_stacks": 0.0,
	"magnet_range": 80.0,
}


static func calculate_stats(
	items: Array[ItemData],
	meta_upgrades: Dictionary = {} # z.B. {"max_hp": 1, "damage": 2, "speed": 1, "dash_cd": 1}
) -> Dictionary:
	var adds: Dictionary = {}
	var muls: Dictionary = {}

	# Meta Upgrades verarbeiten
	var meta_hp_lvl: int = int(meta_upgrades.get("max_hp", 0))
	if meta_hp_lvl > 0:
		adds["max_hp"] = adds.get("max_hp", 0.0) + (meta_hp_lvl * 2.0)

	var meta_dmg_lvl: int = int(meta_upgrades.get("damage", 0))
	if meta_dmg_lvl > 0:
		muls["damage"] = muls.get("damage", 1.0) * (1.0 + meta_dmg_lvl * 0.20)

	var meta_spd_lvl: int = int(meta_upgrades.get("speed", 0))
	if meta_spd_lvl > 0:
		muls["speed"] = muls.get("speed", 1.0) * (1.0 + meta_spd_lvl * 0.15)

	var meta_dash_lvl: int = int(meta_upgrades.get("dash_cd", 0))
	if meta_dash_lvl > 0:
		muls["dash_cooldown"] = muls.get("dash_cooldown", 1.0) * maxf(0.4, 1.0 - (meta_dash_lvl * 0.20))

	# Items verarbeiten
	for it in items:
		for stat_name: String in it.stat_adds:
			adds[stat_name] = adds.get(stat_name, 0.0) + float(it.stat_adds[stat_name])
		for stat_name: String in it.stat_muls:
			muls[stat_name] = muls.get(stat_name, 1.0) * float(it.stat_muls[stat_name])

	# Zusammenrechnen
	var result: Dictionary = {}
	for stat_name: String in BASE_STATS:
		var base: float = float(BASE_STATS[stat_name])
		var add_val: float = float(adds.get(stat_name, 0.0))
		var mul_val: float = float(muls.get(stat_name, 1.0))
		result[stat_name] = (base + add_val) * mul_val

	# Grenzen / Clamping
	result["max_hp"] = maxf(2.0, roundf(float(result["max_hp"])))
	result["speed"] = clampf(float(result["speed"]), 200.0, 900.0)
	result["damage"] = maxf(0.5, float(result["damage"]))
	result["dash_cooldown"] = clampf(float(result["dash_cooldown"]), 0.25, 2.0)
	result["dash_charges"] = maxf(1.0, roundf(float(result["dash_charges"])))
	result["crit_chance"] = clampf(float(result["crit_chance"]), 0.0, 1.0)
	return result
