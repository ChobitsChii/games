extends TestCase
## Tests für das Kampfsystem und die Treffer-Berechnungen in Lumaria.


func test_sword_damage_tiers() -> void:
	assert_eq(CombatCalculator.calculate_sword_damage(1), 20, "Stufe 1 Schaden")
	assert_eq(CombatCalculator.calculate_sword_damage(2), 35, "Stufe 2 Schaden")
	assert_eq(CombatCalculator.calculate_sword_damage(3), 55, "Stufe 3 Schaden")


func test_spin_attack_multiplier() -> void:
	var normal_dmg: int = CombatCalculator.calculate_sword_damage(1, false)
	var spin_dmg: int = CombatCalculator.calculate_sword_damage(1, true)
	assert_eq(spin_dmg, int(round(20.0 * 1.8)), "Wirbelangriff macht 1.8x Schaden")
	assert_true(spin_dmg > normal_dmg, "Wirbelangriff stärker als Normalhieb")


func test_unblocked_damage() -> void:
	var result: Dictionary = CombatCalculator.resolve_defense(40, false, 0.0)
	assert_false(result["blocked"], "Nicht geblockt")
	assert_false(result["parried"], "Nicht pariert")
	assert_eq(result["damage_taken"], 40, "Voller Schaden genommen")


func test_standard_block_damage_reduction() -> void:
	# Schild seit 0.5s gehoben (außerhalb des 0.22s Parry-Fensters)
	var result: Dictionary = CombatCalculator.resolve_defense(50, true, 0.5)
	assert_true(result["blocked"], "Erfolgreich geblockt")
	assert_false(result["parried"], "Kein Parry außerhalb des Fensters")
	# 50 - 80% (40) = 10 Schaden
	assert_eq(result["damage_taken"], 10, "80 % Schaden abgefangen")


func test_perfect_parry() -> void:
	# Schild frisch gehoben vor 0.10s (innerhalb des 0.22s Fensters)
	var result: Dictionary = CombatCalculator.resolve_defense(50, true, 0.10)
	assert_true(result["blocked"], "Geblockt")
	assert_true(result["parried"], "Perfekt pariert")
	assert_eq(result["damage_taken"], 0, "Kein Schaden erlitten bei Parry")
	assert_true(result["stun_duration"] > 1.0, "Angreifer wird betäubt")


func test_knockback_direction_and_force() -> void:
	var attacker := Vector2(100, 100)
	var target := Vector2(200, 100) # Rechter Nachbar
	var kb: Vector2 = CombatCalculator.calculate_knockback(attacker, target, 400.0, 0.0)
	assert_almost(kb.x, 400.0, "Knockback nach rechts")
	assert_almost(kb.y, 0.0, "Keine vertikale Abweichung")

	# Mit 50 % Resistenz
	var kb_res: Vector2 = CombatCalculator.calculate_knockback(attacker, target, 400.0, 0.5)
	assert_almost(kb_res.x, 200.0, "Halbierte Rückstoßkraft durch Resistenz")
