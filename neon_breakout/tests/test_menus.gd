extends TestCase
## Tests für Menü-Bildschirme: Lautstärke-Umrechnung, Credits-Daten, Szenen bauen sich auf.


func test_volume_to_db() -> void:
	assert_almost(AudioSettings.volume_to_db(1.0), 0.0, "volle Lautstärke = 0 dB")
	assert_almost(AudioSettings.volume_to_db(0.5), -6.0206, "halbe Lautstärke", 0.01)
	assert_eq(AudioSettings.volume_to_db(0.0), AudioSettings.MIN_DB, "0 ist stumm")
	assert_eq(AudioSettings.volume_to_db(-3.0), AudioSettings.MIN_DB, "negativ wird begrenzt")
	assert_almost(AudioSettings.volume_to_db(7.0), 0.0, "über 1 wird begrenzt")


func test_set_volume_clamps_and_applies() -> void:
	AudioSettings.ensure_sfx_bus()
	var old: float = AudioSettings.get_volume(AudioSettings.SFX)
	AudioSettings.set_volume(AudioSettings.SFX, 2.0, false)
	assert_almost(AudioSettings.get_volume(AudioSettings.SFX), 1.0, "begrenzt auf 1")
	AudioSettings.set_volume(AudioSettings.SFX, 0.25, false)
	var index := AudioServer.get_bus_index(AudioSettings.SFX_BUS)
	assert_true(index != -1, "Sfx-Bus existiert")
	assert_almost(AudioServer.get_bus_volume_db(index), AudioSettings.volume_to_db(0.25), "Bus-Lautstärke gesetzt", 0.01)
	AudioSettings.set_volume(&"unknown", 0.1, false)
	AudioSettings.set_volume(AudioSettings.SFX, old, false)


func test_credits_entries_are_complete() -> void:
	assert_true(CreditsData.ENTRIES.size() > 0, "Credits nicht leer")
	for entry in CreditsData.ENTRIES:
		assert_true(entry.has("name") and entry.has("author") and entry.has("license"), "Felder vorhanden")
		assert_true(CreditsData.format_entry(entry).length() > 3, "Zeile nicht leer")
	var fonts := CreditsData.format_entry(CreditsData.ENTRIES[0])
	assert_true(fonts.contains("Indian Type Foundry") and fonts.contains("OFL") or fonts.contains("Open Font"), "Schrift mit Autor und Lizenz")


func test_screens_instantiate() -> void:
	for path in ["res://scenes/options.tscn", "res://scenes/credits.tscn", "res://scenes/main_menu.tscn"]:
		var scene: Control = (load(path) as PackedScene).instantiate()
		assert_true(scene != null, path + " instanziiert")
		scene.free()
