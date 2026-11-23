extends Node
## Zentraler Audio-Service für Lautstärke-Busse ("Master", "Music", "Sfx") und Ambient-Musik.
##
## Autoload (nach SaveService). Speichert Einstellungen unter "audio" in SaveService.

signal volume_changed(bus_name: String, value: float)

const VOLUME_STEPS: Array[float] = [1.0, 0.7, 0.4, 0.0]
const DEFAULT_VOLUMES: Dictionary = {
	"Master": 1.0,
	"Music": 0.7,
	"Sfx": 0.85,
}
const BUS_SAVE_KEYS: Dictionary = {
	"Master": "master",
	"Music": "music",
	"Sfx": "sfx",
}
const MIN_DB := -80.0

var _volumes: Dictionary = DEFAULT_VOLUMES.duplicate()
var _music_player: AudioStreamPlayer = null
var _current_theme: String = ""
var _theme_cache: Dictionary = {}
var _shutting_down: bool = false


static func volume_to_db(linear: float) -> float:
	var v := clampf(linear, 0.0, 1.0)
	if v <= 0.001:
		return MIN_DB
	return maxf(linear_to_db(v), MIN_DB)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music", "Master")
	_ensure_bus("Sfx", "Master")

	for bus_name: String in BUS_SAVE_KEYS:
		var save_key: String = BUS_SAVE_KEYS[bus_name]
		var default_val: float = float(DEFAULT_VOLUMES.get(bus_name, 1.0))
		_volumes[bus_name] = clampf(float(SaveService.get_value("audio", save_key, default_val)), 0.0, 1.0)
	_apply_all_buses()

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)


func _ensure_bus(bus_name: String, send_to: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	if AudioServer.get_bus_index(send_to) != -1:
		AudioServer.set_bus_send(idx, send_to)


func _apply_all_buses() -> void:
	for bus_name: String in _volumes:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx != -1:
			AudioServer.set_bus_volume_db(idx, volume_to_db(float(_volumes[bus_name])))


func get_volume(bus_name: String) -> float:
	return float(_volumes.get(bus_name, 1.0))


func set_volume(bus_name: String, value: float, persist: bool = true) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	_volumes[bus_name] = clamped
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, volume_to_db(clamped))
	if persist and BUS_SAVE_KEYS.has(bus_name):
		SaveService.set_value("audio", str(BUS_SAVE_KEYS[bus_name]), clamped)
	volume_changed.emit(bus_name, clamped)


func cycle_volume(bus_name: String) -> float:
	var current := get_volume(bus_name)
	var next_val: float = VOLUME_STEPS[0]
	var matched_idx := -1
	for i in range(VOLUME_STEPS.size()):
		if absf(current - VOLUME_STEPS[i]) <= 0.03:
			matched_idx = i
			break
	if matched_idx != -1:
		next_val = VOLUME_STEPS[(matched_idx + 1) % VOLUME_STEPS.size()]
	else:
		# Zwischengröße (z. B. 0.85): nächstkleinere Stufe wählen
		for step in VOLUME_STEPS:
			if step < current - 0.03:
				next_val = step
				break
	set_volume(bus_name, next_val)
	return next_val


func format_volume_label(label_key: String, bus_name: String) -> String:
	var v := get_volume(bus_name)
	if v <= 0.001:
		return "%s: %s" % [tr(label_key), tr("COMMON_AUDIO_OFF")]
	return "%s: %d%%" % [tr(label_key), roundi(v * 100.0)]


func play_music_theme(theme_name: String, volume_db: float = -8.0) -> void:
	if _shutting_down:
		return
	if SaveService.is_test_mode:
		_current_theme = theme_name
		return
	if _music_player == null or not is_instance_valid(_music_player):
		return
	if _current_theme == theme_name and _music_player.playing:
		return
	_current_theme = theme_name
	var stream: AudioStreamWAV
	if _theme_cache.has(theme_name):
		stream = _theme_cache[theme_name]
	else:
		stream = SharedSynthMusic.create_theme(theme_name)
		_theme_cache[theme_name] = stream
	if stream != null:
		_music_player.stream = stream
		_music_player.volume_db = volume_db
		_music_player.play()


func stop_music() -> void:
	_current_theme = ""
	if _music_player != null and is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.stream = null


func stop_all() -> void:
	_shutting_down = true
	stop_music()
	_theme_cache.clear()


func _exit_tree() -> void:
	stop_all()
