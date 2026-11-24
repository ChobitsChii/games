class_name Minimap
extends Control
## Stilvolle Obsidian-Minimap für Crypt Dash: zeigt 7x7 Raumraster mit Türen, Schatz- und Boss-Symbolen.

var dungeon: DungeonGenerator.DungeonFloor
var current_coords: Vector2i = Vector2i(3, 3)
var visited_rooms: Dictionary = {} # Vector2i -> bool

const CELL_SIZE := 20.0
const PADDING := 5.0
const GRID_DIM := 7


func _init() -> void:
	custom_minimum_size = Vector2(
		GRID_DIM * (CELL_SIZE + PADDING) + 18.0,
		GRID_DIM * (CELL_SIZE + PADDING) + 18.0
	)
	size = custom_minimum_size
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

	var bg_rect := Rect2(Vector2.ZERO, size)
	var panel_sb := CryptTheme.make_glass_card(
		Color(0.04, 0.06, 0.12, 0.88),
		Color(0.24, 0.56, 0.72, 0.72),
		2, 12,
		Color(0.0, 0.0, 0.0, 0.6), 10
	)
	draw_style_box(panel_sb, bg_rect)

	var offset_x := 11.0
	var offset_y := 11.0

	for y in range(GRID_DIM):
		for x in range(GRID_DIM):
			var coords := Vector2i(x, y)
			var r_data: DungeonGenerator.DungeonRoom = dungeon.get_room(coords)
			if r_data == null:
				continue

			var is_visited: bool = visited_rooms.get(coords, false)
			var is_adjacent: bool = false
			if not is_visited:
				for n_dir in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
					if visited_rooms.get(coords + n_dir, false):
						is_adjacent = true
						break

			if not is_visited and not is_adjacent:
				continue

			var cell_pos := Vector2(
				offset_x + x * (CELL_SIZE + PADDING),
				offset_y + y * (CELL_SIZE + PADDING)
			)
			var cell_rect := Rect2(cell_pos, Vector2(CELL_SIZE, CELL_SIZE))
			var center := cell_pos + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)

			var fill_color := Color("1e293b")
			var border_color := Color("334155")

			if is_visited:
				match r_data.type:
					DungeonGenerator.RoomType.START:
						fill_color = Color("0369a1")
					DungeonGenerator.RoomType.TREASURE:
						fill_color = Color("b45309")
					DungeonGenerator.RoomType.BOSS:
						fill_color = Color("991b1b")
					_:
						fill_color = Color("334155")
				border_color = Color("94a3b8")
			else:
				fill_color = Color("0f172a")
				if r_data.type == DungeonGenerator.RoomType.BOSS:
					border_color = Color("ef4444")
				elif r_data.type == DungeonGenerator.RoomType.TREASURE:
					border_color = Color("f59e0b")
				else:
					border_color = Color("475569")

			var cell_sb := StyleBoxFlat.new()
			cell_sb.bg_color = fill_color
			cell_sb.border_color = border_color
			cell_sb.set_border_width_all(1)
			cell_sb.set_corner_radius_all(4)
			draw_style_box(cell_sb, cell_rect)

			if is_visited:
				var conn_col := Color("38bdf8")
				if r_data.doors["north"]:
					draw_line(cell_pos + Vector2(CELL_SIZE * 0.5, 0.0), cell_pos + Vector2(CELL_SIZE * 0.5, -PADDING), conn_col, 2.5)
				if r_data.doors["south"]:
					draw_line(cell_pos + Vector2(CELL_SIZE * 0.5, CELL_SIZE), cell_pos + Vector2(CELL_SIZE * 0.5, CELL_SIZE + PADDING), conn_col, 2.5)
				if r_data.doors["west"]:
					draw_line(cell_pos + Vector2(0.0, CELL_SIZE * 0.5), cell_pos + Vector2(-PADDING, CELL_SIZE * 0.5), conn_col, 2.5)
				if r_data.doors["east"]:
					draw_line(cell_pos + Vector2(CELL_SIZE, CELL_SIZE * 0.5), cell_pos + Vector2(CELL_SIZE + PADDING, CELL_SIZE * 0.5), conn_col, 2.5)

			if r_data.type == DungeonGenerator.RoomType.TREASURE and coords != current_coords:
				var d := PackedVector2Array([
					center + Vector2(0.0, -4.5),
					center + Vector2(4.5, 0.0),
					center + Vector2(0.0, 4.5),
					center + Vector2(-4.5, 0.0),
				])
				draw_colored_polygon(d, Color("fde047"))
			elif r_data.type == DungeonGenerator.RoomType.BOSS and coords != current_coords:
				draw_circle(center, 4.5, Color("f87171"))
				draw_line(center + Vector2(-4.0, -3.0), center + Vector2(-5.5, -6.0), Color("fca5a5"), 1.5)
				draw_line(center + Vector2(4.0, -3.0), center + Vector2(5.5, -6.0), Color("fca5a5"), 1.5)

			if coords == current_coords:
				draw_circle(center, CELL_SIZE * 0.32, Color("22d3ee"))
				draw_circle(center, CELL_SIZE * 0.16, Color.WHITE)
