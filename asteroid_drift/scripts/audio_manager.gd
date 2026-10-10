class_name AudioManager
extends Node
## Globaler Audio-Manager für Effekte und Soundkulisse.

var _sfx_players: Array[AudioStreamPlayer] = []
const MAX_PLAYERS := 12

var _sounds: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(MAX_PLAYERS):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)

	_load_sound("shoot", "res://assets/audio/shoot.ogg")
	_load_sound("shoot_double", "res://assets/audio/shoot_double.ogg")
	_load_sound("explosion", "res://assets/audio/explosion.ogg")
	_load_sound("hit", "res://assets/audio/hit.ogg")
	_load_sound("hit_shield", "res://assets/audio/hit_shield.ogg")
	_load_sound("click", "res://assets/audio/click.ogg")
	_load_sound("card_select", "res://assets/audio/card_select.ogg")
	_load_sound("pickup", "res://assets/audio/sun_collect.ogg")
	_load_sound("wave_start", "res://assets/audio/final_wave.ogg")
	_load_sound("game_over", "res://assets/audio/lose.ogg")
	_load_sound("hyperspace", "res://assets/audio/win.ogg")


func _load_sound(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path)
		if stream:
			_sounds[key] = stream


func play(sound_name: String, pitch_range: float = 0.05, volume_db: float = 0.0) -> void:
	if not _sounds.has(sound_name):
		return

	var stream: AudioStream = _sounds[sound_name]
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			if pitch_range > 0.0:
				p.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
			else:
				p.pitch_scale = 1.0
			p.play()
			return
