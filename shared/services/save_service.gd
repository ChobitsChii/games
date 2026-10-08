extends Node
## Speichert Einstellungen und Spielstände als ConfigFile unter user://.
##
## Autoload. Muss VOR LocaleService und DisplayService registriert sein,
## weil diese beim Start ihre gespeicherten Werte lesen.

const SETTINGS_PATH := "user://settings.cfg"

var _config := ConfigFile.new()


func _ready() -> void:
	# Eine fehlende Datei beim ersten Start ist normal und kein Fehler.
	_config.load(SETTINGS_PATH)


func get_value(section: String, key: String, default: Variant = null) -> Variant:
	return _config.get_value(section, key, default)


func set_value(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)
	save()


func save() -> void:
	var err := _config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("SaveService: %s konnte nicht gespeichert werden (Fehler %d)" % [SETTINGS_PATH, err])
