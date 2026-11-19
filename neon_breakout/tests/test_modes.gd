extends TestCase
## Tests für die Spielmodi: Moduswerte, Chaos, Endlos, Boss, Zeitangriff und Demo-Tipps.


func _rng(seed_value: int = 7) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


# --- GameMode -------------------------------------------------------------

func test_modes_have_texts_and_order() -> void:
	assert_eq(GameMode.ORDER.size(), GameMode.NAME_KEYS.size(), "jeder Modus steht in der Reihenfolge")
	for mode in GameMode.ORDER:
		assert_true(GameMode.NAME_KEYS.has(mode) and GameMode.DESC_KEYS.has(mode), "Name und Beschreibung")


func test_classic_keeps_old_highscore_key() -> void:
	assert_eq(GameMode.best_key(GameMode.Id.CLASSIC), "best", "Klassisch nutzt den bisherigen Rekord")
	assert_eq(GameMode.best_key(GameMode.Id.ENDLESS), "best_endless", "eigene Rekorde")
	assert_eq(GameMode.best_key(GameMode.Id.DEMO), "", "Demo speichert nichts")


func test_mode_rules() -> void:
	assert_true(not GameMode.has_lives(GameMode.Id.ZEN), "Zen hat keine Leben")
	assert_true(GameMode.has_lives(GameMode.Id.CLASSIC), "Klassisch hat Leben")
	assert_true(GameMode.speed_factor(GameMode.Id.ZEN) < 1.0, "Zen ist langsamer")
	assert_eq(GameMode.speed_factor(GameMode.Id.CLASSIC), 1.0, "Klassisch unverändert")
	assert_eq(GameMode.drop_chance(GameMode.Id.CLASSIC), PowerUps.DROP_CHANCE, "Klassisch unverändert")
	assert_true(GameMode.drop_chance(GameMode.Id.ZEN) > PowerUps.DROP_CHANCE, "Zen mit mehr Power-Ups")
	assert_true(GameMode.is_demo(GameMode.Id.DEMO) and not GameMode.is_demo(GameMode.Id.CLASSIC), "Demo erkannt")


# --- Chaos ----------------------------------------------------------------

func test_chaos_first_event_comes_early() -> void:
	var chaos := ChaosEvents.new()
	var rng := _rng()
	assert_eq(chaos.advance(ChaosEvents.FIRST_DELAY - 0.5, rng), -1, "noch nichts")
	assert_true(chaos.advance(1.0, rng) >= 0, "dann das erste Ereignis")


func test_chaos_timed_event_expires() -> void:
	var chaos := ChaosEvents.new()
	chaos.trigger(ChaosEvents.Kind.REVERSE)
	assert_true(chaos.is_active(ChaosEvents.Kind.REVERSE), "läuft")
	assert_true(chaos.tick(ChaosEvents.DURATIONS[ChaosEvents.Kind.REVERSE] - 1.0).is_empty(), "noch nicht abgelaufen")
	var expired := chaos.tick(1.5)
	assert_eq(expired, [ChaosEvents.Kind.REVERSE], "abgelaufen")
	assert_true(not chaos.is_active(ChaosEvents.Kind.REVERSE), "vorbei")


func test_chaos_instant_event_is_not_tracked() -> void:
	var chaos := ChaosEvents.new()
	chaos.trigger(ChaosEvents.Kind.RAIN)
	assert_true(not chaos.is_active(ChaosEvents.Kind.RAIN), "Regen wirkt sofort")


func test_chaos_pick_avoids_running_events_and_is_reproducible() -> void:
	var chaos := ChaosEvents.new()
	chaos.trigger(ChaosEvents.Kind.GHOST)
	for i in 40:
		assert_true(chaos.pick(_rng(i)) != ChaosEvents.Kind.GHOST, "läuft schon, wird nicht gewählt")
	assert_eq(chaos.pick(_rng(3)), chaos.pick(_rng(3)), "gleicher Seed, gleiche Wahl")


func test_chaos_every_kind_has_name_and_duration() -> void:
	for kind in ChaosEvents.Kind.values():
		assert_true(ChaosEvents.NAME_KEYS.has(kind) and ChaosEvents.DURATIONS.has(kind), "vollständig")


