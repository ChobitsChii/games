extends TestCase
## Tests für das Run-Autosave- und Fortsetzen-System (RunSaveManager).


func test_serialize_and_restore_roundtrip() -> void:
	SaveService.set_test_mode(true)
	RunSaveManager.clear_run()
	assert_false(RunSaveManager.has_saved_run(), "Anfangs kein Run gespeichert")

	var dungeon := DungeonGenerator.generate_floor(777, 2)
	var start_c := dungeon.start_room_coords
	var boss_c := dungeon.boss_room_coords
	var treasure_c := dungeon.treasure_room_coords

	# Markiere einen Kampfraum + Schatzraum als gesäubert bzw. Truhe geöffnet
	var combat_c := start_c
	for c: Vector2i in dungeon.rooms:
		var rm := dungeon.get_room(c)
		if rm.type == DungeonGenerator.RoomType.COMBAT:
			combat_c = c
			rm.cleared = true
			break
	var tr_room := dungeon.get_room(treasure_c)
	if tr_room != null:
		tr_room.cleared = true
		tr_room.chest_opened = true

	var visited := {start_c: true, combat_c: true, treasure_c: true}
	var all_items := ItemCatalog.get_all_items()
	var picked: Array[ItemData] = [all_items[0], all_items[4]]

	var payload := RunSaveManager.serialize_run(
		777, 2, combat_c, 9, "twin_fangs", picked, dungeon, visited
	)
	RunSaveManager.save_run(payload)

	assert_true(RunSaveManager.has_saved_run(), "Gespeicherter Run wird erkannt")
	var loaded := RunSaveManager.load_run()
	assert_eq(int(loaded["seed"]), 777, "Seed wiederhergestellt")
	assert_eq(int(loaded["floor"]), 2, "Etage wiederhergestellt")
	assert_eq(int(loaded["hp"]), 9, "HP wiederhergestellt")
	assert_eq(str(loaded["weapon_id"]), "twin_fangs", "Waffe wiederhergestellt")
	assert_eq(Vector2i(int(loaded["room_x"]), int(loaded["room_y"])), combat_c, "Raumkoordinaten stimmen")

	var restored_items := RunSaveManager.restore_items(loaded["item_ids"])
	assert_eq(restored_items.size(), 2, "2 Relikte wiederhergestellt")
	assert_eq(restored_items[0].id, all_items[0].id, "Erstes Relikt stimmt")
	assert_eq(restored_items[1].id, all_items[4].id, "Zweites Relikt stimmt")

	var restored_dungeon := DungeonGenerator.generate_floor(777, 2)
	var restored_visited := RunSaveManager.apply_floor_state(restored_dungeon, loaded)
	assert_true(restored_dungeon.get_room(combat_c).cleared, "Kampfraum bleibt gesäubert")
	assert_false(restored_dungeon.get_room(boss_c).cleared, "Bossraum bleibt ungesäubert")
	if tr_room != null:
		assert_true(restored_dungeon.get_room(treasure_c).chest_opened, "Schatztruhe bleibt geöffnet")
	assert_true(bool(restored_visited.get(combat_c, false)), "Minimap-Besuchtstatus wiederhergestellt")

	RunSaveManager.clear_run()
	assert_false(RunSaveManager.has_saved_run(), "Clear entfernt den Spielstand")


func test_invalid_save_rejected() -> void:
	SaveService.set_test_mode(true)
	SaveService.set_value("crypt_dash", "active_run", {"version": 99, "seed": 1, "floor": 1, "hp": 10})
	assert_false(RunSaveManager.has_saved_run(), "Ungültige Schema-Version abgelehnt")

	SaveService.set_value("crypt_dash", "active_run", {"version": 1, "seed": 1, "floor": 2, "hp": 0})
	assert_false(RunSaveManager.has_saved_run(), "Toter Spielstand (0 HP) abgelehnt")

	SaveService.set_value("crypt_dash", "active_run", {"version": 1, "seed": 1, "floor": 5, "hp": 10})
	assert_false(RunSaveManager.has_saved_run(), "Ungültige Etage abgelehnt")
	RunSaveManager.clear_run()
