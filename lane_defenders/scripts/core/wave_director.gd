class_name WaveDirector
extends RefCounted
## Koordiniert das zeitliche Erscheinen von Gegnerwellen basierend auf LevelData.

var level_data: LevelData
var current_time: float = 0.0
var _spawn_index: int = 0
var _sorted_spawns: Array[Dictionary] = []
var final_wave_time: float = 0.0
var final_wave_signaled: bool = false


func _init(p_level: LevelData = null) -> void:
	if p_level != null:
		set_level(p_level)


func set_level(p_level: LevelData) -> void:
	level_data = p_level
	current_time = 0.0
	_spawn_index = 0
	final_wave_signaled = false

	_sorted_spawns.clear()
	for s in p_level.spawns:
		_sorted_spawns.append(s.duplicate())
	_sorted_spawns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("time", 0.0)) < float(b.get("time", 0.0))
	)

	var last_time := 0.0
	if not _sorted_spawns.is_empty():
		last_time = float(_sorted_spawns.back().get("time", 0.0))
	# Grosse Schlusswelle beginnt bei 85% der Spieldauer
	final_wave_time = maxf(1.0, last_time * 0.85)


func update(delta: float) -> Array[Dictionary]:
	var triggered: Array[Dictionary] = []
	if level_data == null:
		return triggered

	current_time += delta

	while _spawn_index < _sorted_spawns.size():
		var s: Dictionary = _sorted_spawns[_spawn_index]
		if current_time >= float(s.get("time", 0.0)):
			triggered.append(s)
			_spawn_index += 1
		else:
			break

	return triggered


func check_final_wave_trigger() -> bool:
	if not final_wave_signaled and current_time >= final_wave_time:
		final_wave_signaled = true
		return true
	return false


func is_all_spawns_dispatched() -> bool:
	return _spawn_index >= _sorted_spawns.size()


func get_progress() -> float:
	if _sorted_spawns.is_empty():
		return 1.0
	var last_time := float(_sorted_spawns.back().get("time", 1.0))
	if last_time <= 0.0:
		return 1.0
	return clampf(current_time / last_time, 0.0, 1.0)
