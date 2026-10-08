extends TestCase


func test_paddle_bounce_center_goes_straight_up() -> void:
	var v := BreakoutMath.paddle_bounce(500.0, 500.0, 180.0, 640.0)
	assert_almost(v.x, 0.0, "x")
	assert_almost(v.y, -640.0, "y")


func test_paddle_bounce_edges_are_angled_and_mirrored() -> void:
	var right := BreakoutMath.paddle_bounce(590.0, 500.0, 180.0, 640.0)
	var left := BreakoutMath.paddle_bounce(410.0, 500.0, 180.0, 640.0)
	assert_true(right.x > 0.0 and right.y < 0.0, "rechter Rand fliegt nach rechts oben")
	assert_almost(left.x, -right.x, "links ist gespiegelt")
	assert_almost(right.length(), 640.0, "Geschwindigkeit bleibt gleich")
	assert_almost(rad_to_deg(atan2(right.x, -right.y)), 60.0, "maximaler Winkel 60 Grad", 0.01)


func test_paddle_bounce_outside_is_clamped() -> void:
	var edge := BreakoutMath.paddle_bounce(590.0, 500.0, 180.0, 640.0)
	var outside := BreakoutMath.paddle_bounce(700.0, 500.0, 180.0, 640.0)
	assert_almost(outside.x, edge.x, "x")
	assert_almost(outside.y, edge.y, "y")


func test_enforce_min_vertical_keeps_length() -> void:
	var v := BreakoutMath.enforce_min_vertical(Vector2(640.0, -10.0))
	assert_almost(v.length(), Vector2(640.0, -10.0).length(), "Länge")
	assert_true(absf(v.y) >= v.length() * BreakoutMath.MIN_VERTICAL_RATIO - 0.001, "genug vertikal")
	assert_true(v.x > 0.0 and v.y < 0.0, "Richtung bleibt")


func test_enforce_min_vertical_does_not_change_steep_vectors() -> void:
	var v := Vector2(100.0, -600.0)
	assert_eq(BreakoutMath.enforce_min_vertical(v), v)


func test_enforce_min_vertical_handles_horizontal_and_zero() -> void:
	var v := BreakoutMath.enforce_min_vertical(Vector2(-640.0, 0.0))
	assert_true(v.y < 0.0 and v.x < 0.0, "waagerecht wird nach oben geneigt")
	assert_eq(BreakoutMath.enforce_min_vertical(Vector2.ZERO), Vector2.ZERO)


func test_speed_grows_and_is_capped() -> void:
	assert_almost(BreakoutMath.speed_for(1, 0), BreakoutMath.BASE_SPEED, "Startgeschwindigkeit")
	assert_true(BreakoutMath.speed_for(1, 10) > BreakoutMath.speed_for(1, 0), "mehr Blöcke, schneller")
	assert_true(BreakoutMath.speed_for(2, 0) > BreakoutMath.speed_for(1, 0), "höheres Level, schneller")
	assert_almost(BreakoutMath.speed_for(99, 999), BreakoutMath.MAX_SPEED, "Obergrenze")


func test_brick_points() -> void:
	assert_eq(BreakoutMath.brick_points(1), 10)
	assert_eq(BreakoutMath.brick_points(3), 30)


func test_all_levels_are_valid() -> void:
	assert_true(BreakoutLevels.LEVELS.size() > 0, "es gibt Level")
	for i in BreakoutLevels.LEVELS.size():
		var rows: Array = BreakoutLevels.LEVELS[i]
		assert_true(BreakoutLevels.is_valid(rows), "Level %d ist gültig" % (i + 1))
		assert_true(BreakoutLevels.breakable_count(rows) > 0, "Level %d hat zerstörbare Blöcke" % (i + 1))


func test_level_lookup_wraps_around() -> void:
	var count := BreakoutLevels.LEVELS.size()
	assert_eq(BreakoutLevels.get_level(1), BreakoutLevels.get_level(count + 1))


func test_invalid_levels_are_rejected() -> void:
	assert_true(not BreakoutLevels.is_valid(["111"]), "falsche Länge")
	assert_true(not BreakoutLevels.is_valid(["11111111Z1"]), "ungültiges Zeichen")
