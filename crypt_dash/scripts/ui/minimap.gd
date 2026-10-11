class_name Minimap
extends Control
## Minimap für Crypt Dash: Zeigt ein 7x7 Raster der besuchten und angrenzenden Räume.
## Icons & Farben:
## - Spieler / Aktueller Raum: Türkis leuchtend
## - Besuchter Kampfraum: Hellgrau
## - Unbesuchter bekannter Nachbar: Dunkles Schieferblau
## - Schatzkammer: Gold
## - Bossraum: Rubinrot

var dungeon: DungeonGenerator.DungeonFloor
var current_coords: Vector2i = Vector2i(3, 3)
var visited_rooms: Dictionary = {} # Vector2i -> bool

const CELL_SIZE := 20.0
const PADDING := 4.0
const GRID_DIM := 7


func _init() -> void:
	custom_minimum_size = Vector2(
		GRID_DIM * (CELL_SIZE + PADDING) + 16.0,
		GRID_DIM * (CELL_SIZE + PADDING) + 16.0
	)
	mouse_filter = MOUSE_FILTER_IGNORE


func set_dungeon(d: DungeonGenerator.DungeonFloor) -> void:
	dungeon = d
	visited_rooms.clear()
	if d != null:
		set_current_room(d.start_room_coords)


func set_current_room(coords: Vector2i) -> void:
	current_coords = coords
	visited_rooms[coords] = true
	queue_redraw()


func _draw() -> void:
	if dungeon == null:
		return

	# Hintergrund-Kasten (abgerundetes Panel)
	var bg_rect := Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, Color(0.04, 0.07, 0.12, 0.8), true)
	draw_rect(bg_rect, Color(0.12, 0.2, 0.3, 0.9), false, 2.0)

	var offset_x := 8.0
	var offset_y := 8.0

	# 7x7 Räume zeichnen
	for y in range(GRID_DIM):
		for x in range(GRID_DIM):
			var coords := Vector2i(x, y)
			var r_data: DungeonGenerator.DungeonRoom = dungeon.get_room(coords)
			if r_data == null:
				continue

			var is_visited: bool = visited_rooms.get(coords, false)
			# Prüfen ob Raum an einen besuchten Raum angrenzt (Fog of War)
			var is_adjacent: bool = false
			if not is_visited:
				for n_dir in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
					if visited_rooms.get(coords + n_dir, false):
						is_adjacent = true
						break

			if not is_visited and not is_adjacent:
				continue # Noch im Nebel

			var cell_pos := Vector2(
				offset_x + x * (CELL_SIZE + PADDING),
				offset_y + y * (CELL_SIZE + PADDING)
			)
			var cell_rect := Rect2(cell_pos, Vector2(CELL_SIZE, CELL_SIZE))

			var fill_color := Color("1e293b")
			var border_color := Color("334155")

			if is_visited:
				match r_data.type:
					DungeonGenerator.RoomType.START:
						fill_color = Color("0284c7") # Blau
					DungeonGenerator.RoomType.TREASURE:
						fill_color = Color("f59e0b") # Gold
					DungeonGenerator.RoomType.BOSS:
						fill_color = Color("ef4444") # Rot
					_:
						fill_color = Color("475569") # Besuchter Kampfraum
				border_color = Color("94a3b8")
			else:
				# Bekannter Nachbarraum
				fill_color = Color("0f172a")
				border_color = Color("38bdf8") if r_data.type == DungeonGenerator.RoomType.BOSS else Color("334155")

			draw_rect(cell_rect, fill_color, true)
			draw_rect(cell_rect, border_color, false, 1.5)

			# Türen als kleine Verbindungen zeichnen
			if is_visited:
				if r_data.doors["north"]:
					draw_line(cell_pos + Vector2(CELL_SIZE / 2.0, 0), cell_pos + Vector2(CELL_SIZE / 2.0, -PADDING), Color("38bdf8"), 2.0)
				if r_data.doors["south"]:
					draw_line(cell_pos + Vector2(CELL_SIZE / 2.0, CELL_SIZE), cell_pos + Vector2(CELL_SIZE / 2.0, CELL_SIZE + PADDING), Color("38bdf8"), 2.0)
				if r_data.doors["west"]:
					draw_line(cell_pos + Vector2(0, CELL_SIZE / 2.0), cell_pos + Vector2(-PADDING, CELL_SIZE / 2.0), Color("38bdf8"), 2.0)
				if r_data.doors["east"]:
					draw_line(cell_pos + Vector2(CELL_SIZE, CELL_SIZE / 2.0), cell_pos + Vector2(CELL_SIZE + PADDING, CELL_SIZE / 2.0), Color("38bdf8"), 2.0)

			# Aktueller Spieler-Marker
			if coords == current_coords:
				draw_circle(cell_pos + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0), CELL_SIZE / 3.0, Color("22d3ee"))
				draw_circle(cell_pos + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0), CELL_SIZE / 5.0, Color.WHITE)
