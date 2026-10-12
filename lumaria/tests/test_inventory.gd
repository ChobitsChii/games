extends TestCase
## Tests für Inventar-, Lebens- und Ausrüstungs-Modell in Lumaria.


func test_initial_vitality_state() -> void:
	var inv := InventoryModel.new()
	assert_eq(inv.max_vitality_quarters, 12, "Start mit 12 Vierteln (3 volle Sphären)")
	assert_eq(inv.current_vitality_quarters, 12, "Volle Gesundheit zu Beginn")
	assert_true(inv.is_alive(), "Spieler lebt")
	assert_true(inv.is_full_health(), "Volle Gesundheit")


func test_damage_and_healing() -> void:
	var inv := InventoryModel.new()
	var died_state := [false]
	inv.died.connect(func() -> void: died_state[0] = true)

	var dead: bool = inv.take_damage(4) # 1 Sphäre Schaden
	assert_false(dead, "Noch am Leben")
	assert_eq(inv.current_vitality_quarters, 8, "Noch 8 Viertel übrig")

	var gained: int = inv.heal(2)
	assert_eq(gained, 2, "2 Viertel geheilt")
	assert_eq(inv.current_vitality_quarters, 10, "10 Viertel nach Heilung")

	# Überheilung wird gedeckelt
	var over: int = inv.heal(20)
	assert_eq(inv.current_vitality_quarters, 12, "Auf Maximum gedeckelt")
	assert_eq(over, 2, "Nur bis zum Maximum geheilt")

	# Tödlicher Schaden
	var lethal: bool = inv.take_damage(12)
	assert_true(lethal, "Tödlicher Schaden")
	assert_eq(inv.current_vitality_quarters, 0, "0 HP")
	assert_true(died_state[0], "Died-Signal ausgelöst")


func test_sphere_fragments_expand_max_health() -> void:
	var inv := InventoryModel.new()
	inv.take_damage(4) # Jetzt bei 8/12

	assert_false(inv.add_sphere_fragment(), "Fragment 1/4")
	assert_false(inv.add_sphere_fragment(), "Fragment 2/4")
	assert_false(inv.add_sphere_fragment(), "Fragment 3/4")
	assert_eq(inv.max_vitality_quarters, 12, "Noch nicht erweitert")

	var completed: bool = inv.add_sphere_fragment()
	assert_true(completed, "4. Fragment vollendet neue Sphäre")
	assert_eq(inv.max_vitality_quarters, 16, "Erweitert auf 16 Viertel (4 volle Sphären)")
	assert_eq(inv.current_vitality_quarters, 12, "Lebensenergie um 4 Viertel bei Erweiterung geheilt")
	assert_eq(inv.sphere_fragments, 0, "Fragmente wieder auf 0 zurückgesetzt")


func test_lumen_currency_transactions() -> void:
	var inv := InventoryModel.new()
	assert_eq(inv.lumen, 0, "Start mit 0 Lumen")

	inv.add_lumen(50)
	assert_eq(inv.lumen, 50, "50 Lumen gesammelt")

	var spent_ok: bool = inv.spend_lumen(30)
	assert_true(spent_ok, "Kauf erfolgreich")
	assert_eq(inv.lumen, 20, "20 Lumen verbleiben")

	var spent_fail: bool = inv.spend_lumen(50)
	assert_false(spent_fail, "Nicht genug Lumen")
	assert_eq(inv.lumen, 20, "Lumen unverändert nach fehlgeschlagenem Kauf")


func test_gadget_unlock_and_equip() -> void:
	var inv := InventoryModel.new()
	inv.unlock_gadget("boomerang")
	inv.unlock_gadget("tether")

	assert_eq(inv.unlocked_gadgets.size(), 2, "2 Gadgets freigeschaltet")
	assert_eq(inv.slot_1_gadget, "boomerang", "Automatisch Slot 1 belegt")
	assert_eq(inv.slot_2_gadget, "tether", "Automatisch Slot 2 belegt")

	# Slot wechseln
	assert_true(inv.equip_gadget(1, "tether"), "Tether auf Slot 1 gelegt")
	assert_eq(inv.slot_1_gadget, "tether", "Slot 1 ist nun Tether")
	assert_false(inv.equip_gadget(1, "bombs"), "Nicht freigeschaltetes Gadget kann nicht ausgerüstet werden")


func test_serialization_roundtrip() -> void:
	var inv1 := InventoryModel.new()
	inv1.take_damage(3)
	inv1.add_sphere_fragment()
	inv1.add_lumen(125)
	inv1.sword_tier = 2
	inv1.small_keys = 3
	inv1.has_boss_key = true
	inv1.unlock_gadget("boomerang")
	inv1.unlock_gadget("bombs")

	var data: Dictionary = inv1.serialize()

	var inv2 := InventoryModel.new()
	inv2.deserialize(data)

	assert_eq(inv2.current_vitality_quarters, 9, "HP wiederhergestellt")
	assert_eq(inv2.sphere_fragments, 1, "Fragmente wiederhergestellt")
	assert_eq(inv2.lumen, 125, "Lumen wiederhergestellt")
	assert_eq(inv2.sword_tier, 2, "Schwertstufe wiederhergestellt")
	assert_eq(inv2.small_keys, 3, "Schlüssel wiederhergestellt")
	assert_true(inv2.has_boss_key, "Bossschlüssel wiederhergestellt")
	assert_eq(inv2.unlocked_gadgets.size(), 2, "Gadgets wiederhergestellt")
