class_name SoundEffects
extends Node
## Erzeugt und spielt synthetisierte Soundeffekte für Connect Four Deluxe ab.
## Vollständig prozedural ohne externe Binärdateien (Web-, Linux- und Windows-kompatibel).

static var _instance: SoundEffects

var _players: Array[AudioStreamPlayer] = []
var _player_idx := 0
var _sample_rate := 22050


func _init() -> void:
	_instance = self


static func get_instance() -> SoundEffects:
	return _instance


func _ready() -> void:
	for i in range(8):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play_drop() -> void:
	# Akustischer Holzeinschlag: Kurzer harter Klick + tiefer Resonanzkörper
	_play_stream(_generate_sweep(380.0, 95.0, 0.08, 0.45))


func play_hover() -> void:
	_play_stream(_generate_tone(480.0, 0.025, 0.15, "triangle"))


func play_win() -> void:
	# C-Dur-Akkord mit Fanfaren-Klang
	_play_stream(_generate_chord([523.25, 659.25, 783.99, 1046.5], 0.6, 0.4))


func play_draw() -> void:
	_play_stream(_generate_sweep(280.0, 140.0, 0.35, 0.25))


func play_undo() -> void:
	_play_stream(_generate_sweep(120.0, 320.0, 0.06, 0.25))


func play_hint() -> void:
	_play_stream(_generate_chord([880.0, 1318.5], 0.25, 0.3))


func play_button() -> void:
	_play_stream(_generate_tone(620.0, 0.03, 0.18, "sine"))


func _play_stream(stream: AudioStreamWAV) -> void:
	if _players.is_empty():
		return
	var player := _players[_player_idx]
	_player_idx = (_player_idx + 1) % _players.size()
	player.stream = stream
	player.play()


func _generate_tone(freq: float, duration: float, volume: float, wave_type: String = "sine") -> AudioStreamWAV:
	var frames := int(duration * _sample_rate)
	var data := PackedByteArray()
	data.resize(frames * 2)

	for i in range(frames):
		var t := float(i) / float(_sample_rate)
		var env := 1.0 - (float(i) / float(frames))
		var sample := 0.0

		if wave_type == "sine":
			sample = sin(TAU * freq * t)
		elif wave_type == "triangle":
			sample = 2.0 * absf(2.0 * (t * freq - floorf(t * freq + 0.5))) - 1.0

		var val := int(clampf(sample * volume * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = _sample_rate
	stream.data = data
	return stream


func _generate_sweep(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var frames := int(duration * _sample_rate)
	var data := PackedByteArray()
	data.resize(frames * 2)

	for i in range(frames):
		var progress := float(i) / float(frames)
		var freq := lerpf(start_freq, end_freq, progress)
		var t := float(i) / float(_sample_rate)
		var env := 1.0 - progress
		var sample := sin(TAU * freq * t)
		var val := int(clampf(sample * volume * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = _sample_rate
	stream.data = data
	return stream


func _generate_chord(frequencies: Array, duration: float, volume: float) -> AudioStreamWAV:
	var frames := int(duration * _sample_rate)
	var data := PackedByteArray()
	data.resize(frames * 2)

	for i in range(frames):
		var t := float(i) / float(_sample_rate)
		var env := 1.0 - (float(i) / float(frames))
		var sample := 0.0
		for f in frequencies:
			sample += sin(TAU * float(f) * t)
		sample /= float(frequencies.size())
		var val := int(clampf(sample * volume * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = _sample_rate
	stream.data = data
	return stream
