class_name Matrix
extends RefCounted
## Repräsentiert das 10x22 Spielfeld von Block Stack.
## Reihen 0 und 1 sind unsichtbare Pufferreihen, 2 bis 21 sind sichtbar.

var grid: Array = []


func _init() -> void:
	clear()


func clear() -> void:
	grid = []
	for r in range(StackConfig.TOTAL_ROWS):
		var row: Array[String] = []
		for c in range(StackConfig.COLS):
			row.append("")
		grid.append(row)


func clone() -> Matrix:
	var copy := Matrix.new()
	for r in range(StackConfig.TOTAL_ROWS):
		for c in range(StackConfig.COLS):
			copy.grid[r][c] = grid[r][c]
	return copy


func is_inside_cols(col: int) -> bool:
	return col >= 0 and col < StackConfig.COLS


func get_cell(col: int, row: int) -> String:
	if col < 0 or col >= StackConfig.COLS or row < 0 or row >= StackConfig.TOTAL_ROWS:
		return ""
	return grid[row][col]


func set_cell(col: int, row: int, val: String) -> void:
	if col >= 0 and col < StackConfig.COLS and row >= 0 and row < StackConfig.TOTAL_ROWS:
		grid[row][col] = val


func can_fit(piece_type: String, rot: int, pos: Vector2i) -> bool:
	var cells := Piece.get_cells(piece_type, rot)
	for cell in cells:
		var c := pos.x + cell.x
		var r := pos.y + cell.y
		if c < 0 or c >= StackConfig.COLS:
			return false
		if r >= StackConfig.TOTAL_ROWS:
			return false
		if r >= 0:
			if grid[r][c] != "":
				return false
	return true


func lock_piece(piece_type: String, rot: int, pos: Vector2i) -> void:
	var cells := Piece.get_cells(piece_type, rot)
	for cell in cells:
		var c := pos.x + cell.x
		var r := pos.y + cell.y
		if c >= 0 and c < StackConfig.COLS and r >= 0 and r < StackConfig.TOTAL_ROWS:
			grid[r][c] = piece_type


func find_full_lines() -> Array[int]:
	var full: Array[int] = []
	for r in range(StackConfig.TOTAL_ROWS):
		var is_full := true
		for c in range(StackConfig.COLS):
			if grid[r][c] == "":
				is_full = false
				break
		if is_full:
			full.append(r)
	return full


func clear_lines(lines_to_clear: Array[int]) -> int:
	if lines_to_clear.is_empty():
		return 0
	# Löscht von oben nach unten bzw. filtert volle Reihen aus
	var new_grid: Array = []
	var cleared_count := lines_to_clear.size()
	for i in range(cleared_count):
		var empty_row: Array[String] = []
		for c in range(StackConfig.COLS):
			empty_row.append("")
		new_grid.append(empty_row)

	for r in range(StackConfig.TOTAL_ROWS):
		if not lines_to_clear.has(r):
			new_grid.append(grid[r])

	grid = new_grid
	return cleared_count


func add_garbage(count: int, hole_col: int) -> void:
	if count <= 0:
		return
	var valid_hole: int = clampi(hole_col, 0, StackConfig.COLS - 1)
	for i in range(count):
		grid.remove_at(0)
		var garbage_row: Array[String] = []
		for c in range(StackConfig.COLS):
			if c == valid_hole:
				garbage_row.append("")
			else:
				garbage_row.append("GARBAGE")
		grid.append(garbage_row)


func get_column_height(col: int) -> int:
	if col < 0 or col >= StackConfig.COLS:
		return 0
	for r in range(StackConfig.TOTAL_ROWS):
		if grid[r][col] != "":
			return StackConfig.TOTAL_ROWS - r
	return 0


func get_aggregate_height() -> int:
	var total := 0
	for c in range(StackConfig.COLS):
		total += get_column_height(c)
	return total


func count_holes() -> int:
	var holes := 0
	for c in range(StackConfig.COLS):
		var block_found := false
		for r in range(StackConfig.TOTAL_ROWS):
			if grid[r][c] != "":
				block_found = true
			elif block_found:
				holes += 1
	return holes


func get_bumpiness() -> int:
	var bumpiness := 0
	for c in range(StackConfig.COLS - 1):
		var h1 := get_column_height(c)
		var h2 := get_column_height(c + 1)
		bumpiness += absi(h1 - h2)
	return bumpiness


func is_empty_board() -> bool:
	for r in range(StackConfig.TOTAL_ROWS):
		for c in range(StackConfig.COLS):
			if grid[r][c] != "":
				return false
	return true
