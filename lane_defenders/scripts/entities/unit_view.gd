class_name UnitView
extends Node2D
## Grafische Darstellung einer Einheit auf dem Spielfeld.
## Zeichnet Cartoon-Grafik prozedural und führt sanfte Idle- und Angriffs-Tweens aus.

var unit: GridModel.GridUnit
var _base_scale := Vector2.ONE
var _tween: Tween


func _ready() -> void:
	_start_idle_tween()


func setup(p_unit: GridModel.GridUnit) -> void:
	unit = p_unit
	queue_redraw()


func play_attack_animation() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	# Kleiner Rückstoß / Recoil
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.85, 1.15), 0.08)
	t.tween_property(self, "scale", Vector2(1.1, 0.9), 0.1)
	t.tween_property(self, "scale", Vector2.ONE, 0.12)
	t.finished.connect(_start_idle_tween)


func _start_idle_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_loops()
	# Sanftes Atmen / Wippen
	_tween.tween_property(self, "scale", Vector2(1.04, 0.96), 0.8).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "scale", Vector2(0.97, 1.03), 0.8).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	if unit == null or unit.unit_data == null:
		return

	var udata := unit.unit_data
	var id := udata.id

	# Weicher Schatten
	draw_circle(Vector2(0, 48), 42.0, Color(0, 0, 0, 0.25))

	match id:
		"generator":
			_draw_generator()
		"shooter":
			_draw_shooter(false)
		"double_shooter":
			_draw_shooter(true)
		"frost":
			_draw_frost_tower()
		"wall":
			_draw_wall()
		"mine":
			_draw_mine()
		"area_launcher":
			_draw_area_launcher()
		_:
			draw_circle(Vector2.ZERO, 38.0, udata.color)

	# Lebenspunkte-Balken (nur anzeigen wenn beschädigt)
	if unit.current_hp < unit.max_hp and unit.max_hp > 0:
		var bar_w := 70.0
		var bar_h := 8.0
		var bar_x := -bar_w * 0.5
		var bar_y := -55.0
		var pct := clampf(float(unit.current_hp) / float(unit.max_hp), 0.0, 1.0)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.1, 0.1, 0.1, 0.8), true)
		draw_rect(Rect2(bar_x + 1, bar_y + 1, (bar_w - 2) * pct, bar_h - 2), Color(0.2, 0.85, 0.3, 0.9), true)


func _draw_generator() -> void:
	# Goldene Sonnenblume / Energiekern
	var petal_count := 8
	var petal_radius := 34.0
	for i in range(petal_count):
		var angle := (TAU / float(petal_count)) * float(i)
		var p_pos := Vector2(cos(angle), sin(angle)) * 26.0
		draw_circle(p_pos, 16.0, Color("ffd700"))
	# Kern
	draw_circle(Vector2.ZERO, 28.0, Color("ffb300"))
	# Freundliches Gesicht
	draw_circle(Vector2(-10, -6), 4.0, Color("2e1a00"))
	draw_circle(Vector2(10, -6), 4.0, Color("2e1a00"))
	draw_arc(Vector2(0, 4), 10.0, 0.2, PI - 0.2, 12, Color("2e1a00"), 3.0)


func _draw_shooter(is_double: bool) -> void:
	# Robuste Erbsenkanone / Geschützturm
	var base_col := Color("4fc3f7") if not is_double else Color("0288d1")
	# Sockel
	draw_circle(Vector2(0, 15), 32.0, Color(base_col, 0.6))
	# Rohre
	if is_double:
		draw_rect(Rect2(4, -18, 38, 14), base_col, true)
		draw_rect(Rect2(4, 4, 38, 14), base_col, true)
	else:
		draw_rect(Rect2(6, -9, 42, 18), base_col, true)
	# Turmkopf
	draw_circle(Vector2.ZERO, 30.0, base_col)
	draw_circle(Vector2.ZERO, 22.0, Color(base_col.lightened(0.25)))
	# Augen
	draw_circle(Vector2(-6, -6), 5.0, Color("0b2b3b"))
	draw_circle(Vector2(12, -6), 5.0, Color("0b2b3b"))


func _draw_frost_tower() -> void:
	# Eis-Kristall-Turm
	var ice_col := Color("80d8ff")
	draw_circle(Vector2(0, 16), 34.0, Color(0.2, 0.5, 0.8, 0.5))
	# Rohr
	draw_rect(Rect2(8, -8, 38, 16), ice_col, true)
	# Eiskristall-Kopf (Rhombus)
	var pts := PackedVector2Array([
		Vector2(0, -34),
		Vector2(28, 0),
		Vector2(0, 34),
		Vector2(-28, 0)
	])
	draw_colored_polygon(pts, ice_col)
	draw_polyline(pts, Color.WHITE, 2.5)
	# Schimmer
	draw_circle(Vector2.ZERO, 10.0, Color(1, 1, 1, 0.8))


func _draw_wall() -> void:
	# Stabile Fels-/Nuss-Mauer
	var wall_col := Color("8d6e63")
	draw_rect(Rect2(-36, -42, 72, 84), wall_col, true)
	draw_rect(Rect2(-36, -42, 72, 84), wall_col.darkened(0.3), false, 4.0)
	# Augen (zeigt Zustand)
	var eye_col := Color("2d1c16")
	if unit.current_hp < unit.max_hp * 0.4:
		# Schmerzhafter Blick
		draw_line(Vector2(-20, -15), Vector2(-8, -10), eye_col, 4.0)
		draw_line(Vector2(8, -10), Vector2(20, -15), eye_col, 4.0)
	else:
		draw_circle(Vector2(-14, -12), 6.0, eye_col)
		draw_circle(Vector2(14, -12), 6.0, eye_col)
		draw_circle(Vector2(-12, -14), 2.0, Color.WHITE)
		draw_circle(Vector2(16, -14), 2.0, Color.WHITE)


func _draw_mine() -> void:
	var mine_col := Color("ff7043")
	# Flache Knolle
	draw_circle(Vector2(0, 12), 32.0, mine_col)
	# Antenne
	draw_line(Vector2(0, 0), Vector2(0, -28), Color("3e2723"), 4.0)
	# Blinkendes Licht
	var light_col := Color("76ff03") if unit.is_armed else Color("ff1744")
	draw_circle(Vector2(0, -30), 8.0, light_col)
	# Augen
	draw_circle(Vector2(-10, 8), 4.0, Color("3e2723"))
	draw_circle(Vector2(10, 8), 4.0, Color("3e2723"))


func _draw_area_launcher() -> void:
	# Violette Mörserkanone
	var col := Color("ab47bc")
	draw_circle(Vector2(0, 16), 34.0, col.darkened(0.3))
	# Schräges Mörserrohr nach oben/vorne
	var pts := PackedVector2Array([
		Vector2(-12, 10),
		Vector2(28, -25),
		Vector2(38, -15),
		Vector2(0, 24)
	])
	draw_colored_polygon(pts, col)
	draw_circle(Vector2(0, 10), 24.0, col.lightened(0.2))
