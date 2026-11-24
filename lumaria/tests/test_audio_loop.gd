extends TestCase
## Unit-Tests für Lumarias prozedurale AudioStreamWAV-Musikloops und Guard-Frames.


func test_lumaria_music_loops_have_guard_frames_and_wrap_cleanly() -> void:
	var expected_frames := int(22050 * 4.0)
	for track_name: String in ["village", "dungeon", "boss", "victory"]:
		var stream: AudioStreamWAV = AudioManager._get_or_create_music_stream(track_name)
		assert_true(stream != null, "Track '%s' erzeugt Stream" % track_name)
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, "Track '%s' ist 16-bit" % track_name)
		assert_eq(stream.mix_rate, 22050, "Track '%s' nutzt 22050 Hz" % track_name)
		assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "Track '%s' loopt vorwärts" % track_name)
		assert_eq(stream.loop_begin, 0, "Track '%s' Loop-Beginn ist 0" % track_name)
		assert_eq(stream.loop_end, expected_frames - 1, "Track '%s' Loop-Ende liegt strikt im Puffer" % track_name)
		assert_eq(
			stream.data.size(),
			(expected_frames + AudioManager.MUSIC_GUARD_FRAMES) * 2,
			"Track '%s' Datengröße inklusive Guard-Frames" % track_name
		)
		for g in range(AudioManager.MUSIC_GUARD_FRAMES):
			assert_eq(
				stream.data.decode_s16((expected_frames + g) * 2),
				stream.data.decode_s16(g * 2),
				"Track '%s' Guard-Sample %d stimmt mit Loop-Start überein" % [track_name, g]
			)

		var pb := stream.instantiate_playback()
		assert_true(pb != null, "Playback für '%s' instanziiert" % track_name)
		pb.start(0.0)
		var max_after_wrap := 0.0
		for step in range(250): # ~5.33 s bei 48 kHz (über den 4.0s-Loop-Punkt hinaus)
			var buf := pb.mix_audio(44100.0 / 48000.0, 1024)
			assert_true(pb.is_playing(), "Track '%s' spielt bei Schritt %d weiter" % [track_name, step])
			if step >= 210:
				for frame in buf:
					max_after_wrap = maxf(max_after_wrap, absf(frame.x))
		assert_true(max_after_wrap > 0.01, "Track '%s' liefert Audio nach 4s-Loop-Wrap" % track_name)
		pb.stop()
