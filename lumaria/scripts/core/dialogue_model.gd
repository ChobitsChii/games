class_name DialogueModel
extends RefCounted
## Daten- und Logikmodell für das Dialogsystem in Lumaria.
## Verwaltet Gesprächsverläufe, Sprecher, Mehrseiten-Texte und Auswahlentscheidungen.
## Vollständig ohne Szenenbaum unit-testbar.

const DIALOGUES: Dictionary = {
	"morwen": {
		"name_key": "NPC_MORWEN",
		"portrait": "res://assets/portraits/portrait_morwen.png",
		"pages": ["DIALOGUE_MORWEN_1", "DIALOGUE_MORWEN_2"],
		"choices": [
			{"id": "ready", "text_key": "DIALOGUE_MORWEN_CHOICE_READY", "reply_key": ""},
			{"id": "lore", "text_key": "DIALOGUE_MORWEN_CHOICE_LORE", "reply_key": "DIALOGUE_MORWEN_LORE_REPLY"},
		]
	},
	"thalon": {
		"name_key": "NPC_THALON",
		"portrait": "res://assets/portraits/portrait_thalon.png",
		"pages": ["DIALOGUE_THALON_1", "DIALOGUE_THALON_2"],
		"choices": [
			{"id": "technique", "text_key": "DIALOGUE_THALON_CHOICE_TECHNIQUE", "reply_key": "DIALOGUE_THALON_TECHNIQUE_REPLY"},
			{"id": "thanks", "text_key": "DIALOGUE_THALON_CHOICE_THANKS", "reply_key": ""},
		]
	},
	"lyra": {
		"name_key": "NPC_LYRA",
		"portrait": "res://assets/portraits/portrait_lyra.png",
		"pages": ["DIALOGUE_LYRA_1", "DIALOGUE_LYRA_2"],
		"choices": [
			{"id": "advice", "text_key": "DIALOGUE_LYRA_CHOICE_ADVICE", "reply_key": "DIALOGUE_LYRA_ADVICE_REPLY"},
			{"id": "farewell", "text_key": "DIALOGUE_LYRA_CHOICE_FAREWELL", "reply_key": ""},
		]
	}
}

var current_npc_id: String = ""
var current_page: int = 0
var in_reply_mode: bool = false
var active_reply_key: String = ""
var is_dialogue_open: bool = false


func start_dialogue(npc_id: String) -> bool:
	if not DIALOGUES.has(npc_id):
		return false
	current_npc_id = npc_id
	current_page = 0
	in_reply_mode = false
	active_reply_key = ""
	is_dialogue_open = true
	return true


func get_speaker_name_key() -> String:
	if not is_dialogue_open:
		return ""
	return DIALOGUES[current_npc_id].get("name_key", "")


func get_portrait_path() -> String:
	if not is_dialogue_open:
		return ""
	return DIALOGUES[current_npc_id].get("portrait", "")


func get_current_text_key() -> String:
	if not is_dialogue_open:
		return ""
	if in_reply_mode:
		return active_reply_key
	var pages: Array = DIALOGUES[current_npc_id].get("pages", [])
	if current_page >= 0 and current_page < pages.size():
		return pages[current_page]
	return ""


func get_current_page_index() -> int:
	return current_page


func get_total_pages() -> int:
	if not is_dialogue_open:
		return 0
	var pages: Array = DIALOGUES[current_npc_id].get("pages", [])
	return pages.size()


func is_on_last_page() -> bool:
	if not is_dialogue_open or in_reply_mode:
		return true
	return current_page >= (get_total_pages() - 1)


func has_choices() -> bool:
	if not is_dialogue_open or in_reply_mode:
		return false
	if not is_on_last_page():
		return false
	var choices: Array = DIALOGUES[current_npc_id].get("choices", [])
	return not choices.is_empty()


func get_choices() -> Array[Dictionary]:
	if not has_choices():
		return []
	var res: Array[Dictionary] = []
	var raw_choices: Array = DIALOGUES[current_npc_id].get("choices", [])
	for c: Dictionary in raw_choices:
		res.append(c)
	return res


## Geht zur nächsten Dialogseite. Gibt true zurück, wenn eine neue Seite vorliegt,
## oder false, falls das Gespräch beendet ist oder auf Auswahl gewartet wird.
func advance_page() -> bool:
	if not is_dialogue_open:
		return false
	if in_reply_mode:
		close_dialogue()
		return false
	if is_on_last_page():
		if has_choices():
			return false
		close_dialogue()
		return false
	current_page += 1
	return true


## Wählt eine Antwortoption aus. Gibt den Antwortschlüssel zurück, oder beendet den Dialog.
func select_choice(choice_id: String) -> String:
	if not has_choices():
		return ""
	for c in get_choices():
		if c["id"] == choice_id:
			var reply: String = c.get("reply_key", "")
			if reply != "":
				in_reply_mode = true
				active_reply_key = reply
				return reply
			else:
				close_dialogue()
				return ""
	return ""


func close_dialogue() -> void:
	is_dialogue_open = false
	current_npc_id = ""
	current_page = 0
	in_reply_mode = false
	active_reply_key = ""
