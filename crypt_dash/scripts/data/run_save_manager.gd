class_name RunSaveManager
extends RefCounted
## Reine Daten-/Logikklasse zur Serialisierung und Wiederherstellung eines aktiven Crypt-Dash-Runs (über SaveService).

const SAVE_SECTION := "crypt_dash"
const SAVE_KEY := "active_run"
const SCHEMA_VERSION := 1


static func coord_to_key(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]


static func key_to_coord(s: String) -> Vector2i:
	var parts := s.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


static func serialize_run(
		seed_val: int,
		floor_num: int,
		room_coords: Vector2i,
		player_hp: int,
		weapon_id: String,
		items: Array[ItemData],
		dungeon: DungeonGenerator.DungeonFloor,
		visited_rooms: Dictionary) -> Dictionary:
	var item_ids: Array[String] = []
	for it in items:
		if it != null:
			item_ids.append(it.id)

	var visited_keys: Array[String] = []
	for k in visited_rooms:
		if bool(visited_rooms[k]) and k is Vector2i:
			visited_keys.append(coord_to_key(k as Vector2i))

	var cur_key := coord_to_key(room_coords)
	if not visited_keys.has(cur_key):
		visited_keys.append(cur_key)

	var cleared_keys: Array[String] = []
	var opened_keys: Array[String] = []
	if dungeon != null:
		for c: Vector2i in dungeon.rooms:
			var rm: DungeonGenerator.DungeonRoom = dungeon.rooms[c]
			if rm.cleared:
				cleared_keys.append(coord_to_key(c))
			if rm.chest_opened:
				opened_keys.append(coord_to_key(c))

	return {
		"version": SCHEMA_VERSION,
		"seed": seed_val,
		"floor": clampi(floor_num, 1, 3),
		"room_x": room_coords.x,
		"room_y": room_coords.y,
		"hp": maxi(1, player_hp),
		"weapon_id": weapon_id,
		"item_ids": item_ids,
		"visited": visited_keys,
		"cleared": cleared_keys,
		"opened_chests": opened_keys,
	}


static func save_run(data: Dictionary) -> bool:
	return SaveService.set_value(SAVE_SECTION, SAVE_KEY, data, true)


static func load_run() -> Dictionary:
	var raw: Variant = SaveService.get_value(SAVE_SECTION, SAVE_KEY, {})
	if not (raw is Dictionary):
		return {}
	var d := raw as Dictionary
	if int(d.get("version", 0)) != SCHEMA_VERSION:
		return {}
	if not d.has("seed"):
		return {}
	var f := int(d.get("floor", 0))
	var hp := int(d.get("hp", 0))
	if f < 1 or f > 3 or hp <= 0:
		return {}
	return d


static func has_saved_run() -> bool:
	return not load_run().is_empty()


static func clear_run() -> void:
	SaveService.set_value(SAVE_SECTION, SAVE_KEY, {}, true)


static func restore_items(item_ids: Array) -> Array[ItemData]:
	var catalog := ItemCatalog.get_all_items()
	var by_id := {}
	for it in catalog:
		by_id[it.id] = it
	var result: Array[ItemData] = []
	for raw_id in item_ids:
		var id_str := str(raw_id)
		if by_id.has(id_str):
			result.append(by_id[id_str] as ItemData)
	return result


static func apply_floor_state(dungeon: DungeonGenerator.DungeonFloor, data: Dictionary) -> Dictionary:
	if dungeon == null:
		return {}
	var cleared_raw: Variant = data.get("cleared", [])
	if cleared_raw is Array:
		for s in cleared_raw:
			var c := key_to_coord(str(s))
			var rm := dungeon.get_room(c)
			if rm != null:
				rm.cleared = true

	var opened_raw: Variant = data.get("opened_chests", [])
	if opened_raw is Array:
		for s in opened_raw:
			var c := key_to_coord(str(s))
			var rm := dungeon.get_room(c)
			if rm != null:
				rm.chest_opened = true

	var visited: Dictionary = {}
	visited[dungeon.start_room_coords] = true
	var visited_raw: Variant = data.get("visited", [])
	if visited_raw is Array:
		for s in visited_raw:
			var c := key_to_coord(str(s))
			if dungeon.rooms.has(c):
				visited[c] = true
	var cur := Vector2i(int(data.get("room_x", dungeon.start_room_coords.x)), int(data.get("room_y", dungeon.start_room_coords.y)))
	if dungeon.rooms.has(cur):
		visited[cur] = true
	return visited
