class_name DungeonState
extends RefCounted
## Verwaltet den persistenten Zustand eines Dungeons in Lumaria.
## Speichert besuchte Räume, freigeschaltete Türen, betätigte Schalter,
## geöffnete Truhen, Schlüssel und Boss-Status. Vollständig testbar ohne Nodes.

signal room_changed(room_id: int)
signal door_opened(door_id: String)
signal switch_toggled(switch_id: String, active: bool)
signal chest_opened(chest_id: String, item_type: String)
signal boss_defeated_changed()
signal prism_collected_changed()

var dungeon_id: String = "shrine_roots"
var current_room: int = 0
var rooms_visited: Dictionary = {}
var doors_unlocked: Dictionary = {}
var switches_active: Dictionary = {}
var chests_opened: Dictionary = {}
var keys_collected: int = 0
var keys_used: int = 0
var has_boss_key: bool = false
var boss_defeated: bool = false
var prism_collected: bool = false


func _init(id: String = "shrine_roots") -> void:
	dungeon_id = id
	visit_room(0)


func get_available_keys() -> int:
	return maxi(0, keys_collected - keys_used)


func visit_room(room_id: int) -> bool:
	var first_visit: bool = not rooms_visited.get(room_id, false)
	rooms_visited[room_id] = true
	current_room = room_id
	room_changed.emit(room_id)
	return first_visit


func is_room_visited(room_id: int) -> bool:
	return rooms_visited.get(room_id, false)


func add_key() -> void:
	keys_collected += 1


func can_unlock_door(door_id: String, requires_boss_key: bool = false) -> bool:
	if is_door_unlocked(door_id):
		return true
	if requires_boss_key:
		return has_boss_key
	return get_available_keys() > 0


func unlock_door(door_id: String, requires_boss_key: bool = false) -> bool:
	if is_door_unlocked(door_id):
		return true
	if requires_boss_key:
		if not has_boss_key:
			return false
		doors_unlocked[door_id] = true
		door_opened.emit(door_id)
		return true
	
	if get_available_keys() <= 0:
		return false

	keys_used += 1
	doors_unlocked[door_id] = true
	door_opened.emit(door_id)
	return true


func is_door_unlocked(door_id: String) -> bool:
	return doors_unlocked.get(door_id, false)


func set_switch(switch_id: String, active: bool) -> void:
	switches_active[switch_id] = active
	switch_toggled.emit(switch_id, active)


func toggle_switch(switch_id: String) -> bool:
	var new_state: bool = not switches_active.get(switch_id, false)
	set_switch(switch_id, new_state)
	return new_state


func is_switch_active(switch_id: String) -> bool:
	return switches_active.get(switch_id, false)


func open_chest(chest_id: String, item_type: String) -> Dictionary:
	if is_chest_opened(chest_id):
		return {"success": false, "already_opened": true, "item": ""}

	chests_opened[chest_id] = true

	match item_type:
		"small_key":
			add_key()
		"boss_key":
			has_boss_key = true
		"sun_prism":
			collect_prism()

	chest_opened.emit(chest_id, item_type)
	return {"success": true, "already_opened": false, "item": item_type}


func is_chest_opened(chest_id: String) -> bool:
	return chests_opened.get(chest_id, false)


func defeat_boss() -> void:
	if not boss_defeated:
		boss_defeated = true
		boss_defeated_changed.emit()


func collect_prism() -> void:
	if not prism_collected:
		prism_collected = true
		prism_collected_changed.emit()


func to_dict() -> Dictionary:
	return {
		"dungeon_id": dungeon_id,
		"current_room": current_room,
		"rooms_visited": rooms_visited,
		"doors_unlocked": doors_unlocked,
		"switches_active": switches_active,
		"chests_opened": chests_opened,
		"keys_collected": keys_collected,
		"keys_used": keys_used,
		"has_boss_key": has_boss_key,
		"boss_defeated": boss_defeated,
		"prism_collected": prism_collected
	}


func from_dict(data: Dictionary) -> void:
	dungeon_id = data.get("dungeon_id", "shrine_roots")
	current_room = data.get("current_room", 0)
	rooms_visited = data.get("rooms_visited", {})
	doors_unlocked = data.get("doors_unlocked", {})
	switches_active = data.get("switches_active", {})
	chests_opened = data.get("chests_opened", {})
	keys_collected = data.get("keys_collected", 0)
	keys_used = data.get("keys_used", 0)
	has_boss_key = data.get("has_boss_key", false)
	boss_defeated = data.get("boss_defeated", false)
	prism_collected = data.get("prism_collected", false)
