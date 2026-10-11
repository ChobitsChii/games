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


func test_boss_room_cleared_and_persistence() -> void:
	var r_data := DungeonGenerator.DungeonRoom.new()
	r_data.type = DungeonGenerator.RoomType.BOSS
	r_data.doors = {"north": true, "south": false, "east": false, "west": false}
	r_data.coords = Vector2i(5, 5)
	r_data.cleared = false

	var room := RoomTemplate.new()
	room.setup_room(r_data)
	assert_false(room.is_cleared, "Bossraum anfangs nicht gesäubert")
	assert_false(r_data.cleared, "Raum-Daten anfangs nicht gesäubert")
	assert_true(room._door_barriers.has("north"), "Nordtür hat Barriere")

	# Boss besiegen
	room._mark_room_cleared()
	assert_true(room.is_cleared, "Raum ist nun gesäubert")
	assert_true(r_data.cleared, "Raum-Daten als gesäubert markiert")
	assert_false(room._door_barriers.has("north"), "Tür-Barriere ist entriegelt und entfernt")

	# Exit-Node muss existieren
	var has_exit := false
	for child in room.get_children():
		if child is RoomTemplate.FloorExitNode:
			has_exit = true
			break
	assert_true(has_exit, "Treppe/Ausgang wurde gespawnt")
	room.queue_free()

	# Raum erneut betreten: Boss darf nicht respawnen, Ausgang muss da sein
	var room_reentered := RoomTemplate.new()
	room_reentered.setup_room(r_data)
	assert_true(room_reentered.is_cleared, "Wiederbetretener Raum bleibt gesäubert")
	assert_false(room_reentered._door_barriers.has("north"), "Keine Barriere bei gecleartem Raum")
	var has_boss := false
	var reentered_has_exit := false
	for child in room_reentered.get_children():
		if child is BaseBoss:
			has_boss = true
		elif child is RoomTemplate.FloorExitNode:
			reentered_has_exit = true
	assert_false(has_boss, "Boss spawnt nicht erneut")
	assert_true(reentered_has_exit, "Treppe/Ausgang bleibt vorhanden")
	room_reentered.queue_free()
