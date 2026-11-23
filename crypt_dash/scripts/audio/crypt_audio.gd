extends Node
## Sound-Effekt-Manager für Crypt Dash auf Basis von SharedSynthMusic.
## Läuft als Autoload ("CryptAudio") auf Bus "Sfx".

const POOL_SIZE := 8

var _players: Array[AudioStreamPlayer] = []
var _idx: int = 0
var _cache: Dictionary = {}
var _shutting_down: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var target_bus := "Sfx" if AudioServer.get_bus_index("Sfx") != -1 else "Master"
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = target_bus
		add_child(p)
		_players.append(p)

	_cache = {
		"shoot": SharedSynthMusic.create_tone(640.0, 0.06, 0.22, "triangle", 280.0),
		"dash": SharedSynthMusic.create_tone(320.0, 0.10, 0.26, "noise", 120.0),
		"hit": SharedSynthMusic.create_tone(190.0, 0.11, 0.34, "square", 75.0),
		"enemy_die": SharedSynthMusic.create_tone(340.0, 0.15, 0.28, "triangle", 90.0),
		"item_pickup": SharedSynthMusic.create_tone(540.0, 0.16, 0.28, "sine", 880.0),
		"door_open": SharedSynthMusic.create_tone(210.0, 0.12, 0.24, "sine", 340.0),
		"boss_phase": SharedSynthMusic.create_tone(150.0, 0.26, 0.32, "square", 300.0),
		"game_over": SharedSynthMusic.create_tone(300.0, 0.36, 0.30, "triangle", 85.0),
		"victory": SharedSynthMusic.create_tone(523.25, 0.32, 0.28, "sine", 1046.5),
		"click": SharedSynthMusic.create_tone(580.0, 0.04, 0.20, "sine"),
	}


func play_shoot() -> void:
	_play("shoot", randf_range(0.95, 1.08), -3.0)


func play_dash() -> void:
	_play("dash", randf_range(0.95, 1.05), -2.0)


func play_hit() -> void:
	_play("hit", randf_range(0.9, 1.05), 0.0)


func play_enemy_die() -> void:
	_play("enemy_die", randf_range(0.92, 1.08), -1.0)


func play_item_pickup() -> void:
	_play("item_pickup", 1.0, 0.0)


func play_door_open() -> void:
	_play("door_open", 1.0, -2.0)


func play_boss_phase() -> void:
	_play("boss_phase", 1.0, 1.0)


func play_game_over() -> void:
	_play("game_over", 1.0, 0.0)


func play_victory() -> void:
	_play("victory", 1.0, 0.0)


func play_click() -> void:
	_play("click", 1.0, -4.0)


func _play(key: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if _shutting_down or _players.is_empty() or not _cache.has(key):
		return
	var p := _players[_idx]
	_idx = (_idx + 1) % _players.size()
	p.stream = _cache[key]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func stop_all() -> void:
	_shutting_down = true
	for p in _players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	_cache.clear()


func _exit_tree() -> void:
	stop_all()
	_players.clear()
