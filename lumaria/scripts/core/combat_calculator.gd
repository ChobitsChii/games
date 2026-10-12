class_name CombatCalculator
extends RefCounted
## Reine Logikklasse für Schadens-, Block-, Parry- und Knockback-Berechnungen in Lumaria.
## Vollständig ohne Szenenbaum testbar.

const PARRY_WINDOW_SEC := 0.22
const BASE_KNOCKBACK_FORCE := 380.0

const SWORD_DAMAGE_TIERS: Dictionary = {
	1: 20,
	2: 35,
	3: 55,
}

const SPIN_ATTACK_MULTIPLIER := 1.8
const RESONANCE_BEAM_DAMAGE := 15


## Berechnet den Grundschaden des Schwertes anhand der Klingenstufe.
static func calculate_sword_damage(tier: int, is_spin: bool = false, is_critical: bool = false) -> int:
	var base_dmg: int = SWORD_DAMAGE_TIERS.get(tier, 20)
	var final_dmg: float = float(base_dmg)
	if is_spin:
		final_dmg *= SPIN_ATTACK_MULTIPLIER
	if is_critical:
		final_dmg *= 1.5
	return int(round(final_dmg))


## Prüft, ob ein Angriff abgewehrt oder pariert wurde.
## Gibt ein Dictionary zurück: { "parried": bool, "blocked": bool, "damage_taken": int, "stun_duration": float }
static func resolve_defense(incoming_damage: int, is_blocking: bool, block_timer_sec: float) -> Dictionary:
	if not is_blocking:
		return {
			"parried": false,
			"blocked": false,
			"damage_taken": incoming_damage,
			"stun_duration": 0.0,
		}
	
	# Parry-Fenster: Schild wurde vor weniger als PARRY_WINDOW_SEC gehoben
	if block_timer_sec <= PARRY_WINDOW_SEC:
		return {
			"parried": true,
			"blocked": true,
			"damage_taken": 0,
			"stun_duration": 1.5, # Betäubt den Angreifer
		}
	
	# Normaler Block: 80% Schadensabsorption, mindestens 1 Schaden abgefangen
	var absorbed: int = int(round(float(incoming_damage) * 0.8))
	var remaining: int = maxi(incoming_damage - absorbed, 0)
	return {
		"parried": false,
		"blocked": true,
		"damage_taken": remaining,
		"stun_duration": 0.0,
	}


## Berechnet den Rückstoß-Vektor für getroffene Entities.
static func calculate_knockback(attacker_pos: Vector2, target_pos: Vector2, force: float = BASE_KNOCKBACK_FORCE, resistance: float = 0.0) -> Vector2:
	var diff := target_pos - attacker_pos
	if diff.length_squared() < 0.001:
		diff = Vector2.DOWN
	var dir := diff.normalized()
	var effective_force := force * clampf(1.0 - resistance, 0.0, 1.0)
	return dir * effective_force
