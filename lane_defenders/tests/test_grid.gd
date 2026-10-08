extends TestCase
## Tests für das Raster-Modell von Lane Defenders.


func test_empty_grid_bounds() -> void:
	var grid := GridModel.new(5, 9)
	assert_true(grid.is_valid_cell(0, 0), "Zelle (0,0) gültig")
	assert_true(grid.is_valid_cell(4, 8), "Zelle (4,8) gültig")
	assert_false(grid.is_valid_cell(-1, 0), "Zelle (-1,0) ungültig")
	assert_false(grid.is_valid_cell(5, 0), "Zelle (5,0) ungültig")
	assert_false(grid.is_valid_cell(0, 9), "Zelle (0,9) ungültig")
	assert_true(grid.is_cell_empty(2, 3), "Zelle (2,3) leer")


func test_place_and_remove_unit() -> void:
	var grid := GridModel.new(5, 9)
	var udata := UnitData.new()
	udata.id = "test_unit"
	udata.max_hp = 300

	var placed := grid.place_unit(2, 3, udata)
	assert_true(placed != null, "Einheit platziert")
	assert_eq(placed.lane, 2, "Lane korrekt")
	assert_eq(placed.col, 3, "Spalte korrekt")
	assert_eq(placed.current_hp, 300, "HP initialisiert")
	assert_false(grid.is_cell_empty(2, 3), "Zelle nicht mehr leer")

	# Doppeltes Platzieren abweisen
	var duplicate := grid.place_unit(2, 3, udata)
	assert_true(duplicate == null, "Doppeltes Platzieren abgewiesen")

	# Entfernen
	var removed := grid.remove_unit(2, 3)
	assert_true(removed, "Einheit entfernt")
	assert_true(grid.is_cell_empty(2, 3), "Zelle wieder leer")


func test_coordinates_conversion() -> void:
	var grid := GridModel.new(5, 9)
	# GRID_ORIGIN = (260, 200), CELL_WIDTH = 140, CELL_HEIGHT = 140
	assert_eq(grid.get_col_for_x(260.0), 0, "Spalte bei 260 ist 0")
	assert_eq(grid.get_col_for_x(400.0), 1, "Spalte bei 400 ist 1")
	assert_eq(grid.get_col_for_x(250.0), -1, "Spalte links vom Raster ist -1")

	assert_eq(grid.get_lane_for_y(200.0), 0, "Lane bei 200 ist 0")
	assert_eq(grid.get_lane_for_y(340.0), 1, "Lane bei 340 ist 1")
	assert_eq(grid.get_lane_for_y(150.0), -1, "Lane oberhalb ist -1")

	var center := grid.get_cell_center(0, 0)
	assert_almost(center.x, 330.0, "Center X von (0,0)")
	assert_almost(center.y, 270.0, "Center Y von (0,0)")
