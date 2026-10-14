extends TestCase
## Testet die Prüfungen des Turms und den Phasenablauf von Endboss Malakor.

func test_tower_trials_progression_and_apex_unlock() -> void:
	var state := TowerTrialState.new()
	assert_false(state.is_apex_unlocked(), "Apex initial gesperrt")

	assert_true(state.complete_trial("roots"), "Wurzel-Prüfung abgeschlossen")
	assert_false(state.is_apex_unlocked(), "Noch nicht vollendet")

	assert_true(state.complete_trial("depths"), "Tiefen-Prüfung abgeschlossen")
	assert_false(state.is_apex_unlocked(), "Noch nicht vollendet")

	assert_true(state.complete_trial("winds"), "Wind-Prüfung abgeschlossen")
	assert_true(state.is_apex_unlocked(), "Alle 3 Prüfungen geschafft -> Apex freigeschaltet!")


func test_malakor_phase_transitions_and_barrier_elements() -> void:
	var state := TowerTrialState.new()
	assert_eq(state.malakor_phase, 1, "Phase 1: Schattenduelle")

	# Vorzeitiges Brechen der Barriere in Phase 1 wirkungslos
	assert_false(state.break_barrier_element("nature"), "Keine Barriere in Phase 1")

	# Übergang zu Phase 2
	var p2 := state.advance_malakor_phase()
	assert_eq(p2, 2, "Phase 2: Kristallbarriere")

	# Elemente nach und nach brechen
	assert_true(state.break_barrier_element("nature"), "Natur-Barriere gebrochen")
	assert_true(state.break_barrier_element("tide"), "Gezeiten-Barriere gebrochen")
	assert_false(state.is_malakor_defeated, "Noch nicht besiegt")

	# Letztes Element bricht -> automatischer Wechsel zu Phase 3!
	assert_true(state.break_barrier_element("storm"), "Sturm-Barriere gebrochen")
	assert_eq(state.malakor_phase, 3, "Automatisch Phase 3 erreicht")

	# Letzter Schlag in Phase 3
	state.advance_malakor_phase()
	assert_true(state.is_malakor_defeated, "Malakor besiegt!")


func test_tower_state_serialization_roundtrip() -> void:
	var orig := TowerTrialState.new()
	orig.complete_trial("roots")
	orig.complete_trial("winds")
	orig.advance_malakor_phase()

	var data := orig.serialize()
	var restored := TowerTrialState.new()
	restored.deserialize(data)

	assert_true(restored.trial_roots, "Wurzel-Prüfung erhalten")
	assert_false(restored.trial_depths, "Tiefen-Prüfung nicht abgeschlossen")
	assert_true(restored.trial_winds, "Wind-Prüfung erhalten")
	assert_eq(restored.malakor_phase, 2, "Phase 2 erhalten")
