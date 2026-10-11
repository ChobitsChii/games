class_name DungeonGenerator
extends RefCounted
## Prozeduraler Dungeon-Generator für Crypt Dash.
## Laut Plan:
## 1. 7x7 Raster, Startraum in der Mitte (3,3).
## 2. Raumanzahl: 7 + floor_idx * 2
## 3. Nachbarfeld wählen mit höchstens einem bereits belegten Nachbarn (vermeidet Klumpen).
## 4. Bossraum = per BFS am weitesten entfernter Raum.
## 5. Schatzraum = ein Sackgassen-Raum (genau 1 Tür / Nachbar), ungleich Start oder Boss.
## 6. Alle anderen Räume sind Kampfräume.
## 7. Deterministisch über Seed (seed + floor_idx * 1000).

enum RoomType {
	START,
	COMBAT,
	TREASURE,
	BOSS,
}

class DungeonRoom extends RefCounted:
	var coords: Vector2i
	var type: RoomType = RoomType.COMBAT
	var doors: Dictionary = {
		"north": false,
		"south": false,
		"east": false,
		"west": false,
	}
	var distance_from_start: int = 0
	var template_index: int = 0
	var cleared: bool = false
	var chest_opened: bool = false


class DungeonFloor extends RefCounted:
	var floor_idx: int = 1
	var seed_used: int = 0
	var rooms: Dictionary = {} # Vector2i -> DungeonRoom
	var start_room_coords: Vector2i = Vector2i(3, 3)
	var boss_room_coords: Vector2i = Vector2i.ZERO
	var treasure_room_coords: Vector2i = Vector2i.ZERO

	func get_room(coords: Vector2i) -> DungeonRoom:
		return rooms.get(coords, null)


static func generate_floor(base_seed: int, floor_idx: int) -> DungeonFloor:
	var floor_seed: int = base_seed + (floor_idx * 1000)
	var rng := RandomNumberGenerator.new()
	rng.seed = floor_seed

	var dungeon := DungeonFloor.new()
	dungeon.floor_idx = floor_idx
	dungeon.seed_used = floor_seed

	var target_room_count: int = 7 + (floor_idx * 2)
	var start_pos := Vector2i(3, 3)
	dungeon.start_room_coords = start_pos

	var rooms_map: Dictionary = {} # Vector2i -> DungeonRoom
	var start_room := DungeonRoom.new()
	start_room.coords = start_pos
	start_room.type = RoomType.START
	start_room.cleared = true
	rooms_map[start_pos] = start_room

	var directions := [
		Vector2i(0, -1), # North
		Vector2i(0, 1),  # South
		Vector2i(-1, 0), # West
		Vector2i(1, 0),  # East
	]

	# Schrittweises Wachsen
	var attempts := 0
	while rooms_map.size() < target_room_count and attempts < 1000:
		attempts += 1
		var keys: Array = rooms_map.keys()
		var rand_existing_coords: Vector2i = keys[rng.randi_range(0, keys.size() - 1)]

		var free_neighbors: Array[Vector2i] = []
		for dir in directions:
			var n_pos: Vector2i = rand_existing_coords + dir
			if n_pos.x >= 0 and n_pos.x < 7 and n_pos.y >= 0 and n_pos.y < 7:
				if not rooms_map.has(n_pos):
					# Prüfen wie viele Nachbarn n_pos bereits hat
					var occupied_neighbors := 0
					for check_dir in directions:
						if rooms_map.has(n_pos + check_dir):
							occupied_neighbors += 1
					if occupied_neighbors <= 1:
						free_neighbors.append(n_pos)

		if not free_neighbors.is_empty():
			var picked_pos: Vector2i = free_neighbors[rng.randi_range(0, free_neighbors.size() - 1)]
			var new_room := DungeonRoom.new()
			new_room.coords = picked_pos
			new_room.type = RoomType.COMBAT
			new_room.template_index = rng.randi_range(0, 4)
			rooms_map[picked_pos] = new_room

	# Türen zwischen angrenzenden belegten Räumen aufbauen
	for pos: Vector2i in rooms_map:
		var room: DungeonRoom = rooms_map[pos]
		if rooms_map.has(pos + Vector2i(0, -1)):
			room.doors["north"] = true
		if rooms_map.has(pos + Vector2i(0, 1)):
			room.doors["south"] = true
		if rooms_map.has(pos + Vector2i(-1, 0)):
			room.doors["west"] = true
		if rooms_map.has(pos + Vector2i(1, 0)):
			room.doors["east"] = true

	# Breitensuche (BFS) für Distanzen ab Startraum
	var queue: Array[Vector2i] = [start_pos]
	var visited: Dictionary = {start_pos: 0}
	var max_dist := 0
	var furthest_pos := start_pos

	while not queue.is_empty():
		var curr_pos: Vector2i = queue.pop_front()
		var curr_dist: int = int(visited[curr_pos])
		var curr_room: DungeonRoom = rooms_map[curr_pos]
		curr_room.distance_from_start = curr_dist

		if curr_dist > max_dist:
			max_dist = curr_dist
			furthest_pos = curr_pos

		for dir in directions:
			var n_pos: Vector2i = curr_pos + dir
			if rooms_map.has(n_pos) and not visited.has(n_pos):
				# Muss Tür haben
				var has_door := false
				if dir == Vector2i(0, -1) and curr_room.doors["north"]: has_door = true
				if dir == Vector2i(0, 1) and curr_room.doors["south"]: has_door = true
				if dir == Vector2i(-1, 0) and curr_room.doors["west"]: has_door = true
				if dir == Vector2i(1, 0) and curr_room.doors["east"]: has_door = true
				if has_door:
					visited[n_pos] = curr_dist + 1
					queue.push_back(n_pos)

	# Bossraum = am weitesten entfernt
	var boss_room: DungeonRoom = rooms_map[furthest_pos]
	boss_room.type = RoomType.BOSS
	dungeon.boss_room_coords = furthest_pos

	# Schatzraum = Sackgasse (genau 1 Tür), ungleich Start oder Boss
	var dead_ends: Array[Vector2i] = []
	for pos: Vector2i in rooms_map:
		if pos == start_pos or pos == furthest_pos:
			continue
		var room: DungeonRoom = rooms_map[pos]
		var door_count := 0
		for d in ["north", "south", "west", "east"]:
			if room.doors[d]:
				door_count += 1
		if door_count == 1:
			dead_ends.append(pos)

	if not dead_ends.is_empty():
		var treasure_pos: Vector2i = dead_ends[rng.randi_range(0, dead_ends.size() - 1)]
		var treasure_room: DungeonRoom = rooms_map[treasure_pos]
		treasure_room.type = RoomType.TREASURE
		dungeon.treasure_room_coords = treasure_pos
	else:
		# Fallback: irgendein Raum mit wenig Türen ungleich Start und Boss
		for pos: Vector2i in rooms_map:
			if pos != start_pos and pos != furthest_pos:
				var r: DungeonRoom = rooms_map[pos]
				r.type = RoomType.TREASURE
				dungeon.treasure_room_coords = pos
				break

	dungeon.rooms = rooms_map
	return dungeon
