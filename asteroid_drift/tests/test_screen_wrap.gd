extends TestCase
## Testet das Bildschirm-Wrapping an allen Rändern und Ecken.

const RECT := Rect2(0.0, 0.0, 1920.0, 1080.0)


func test_inside_rect_remains_unchanged() -> void:
	var inside := Vector2(500.0, 400.0)
	var wrapped := ScreenWrap.wrap_position(inside, RECT)
	assert_true(wrapped.is_equal_approx(inside), "Position im Viewport bleibt gleich")


func test_wrap_right_edge() -> void:
	var beyond_right := Vector2(1930.0, 500.0)
	var wrapped := ScreenWrap.wrap_position(beyond_right, RECT)
	assert_true(is_equal_approx(wrapped.x, 10.0), "Rechter Rand wickelt nach links um: %f" % wrapped.x)
	assert_true(is_equal_approx(wrapped.y, 500.0), "Y bleibt erhalten")


func test_wrap_left_edge() -> void:
	var beyond_left := Vector2(-20.0, 300.0)
	var wrapped := ScreenWrap.wrap_position(beyond_left, RECT)
	assert_true(is_equal_approx(wrapped.x, 1900.0), "Linker Rand wickelt nach rechts um: %f" % wrapped.x)
	assert_true(is_equal_approx(wrapped.y, 300.0), "Y bleibt erhalten")


func test_wrap_bottom_edge() -> void:
	var beyond_bottom := Vector2(600.0, 1100.0)
	var wrapped := ScreenWrap.wrap_position(beyond_bottom, RECT)
	assert_true(is_equal_approx(wrapped.x, 600.0), "X bleibt erhalten")
	assert_true(is_equal_approx(wrapped.y, 20.0), "Unterer Rand wickelt nach oben um: %f" % wrapped.y)


func test_wrap_top_edge() -> void:
	var beyond_top := Vector2(600.0, -15.0)
	var wrapped := ScreenWrap.wrap_position(beyond_top, RECT)
	assert_true(is_equal_approx(wrapped.x, 600.0), "X bleibt erhalten")
	assert_true(is_equal_approx(wrapped.y, 1065.0), "Oberer Rand wickelt nach unten um: %f" % wrapped.y)


func test_wrap_all_four_corners() -> void:
	# Oben-Links
	var topleft := Vector2(-10.0, -10.0)
	var wrapped_tl := ScreenWrap.wrap_position(topleft, RECT)
	assert_true(is_equal_approx(wrapped_tl.x, 1910.0) and is_equal_approx(wrapped_tl.y, 1070.0), "Ecke Oben-Links")

	# Oben-Rechts
	var topright := Vector2(1930.0, -20.0)
	var wrapped_tr := ScreenWrap.wrap_position(topright, RECT)
	assert_true(is_equal_approx(wrapped_tr.x, 10.0) and is_equal_approx(wrapped_tr.y, 1060.0), "Ecke Oben-Rechts")

	# Unten-Links
	var bottomleft := Vector2(-15.0, 1090.0)
	var wrapped_bl := ScreenWrap.wrap_position(bottomleft, RECT)
	assert_true(is_equal_approx(wrapped_bl.x, 1905.0) and is_equal_approx(wrapped_bl.y, 10.0), "Ecke Unten-Links")

	# Unten-Rechts
	var bottomright := Vector2(1925.0, 1085.0)
	var wrapped_br := ScreenWrap.wrap_position(bottomright, RECT)
	assert_true(is_equal_approx(wrapped_br.x, 5.0) and is_equal_approx(wrapped_br.y, 5.0), "Ecke Unten-Rechts")


func test_wrap_with_margin() -> void:
	var margin := 50.0
	# Bei Margin 50 geht das Rechteck von -50 bis 1970 (Breite 2020)
	var pos := Vector2(-60.0, 500.0)
	var wrapped := ScreenWrap.wrap_with_margin(pos, RECT, margin)
	# -60 relativ zu -50 ist -10 -> fposmod(-10, 2020) = 2010 -> -50 + 2010 = 1960
	assert_true(is_equal_approx(wrapped.x, 1960.0), "Margin-Wrap links nach rechts: %f" % wrapped.x)
