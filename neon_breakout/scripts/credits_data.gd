class_name CreditsData
extends RefCounted
## Einträge des Credits-Bildschirms (spiegeln `CREDITS.md`). `name`/`author` sind
## Übersetzungsschlüssel, `license` ist ein Lizenzname und wird nicht übersetzt.

const ENTRIES: Array[Dictionary] = [
	{"name": "CREDITS_FONT", "author": "Indian Type Foundry", "license": "SIL Open Font License 1.1"},
	{"name": "CREDITS_SFX", "author": "CREDITS_SELF", "license": ""},
	{"name": "CREDITS_MUSIC", "author": "CREDITS_SELF", "license": ""},
	{"name": "CREDITS_GRAPHICS", "author": "CREDITS_SELF", "license": ""},
	{"name": "CREDITS_ENGINE", "author": "Godot Engine contributors", "license": "MIT"},
]


## Zeile für die Anzeige: "Name – Autor (Lizenz)".
static func format_entry(entry: Dictionary) -> String:
	var author := String(entry["author"])
	if author.begins_with("CREDITS_"):
		author = TranslationServer.translate(author)
	var text := "%s – %s" % [TranslationServer.translate(entry["name"]), author]
	if String(entry["license"]) != "":
		text += " (%s)" % entry["license"]
	return text
