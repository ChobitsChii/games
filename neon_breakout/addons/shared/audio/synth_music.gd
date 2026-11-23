class_name SharedSynthMusic
extends RefCounted
## Prozedural synthetisierte nahtlose Musik-Loops und Sound-Effekt-Töne.
## Alle Musik-Themen sind phasenrein auf 4.0 Sekunden ausgerichtet (22050 Hz, 16-bit Mono WAV).

const SAMPLE_RATE := 22050
const LOOP_DURATION := 4.0


static func _snap_freq(hz: float) -> float:
	return maxf(0.25, roundf(hz * LOOP_DURATION) / LOOP_DURATION)


## Erzeugt einen 4-Sekunden nahtlosen Loop für das jeweilige Spiel-Thema.
static func create_theme(theme_name: String) -> AudioStreamWAV:
	var num_samples := int(SAMPLE_RATE * LOOP_DURATION)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	match theme_name:
		"space":
			var d2 := _snap_freq(73.42)
			var a2 := _snap_freq(110.0)
			var f3 := _snap_freq(174.61)
			var c4 := _snap_freq(261.63)
			var arp_freqs: Array[float] = [
				_snap_freq(293.66), _snap_freq(349.23), _snap_freq(440.0), _snap_freq(523.25),
				_snap_freq(440.0), _snap_freq(349.23), _snap_freq(329.63), _snap_freq(293.66),
			]
			for i in range(num_samples):
				var t := float(i) / float(SAMPLE_RATE)
				var swell := 0.8 + 0.2 * sin(TAU * 0.25 * t)
				var pad := (
					sin(TAU * d2 * t) * 0.30
					+ sin(TAU * a2 * t) * 0.20
					+ sin(TAU * f3 * t) * 0.14
					+ sin(TAU * c4 * t) * 0.10
				) * swell
				var step_dur := 0.5
				var step_idx := int(floorf(t / step_dur)) % arp_freqs.size()
				var local_t := fmod(t, step_dur)
				var env := minf(local_t / 0.015, 1.0) * exp(-local_t * 6.5)
				var shimmer := sin(TAU * arp_freqs[step_idx] * t) * env * 0.14
				var val := clampi(int((pad + shimmer) * 16500.0), -32767, 32767)
				data.encode_s16(i * 2, val)

		"lounge":
			var c3 := _snap_freq(130.81)
			var g3 := _snap_freq(196.0)
			var b3 := _snap_freq(246.94)
			var d4 := _snap_freq(293.66)
			var chord_notes: Array[float] = [
				_snap_freq(392.0), _snap_freq(493.88), _snap_freq(587.33), _snap_freq(659.25),
				_snap_freq(587.33), _snap_freq(493.88), _snap_freq(440.0), _snap_freq(392.0),
			]
			for i in range(num_samples):
				var t := float(i) / float(SAMPLE_RATE)
				var warm := (
					sin(TAU * c3 * t) * 0.26
					+ sin(TAU * g3 * t) * 0.18
					+ sin(TAU * b3 * t) * 0.12
					+ sin(TAU * d4 * t) * 0.10
				) * (0.88 + 0.12 * sin(TAU * 0.5 * t))
				var beat_dur := 0.5
				var beat_idx := int(floorf(t / beat_dur)) % chord_notes.size()
				var local_t := fmod(t, beat_dur)
				var bell_env := minf(local_t / 0.01, 1.0) * exp(-local_t * 7.5)
				var bell := sin(TAU * chord_notes[beat_idx] * t) * bell_env * 0.16
				var val := clampi(int((warm + bell) * 16500.0), -32767, 32767)
				data.encode_s16(i * 2, val)

		"puzzle":
			var a2 := _snap_freq(110.0)
			var e3 := _snap_freq(164.81)
			var arp: Array[float] = [
				_snap_freq(220.0), _snap_freq(261.63), _snap_freq(329.63), _snap_freq(392.0),
				_snap_freq(440.0), _snap_freq(392.0), _snap_freq(329.63), _snap_freq(261.63),
				_snap_freq(220.0), _snap_freq(293.66), _snap_freq(349.23), _snap_freq(440.0),
				_snap_freq(392.0), _snap_freq(329.63), _snap_freq(293.66), _snap_freq(261.63),
			]
			for i in range(num_samples):
				var t := float(i) / float(SAMPLE_RATE)
				var bass_beat := fmod(t, 0.5)
				var bass_env := minf(bass_beat / 0.008, 1.0) * (0.55 + 0.45 * exp(-bass_beat * 4.5))
				var bass := (sin(TAU * a2 * t) * 0.28 + sin(TAU * e3 * t) * 0.14) * bass_env
				var step_dur := 0.25
				var idx := int(floorf(t / step_dur)) % arp.size()
				var local_t := fmod(t, step_dur)
				var env := minf(local_t / 0.008, 1.0) * exp(-local_t * 9.0)
				var lead_phase := fposmod(t * arp[idx], 1.0)
				var tri := 2.0 * absf(2.0 * (lead_phase - 0.5)) - 1.0
				var lead := (sin(TAU * arp[idx] * t) * 0.65 + tri * 0.35) * env * 0.22
				var val := clampi(int((bass + lead) * 16500.0), -32767, 32767)
				data.encode_s16(i * 2, val)

		"meadow":
			var g2 := _snap_freq(98.0)
			var d3 := _snap_freq(146.83)
			var g3 := _snap_freq(196.0)
			var b3 := _snap_freq(246.94)
			var pluck: Array[float] = [
				_snap_freq(392.0), _snap_freq(493.88), _snap_freq(587.33), _snap_freq(493.88),
				_snap_freq(440.0), _snap_freq(523.25), _snap_freq(587.33), _snap_freq(659.25),
			]
			for i in range(num_samples):
				var t := float(i) / float(SAMPLE_RATE)
				var breeze := 0.85 + 0.15 * sin(TAU * 0.5 * t)
				var pad := (
					sin(TAU * g2 * t) * 0.24
					+ sin(TAU * d3 * t) * 0.18
					+ sin(TAU * g3 * t) * 0.16
					+ sin(TAU * b3 * t) * 0.12
				) * breeze
				var step_dur := 0.5
				var idx := int(floorf(t / step_dur)) % pluck.size()
				var local_t := fmod(t, step_dur)
				var env := minf(local_t / 0.01, 1.0) * exp(-local_t * 6.0)
				var melody := sin(TAU * pluck[idx] * t) * env * 0.18
				var val := clampi(int((pad + melody) * 16500.0), -32767, 32767)
				data.encode_s16(i * 2, val)

		"crypt":
			var d2 := _snap_freq(73.42)
			var a2 := _snap_freq(110.0)
			var bb2 := _snap_freq(116.54)
			var eb3 := _snap_freq(155.56)
			for i in range(num_samples):
				var t := float(i) / float(SAMPLE_RATE)
				var pulse_t := fmod(t, 1.0)
				var pulse_env := minf(pulse_t / 0.012, 1.0) * exp(-pulse_t * 5.0)
				var drone := (
					sin(TAU * d2 * t) * 0.34
					+ sin(TAU * a2 * t) * 0.16
					+ sin(TAU * bb2 * t) * 0.10 * (0.6 + 0.4 * sin(TAU * 0.25 * t))
				)
				var chime := sin(TAU * eb3 * t) * pulse_env * 0.18
				var sub_kick := sin(TAU * _snap_freq(60.0) * t) * pulse_env * 0.18
				var val := clampi(int((drone + chime + sub_kick) * 16500.0), -32767, 32767)
				data.encode_s16(i * 2, val)

		_:
			var c3 := _snap_freq(130.81)
			var g3 := _snap_freq(196.0)
			var e4 := _snap_freq(329.63)
			for i in range(num_samples):
				var t := float(i) / float(SAMPLE_RATE)
				var amp := sin(TAU * c3 * t) * 0.25 + sin(TAU * g3 * t) * 0.18 + sin(TAU * e4 * t) * 0.10
				var val := clampi(int(amp * 15000.0), -32767, 32767)
				data.encode_s16(i * 2, val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	stream.data = data
	return stream


## Erzeugt einen kurzen Effekt-Ton ("sine", "triangle", "square", "noise") mit optionalem Sweep.
static func create_tone(
	freq: float,
	duration: float,
	volume: float = 0.25,
	waveform: String = "sine",
	end_freq: float = -1.0
) -> AudioStreamWAV:
	var safe_duration := maxf(duration, 0.01)
	var frames := maxi(1, int(safe_duration * SAMPLE_RATE))
	var data := PackedByteArray()
	data.resize(frames * 2)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var phase := 0.0
	var attack_samples := maxf(1.0, 0.003 * SAMPLE_RATE)

	for i in range(frames):
		var progress := float(i) / float(frames)
		var cur_freq := freq if end_freq <= 0.0 else lerpf(freq, end_freq, progress)
		phase = fposmod(phase + cur_freq / float(SAMPLE_RATE), 1.0)
		var attack := minf(float(i) / attack_samples, 1.0)
		var env := attack * (1.0 - progress)
		var sample := 0.0
		match waveform:
			"sine":
				sample = sin(TAU * phase)
			"triangle":
				sample = 1.0 - 4.0 * absf(phase - 0.5)
			"square":
				sample = 0.75 if phase < 0.5 else -0.75
			"noise":
				sample = rng.randf_range(-1.0, 1.0)
			_:
				sample = sin(TAU * phase)

		var val := clampi(int(clampf(sample * env * volume, -1.0, 1.0) * 32767.0), -32767, 32767)
		data.encode_s16(i * 2, val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream
