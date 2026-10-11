extends TestCase
## Testet den Boss-Zustandsautomaten und die Angriffsmuster.

func test_boss_phases_transition_and_patterns() -> void:
	var runner := BossPatternRunner.new()

	var phase_1: Array = [
		BossPhase.create("idle_1", 1.0, "idle"),
		BossPhase.create("charge_1", 2.0, "charge"),
	]
	var phase_2: Array = [
		BossPhase.create("slam_2", 1.5, "slam"),
		BossPhase.create("summon_2", 2.0, "summon"),
	]
	var phase_3: Array = [
		BossPhase.create("spiral_3", 3.0, "spiral_shot"),
		BossPhase.create("frenzy_3", 1.0, "charge"),
	]

	runner.init_boss(150, [phase_1, phase_2, phase_3])
	assert_eq(runner.current_phase_idx, 0, "Startet in Phase 0")
	assert_eq(runner.get_current_step().action, "idle", "Erster Schritt ist idle")

	# Schritt weiter
	runner.update(1.1)
	assert_eq(runner.get_current_step().action, "charge", "Zweiter Schritt ist charge")

	# Schaden zufügen -> Phase 1
	var dead := runner.take_damage(60) # HP = 90 / 150 = 60% -> Phase 1
	assert_false(dead, "Noch nicht tot")
	assert_eq(runner.current_phase_idx, 1, "Wechsel zu Phase 1")
	assert_eq(runner.state, BossPatternRunner.BossState.PHASE_TRANSITION, "Im Phasenwechsel")

	# Weiterer Schaden -> Phase 2
	dead = runner.take_damage(60) # HP = 30 / 150 = 20% -> Phase 2
	assert_false(dead, "Noch nicht tot")
	assert_eq(runner.current_phase_idx, 2, "Wechsel zu Phase 2")

	# Tödlicher Treffer
	dead = runner.take_damage(50)
	assert_true(dead, "Boss besiegt")
	assert_eq(runner.state, BossPatternRunner.BossState.DEFEATED, "Status DEFEATED")
