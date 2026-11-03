class_name MusicRenderer
extends RefCounted
## Berechnet den Song aus MusicSynth Stück für Stück. step() arbeitet nur so lange wie
## das übergebene Zeitbudget, damit das Spiel (auch im Browser, ohne Threads) flüssig
## bleibt. Phasen: Klänge erzeugen, abmischen, in einen Stream umwandeln.

enum Phase { EVENTS, MIX, ENCODE, DONE }

const CHUNK := 4000
## Wie stark die Bassdrum die übrigen Stimmen "wegdrückt" (Pumpen) und wie schnell sie zurückkommen.
const DUCK_DEPTH := 0.55
const DUCK_SPEED := 9.0
const TARGET_PEAK := 0.85

var phase: Phase = Phase.EVENTS

var _events: Array = MusicSynth.build_events()
var _event_index := 0
var _length := MusicSynth.total_frames()
var _main := PackedFloat32Array()
var _duck := PackedFloat32Array()
var _mixed := PackedFloat32Array()
var _data := PackedByteArray()
var _cursor := 0
var _peak := 0.0
var _rng := RandomNumberGenerator.new()
var _stream: AudioStreamWAV


func _init() -> void:
	_main.resize(_length)
	_duck.resize(_length)
	_rng.seed = 42


## Arbeitet höchstens `budget_usec` Mikrosekunden. Gibt true zurück, sobald alles fertig ist.
func step(budget_usec: int) -> bool:
	var deadline := Time.get_ticks_usec() + budget_usec
	while phase != Phase.DONE:
		match phase:
			Phase.EVENTS:
				_render_event(_events[_event_index])
				_event_index += 1
				if _event_index >= _events.size():
					phase = Phase.MIX
					_mixed.resize(_length)
					_cursor = 0
			Phase.MIX:
				_mix_chunk()
			Phase.ENCODE:
				_encode_chunk()
		if Time.get_ticks_usec() >= deadline:
			break
	return phase == Phase.DONE


## Rechnet alles am Stück (für Tests). Gibt den fertigen Loop zurück.
func render_all() -> AudioStreamWAV:
	while not step(1_000_000):
		pass
	return result()


## Der fertige Loop-Stream (erst nach Abschluss gültig, sonst null).
func result() -> AudioStreamWAV:
	return _stream


## Fortschritt von 0 bis 1.
func progress() -> float:
	match phase:
		Phase.EVENTS:
			return 0.8 * _event_index / maxf(_events.size(), 1.0)
		Phase.MIX:
			return 0.8 + 0.1 * _cursor / float(_length)
		Phase.ENCODE:
			return 0.9 + 0.1 * _cursor / float(_length)
	return 1.0


## Größter Betrag im Mix (Tests und Normalisierung).
func peak() -> float:
	return _peak


## Mix als Gleitkommawerte vor der Umwandlung (für Tests).
func mixed() -> PackedFloat32Array:
	return _mixed


func _render_event(e: Dictionary) -> void:
	var rate := float(MusicSynth.RATE)
	var start: int = e["start"]
	var length: int = e["length"]
	var from: int = e["seg_from"]
	var to: int = e["seg_to"]
	var vol: float = e["vol"]
	var freq: float = e["freq"]
	var buffer := _duck if e["duck"] else _main
	var kind: MusicSynth.Kind = e["kind"]
	var lowpass := 0.0
	var previous_noise := 0.0
	var tau_f := TAU * freq

	for i in range(from, to):
		var t := i / rate
		var sample := 0.0
		match kind:
			MusicSynth.Kind.KICK:
				# Tonhöhe fällt schnell von ~130 auf 42 Hz.
				var phase_value := 42.0 * t + 90.0 * (1.0 - exp(-28.0 * t)) / 28.0
				sample = sin(TAU * phase_value) * exp(-14.0 * t) * minf(i / 20.0, 1.0)
			MusicSynth.Kind.HAT:
				var noise := _rng.randf() * 2.0 - 1.0
				sample = (noise - previous_noise) * 0.5 * exp(-70.0 * t)
				previous_noise = noise
			MusicSynth.Kind.BASS:
				var cycle := fposmod(freq * t, 1.0)
				lowpass += 0.13 * ((2.0 * cycle - 1.0) - lowpass)
				sample = (lowpass + 0.5 * sin(tau_f * t)) * minf(t / 0.004, 1.0) * exp(-5.5 * t)
			MusicSynth.Kind.ARP:
				sample = (sin(tau_f * t) + 0.35 * sin(2.0 * tau_f * t)) * exp(-14.0 * t) * minf(t / 0.003, 1.0)
			MusicSynth.Kind.PAD:
				var fade_in := minf(t / MusicSynth.PAD_FADE_SECONDS, 1.0)
				var fade_out := minf((length - i) / rate / MusicSynth.PAD_FADE_SECONDS, 1.0)
				sample = sin(tau_f * t) * fade_in * fade_out
		# posmod: Ereignisse vor dem Anfang oder hinter dem Ende laufen im Loop weiter.
		var index := posmod(start + i, _length)
		buffer[index] += sample * vol


func _mix_chunk() -> void:
	var beat := MusicSynth.beat_samples()
	var rate := float(MusicSynth.RATE)
	var end := mini(_cursor + CHUNK, _length)
	for i in range(_cursor, end):
		var since_beat := fposmod(i, beat) / rate
		var gain := 1.0 - DUCK_DEPTH * exp(-since_beat * DUCK_SPEED)
		var value := _main[i] + _duck[i] * gain
		_mixed[i] = value
		_peak = maxf(_peak, absf(value))
	_cursor = end
	if _cursor >= _length:
		_cursor = 0
		_data.resize(_length * 2)
		phase = Phase.ENCODE


func _encode_chunk() -> void:
	var scale := TARGET_PEAK / maxf(_peak, 0.0001)
	var end := mini(_cursor + CHUNK, _length)
	for i in range(_cursor, end):
		_data.encode_s16(i * 2, int(clampf(_mixed[i] * scale, -1.0, 1.0) * 32767.0))
	_cursor = end
	if _cursor >= _length:
		_stream = AudioStreamWAV.new()
		_stream.format = AudioStreamWAV.FORMAT_16_BITS
		_stream.mix_rate = MusicSynth.RATE
		_stream.stereo = false
		_stream.data = _data
		_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_stream.loop_begin = 0
		_stream.loop_end = _length
		phase = Phase.DONE
