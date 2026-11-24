extends Node
## Speichert Einstellungen und Spielstände als ConfigFile unter user://.
##
## Autoload. Muss VOR LocaleService und DisplayService registriert sein,
## weil diese beim Start ihre gespeicherten Werte lesen.

const SETTINGS_PATH := "user://settings.cfg"

var _config := ConfigFile.new()
var _loaded := false
var _dirty := false
var is_test_mode := false
var flush_count: int = 0


func _init() -> void:
	for arg in OS.get_cmdline_args():
		if "tests/run_tests.gd" in arg or "tests/smoke" in arg:
			is_test_mode = true
			break


func _ready() -> void:
	_ensure_loaded()


func _ensure_loaded() -> void:
	if not _loaded:
		if not is_test_mode:
			_config.load(SETTINGS_PATH)
		_loaded = true


func get_value(section: String, key: String, default: Variant = null) -> Variant:
	_ensure_loaded()
	return _config.get_value(section, key, default)


func set_value(section: String, key: String, value: Variant, flush: bool = true) -> bool:
	_ensure_loaded()
	if _config.has_section_key(section, key):
		var prev: Variant = _config.get_value(section, key)
		if typeof(prev) == typeof(value) and prev == value:
			if flush and _dirty:
				return save()
			return false
	_config.set_value(section, key, value)
	_dirty = true
	if flush:
		return save()
	return false


func save() -> bool:
	if not _dirty:
		return false
	if is_test_mode:
		_dirty = false
		flush_count += 1
		return true
	var err := _config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("SaveService: %s konnte nicht gespeichert werden (Fehler %d)" % [SETTINGS_PATH, err])
		return false
	_dirty = false
	flush_count += 1
	return true


## Schaltet isolierten Test-Modus ein oder aus, um Spieler-Spielstände zu schützen.
func set_test_mode(enabled: bool) -> void:
	is_test_mode = enabled
	_config = ConfigFile.new()
	_loaded = true
	_dirty = false
	flush_count = 0

