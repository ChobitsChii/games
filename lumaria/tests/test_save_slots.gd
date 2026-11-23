extends TestCase
## Unit-Tests für SaveSlotManager (3 Speicher-Slots) und QuestManager-Serialisierung in Lumaria.


func test_quest_manager_serialization_roundtrip() -> void:
	var q1 := QuestManager.new()
	q1.start_quest("side_lyra", "QUEST_MAIN_TITLE", "QUEST_MAIN_DESC")
	q1.advance_quest("side_lyra", "MSG_BOW_UNLOCKED")
	q1.complete_quest("main_sun_prism")

	var serialized: Dictionary = q1.serialize()
	var q2 := QuestManager.new()
	q2.deserialize(serialized)

	assert_true(q2.is_quest_completed("main_sun_prism"), "Abgeschlossene Hauptquest wiederhergestellt")
	assert_eq(q2.get_quest_state("side_lyra"), QuestManager.QuestState.ACTIVE, "Aktive Nebenquest wiederhergestellt")
	assert_eq(q2.get_active_quest_desc_key(), "MSG_BOW_UNLOCKED", "Fortschritts-Textschlüssel wiederhergestellt")


func test_three_save_slots_isolation_and_delete() -> void:
	SaveService.set_test_mode(true)
	SaveSlotManager.reset_runtime()

	# Slot 1 anlegen und Fortschritt speichern
	SaveSlotManager.start_new_slot(1)
	assert_eq(SaveSlotManager.active_slot, 1, "Slot 1 aktiv")
	assert_true(SaveSlotManager.has_slot(1), "Slot 1 existiert")
	assert_false(SaveSlotManager.has_slot(2), "Slot 2 noch leer")

	SaveSlotManager.runtime_inventory.add_lumen(140)
	SaveSlotManager.runtime_inventory.unlock_gadget("bow")
	SaveSlotManager.runtime_inventory.equip_gadget(2, "bow")
	var shrine := SaveSlotManager.get_or_init_dungeon("shrine_roots")
	shrine.add_key()
	shrine.open_chest("c_prism", "sun_prism")
	SaveSlotManager.record_prism("sun_prism")
	SaveSlotManager.save_active_slot("res://scenes/world/shrine_roots.tscn")

	# Slot 2 unabhängig anlegen
	SaveSlotManager.start_new_slot(2)
	assert_eq(SaveSlotManager.runtime_inventory.lumen, 0, "Slot 2 startet mit 0 Lumen")
	SaveSlotManager.runtime_inventory.add_lumen(25)
	SaveSlotManager.save_active_slot("res://scenes/game.tscn")

	# Slot 1 wieder laden und Vollständigkeit prüfen
	assert_true(SaveSlotManager.load_slot(1), "Slot 1 geladen")
	assert_eq(SaveSlotManager.current_scene_path, "res://scenes/world/shrine_roots.tscn", "Szene aus Slot 1 geladen")
	assert_eq(SaveSlotManager.runtime_inventory.lumen, 140, "Lumen aus Slot 1 geladen")
	assert_true(SaveSlotManager.runtime_inventory.has_gadget("bow"), "Prisma-Bogen aus Slot 1 geladen")
	assert_eq(SaveSlotManager.runtime_inventory.slot_2_gadget, "bow", "Slot 2 Gadget 'bow' erhalten")
	assert_true(SaveSlotManager.get_or_init_dungeon("shrine_roots").prism_collected, "Dungeon-Fortschritt erhalten")
	assert_eq(SaveSlotManager.runtime_prisms.size(), 1, "1 Prisma gespeichert")

	# Zusammenfassungen prüfen
	var sum1 := SaveSlotManager.get_slot_summary(1)
	assert_true(bool(sum1["exists"]), "Summary Slot 1 existiert")
	assert_eq(int(sum1["lumen"]), 140, "Summary Slot 1 Lumen stimmt")
	assert_eq(int(sum1["gadgets_count"]), 2, "Summary Slot 1 hat 2 Gadgets")
	assert_eq(int(sum1["prisms_count"]), 1, "Summary Slot 1 hat 1 Prisma")

	var sum3 := SaveSlotManager.get_slot_summary(3)
	assert_false(bool(sum3["exists"]), "Summary Slot 3 ist leer")

	# Slot 1 löschen
	SaveSlotManager.delete_slot(1)
	assert_false(SaveSlotManager.has_slot(1), "Slot 1 nach Löschen leer")
	assert_true(SaveSlotManager.has_slot(2), "Slot 2 bleibt erhalten")

	SaveSlotManager.reset_runtime()
	SaveService.set_test_mode(true)


func test_standalone_inventory_init_requires_gadgets() -> void:
	SaveService.set_test_mode(true)
	SaveSlotManager.reset_runtime()

	var inv := SaveSlotManager.get_or_init_inventory(["boomerang", "bombs", "tether"])
	assert_true(inv.has_gadget("boomerang"), "Bumerang im Standalone-Modus entsperrt")
	assert_true(inv.has_gadget("bombs"), "Bomben im Standalone-Modus entsperrt")
	assert_true(inv.has_gadget("tether"), "Fangseil im Standalone-Modus entsperrt")
	assert_eq(inv.slot_1_gadget, "boomerang", "Slot 1 Standard Bumerang")
	assert_eq(inv.slot_2_gadget, "bombs", "Slot 2 Standard Bomben")

	SaveSlotManager.reset_runtime()
