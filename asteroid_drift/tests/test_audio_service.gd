extends TestCase
## Unit-Tests für SharedSynthMusic, AudioService und das F3-Debug-Overlay in DisplayService.


func test_synth_music_themes_are_valid_seamless_loops() -> void:
	for theme_name: String in ["space", "lounge", "puzzle", "meadow", "crypt"]:
		var stream := SharedSynthMusic.create_theme(theme_name)
		assert_true(stream != null, "Theme '%s' erzeugt Stream" % theme_name)
		assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "Theme '%s' loopt vorwärts" % theme_name)
		assert_eq(stream.mix_rate, SharedSynthMusic.SAMPLE_RATE, "Sample-Rate 22050")
		assert_true(stream.loop_end > 0, "Theme '%s' hat gültiges Loop-Ende" % theme_name)
		assert_true(stream.data.size() == stream.loop_end * 2, "Theme '%s' Datengröße passt zu 16-bit Samples" % theme_name)


func test_synth_music_tones_and_sweeps() -> void:
	for wave: String in ["sine", "triangle", "square", "noise"]:
		var tone := SharedSynthMusic.create_tone(440.0, 0.08, 0.25, wave)
		assert_true(tone != null, "Ton '%s' erzeugt Stream" % wave)
		assert_eq(tone.loop_mode, AudioStreamWAV.LOOP_DISABLED, "Effektton '%s' loopt nicht" % wave)
		assert_true(tone.data.size() > 100, "Ton '%s' hat Audiodaten" % wave)
	var sweep := SharedSynthMusic.create_tone(600.0, 0.12, 0.3, "sine", 180.0)
	assert_true(sweep != null and sweep.data.size() > 100, "Sweep-Ton erzeugt Audiodaten")


func test_audio_service_volume_conversion_and_cycling() -> void:
	assert_true(AudioService.volume_to_db(0.0) <= -79.9, "0.0 entspricht stumm")
	assert_almost(AudioService.volume_to_db(1.0), 0.0, "1.0 entspricht 0 dB")
	assert_true(AudioService.volume_to_db(0.5) < 0.0 and AudioService.volume_to_db(0.5) > -10.0, "0.5 ist moderat gedämpft")

	AudioService.set_volume("Music", 1.0, false)
	assert_almost(AudioService.cycle_volume("Music"), 0.7, "Zyklus 1.0 -> 0.7")
	assert_almost(AudioService.cycle_volume("Music"), 0.4, "Zyklus 0.7 -> 0.4")
	assert_almost(AudioService.cycle_volume("Music"), 0.0, "Zyklus 0.4 -> 0.0")
	assert_eq(
		AudioService.format_volume_label("COMMON_VOLUME_MUSIC", "Music"),
		"%s: %s" % [tr("COMMON_VOLUME_MUSIC"), tr("COMMON_AUDIO_OFF")],
		"Stumm-Label verwendet COMMON_AUDIO_OFF"
	)
	assert_almost(AudioService.cycle_volume("Music"), 1.0, "Zyklus 0.0 -> 1.0")
	assert_eq(
		AudioService.format_volume_label("COMMON_VOLUME_MUSIC", "Music"),
		"%s: 100%%" % tr("COMMON_VOLUME_MUSIC"),
		"100%-Label formatiert korrekt"
	)
	AudioService.set_volume("Music", 0.7, false)


func test_display_service_debug_overlay_toggle() -> void:
	assert_true(not DisplayService.is_debug_overlay_visible(), "Debug-Overlay initial aus")
	DisplayService.set_debug_overlay(true)
	assert_true(DisplayService.is_debug_overlay_visible(), "Debug-Overlay eingeschaltet")
	DisplayService.set_debug_overlay(false)
	assert_true(not DisplayService.is_debug_overlay_visible(), "Debug-Overlay wieder aus")