func test_chaos_clear() -> void:
	var chaos := ChaosEvents.new()
	chaos.trigger(ChaosEvents.Kind.FAST)
	chaos.clear()
	assert_true(chaos.active_kinds().is_empty(), "alles beendet")


# --- Endlos ---------------------------------------------------------------

func test_endless_interval_shrinks_to_minimum() -> void:
	assert_eq(EndlessRules.interval(0), EndlessRules.START_INTERVAL, "am Anfang")
	assert_true(EndlessRules.interval(10) < EndlessRules.interval(0), "wird schneller")
	assert_eq(EndlessRules.interval(500), EndlessRules.MIN_INTERVAL, "nie schneller als das Minimum")


func test_endless_level_grows() -> void:
	assert_eq(EndlessRules.level_for(0), 1, "Start")
	assert_eq(EndlessRules.level_for(EndlessRules.ROWS_PER_LEVEL), 2, "nach einigen Reihen")


func test_endless_rows_are_valid() -> void:
	var rng := _rng(11)
	var columns := BreakoutConfig.BRICK_COLUMNS
	for rows in 60:
		var row := EndlessRules.generate_row(rng, rows)
		assert_eq(row.length(), columns, "Reihenlänge")
		var destructible := 0
		for c in row:
			assert_true(c in ".123X", "gültiges Zeichen")
			if c in "123":
				destructible += 1
			if c == "X":
				assert_true(rows >= EndlessRules.INDESTRUCTIBLE_FROM_ROW, "X erst später")
		assert_true(destructible > 0, "mindestens ein zerstörbarer Block")


func test_endless_rows_follow_seed() -> void:
	assert_eq(EndlessRules.generate_row(_rng(5), 3), EndlessRules.generate_row(_rng(5), 3), "reproduzierbar")


func test_endless_overrun() -> void:
	assert_true(not EndlessRules.is_overrun(500.0, 900.0), "weit weg")
	assert_true(EndlessRules.is_overrun(900.0, 900.0), "an der Grenze")


# --- Boss -----------------------------------------------------------------

func test_boss_gets_tougher_with_tier() -> void:
	assert_true(BossRules.hp_for(2) > BossRules.hp_for(1), "mehr Leben")
	assert_true(BossRules.shot_speed(3) > BossRules.shot_speed(1), "schnellere Schüsse")
	assert_true(BossRules.attack_interval(3, 0) < BossRules.attack_interval(1, 0), "greift öfter an")
	assert_eq(BossRules.hp_for(0), BossRules.hp_for(1), "Stufe unter 1 wie 1")


func test_boss_phases() -> void:
	assert_eq(BossRules.phase_for(1.0), 0, "voll")
	assert_eq(BossRules.phase_for(0.5), 1, "halb")
	assert_eq(BossRules.phase_for(0.1), BossRules.MAX_PHASE, "fast besiegt")
	assert_true(BossRules.attack_interval(1, 2) < BossRules.attack_interval(1, 0), "wütender, öfter")
	assert_true(BossRules.attack_interval(99, 2) >= BossRules.MIN_INTERVAL, "Minimum bleibt")
	assert_true(BossRules.shots_for(2) > BossRules.shots_for(0), "mehr Schüsse")


func test_boss_shot_offsets_are_centered() -> void:
	var offsets := BossRules.shot_offsets(3)
	assert_eq(offsets.size(), 3, "drei Schüsse")
	assert_almost(offsets[0] + offsets[2], 0.0, "symmetrisch")
	assert_almost(offsets[1], 0.0, "einer in der Mitte")
	assert_eq(BossRules.shot_offsets(1), [0.0] as Array[float], "ein Schuss mittig")


func test_boss_takes_damage_and_dies() -> void:
	var boss := Boss.new()
	boss.setup_boss(1, 960.0, 1200.0)
	var destroyed := [false]
	boss.destroyed.connect(func(_b: Brick) -> void: destroyed[0] = true)
	assert_eq(boss.hp, BossRules.hp_for(1), "volle Leben")
	assert_almost(boss.hp_fraction(), 1.0, "Leiste voll")
	for i in BossRules.hp_for(1) - 1:
		assert_true(not boss.hit(), "überlebt")
	assert_true(not destroyed[0], "noch nicht zerstört")
	assert_true(boss.hit(), "letzter Treffer zerstört ihn")
	assert_true(destroyed[0], "Signal gesendet")
	boss.free()


