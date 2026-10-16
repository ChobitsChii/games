extends TestCase
## Prüft die Sound-Synthese: Längen, Pegel und Streams. Ohne Audiogerät lauffähig.


func test_tone_length_matches_duration() -> void:
	var samples := SfxSynth.tone(SfxSynth.Wave.SINE, 440.0, 440.0, 0.1)
	assert_eq(samples.size(), int(0.1 * SfxSynth.SAMPLE_RATE), "Länge")


func test_tone_is_audible_and_never_clips() -> void:
	for wave in [SfxSynth.Wave.SINE, SfxSynth.Wave.TRIANGLE, SfxSynth.Wave.SQUARE, SfxSynth.Wave.NOISE]:
		var samples := SfxSynth.tone(wave, 300.0, 600.0, 0.1, 0.5, 0.004, 2.0, 0.4)
		var peak := SfxSynth.peak(samples)
		assert_true(peak > 0.05, "Welle %d ist hörbar (Pegel %f)" % [wave, peak])
		assert_true(peak <= 0.5 + 0.001, "Welle %d übersteuert nicht (Pegel %f)" % [wave, peak])


func test_tone_fades_out() -> void:
	var samples := SfxSynth.tone(SfxSynth.Wave.SINE, 440.0, 440.0, 0.2, 0.5, 0.004, 2.0)
	var tail := samples.slice(samples.size() - 50)
	assert_true(SfxSynth.peak(tail) < 0.01, "Ende ist (fast) still, kein Knacken")


func test_sequence_length_is_sum_of_notes() -> void:
	var samples := SfxSynth.sequence([440.0, 550.0, 660.0], 0.1)
	assert_eq(samples.size(), 3 * int(0.1 * SfxSynth.SAMPLE_RATE), "Länge")


func test_mix_uses_longer_length() -> void:
	var short := SfxSynth.tone(SfxSynth.Wave.SINE, 440.0, 440.0, 0.05)
	var long := SfxSynth.tone(SfxSynth.Wave.SINE, 440.0, 440.0, 0.15)
	assert_eq(SfxSynth.mix(short, long).size(), long.size(), "mix")


func test_to_stream_format() -> void:
	var samples := SfxSynth.tone(SfxSynth.Wave.TRIANGLE, 500.0, 400.0, 0.1)
	var stream := SfxSynth.to_stream(samples)
	assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, "Format")
	assert_eq(stream.mix_rate, SfxSynth.SAMPLE_RATE, "Abtastrate")
	assert_true(not stream.stereo, "mono")
	assert_eq(stream.data.size(), samples.size() * 2, "2 Byte pro Sample")


func test_to_stream_clamps_loud_input() -> void:
	var stream := SfxSynth.to_stream(PackedFloat32Array([5.0, -5.0]))
	assert_eq(stream.data.decode_s16(0), 32767, "oben begrenzt")
	assert_eq(stream.data.decode_s16(2), -32767, "unten begrenzt")
