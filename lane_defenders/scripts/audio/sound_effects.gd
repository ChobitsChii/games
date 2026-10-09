class_name SoundEffects
extends Node
## Sound-Effekt-Manager für Lane Defenders mit hochwertigen Kenney CC0 Audio-Assets.

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _pool_size := 12
var _current_player := 0


func _ready() -> void:
	# Pool von AudioStreamPlayer für überlappende Sounds
	for i in range(_pool_size):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

	_load_sound("shoot", "res://assets/sounds/shoot.ogg")
	_load_sound("shoot_double", "res://assets/sounds/shoot_double.ogg")
	_load_sound("shoot_frost", "res://assets/sounds/shoot_frost.ogg")
	_load_sound("hit", "res://assets/sounds/hit.ogg")
	_load_sound("hit_shield", "res://assets/sounds/hit_shield.ogg")
	_load_sound("sun_collect", "res://assets/sounds/sun_collect.ogg")
	_load_sound("explosion", "res://assets/sounds/explosion.ogg")
	_load_sound("place", "res://assets/sounds/place.ogg")
	_load_sound("dig", "res://assets/sounds/dig.ogg")
	_load_sound("click", "res://assets/sounds/click.ogg")
	_load_sound("card_select", "res://assets/sounds/card_select.ogg")
	_load_sound("error", "res://assets/sounds/error.ogg")
	_load_sound("final_wave", "res://assets/sounds/final_wave.ogg")
	_load_sound("win", "res://assets/sounds/win.ogg")
	_load_sound("lose", "res://assets/sounds/lose.ogg")


func _load_sound(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		_streams[key] = load(path)


func play_shoot(is_double: bool = false, is_frost: bool = false) -> void:
	var sound := "shoot"
	if is_frost:
		sound = "shoot_frost"
	elif is_double:
		sound = "shoot_double"
	_play(sound, randf_range(0.95, 1.08), -2.0)


func play_hit(is_shield: bool = false) -> void:
	var sound := "hit_shield" if is_shield else "hit"
	_play(sound, randf_range(0.92, 1.08), 0.0)


func play_sun_collect() -> void:
	_play("sun_collect", randf_range(0.98, 1.05), 1.0)


func play_explosion() -> void:
	_play("explosion", randf_range(0.9, 1.1), 3.0)


func play_place() -> void:
	_play("place", randf_range(0.95, 1.05), 1.0)


func play_dig() -> void:
	_play("dig", randf_range(0.95, 1.05), 0.0)


func play_card_select() -> void:
	_play("card_select", 1.0, 0.0)


func play_click() -> void:
	_play("click", 1.0, -3.0)


func play_error() -> void:
	_play("error", 1.0, 0.0)


func play_final_wave() -> void:
	_play("final_wave", 1.0, 2.0)


func play_win() -> void:
	_play("win", 1.0, 2.0)


func play_lose() -> void:
	_play("lose", 1.0, 2.0)


func _play(key: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not _streams.has(key):
		return
	var stream: AudioStream = _streams[key]
	var p := _players[_current_player]
	_current_player = (_current_player + 1) % _pool_size
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()
