extends Node
## Hintergrundmusik. Der Loop wird beim Start im Hintergrund berechnet (MusicRenderer,
## ein Stück pro Frame) und blendet ein, sobald er fertig ist. An/Aus wird gespeichert.
## Autoload "Music". Läuft auch bei pausiertem Spiel weiter.

signal enabled_changed(enabled: bool)

const BUS_NAME := "Music"
## Zeit pro Frame für die Berechnung (Millisekunden). Der Rest bleibt für das Spiel.
const RENDER_BUDGET_USEC := 9000
const PLAY_DB := -9.0
const SILENT_DB := -60.0
const MUFFLED_HZ := 900.0
const OPEN_HZ := 20000.0
## Pro Level wird die Musik etwas schneller (Tonhöhe und Tempo), bis zu dieser Stufe.
const LEVEL_PITCH_STEP := 0.012
const LEVEL_PITCH_MAX_STEPS := 12

var enabled := true

var _player: AudioStreamPlayer
var _renderer: MusicRenderer
var _filter: AudioEffectLowPassFilter
var _volume_tween: Tween
var _filter_tween: Tween
var _pitch_tween: Tween
var _ready_to_play := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# In Tests gibt es keine Musik: spart Rechenzeit und hält die Läufe reproduzierbar.
	if SaveService.is_test_mode:
		set_process(false)
		return
	enabled = SaveService.get_value("settings", "music", true)
	_setup_bus()
	_player = AudioStreamPlayer.new()
	_player.bus = BUS_NAME
	_player.volume_db = SILENT_DB
	add_child(_player)
	_renderer = MusicRenderer.new()


func _process(_delta: float) -> void:
	if _renderer == null:
		return
	if _renderer.step(RENDER_BUDGET_USEC):
		_player.stream = _renderer.result()
		_renderer = null
		_ready_to_play = true
		set_process(false)
		if enabled:
			_start()


func _exit_tree() -> void:
	if _player != null:
		_player.stop()
		_player.stream = null


func set_enabled(value: bool) -> void:
	enabled = value
	SaveService.set_value("settings", "music", enabled)
	if _player != null and _ready_to_play:
		if enabled:
			_start()
		else:
			_fade_to(SILENT_DB, 0.4, true)
	enabled_changed.emit(enabled)


func toggle() -> void:
	set_enabled(not enabled)


## Dumpfer Klang (z. B. bei Pause und Game Over), `false` öffnet ihn wieder.
func set_muffled(value: bool) -> void:
	if _filter == null:
		return
	if _filter_tween != null:
		_filter_tween.kill()
	_filter_tween = create_tween().set_ignore_time_scale(true)
	_filter_tween.tween_property(_filter, "cutoff_hz", MUFFLED_HZ if value else OPEN_HZ, 0.35)


## Passt Tempo und Tonhöhe an das Level an (Level 1 = normal).
func set_level(level: int) -> void:
	if _player == null:
		return
	var steps := clampi(level - 1, 0, LEVEL_PITCH_MAX_STEPS)
	var target := 1.0 + LEVEL_PITCH_STEP * steps
	if _pitch_tween != null:
		_pitch_tween.kill()
	_pitch_tween = create_tween().set_ignore_time_scale(true)
	_pitch_tween.tween_property(_player, "pitch_scale", target, 0.8)


func is_ready_to_play() -> bool:
	return _ready_to_play


func _start() -> void:
	if not _player.playing:
		_player.play()
	_fade_to(PLAY_DB, 2.0, false)


func _fade_to(db: float, seconds: float, stop_after: bool) -> void:
	if _volume_tween != null:
		_volume_tween.kill()
	_volume_tween = create_tween().set_ignore_time_scale(true)
	_volume_tween.tween_property(_player, "volume_db", db, seconds)
	if stop_after:
		_volume_tween.tween_callback(_player.stop)


func _setup_bus() -> void:
	var index := AudioServer.get_bus_index(BUS_NAME)
	if index == -1:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, BUS_NAME)
		AudioServer.set_bus_send(index, "Master")
		_filter = AudioEffectLowPassFilter.new()
		_filter.cutoff_hz = OPEN_HZ
		AudioServer.add_bus_effect(index, _filter)
	else:
		_filter = AudioServer.get_bus_effect(index, 0) as AudioEffectLowPassFilter
