class_name QuestManager
extends RefCounted
## Quest- und Fortschrittsverwaltung für Lumaria: The Prismatic Odyssey.
## Verwaltet Haupt- und Nebenquests sowie deren Meilensteine.
## Vollständig ohne Szenenbaum unit-testbar.

enum QuestState { UNSTARTED, ACTIVE, COMPLETED }

var _quests: Dictionary = {
	"main_sun_prism": {
		"title_key": "QUEST_MAIN_TITLE",
		"desc_key": "QUEST_MAIN_DESC",
		"state": QuestState.ACTIVE,
		"step": 0,
	}
}


func get_active_quest_title_key() -> String:
	for q_id in _quests:
		if _quests[q_id]["state"] == QuestState.ACTIVE:
			return _quests[q_id]["title_key"]
	return ""


func get_active_quest_desc_key() -> String:
	for q_id in _quests:
		if _quests[q_id]["state"] == QuestState.ACTIVE:
			return _quests[q_id]["desc_key"]
	return ""


func get_quest_state(quest_id: String) -> QuestState:
	if _quests.has(quest_id):
		return _quests[quest_id]["state"]
	return QuestState.UNSTARTED


func start_quest(quest_id: String, title_key: String, desc_key: String) -> void:
	_quests[quest_id] = {
		"title_key": title_key,
		"desc_key": desc_key,
		"state": QuestState.ACTIVE,
		"step": 0,
	}


func advance_quest(quest_id: String, new_desc_key: String = "") -> void:
	if not _quests.has(quest_id):
		return
	_quests[quest_id]["step"] += 1
	if new_desc_key != "":
		_quests[quest_id]["desc_key"] = new_desc_key


func complete_quest(quest_id: String) -> void:
	if _quests.has(quest_id):
		_quests[quest_id]["state"] = QuestState.COMPLETED


func is_quest_completed(quest_id: String) -> bool:
	return get_quest_state(quest_id) == QuestState.COMPLETED
