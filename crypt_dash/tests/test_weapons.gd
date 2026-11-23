extends TestCase
## Tests für das Startwaffen-System (WeaponCatalog) in Crypt Dash.


func test_weapon_catalog_has_three_weapons() -> void:
	var weapons := WeaponCatalog.get_all()
	assert_eq(weapons.size(), 3, "Genau 3 Startwaffen vorhanden")
	assert_eq(str(weapons[0]["id"]), "daggers", "Basiswaffe ist daggers")
	assert_true(WeaponCatalog.is_unlocked("daggers"), "Schattendolche sind immer frei")


func test_buy_and_equip_weapons() -> void:
	SaveService.set_value("crypt_dash", "souls", 15)
	SaveService.set_value("crypt_dash", "weapons_unlocked", ["daggers"])
	SaveService.set_value("crypt_dash", "weapon_equipped", "daggers")

	assert_false(WeaponCatalog.try_buy_or_equip("arcane_staff"), "Arkanstab zu teuer bei 15 Seelen")
	assert_eq(WeaponCatalog.get_equipped_id(), "daggers", "Dolche bleiben ausgerüstet")

	assert_true(WeaponCatalog.try_buy_or_equip("twin_fangs"), "Zwillingsklingen für 12 Seelen gekauft")
	assert_eq(int(SaveService.get_value("crypt_dash", "souls", -1)), 3, "3 Seelen verbleiben")
	assert_true(WeaponCatalog.is_unlocked("twin_fangs"), "Zwillingsklingen sind freigeschaltet")
	assert_eq(WeaponCatalog.get_equipped_id(), "twin_fangs", "Zwillingsklingen sind ausgerüstet")

	# Kostenlos zurückwechseln
	assert_true(WeaponCatalog.try_buy_or_equip("daggers"), "Zurückwechseln auf Dolche")
	assert_eq(WeaponCatalog.get_equipped_id(), "daggers", "Dolche aktiv")


func test_weapon_stat_modifiers() -> void:
	var base := PlayerStatsCalculator.calculate_stats([])
	var staff_stats := WeaponCatalog.apply_weapon_to_stats(base, "arcane_staff")
	assert_almost(float(staff_stats["damage"]), float(base["damage"]) * 1.85, "Arkanstab erhöht Schaden um 85%")
	assert_almost(float(staff_stats["attack_rate"]), float(base["attack_rate"]) * 0.65, "Arkanstab senkt Feuerrate")

	var twin_stats := WeaponCatalog.apply_weapon_to_stats(base, "twin_fangs")
	assert_almost(float(twin_stats["attack_rate"]), float(base["attack_rate"]) * 1.5, "Zwillingsklingen erhöhen Feuerrate")