# --- Zeitangriff ----------------------------------------------------------

func test_time_format() -> void:
	assert_eq(TimeAttack.format_time(0.0), "0:00.00", "null")
	assert_eq(TimeAttack.format_time(75.5), "1:15.50", "über eine Minute")
	assert_eq(TimeAttack.format_time(-3.0), "0:00.00", "negativ wird begrenzt")


func test_time_bonus() -> void:
	var par := TimeAttack.par_time(20)
	assert_eq(TimeAttack.bonus(par + 5.0, 20), 0, "zu langsam: kein Bonus")
	assert_true(TimeAttack.bonus(par - 10.0, 20) > TimeAttack.bonus(par - 2.0, 20), "schneller = mehr Bonus")
	assert_true(TimeAttack.par_time(40) > TimeAttack.par_time(10), "mehr Blöcke = mehr Zeit")


func test_time_record() -> void:
	assert_true(TimeAttack.is_record(50.0, 0.0), "erste Zeit ist ein Rekord")
	assert_true(TimeAttack.is_record(40.0, 50.0), "schneller")
	assert_true(not TimeAttack.is_record(60.0, 50.0), "langsamer")


# --- Demo-Coach -----------------------------------------------------------

func test_coach_cooldown_between_tips() -> void:
	var coach := DemoCoach.new()
	assert_true(coach.tip_for(&"level_start") != "", "erster Tipp sofort")
	assert_eq(coach.tip_for(&"combo"), "", "zu früh für den nächsten")
	coach.advance(DemoCoach.COOLDOWN + 0.1)
	assert_eq(coach.tip_for(&"combo"), "TIP_COMBO", "nach der Pause wieder")


func test_coach_ignores_unknown_events_and_repeats_rarely() -> void:
	var coach := DemoCoach.new()
	assert_eq(coach.tip_for(&"gibt_es_nicht"), "", "unbekannt")
	coach.advance(DemoCoach.COOLDOWN + 1.0)
	assert_eq(coach.tip_for(&"combo"), "TIP_COMBO", "zeigen")
	coach.advance(DemoCoach.COOLDOWN + 1.0)
	assert_eq(coach.tip_for(&"combo"), "", "gleicher Tipp nicht gleich nochmal")
	coach.advance(DemoCoach.COOLDOWN * 3.0)
	assert_eq(coach.tip_for(&"combo"), "TIP_COMBO", "viel später wieder")
	assert_eq(coach.times_shown("TIP_COMBO"), 2, "gezählt")


func test_coach_events_and_tips_exist() -> void:
	for event in DemoCoach.TIPS:
		for key in DemoCoach.TIPS[event]:
			assert_true(String(key).begins_with("TIP_"), "Schlüssel")


func test_coach_hit_ratio_and_events() -> void:
	assert_almost(DemoCoach.hit_ratio(100.0, 100.0, 180.0), 0.0, "Mitte")
	assert_almost(DemoCoach.hit_ratio(190.0, 100.0, 180.0), 1.0, "rechter Rand")
	assert_almost(DemoCoach.hit_ratio(0.0, 100.0, 180.0), -1.0, "links, begrenzt")
	assert_eq(DemoCoach.paddle_event(0.9), &"paddle_edge", "Rand")
	assert_eq(DemoCoach.paddle_event(-0.1), &"paddle_center", "Mitte")


func test_coach_aim_leads_ball_toward_target() -> void:
	assert_true(DemoCoach.aim_ratio(500.0, 1000.0) > 0.0, "Ziel rechts: Ball nach rechts lenken")
	assert_true(DemoCoach.aim_ratio(1000.0, 500.0) < 0.0, "Ziel links: nach links")
	assert_true(absf(DemoCoach.aim_ratio(500.0, 1500.0)) > absf(DemoCoach.aim_ratio(500.0, 560.0)), "weiter weg = weiter außen")
	assert_true(absf(DemoCoach.aim_ratio(0.0, 5000.0)) <= 0.85, "nie über den Rand hinaus")
