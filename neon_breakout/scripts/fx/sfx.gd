extends Node
## Spielt die Soundeffekte von Neon Breakout. Alle Klänge werden beim Start
## synthetisiert (siehe SfxSynth). Autoload "Sfx".

const POOL_SIZE := 10

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_build_sounds()


func _exit_tree() -> void:
	stop_all()
	_streams.clear()


## Stoppt alle laufenden Klänge (z. B. vor dem Beenden, damit nichts übrig bleibt).
func stop_all() -> void:
	for player in _players:
		player.stop()
		player.stream = null


## Spielt einen Klang. `pitch` verändert die Tonhöhe (z. B. steigend bei Combos),
## ein kleiner Zufallsanteil sorgt für Abwechslung.
func play(sound: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null or _players.is_empty():
		push_warning("Sfx: Unbekannter Klang '%s'" % sound)
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.pitch_scale = pitch * randf_range(0.97, 1.03)
	player.volume_db = volume_db
	player.play()


func has_sound(sound: StringName) -> bool:
	return _streams.has(sound)


func _build_sounds() -> void:
	var W := SfxSynth.Wave
	_add(&"brick_hit", SfxSynth.tone(W.TRIANGLE, 700.0, 520.0, 0.10, 0.5, 0.003, 2.0, 0.3))
	_add(&"brick_break", SfxSynth.mix(
			SfxSynth.tone(W.SINE, 880.0, 1400.0, 0.18, 0.45, 0.003, 1.8, 0.4),
			SfxSynth.tone(W.NOISE, 0.0, 0.0, 0.05, 0.22, 0.001, 2.5)))
	_add(&"metal", SfxSynth.tone(W.SQUARE, 330.0, 300.0, 0.08, 0.25, 0.002, 2.2))
	_add(&"paddle", SfxSynth.mix(
			SfxSynth.tone(W.SINE, 320.0, 200.0, 0.12, 0.6, 0.003, 2.0),
			SfxSynth.tone(W.NOISE, 0.0, 0.0, 0.03, 0.12, 0.001, 3.0)))
	_add(&"wall", SfxSynth.tone(W.TRIANGLE, 240.0, 200.0, 0.06, 0.35, 0.002, 2.0))
	_add(&"launch", SfxSynth.tone(W.SINE, 280.0, 760.0, 0.16, 0.45, 0.004, 1.2))
	_add(&"life_lost", SfxSynth.mix(
			SfxSynth.tone(W.SQUARE, 420.0, 70.0, 0.55, 0.35, 0.004, 1.5),
			SfxSynth.tone(W.NOISE, 0.0, 0.0, 0.25, 0.28, 0.001, 2.0)))
	_add(&"level_clear", SfxSynth.sequence([523.25, 659.25, 783.99, 1046.5], 0.11, W.SINE, 0.5, 0.4))
	_add(&"game_over", SfxSynth.sequence([392.0, 329.63, 261.63, 196.0], 0.18, W.TRIANGLE, 0.55, 0.2))
	_add(&"ui_click", SfxSynth.tone(W.SINE, 900.0, 700.0, 0.05, 0.4, 0.002, 1.5))


func _add(sound: StringName, samples: PackedFloat32Array) -> void:
	_streams[sound] = SfxSynth.to_stream(samples)
