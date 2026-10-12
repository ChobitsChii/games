extends Node
## Verwaltet die Sprache. Neue Sprachen: Spalte in den CSV-Dateien ergänzen
## und hier in SUPPORTED und LANGUAGE_NAMES eintragen.
##
## Autoload (nach SaveService).

signal language_changed(code: String)

const SUPPORTED: PackedStringArray = ["de", "en"]
const FALLBACK := "en"
## Sprachnamen in der jeweiligen Landessprache (werden nie übersetzt).
const LANGUAGE_NAMES := {
	"de": "Deutsch",
	"en": "English",
}

var current: String = FALLBACK


func _ready() -> void:
	var saved: String = SaveService.get_value("settings", "language", "")
	if saved in SUPPORTED:
		set_language(saved, false)
	else:
		set_language(_detect_system_language(), false)


func set_language(code: String, persist: bool = true) -> void:
	if code not in SUPPORTED:
		push_warning("LocaleService: Sprache '%s' wird nicht unterstützt" % code)
		code = FALLBACK
	current = code
	TranslationServer.set_locale(code)
	if persist:
		SaveService.set_value("settings", "language", code)
	language_changed.emit(code)


## Wechselt zur nächsten unterstützten Sprache.
func cycle_language() -> void:
	var index := SUPPORTED.find(current)
	set_language(SUPPORTED[(index + 1) % SUPPORTED.size()])


func get_language_name(code: String = "") -> String:
	if code == "":
		code = current
	return LANGUAGE_NAMES.get(code, code)


func _detect_system_language() -> String:
	var system := OS.get_locale_language()
	return system if system in SUPPORTED else FALLBACK
