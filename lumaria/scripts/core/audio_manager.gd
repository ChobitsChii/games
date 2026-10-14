extends Node
## Audio-Manager für Lumaria: The Prismatic Odyssey.
## Spielt Soundeffekte aus einem dedizierten Player-Pool ab und
## verwaltet nahtlos loopende, prozedural synthetisierte Soundtrack-Themen
## für Dorf, Dungeons, Bosskämpfe und Epilog.

const SOUNDS: Dictionary = {
	"slash": preload("res://assets/sounds/slash.ogg"),
	"hit": preload("res://assets/sounds/hit.ogg"),
	"parry": preload("res://assets/sounds/parry.ogg"),
	"break": preload("res://assets/sounds/break.ogg"),
	"lumen_collect": preload("res://assets/sounds/lumen_collect.ogg"),
	"dash": preload("res://assets/sounds/dash.ogg"),
	"explosion": preload("res://assets/sounds/explosion.ogg"),
	"dialogue_blip": preload("res://assets/sounds/dialogue_blip.ogg"),
}

var _pool: Array[AudioStreamPlayer] = []
const POOL_SIZE := 8

var _music_player: AudioStreamPlayer = null
var _current_track: String = ""
var _music_cache: Dictionary = {}
var _sfx_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_pool.append(player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)


func play_sfx(sound_name: String, pitch_scale: float = 1.0) -> void:
	var stream: AudioStream = null
	if SOUNDS.has(sound_name):
		stream = SOUNDS[sound_name]
	else:
		stream = _get_or_create_sfx_stream(sound_name)

	if stream == null:
		return

	for player in _pool:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch_scale
			player.play()
			return

	if not _pool.is_empty():
		var player := _pool[0]
		player.stream = stream
		player.pitch_scale = pitch_scale
		player.play()


func play_music(track_name: String, volume_db: float = -10.0) -> void:
	if _current_track == track_name and _music_player.playing:
		return
	_current_track = track_name

	var stream := _get_or_create_music_stream(track_name)
	if stream != null:
		_music_player.stream = stream
		_music_player.volume_db = volume_db
		_music_player.play()


func stop_music() -> void:
	_current_track = ""
	if _music_player and _music_player.playing:
		_music_player.stop()


func get_current_music_track() -> String:
	return _current_track


func _get_or_create_sfx_stream(sfx_name: String) -> AudioStreamWAV:
	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name]

	var stream: AudioStreamWAV = null
	match sfx_name:
		"click", "ui_click":
			stream = _generate_tone(480.0, 0.05, 0.25, "sine")
		"menu_select":
			stream = _generate_tone(640.0, 0.08, 0.2, "triangle")
		"chest_open":
			stream = _generate_tone(520.0, 0.2, 0.3, "sine")
		_:
			stream = _generate_tone(380.0, 0.05, 0.15, "sine")

	if stream != null:
		_sfx_cache[sfx_name] = stream
	return stream


func _get_or_create_music_stream(track_name: String) -> AudioStreamWAV:
	if _music_cache.has(track_name):
		return _music_cache[track_name]

	var sample_rate := 22050
	var duration := 4.0
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	match track_name:
		"village":
			# Sanfte, pastorale Lydian-Akkorde (D-Dur mit G# Glanz)
			for i in range(num_samples):
				var t := float(i) / float(sample_rate)
				var d1 := sin(t * TAU * 146.83) * 0.25 # D3
				var a1 := sin(t * TAU * 220.0) * 0.20 # A3
				var f1 := sin(t * TAU * 369.99) * 0.15 # F#4
				var e1 := sin(t * TAU * 329.63 + sin(t * 1.5) * 0.5) * 0.12 # E4 Schwebung
				var amp := (d1 + a1 + f1 + e1) * (0.85 + sin(t * TAU * 0.5) * 0.15)
				var val := clampi(int(amp * 16000.0), -32767, 32767)
				data.encode_s16(i * 2, val)

		"dungeon":
			# Düstere, hallende Tiefen-Resonanz mit Moll-Sekunde
			for i in range(num_samples):
				var t := float(i) / float(sample_rate)
				var c1 := sin(t * TAU * 65.41) * 0.35 # C2 Sub-Bass
				var g1 := sin(t * TAU * 98.0) * 0.22 # G2
				var eb := sin(t * TAU * 155.56 + sin(t * 3.0) * 0.8) * 0.16 # Eb3
				var shimmer := sin(t * TAU * 311.13) * 0.08 * (0.5 + sin(t * 4.0) * 0.5)
				var amp := (c1 + g1 + eb + shimmer) * (0.9 + sin(t * TAU * 0.25) * 0.1)
				var val := clampi(int(amp * 15000.0), -32767, 32767)
				data.encode_s16(i * 2, val)

		"boss":
			# Treibender, rhythmischer Puls mit bedrohlichen Triolen
			for i in range(num_samples):
				var t := float(i) / float(sample_rate)
				var beat := fmod(t, 0.4615) # ~130 BPM
				var kick := sin(beat * TAU * (90.0 - beat * 90.0)) * exp(-beat * 12.0) * 0.45
				var bass := sin(t * TAU * 73.42) * 0.30 # D2
				var tension := sin(t * TAU * 103.83) * 0.15 * (0.6 + sin(t * 8.0) * 0.4) # Ab2 Tritonus
				var pulse := (kick + bass + tension)
				var val := clampi(int(pulse * 18000.0), -32767, 32767)
				data.encode_s16(i * 2, val)

		"victory":
			# Strahlende, triumphale Dur-Akkorde
			for i in range(num_samples):
				var t := float(i) / float(sample_rate)
				var c := sin(t * TAU * 261.63) * 0.25 # C4
				var e := sin(t * TAU * 329.63) * 0.22 # E4
				var g := sin(t * TAU * 392.00) * 0.20 # G4
				var c2 := sin(t * TAU * 523.25) * 0.15 # C5
				var d2 := sin(t * TAU * 587.33 + sin(t * 2.0)) * 0.10 # D5 Glanz
				var amp := (c + e + g + c2 + d2) * (0.9 + sin(t * TAU * 0.5) * 0.1)
				var val := clampi(int(amp * 16500.0), -32767, 32767)
				data.encode_s16(i * 2, val)

		_:
			# Sanfter Standard-Drone
			for i in range(num_samples):
				var t := float(i) / float(sample_rate)
				var s := sin(t * TAU * 220.0) * 0.3
				data.encode_s16(i * 2, clampi(int(s * 14000.0), -32767, 32767))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	stream.data = data

	_music_cache[track_name] = stream
	return stream


func _generate_tone(freq: float, duration: float, volume: float, waveform: String) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := 1.0 - (float(i) / float(num_samples)) # Linearer Ausklang
		var s := 0.0
		match waveform:
			"sine":
				s = sin(t * TAU * freq)
			"triangle":
				var phase := fmod(t * freq, 1.0)
				s = (absf(phase - 0.5) - 0.25) * 4.0
			_:
				s = sin(t * TAU * freq)

		var val := clampi(int(s * env * volume * 32767.0), -32767, 32767)
		data.encode_s16(i * 2, val)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream
