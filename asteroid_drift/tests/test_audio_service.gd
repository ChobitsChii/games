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
