extends TestCase
## Prüft Komposition und Renderer der Hintergrundmusik. Der volle Render dauert
## ein bis zwei Sekunden und läuft daher nur einmal (Ergebnis wird zwischengespeichert).

var _renderer: MusicRenderer
var _stream: AudioStreamWAV


func _render_once() -> void:
	if _renderer != null:
		return
	_renderer = MusicRenderer.new()
	_stream = _renderer.render_all()


func test_loop_length_is_whole_bars() -> void:
	var frames := MusicSynth.total_frames()
	assert_eq(frames, 378000, "8 Takte bei 112 BPM und 22050 Hz")
	assert_almost(MusicSynth.beat_samples() * MusicSynth.BEATS, float(frames), "Takt-Länge passt", 0.6)


func test_event_counts() -> void:
	var events := MusicSynth.build_events()
	assert_eq(MusicSynth.count_kind(events, MusicSynth.Kind.KICK), 32, "Bassdrum auf jedem Schlag")
	assert_eq(MusicSynth.count_kind(events, MusicSynth.Kind.HAT), 32, "Hi-Hat auf jedem Gegenschlag")
	assert_eq(MusicSynth.count_kind(events, MusicSynth.Kind.BASS), 64, "Bass in Achteln")
	var arp_notes := (MusicSynth.BEATS * 4 - MusicSynth.ARP_START_BAR * 16) * 2
	assert_eq(MusicSynth.count_kind(events, MusicSynth.Kind.ARP), arp_notes, "Arpeggio mit Echo ab Takt 3")
	assert_true(MusicSynth.count_kind(events, MusicSynth.Kind.PAD) > 0, "Akkord-Teppich vorhanden")


func test_events_have_valid_fields() -> void:
	for e: Dictionary in MusicSynth.build_events():
		assert_true(e["length"] > 0, "Länge > 0")
		assert_true(e["seg_from"] >= 0 and e["seg_to"] <= e["length"] and e["seg_from"] < e["seg_to"], "Teilstück liegt im Ereignis")
		assert_true(e["vol"] > 0.0 and e["vol"] < 1.0, "Lautstärke plausibel")
		if e["kind"] in [MusicSynth.Kind.BASS, MusicSynth.Kind.ARP, MusicSynth.Kind.PAD]:
			assert_true(e["freq"] > 30.0 and e["freq"] < 2000.0, "Tonhöhe plausibel (%f)" % e["freq"])


func test_pad_segments_cover_the_whole_note() -> void:
	var covered := {}
	var lengths := {}
	for e: Dictionary in MusicSynth.build_events():
		if e["kind"] != MusicSynth.Kind.PAD:
			continue
		var key := "%d_%f" % [e["start"], e["freq"]]
		covered[key] = covered.get(key, 0) + (e["seg_to"] - e["seg_from"])
		lengths[key] = e["length"]
	assert_eq(covered.size(), MusicSynth.CHORDS.size() * 3, "12 Padtöne")
	for key: String in covered:
		assert_eq(covered[key], lengths[key], "Teilstücke ergeben die ganze Note")


func test_midi_to_hz() -> void:
	assert_almost(MusicSynth.midi_to_hz(69), 440.0, "A4")
	assert_almost(MusicSynth.midi_to_hz(57), 220.0, "A3", 0.01)
	assert_almost(MusicSynth.midi_to_hz(81), 880.0, "A5", 0.01)


func test_rendered_stream_format_and_loop() -> void:
	_render_once()
	var frames := MusicSynth.total_frames()
	assert_true(_stream != null, "Stream vorhanden")
	assert_eq(_stream.format, AudioStreamWAV.FORMAT_16_BITS, "Format")
	assert_eq(_stream.mix_rate, MusicSynth.RATE, "Abtastrate")
	assert_eq(_stream.data.size(), frames * 2, "Datenmenge")
	assert_eq(_stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "Schleife")
	assert_eq(_stream.loop_end, frames, "Schleifenende")


func test_rendered_music_is_audible_and_not_clipping() -> void:
	_render_once()
	assert_true(_renderer.peak() > 0.3, "Mix ist nicht leise (%f)" % _renderer.peak())
	var loudest := 0
	var sum_squares := 0.0
	for i in range(0, _stream.data.size(), 2):
		var value := absi(_stream.data.decode_s16(i))
		loudest = maxi(loudest, value)
		sum_squares += float(value) * float(value)
	assert_true(loudest <= 32767, "kein Übersteuern")
	assert_true(loudest > 0.8 * 32767.0 * MusicRenderer.TARGET_PEAK, "auf Zielpegel normalisiert")
	var rms := sqrt(sum_squares / (_stream.data.size() / 2.0)) / 32767.0
	assert_true(rms > 0.05 and rms < 0.5, "Durchschnittspegel plausibel (%f)" % rms)


func test_loop_boundary_is_smooth() -> void:
	_render_once()
	var mixed := _renderer.mixed()
	var scale := MusicRenderer.TARGET_PEAK / _renderer.peak()
	var jump := absf(mixed[0] - mixed[mixed.size() - 1]) * scale
	assert_true(jump < 0.25, "kein Knacken beim Loop-Übergang (Sprung %f)" % jump)
	# Verglichen mit einem typischen Schritt im Inneren ist der Sprung nicht auffällig groß.
	var biggest_inner := 0.0
	for i in range(1000, 6000):
		biggest_inner = maxf(biggest_inner, absf(mixed[i] - mixed[i - 1]) * scale)
	assert_true(jump < biggest_inner * 3.0 + 0.05, "Übergang ähnlich glatt wie das Innere")


func test_music_has_rhythm() -> void:
	# Auf dem Schlag (Bassdrum) ist es lauter als kurz davor.
	_render_once()
	var mixed := _renderer.mixed()
	var beat := int(MusicSynth.beat_samples())
	var on_beat := 0.0
	var before_beat := 0.0
	for k in range(4, 12):
		var at := k * beat
		for i in range(at, at + 600):
			on_beat = maxf(on_beat, absf(mixed[i]))
		for i in range(at - 900, at - 300):
			before_beat = maxf(before_beat, absf(mixed[i]))
	assert_true(on_beat > before_beat, "Schlag ist lauter als die Pause davor (%f > %f)" % [on_beat, before_beat])


func test_progress_reaches_one() -> void:
	var renderer := MusicRenderer.new()
	assert_almost(renderer.progress(), 0.0, "Start")
	assert_true(not renderer.step(1000), "mit kleinem Budget noch nicht fertig")
	assert_true(renderer.progress() > 0.0 and renderer.progress() < 1.0, "unterwegs")
