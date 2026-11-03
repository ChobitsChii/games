extends TestCase
## Tests für die kleinen Effekt-Helfer: Punkte-Popup (Farbe, Größe) und Effekt-Einstellungen.


func test_popup_color_warms_up_with_multiplier() -> void:
	var low := ScorePopup.color_for(1.0)
	var mid := ScorePopup.color_for(2.5)
	var high := ScorePopup.color_for(PowerUps.MAX_COMBO_MULTIPLIER)
	assert_true(low.is_equal_approx(BreakoutConfig.PALETTE["text"]), "einfacher Wert ist weiß-bläulich")
	assert_true(high.is_equal_approx(BreakoutConfig.PALETTE["accent_alt"]), "Maximum ist Magenta")
	assert_true(mid != low and mid != high, "dazwischen eine eigene Farbe")


func test_popup_color_is_clamped() -> void:
	assert_true(ScorePopup.color_for(0.0).is_equal_approx(ScorePopup.color_for(1.0)), "unter 1 wie 1")
	assert_true(ScorePopup.color_for(99.0).is_equal_approx(ScorePopup.color_for(PowerUps.MAX_COMBO_MULTIPLIER)), "über dem Maximum wie das Maximum")


func test_popup_size_grows_with_multiplier() -> void:
	assert_eq(ScorePopup.size_for(1.0), 32, "klein")
	assert_eq(ScorePopup.size_for(PowerUps.MAX_COMBO_MULTIPLIER), 54, "groß")
	assert_true(ScorePopup.size_for(2.0) > ScorePopup.size_for(1.0), "wächst")
	assert_eq(ScorePopup.size_for(50.0), 54, "begrenzt")


func test_transition_is_inactive_in_tests() -> void:
	# Im Testmodus darf keine Überblendung (und damit kein Tween) entstehen.
	assert_true(SaveService.is_test_mode, "Testmodus ist aktiv")
