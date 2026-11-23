class_name HandlingSettings
extends RefCounted
## Verwaltet Handling-Einstellungen (DAS, ARR) und den Farbblind-Modus für Block Stack.
## Reine Modell-/Hilfsklasse ohne Nodes, unit-testbar.

const DAS_MS: Array[int] = [100, 130, 170, 200, 240]
const ARR_MS: Array[int] = [0, 20, 35, 50, 80]


static func next_das_ms(current_ms: int) -> int:
	return _next_preset(DAS_MS, current_ms)


static func next_arr_ms(current_ms: int) -> int:
	return _next_preset(ARR_MS, current_ms)


static func _next_preset(presets: Array[int], current_ms: int) -> int:
	var idx := presets.find(current_ms)
	if idx != -1:
		return presets[(idx + 1) % presets.size()]
	for val in presets:
		if val > current_ms:
			return val
	return presets[0]


static func get_das_ms() -> int:
	var sec: float = float(SaveService.get_value("handling", "das", StackConfig.DEFAULT_DAS))
	return roundi(sec * 1000.0)


static func get_arr_ms() -> int:
	var sec: float = float(SaveService.get_value("handling", "arr", StackConfig.DEFAULT_ARR))
	return roundi(sec * 1000.0)


static func set_das_ms(ms: int) -> void:
	SaveService.set_value("handling", "das", float(clampi(ms, 50, 500)) / 1000.0)


static func set_arr_ms(ms: int) -> void:
	SaveService.set_value("handling", "arr", float(clampi(ms, 0, 200)) / 1000.0)


static func is_colorblind() -> bool:
	return bool(SaveService.get_value("settings", "colorblind", false))


static func set_colorblind(enabled: bool) -> void:
	SaveService.set_value("settings", "colorblind", enabled)


## Zeichnet ein kontrastreiches Vektor-Symbol pro Tetromino-Typ innerhalb eines Block-Rechtecks.
static func draw_piece_symbol(canvas: CanvasItem, rect: Rect2, piece_type: String) -> void:
	if canvas == null or piece_type == "":
		return
	var c := rect.get_center()
	var r := minf(rect.size.x, rect.size.y) * 0.24
	if r < 2.0:
		return
	var shadow := Color(0.0, 0.0, 0.0, 0.45)
	var fg := Color(1.0, 1.0, 1.0, 0.92)
	var s_off := Vector2(1.0, 1.0)

	match piece_type:
		"I":
			canvas.draw_line(c + Vector2(-r, 0) + s_off, c + Vector2(r, 0) + s_off, shadow, 3.0)
			canvas.draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), fg, 2.5)
		"O":
			canvas.draw_arc(c + s_off, r * 0.9, 0.0, TAU, 20, shadow, 2.4)
			canvas.draw_arc(c, r * 0.9, 0.0, TAU, 20, fg, 2.0)
		"T":
			var pts := PackedVector2Array([
				c + Vector2(0.0, -r),
				c + Vector2(r, r * 0.8),
				c + Vector2(-r, r * 0.8),
				c + Vector2(0.0, -r),
			])
			canvas.draw_polyline(pts, fg, 2.0)
		"S":
			canvas.draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), fg, 2.2)
			canvas.draw_line(c + Vector2(0, -r), c + Vector2(0, r), fg, 2.2)
		"Z":
			var d_pts := PackedVector2Array([
				c + Vector2(0.0, -r),
				c + Vector2(r, 0.0),
				c + Vector2(0.0, r),
				c + Vector2(-r, 0.0),
				c + Vector2(0.0, -r),
			])
			canvas.draw_polyline(d_pts, fg, 2.0)
		"J":
			var box := Rect2(c - Vector2(r * 0.85, r * 0.85), Vector2(r * 1.7, r * 1.7))
			canvas.draw_rect(box, fg, false, 2.0)
		"L":
			var l_pts := PackedVector2Array([
				c + Vector2(-r * 0.65, -r * 0.85),
				c + Vector2(-r * 0.65, r * 0.75),
				c + Vector2(r * 0.75, r * 0.75),
			])
			canvas.draw_polyline(l_pts, fg, 2.2)
		"GARBAGE":
			canvas.draw_line(c + Vector2(-r, -r), c + Vector2(r, r), fg, 2.0)
			canvas.draw_line(c + Vector2(-r, r), c + Vector2(r, -r), fg, 2.0)
