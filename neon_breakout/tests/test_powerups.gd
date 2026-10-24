extends TestCase
## Tests für Power-Up-Regeln, Combo und Effekt-Tracker.


func test_combo_multiplier_curve() -> void:
	assert_almost(PowerUps.combo_multiplier(0), 1.0, "0")
	assert_almost(PowerUps.combo_multiplier(1), 1.0, "erster Block zählt einfach")
	assert_almost(PowerUps.combo_multiplier(2), 1.25, "2")
	assert_almost(PowerUps.combo_multiplier(5), 2.0, "5")


func test_combo_multiplier_is_capped() -> void:
	assert_almost(PowerUps.combo_multiplier(13), 4.0, "Grenze erreicht")
	assert_almost(PowerUps.combo_multiplier(500), 4.0, "bleibt bei 4")


func test_pick_returns_every_kind_with_expected_frequency() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var counts := {}
	var runs := 20000
	for i in runs:
		var kind := PowerUps.pick(rng)
		counts[kind] = counts.get(kind, 0) + 1
	var total_weight := 0
	for kind in PowerUps.WEIGHTS:
		total_weight += PowerUps.WEIGHTS[kind]
	for kind in PowerUps.WEIGHTS:
		assert_true(counts.has(kind), "Art %d kommt vor" % kind)
		var expected := float(PowerUps.WEIGHTS[kind]) / total_weight
		assert_almost(counts.get(kind, 0) / float(runs), expected, "Häufigkeit Art %d" % kind, 0.02)
	assert_true(counts.get(PowerUps.Kind.LIFE, 0) < counts.get(PowerUps.Kind.WIDE, 0), "Extraleben ist seltener")


func test_pick_is_reproducible_with_same_seed() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 99
	b.seed = 99
	for i in 50:
		assert_eq(PowerUps.pick(a), PowerUps.pick(b), "gleicher Seed, gleiche Folge")


func test_drop_chance_is_about_twelve_percent() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var drops := 0
	var runs := 20000
	for i in runs:
		if PowerUps.should_drop(rng):
			drops += 1
	assert_almost(drops / float(runs), PowerUps.DROP_CHANCE, "Drop-Rate", 0.015)
	assert_true(PowerUps.should_drop(rng, 1.0), "Chance 1 trifft immer")
	assert_true(not PowerUps.should_drop(rng, 0.0), "Chance 0 nie")


func test_every_kind_has_name_color_and_known_duration_rule() -> void:
	for kind in PowerUps.Kind.values():
		assert_true(PowerUps.NAME_KEYS.has(kind), "Name für Art %d" % kind)
		assert_true(PowerUps.COLORS.has(kind), "Farbe für Art %d" % kind)
		assert_true(PowerUps.WEIGHTS.has(kind), "Gewicht für Art %d" % kind)
	assert_true(PowerUps.has_duration(PowerUps.Kind.WIDE), "Breit hat Dauer")
	assert_true(not PowerUps.has_duration(PowerUps.Kind.MULTI), "Multiball wirkt sofort")
	assert_true(not PowerUps.has_duration(PowerUps.Kind.LIFE), "Extraleben wirkt sofort")


func test_multi_direction_rotation_keeps_speed() -> void:
	var v := Vector2(0.0, -640.0)
	var rotated := PowerUps.rotated_direction(v, PowerUps.MULTI_ANGLE_DEGREES)
	assert_almost(rotated.length(), 640.0, "Länge bleibt")
	assert_almost(rad_to_deg(v.angle_to(rotated)), 20.0, "Winkel", 0.01)


func test_tracker_timed_effect_expires() -> void:
	var tracker := EffectTracker.new()
	tracker.activate(PowerUps.Kind.WIDE, 15.0)
	assert_true(tracker.is_active(PowerUps.Kind.WIDE), "aktiv")
	assert_eq(tracker.tick(14.0).size(), 0, "noch nicht abgelaufen")
	assert_almost(tracker.remaining(PowerUps.Kind.WIDE), 1.0, "Restzeit")
	var expired := tracker.tick(2.0)
	assert_eq(expired, [PowerUps.Kind.WIDE] as Array, "abgelaufen gemeldet")
	assert_true(not tracker.is_active(PowerUps.Kind.WIDE), "nicht mehr aktiv")


func test_tracker_recollect_extends_but_is_capped() -> void:
	var tracker := EffectTracker.new()
	tracker.activate(PowerUps.Kind.SLOW, 10.0)
	tracker.tick(4.0)
	tracker.activate(PowerUps.Kind.SLOW, 10.0)
	assert_almost(tracker.remaining(PowerUps.Kind.SLOW), 16.0, "verlängert")
	tracker.activate(PowerUps.Kind.SLOW, 10.0)
	assert_almost(tracker.remaining(PowerUps.Kind.SLOW), 20.0, "höchstens das Doppelte")


func test_tracker_laser_counts_shots_and_does_not_time_out() -> void:
	var tracker := EffectTracker.new()
	tracker.activate(PowerUps.Kind.LASER, 10.0)
	tracker.tick(1000.0)
	assert_true(tracker.is_active(PowerUps.Kind.LASER), "Laser läuft nicht ab")
	for i in 10:
		assert_true(tracker.consume(PowerUps.Kind.LASER), "Schuss %d" % (i + 1))
	assert_true(not tracker.consume(PowerUps.Kind.LASER), "leer")
	assert_true(not tracker.is_active(PowerUps.Kind.LASER), "nach dem letzten Schuss inaktiv")


func test_tracker_active_kinds_and_clear() -> void:
	var tracker := EffectTracker.new()
	tracker.activate(PowerUps.Kind.SLOW, 10.0)
	tracker.activate(PowerUps.Kind.WIDE, 15.0)
	assert_eq(tracker.active_kinds(), [PowerUps.Kind.WIDE, PowerUps.Kind.SLOW] as Array, "feste Reihenfolge")
	tracker.clear()
	assert_eq(tracker.active_kinds().size(), 0, "alles gelöscht")
