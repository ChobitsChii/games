extends TestCase
## Testet das Item-System und die Berechnung von Spieler-Attributen:
## 1. Alle 15 Items existieren und haben gültige Übersetzungsschlüssel
## 2. Modifikatoren stapeln additiv und multiplikativ korrekt
## 3. Meta-Upgrades erhöhen Werte vorschriftsmäßig
## 4. Zufallsauswahl filtert ausgeschlossene Items

func test_item_catalog_complete() -> void:
	var items := ItemCatalog.get_all_items()
	assert_eq(items.size(), 15, "Genau 15 Items im Katalog")
	var ids: Dictionary = {}
	for it in items:
		assert_true(it.id != "", "Item hat ID")
		assert_false(ids.has(it.id), "Keine doppelten Item IDs: " + it.id)
		ids[it.id] = true
		assert_true(it.name_key.begins_with("ITEM_"), "Name-Key beginnt mit ITEM_")
		assert_true(it.desc_key.begins_with("ITEM_"), "Desc-Key beginnt mit ITEM_")


func test_stat_calculation_stacking() -> void:
	# Basiswerte prüfen
	var base_stats := PlayerStatsCalculator.calculate_stats([])
	assert_eq(base_stats["max_hp"], 12.0, "Basis HP ist 12")
	assert_eq(base_stats["speed"], 420.0, "Basis Speed ist 420")
	assert_eq(base_stats["damage"], 1.0, "Basis Damage ist 1")
	assert_eq(base_stats["dash_charges"], 1.0, "Basis Dash Charges ist 1")

	# Items hinzufügen
	var boots := ItemData.create("boots", "", "", {}, {"speed": 1.25})
	var dash_extra := ItemData.create("dash_extra", "", "", {"dash_charges": 1.0}, {})
	var heavy := ItemData.create("heavy", "", "", {}, {"damage": 1.5})
	var heart := ItemData.create("heart", "", "", {"max_hp": 4.0}, {})

	var modified_stats := PlayerStatsCalculator.calculate_stats([boots, dash_extra, heavy, heart])
	assert_almost(modified_stats["speed"], 420.0 * 1.25, "Speed mit Boots korrekt")
	assert_almost(modified_stats["damage"], 1.0 * 1.5, "Damage mit Heavy korrekt")
	assert_eq(modified_stats["dash_charges"], 2.0, "Dash charges 2")
	assert_eq(modified_stats["max_hp"], 16.0, "Max HP um 4 erhöht")


func test_meta_upgrades_stacking() -> void:
	var meta := {
		"max_hp": 2,      # +4 HP
		"damage": 1,      # +20%
		"speed": 1,       # +15%
		"dash_cd": 1,     # -20%
	}
	var stats := PlayerStatsCalculator.calculate_stats([], meta)
	assert_eq(stats["max_hp"], 16.0, "Meta HP korrekt")
	assert_almost(stats["damage"], 1.20, "Meta Damage korrekt")
	assert_almost(stats["speed"], 420.0 * 1.15, "Meta Speed korrekt")
	assert_almost(stats["dash_cooldown"], 0.8 * 0.8, "Meta Dash CD korrekt")


func test_random_item_selection() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var picks := ItemCatalog.get_random_selection(rng, 3, ["boots", "dash_extra"])
	assert_eq(picks.size(), 3, "3 Items gewählt")
	for p in picks:
		assert_false(p.id == "boots", "boots ausgeschlossen")
		assert_false(p.id == "dash_extra", "dash_extra ausgeschlossen")
