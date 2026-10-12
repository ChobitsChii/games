extends TestCase
## Unit-Tests für Dungeon-Mechaniken: Schalter, Tore, Truhen und Boss Floragorg.

const SWITCH_SCENE := preload("res://scenes/objects/switch_crystal.tscn")
const DOOR_SCENE := preload("res://scenes/objects/dungeon_door.tscn")
const CHEST_SCENE := preload("res://scenes/objects/treasure_chest.tscn")
const BOSS_SCENE := preload("res://scenes/entities/bosses/boss_floragorg.tscn")


func test_switch_crystal_activation() -> void:
	var sw: SwitchCrystal = SWITCH_SCENE.instantiate()
	assert_false(sw.is_active, "Schalter anfangs inaktiv")

	sw.hit_switch()
	assert_true(sw.is_active, "Schalter nach Treffer aktiv")

	# Permanenter Schalter bleibt nach weiterem Treffer aktiv
	sw.hit_switch()
	assert_true(sw.is_active, "Permanenter Schalter bleibt aktiv")

	sw.free()


func test_dungeon_door_opening() -> void:
	var door: DungeonDoor = DOOR_SCENE.instantiate()
	assert_false(door.is_open, "Tür anfangs geschlossen")

	door.open_door()
	assert_true(door.is_open, "Tür nach Aufsperren offen")

	door.free()


func test_treasure_chest_loot() -> void:
	var chest: TreasureChest = CHEST_SCENE.instantiate()
	chest.chest_id = "chest_test"
	chest.item_type = "small_key"
	assert_false(chest.is_opened, "Truhe anfangs geschlossen")

	var received := [""]
	chest.opened.connect(func(_id: String, loot: String) -> void:
		received[0] = loot
	)

	chest.open_chest()
	assert_true(chest.is_opened, "Truhe geöffnet")
	assert_eq(received[0], "small_key", "Kleiner Schlüssel als Beute erhalten")

	# Erneuter Versuch liefert keine Beute
	received[0] = ""
	chest.open_chest()
	assert_eq(received[0], "", "Bereits geöffnete Truhe gibt kein Item mehr")

	chest.free()


func test_boss_floragorg_phases_and_stun() -> void:
	var boss: BossFloragorg = BOSS_SCENE.instantiate()
	assert_eq(boss.max_health, 200, "Boss hat 200 HP")
	assert_eq(boss.current_health, 200, "Startet mit voller Gesundheit")
	assert_false(boss.is_phase_2, "Startet in Phase 1")

	# Rindenpanzer reduziert Schaden um 75%
	boss.take_hit(40, Vector2.ZERO, 0.0)
	assert_eq(boss.current_health, 190, "Normaler Schaden um 75% reduziert (10 statt 40)")

	# Verwundbaren Kern öffnen
	boss._open_vulnerable_core()
	assert_eq(int(boss.boss_state), int(BossFloragorg.BossState.VULNERABLE), "Kern ist verwundbar")

	# Bumerang betäubt Boss
	boss.stun_boss()
	assert_eq(int(boss.boss_state), int(BossFloragorg.BossState.STUNNED), "Boss ist betäubt")

	# Während des Stuns voller Schaden
	boss.is_invulnerable = false
	boss.take_hit(40, Vector2.ZERO, 0.0)
	assert_eq(boss.current_health, 150, "Voller Schaden im betäubten Zustand")

	# Phase 2 Auslösung unter 50% HP (< 100 HP)
	boss.current_health = 95
	boss._process_ai(0.01)
	assert_true(boss.is_phase_2, "Unter 50% HP wechselt Floragorg in Phase 2 (Enrage)")

	boss.free()