func test_shared_splash_screen_localization_and_dynamic_branding() -> void:
	var prev_lang := LocaleService.current
	var splash := (load("res://scenes/splash_screen.tscn") as PackedScene).instantiate() as SharedSplashScreen
	assert_true(splash != null, "SplashScreen instanziiert")
	splash._ready()

	LocaleService.set_language("de", false)
	assert_true("Taste" in splash.get_prompt_text(), "Deutscher Start-Prompt aktiv")
	assert_eq(splash.get_brand_text(), "Präsentiert von Chii Arcade", "Deutsches Chii-Arcade-Badge aktiv")

	LocaleService.set_language("en", false)
	assert_true("Press any key" in splash.get_prompt_text(), "Englischer Start-Prompt aktiv")
	assert_eq(splash.get_brand_text(), "Powered by Chii Arcade", "Englisches Chii-Arcade-Badge aktiv")

	splash.set_brand_name_override("Chii Studio")
	assert_eq(splash.get_brand_text(), "Powered by Chii Studio", "Markenname dynamisch anpassbar")

	LocaleService.set_language(prev_lang, false)
	splash._exit_tree()
	splash.free()


func test_shared_touch_controls_visibility_and_actions() -> void:
	# 1. Auf dem PC (Linux/Windows) muss das Touch-Overlay standardmäßig unsichtbar und inaktiv sein
	var tc_pc := SharedTouchControls.create_for_asteroid_drift(false)
	tc_pc._ready()
	assert_true(not tc_pc.is_active(), "Touch-UI auf PC standardmäßig inaktiv")
	assert_true(not tc_pc.visible, "Touch-UI auf PC standardmäßig unsichtbar")
	tc_pc._exit_tree()
	tc_pc.free()

	# 2. Mit force=true (Android-Simulation) sind alle 4 Presets aktiv und steuern Aktionen
	var tc_ad := SharedTouchControls.create_for_asteroid_drift(true)
	tc_ad._ready()
	assert_true(tc_ad.is_active() and tc_ad.visible, "Asteroid-Drift-Touch-UI bei Android aktiv")
	assert_eq(tc_ad.get_button_count(), 6, "Asteroid Drift hat 6 Touch-Buttons")
	assert_true(tc_ad.simulate_button_press("thrust"), "Thrust-Button drückbar")
	assert_true(Input.is_action_pressed("thrust"), "Thrust-Action via Touch aktiv")
	assert_true(tc_ad.simulate_button_release("thrust"), "Thrust-Button lösbar")
	assert_true(not Input.is_action_pressed("thrust"), "Thrust-Action nach Release inaktiv")
	tc_ad._exit_tree()
	tc_ad.free()

	var tc_bs := SharedTouchControls.create_for_block_stack(true)
	tc_bs._ready()
	assert_eq(tc_bs.get_button_count(), 8, "Block Stack hat 8 Touch-Buttons")
	assert_true(tc_bs.has_action_button("hard_drop") and tc_bs.has_action_button("hold"), "Block Stack hat Drop & Hold")
	tc_bs._exit_tree()
	tc_bs.free()

	var tc_cd := SharedTouchControls.create_for_crypt_dash(true)
	tc_cd._ready()
	assert_eq(tc_cd.get_stick_count(), 2, "Crypt Dash hat 2 virtuelle Twin-Sticks")
	assert_eq(tc_cd.get_button_count(), 2, "Crypt Dash hat Dash- & Pause-Buttons")
	var aim_state := {"vec": Vector2.ZERO}
	tc_cd.aim_vector_changed.connect(func(v: Vector2, _act: bool) -> void: aim_state["vec"] = v)
	assert_true(tc_cd.simulate_stick_drag("aim", Vector2(1.0, 0.0)), "Aim-Stick ziehbar")
	assert_almost((aim_state["vec"] as Vector2).x, 1.0, "Aim-Stick liefert Zielvektor nach rechts")
	tc_cd.simulate_stick_release("aim")
	tc_cd._exit_tree()
	tc_cd.free()

	var tc_lu := SharedTouchControls.create_for_lumaria(true)
	tc_lu._ready()
	assert_eq(tc_lu.get_stick_count(), 1, "Lumaria hat 1 Bewegungs-Stick")
	assert_eq(tc_lu.get_button_count(), 8, "Lumaria hat 8 Aktions-/Menü-Buttons")
	assert_true(tc_lu.has_action_button("attack") and tc_lu.has_action_button("gadget_1") and tc_lu.has_action_button("inventory"), "Lumaria-Buttons komplett")
	tc_lu._exit_tree()
	tc_lu.free()
