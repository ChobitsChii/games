class_name GridModel
extends RefCounted
## Raster-Modell für Lane Defenders (5 Lanes × 9 Spalten).
## Verwaltet Platzierung, Lebenspunkte und Abfragen von Einheiten ohne Node-Abhängigkeit.

class GridUnit:
	extends RefCounted
	var unit_data: UnitData
	var lane: int
	var col: int
	var current_hp: int
	var max_hp: int
	var attack_timer: float = 0.0
	var produce_timer: float = 0.0
	var arm_timer: float = 0.0
	var is_armed: bool = false

	func _init(p_data: UnitData, p_lane: int, p_col: int) -> void:
		unit_data = p_data
		lane = p_lane
		col = p_col
		max_hp = p_data.max_hp
		current_hp = p_data.max_hp
		attack_timer = 0.0
		produce_timer = 0.0
		arm_timer = 0.0
		is_armed = (p_data.arm_time <= 0.0)

var lanes: int = LaneDefendersConfig.LANES
var cols: int = LaneDefendersConfig.COLS
var _cells: Array = [] # 2D: [lane][col]


func _init(p_lanes: int = LaneDefendersConfig.LANES, p_cols: int = LaneDefendersConfig.COLS) -> void:
	lanes = p_lanes
	cols = p_cols
	clear()


func clear() -> void:
	_cells.clear()
	for l in range(lanes):
		var row: Array = []
		for c in range(cols):
			row.append(null)
		_cells.append(row)


func is_valid_cell(lane: int, col: int) -> bool:
	return lane >= 0 and lane < lanes and col >= 0 and col < cols


func is_cell_empty(lane: int, col: int) -> bool:
	if not is_valid_cell(lane, col):
		return false
	return _cells[lane][col] == null


func place_unit(lane: int, col: int, data: UnitData) -> GridUnit:
	if not is_valid_cell(lane, col) or not is_cell_empty(lane, col) or data == null:
		return null
	var unit := GridUnit.new(data, lane, col)
	_cells[lane][col] = unit
	return unit


func remove_unit(lane: int, col: int) -> bool:
	if not is_valid_cell(lane, col) or _cells[lane][col] == null:
		return false
	_cells[lane][col] = null
	return true


func get_unit(lane: int, col: int) -> GridUnit:
	if not is_valid_cell(lane, col):
		return null
	return _cells[lane][col]


func get_col_for_x(x: float) -> int:
	var offset: float = x - LaneDefendersConfig.GRID_ORIGIN.x
	if offset < 0.0:
		return -1
	var c: int = int(floor(offset / LaneDefendersConfig.CELL_WIDTH))
	return c if (c >= 0 and c < cols) else -1


func get_lane_for_y(y: float) -> int:
	var offset: float = y - LaneDefendersConfig.GRID_ORIGIN.y
	if offset < 0.0:
		return -1
	var l: int = int(floor(offset / LaneDefendersConfig.CELL_HEIGHT))
	return l if (l >= 0 and l < lanes) else -1


func get_cell_rect(lane: int, col: int) -> Rect2:
	return Rect2(
		LaneDefendersConfig.GRID_ORIGIN.x + col * LaneDefendersConfig.CELL_WIDTH,
		LaneDefendersConfig.GRID_ORIGIN.y + lane * LaneDefendersConfig.CELL_HEIGHT,
		LaneDefendersConfig.CELL_WIDTH,
		LaneDefendersConfig.CELL_HEIGHT
	)


func get_cell_center(lane: int, col: int) -> Vector2:
	return Vector2(
		LaneDefendersConfig.GRID_ORIGIN.x + (float(col) + 0.5) * LaneDefendersConfig.CELL_WIDTH,
		LaneDefendersConfig.GRID_ORIGIN.y + (float(lane) + 0.5) * LaneDefendersConfig.CELL_HEIGHT
	)


func get_all_units() -> Array:
	var result: Array = []
	for l in range(lanes):
		for c in range(cols):
			var u: Variant = _cells[l][c]
			if u != null:
				result.append(u)
	return result


func get_units_in_lane(lane: int) -> Array:
	var result: Array = []
	if not (lane >= 0 and lane < lanes):
		return result
	for c in range(cols):
		var u: Variant = _cells[lane][c]
		if u != null:
			result.append(u)
	return result
