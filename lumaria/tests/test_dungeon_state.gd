extends TestCase
## Tests für das DungeonState-System: Raum-Tracking, Türen, Schalter, Truhen und Boss-Fortschritt.


func test_initial_dungeon_state() -> void:
	var state := DungeonState.new("shrine_roots")
	assert_eq(state.dungeon_id, "shrine_roots", "Dungeon ID korrekt gesetzt")
	assert_eq(state.current_room, 0, "Startet in Raum 0")
	assert_true(state.is_room_visited(0), "Raum 0 als besucht markiert")
	assert_false(state.is_room_visited(1), "Raum 1 noch unbesucht")
	assert_eq(state.get_available_keys(), 0, "Keine Schlüssel anfangs")
	assert_false(state.has_boss_key, "Kein Boss-Schlüssel")
	assert_false(state.boss_defeated, "Boss noch nicht besiegt")
	assert_false(state.prism_collected, "Prisma noch nicht geborgen")


func test_room_transitions() -> void:
	var state := DungeonState.new("shrine_roots")
	var is_first: bool = state.visit_room(1)
	assert_true(is_first, "Erster Besuch von Raum 1")
	assert_eq(state.current_room, 1, "Aktueller Raum ist nun 1")

	var is_second: bool = state.visit_room(1)
	assert_false(is_second, "Zweiter Besuch ist nicht first_visit")


func test_key_and_door_unlock_flow() -> void:
	var state := DungeonState.new("shrine_roots")

	# Tür benötigt Schlüssel
	assert_false(state.can_unlock_door("door_room_4"), "Ohne Schlüssel nicht entsperrbar")
	assert_false(state.unlock_door("door_room_4"), "Entsperren schlägt fehl")

	# Schlüssel aufsammeln
	state.add_key()
	assert_eq(state.get_available_keys(), 1, "1 Schlüssel verfügbar")
	assert_true(state.can_unlock_door("door_room_4"), "Nun entsperrbar")

	# Tür aufsperren
	assert_true(state.unlock_door("door_room_4"), "Tür erfolgreich aufgesperrt")
	assert_true(state.is_door_unlocked("door_room_4"), "Tür ist als offen markiert")
	assert_eq(state.get_available_keys(), 0, "Schlüssel verbraucht")

	# Bereits geöffnete Tür bleibt offen
	assert_true(state.can_unlock_door("door_room_4"), "Geöffnete Tür immer zugänglich")


func test_boss_door_unlock_flow() -> void:
	var state := DungeonState.new("shrine_roots")
	assert_false(state.can_unlock_door("boss_gate", true), "Boss-Tor ohne Boss-Schlüssel verriegelt")

	# Normaler Schlüssel öffnet kein Boss-Tor
	state.add_key()
	assert_false(state.can_unlock_door("boss_gate", true), "Normaler Schlüssel reicht nicht")

	# Boss-Schlüssel erhalten
	var chest_res: Dictionary = state.open_chest("chest_boss_key", "boss_key")
	assert_true(chest_res["success"], "Truhe mit Boss-Schlüssel geöffnet")
	assert_true(state.has_boss_key, "Boss-Schlüssel im Besitz")
	assert_true(state.can_unlock_door("boss_gate", true), "Boss-Tor nun entsperrbar")
	assert_true(state.unlock_door("boss_gate", true), "Boss-Tor geöffnet")


func test_switch_toggling() -> void:
	var state := DungeonState.new("shrine_roots")
	assert_false(state.is_switch_active("switch_chasm"), "Schalter anfangs inaktiv")

	var new_state: bool = state.toggle_switch("switch_chasm")
	assert_true(new_state, "Schalter aktiviert")
	assert_true(state.is_switch_active("switch_chasm"), "Schalter-Zustand aktiv")

	new_state = state.toggle_switch("switch_chasm")
	assert_false(new_state, "Schalter deaktiviert")
	assert_false(state.is_switch_active("switch_chasm"), "Schalter-Zustand inaktiv")


func test_chest_and_prism_collection() -> void:
	var state := DungeonState.new("shrine_roots")
	var res1: Dictionary = state.open_chest("chest_1", "small_key")
	assert_true(res1["success"], "Truhe geöffnet")
	assert_eq(state.get_available_keys(), 1, "Schlüssel gutgeschrieben")

	var res2: Dictionary = state.open_chest("chest_1", "small_key")
	assert_false(res2["success"], "Bereits geöffnete Truhe kann nicht erneut geplündert werden")

	state.open_chest("chest_sun_prism", "sun_prism")
	assert_true(state.prism_collected, "Sonnen-Prisma geborgen")


func test_serialization_roundtrip() -> void:
	var state1 := DungeonState.new("shrine_roots")
	state1.visit_room(3)
	state1.add_key()
	state1.unlock_door("door_1")
	state1.set_switch("switch_1", true)
	state1.open_chest("chest_boss_key", "boss_key")
	state1.defeat_boss()

	var data: Dictionary = state1.to_dict()

	var state2 := DungeonState.new("shrine_roots")
	state2.from_dict(data)

	assert_eq(state2.current_room, 3, "Raum nach Wiederherstellung 3")
	assert_true(state2.is_door_unlocked("door_1"), "Tür 1 noch offen")
	assert_true(state2.is_switch_active("switch_1"), "Schalter noch aktiv")
	assert_true(state2.has_boss_key, "Boss-Schlüssel vorhanden")
	assert_true(state2.boss_defeated, "Boss als besiegt gespeichert")
