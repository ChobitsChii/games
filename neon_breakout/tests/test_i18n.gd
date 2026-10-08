extends TestCase
## Prüft die Übersetzungen: Jeder Schlüssel hat alle Sprachen, jeder verwendete
## Schlüssel existiert, und in Szenen stehen keine fest eingetragenen Texte.

const CSV_FILES := [
	"res://addons/shared/i18n/common.csv",
	"res://i18n/neon_breakout.csv",
]
const SOURCE_DIRS := ["res://scripts", "res://scenes", "res://addons/shared"]
const KEY_PREFIXES := "COMMON|DISPLAY|GAME|HUD|MSG|PAUSE|MENU"


## Liest alle CSV-Dateien. Ergebnis: Schlüssel -> {Sprache -> Text}.
func _load_translations() -> Dictionary:
	var result := {}
	for path in CSV_FILES:
		var file := FileAccess.open(path, FileAccess.READ)
		assert_true(file != null, "CSV vorhanden: " + path)
		if file == null:
			continue
		var header := file.get_csv_line()
		while not file.eof_reached():
			var row := file.get_csv_line()
			if row.size() < 2 or row[0] == "":
				continue
			var texts := {}
			for i in range(1, header.size()):
				texts[header[i]] = row[i] if i < row.size() else ""
			assert_true(not result.has(row[0]), "Schlüssel doppelt: " + row[0])
			result[row[0]] = texts
	return result


func _supported_languages() -> PackedStringArray:
	var script: GDScript = load("res://addons/shared/services/locale_service.gd")
	return script.get_script_constant_map()["SUPPORTED"]


func test_every_key_has_every_language() -> void:
	var translations := _load_translations()
	assert_true(translations.size() > 0, "Übersetzungen geladen")
	for key: String in translations:
		for lang in _supported_languages():
			var text: String = translations[key].get(lang, "")
			assert_true(text != "", "%s fehlt in '%s'" % [key, lang])


func test_placeholders_match_between_languages() -> void:
	var translations := _load_translations()
	for key: String in translations:
		var counts := []
		for lang in _supported_languages():
			counts.append(str(translations[key].get(lang, "")).count("%"))
		assert_true(counts.min() == counts.max(), "Platzhalter unterschiedlich in " + key)


func test_used_keys_exist() -> void:
	var translations := _load_translations()
	var regex := RegEx.create_from_string("\"((?:%s)_[A-Z0-9_]+)\"" % KEY_PREFIXES)
	for source_dir in SOURCE_DIRS:
		for extension in [".gd", ".tscn"]:
			for path in list_files(source_dir, extension):
				if path.get_file().begins_with("test_"):
					continue
				var content := FileAccess.get_file_as_string(path)
				for found in regex.search_all(content):
					var key := found.get_string(1)
					assert_true(translations.has(key), "%s: Schlüssel '%s' fehlt in den CSV-Dateien" % [path, key])


func test_scenes_have_no_hardcoded_text() -> void:
	var key_regex := RegEx.create_from_string("^(?:%s)_[A-Z0-9_]+$" % KEY_PREFIXES)
	var text_regex := RegEx.create_from_string("(?m)^text = \"([^\"]*)\"")
	for source_dir in SOURCE_DIRS:
		for path in list_files(source_dir, ".tscn"):
			var content := FileAccess.get_file_as_string(path)
			for found in text_regex.search_all(content):
				var text := found.get_string(1)
				if text == "":
					continue
				assert_true(key_regex.search(text) != null, "%s: fest eingetragener Text '%s'" % [path, text])
