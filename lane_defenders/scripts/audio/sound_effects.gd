class_name SoundEffects
extends Node
## Prozeduraler Sound-Effekt-Generator für Lane Defenders.
## Funktioniert auf allen Plattformen (Linux, Windows, Web) ohne externe Sounddateien.

var _players: Array[AudioStreamPlayer] = []
var _pool_size := 8
var _current_player := 0


func _ready() -> void:
	for i in range(_pool_size):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func play_shoot(is_double: bool = false, is_frost: bool = false) -> void:
	var freq := 580.0
	if is_frost:
		freq = 820.0
	elif is_double:
		freq = 660.0
	_play_tone(freq, 0.08, 0.25, AudioStreamWAV.FORMAT_8_BITS, true)


func play_hit(is_shield: bool = false) -> void:
	var freq := 220.0 if not is_shield else 440.0
	_play_tone(freq, 0.06, 0.2, AudioStreamWAV.FORMAT_8_BITS, false)


func play_sun_collect() -> void:
	_play_tone(880.0, 0.12, 0.3, AudioStreamWAV.FORMAT_8_BITS, true)


func play_explosion() -> void:
	_play_noise(0.25, 0.4)


func play_place() -> void:
	_play_tone(440.0, 0.07, 0.2, AudioStreamWAV.FORMAT_8_BITS, true)


func play_final_wave() -> void:
	_play_tone(330.0, 0.6, 0.45, AudioStreamWAV.FORMAT_8_BITS, true)


func play_win() -> void:
	_play_tone(587.0, 0.4, 0.4, AudioStreamWAV.FORMAT_8_BITS, true)


func play_lose() -> void:
	_play_tone(180.0, 0.5, 0.45, AudioStreamWAV.FORMAT_8_BITS, false)


func _play_tone(freq: float, duration: float, volume: float, _format: AudioStreamWAV.Format, is_sine: bool) -> void:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := 1.0 - (float(i) / float(num_samples))
		var s := 0.0
		if is_sine:
			s = sin(t * freq * TAU)
		else:
			s = 1.0 if sin(t * freq * TAU) > 0.0 else -1.0
		var val := int(clampf((s * env * volume * 127.0) + 128.0, 0.0, 255.0))
		data[i] = val

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data

	var p := _players[_current_player]
	_current_player = (_current_player + 1) % _pool_size
	p.stream = stream
	p.play()


func _play_noise(duration: float, volume: float) -> void:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples)
	var rng := RandomNumberGenerator.new()

	for i in range(num_samples):
		var env := 1.0 - (float(i) / float(num_samples))
		var s := rng.randf_range(-1.0, 1.0)
		var val := int(clampf((s * env * volume * 127.0) + 128.0, 0.0, 255.0))
		data[i] = val

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data

	var p := _players[_current_player]
	_current_player = (_current_player + 1) % _pool_size
	p.stream = stream
	p.play()
