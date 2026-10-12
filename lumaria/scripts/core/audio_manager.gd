extends Node
## Audio-Manager für Lumaria: Spielt SFX aus einem Pool ohne Lecks ab.

const SOUNDS: Dictionary = {
	"slash": preload("res://assets/sounds/slash.ogg"),
	"hit": preload("res://assets/sounds/hit.ogg"),
	"parry": preload("res://assets/sounds/parry.ogg"),
	"break": preload("res://assets/sounds/break.ogg"),
	"lumen_collect": preload("res://assets/sounds/lumen_collect.ogg"),
	"dash": preload("res://assets/sounds/dash.ogg"),
	"explosion": preload("res://assets/sounds/explosion.ogg"),
}

var _pool: Array[AudioStreamPlayer] = []
const POOL_SIZE := 8


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_pool.append(player)


func play_sfx(sound_name: String, pitch_scale: float = 1.0) -> void:
	if not SOUNDS.has(sound_name):
		return
	var stream: AudioStream = SOUNDS[sound_name]
	for player in _pool:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch_scale
			player.play()
			return
	
	# Falls alle belegt sind, nutze den ersten
	if not _pool.is_empty():
		var player := _pool[0]
		player.stream = stream
		player.pitch_scale = pitch_scale
		player.play()
