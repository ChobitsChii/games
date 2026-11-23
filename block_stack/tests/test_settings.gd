extends TestCase
## Tests für HandlingSettings (DAS, ARR, Farbblind-Modus) in Block Stack.


func test_das_and_arr_preset_cycling() -> void:
	assert_eq(HandlingSettings.next_das_ms(100), 130, "DAS 100 -> 130")
	assert_eq(HandlingSettings.next_das_ms(170), 200, "DAS 170 -> 200")
	assert_eq(HandlingSettings.next_das_ms(240), 100, "DAS 240 -> 100 (Wrap)")

	assert_eq(HandlingSettings.next_arr_ms(0), 20, "ARR 0 -> 20")
	assert_eq(HandlingSettings.next_arr_ms(50), 80, "ARR 50 -> 80")
	assert_eq(HandlingSettings.next_arr_ms(80), 0, "ARR 80 -> 0 (Wrap)")


func test_settings_persistence_in_test_mode() -> void:
	HandlingSettings.set_das_ms(130)
	assert_eq(HandlingSettings.get_das_ms(), 130, "DAS als ms gelesen")
	assert_almost(float(SaveService.get_value("handling", "das", 0.0)), 0.13, "DAS als Sekunden gespeichert")

	HandlingSettings.set_arr_ms(0)
	assert_eq(HandlingSettings.get_arr_ms(), 0, "ARR 0 ms gelesen")
	assert_almost(float(SaveService.get_value("handling", "arr", 1.0)), 0.0, "ARR 0.0 s gespeichert")

	HandlingSettings.set_colorblind(true)
	assert_true(HandlingSettings.is_colorblind(), "Farbblind-Modus aktiviert")
	HandlingSettings.set_colorblind(false)
	assert_false(HandlingSettings.is_colorblind(), "Farbblind-Modus wieder deaktiviert")

	HandlingSettings.set_das_ms(roundi(StackConfig.DEFAULT_DAS * 1000.0))
	HandlingSettings.set_arr_ms(roundi(StackConfig.DEFAULT_ARR * 1000.0))
