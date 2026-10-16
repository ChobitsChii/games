class_name SfxSynth
extends RefCounted
## Synthetisiert Soundeffekte aus Sinus-, Dreieck-, Rechteck- und Rauschwellen.
## Keine Audiodateien nötig (läuft identisch auf Linux, Windows und im Web).
## Reine Berechnung ohne Nodes, daher testbar.

const SAMPLE_RATE := 22050

enum Wave { SINE, TRIANGLE, SQUARE, NOISE }


## Ein Ton mit linearem Frequenzverlauf. Die Hüllkurve klingt nach `decay_power` aus
## (größer = schneller). `harmonic` mischt die Oktave dazu (0 = reiner Ton).
static func tone(
		wave: Wave,
		freq_start: float,
		freq_end: float,
		duration: float,
		volume: float = 0.5,
		attack: float = 0.004,
		decay_power: float = 2.0,
		harmonic: float = 0.0) -> PackedFloat32Array:
	var frames := maxi(int(duration * SAMPLE_RATE), 1)
	var out := PackedFloat32Array()
	out.resize(frames)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var attack_frames := maxf(attack * SAMPLE_RATE, 1.0)
	var phase := 0.0
	for i in frames:
		var t := float(i) / float(frames)
		phase += lerpf(freq_start, freq_end, t) / SAMPLE_RATE
		var sample := _wave(wave, phase, rng)
		if harmonic > 0.0:
			sample = (sample + harmonic * sin(TAU * phase * 2.0)) / (1.0 + harmonic)
		var env := pow(1.0 - t, decay_power) * minf(float(i) / attack_frames, 1.0)
		out[i] = sample * env * volume
	return out


## Töne hintereinander (z. B. Arpeggio). Jede Note klingt für sich aus.
static func sequence(
		freqs: Array,
		note_duration: float,
		wave: Wave = Wave.SINE,
		volume: float = 0.5,
		harmonic: float = 0.0) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for freq: float in freqs:
		out.append_array(tone(wave, freq, freq, note_duration, volume, 0.004, 1.6, harmonic))
	return out


## Überlagert zwei Klänge. Das Ergebnis ist so lang wie der längere.
static func mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(maxi(a.size(), b.size()))
	for i in out.size():
		out[i] = (a[i] if i < a.size() else 0.0) + (b[i] if i < b.size() else 0.0)
	return out


## Größter Betrag der Samples (für Tests und Lautstärke-Kontrolle).
static func peak(samples: PackedFloat32Array) -> float:
	var result := 0.0
	for s in samples:
		result = maxf(result, absf(s))
	return result


## Wandelt Samples (-1..1) in einen abspielbaren 16-Bit-Mono-Stream.
static func to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


static func _wave(wave: Wave, phase: float, rng: RandomNumberGenerator) -> float:
	var p := phase - floorf(phase)
	match wave:
		Wave.SINE:
			return sin(TAU * phase)
		Wave.TRIANGLE:
			return 4.0 * absf(p - 0.5) - 1.0
		Wave.SQUARE:
			return 0.6 if p < 0.5 else -0.6
		_:
			return rng.randf_range(-1.0, 1.0)
