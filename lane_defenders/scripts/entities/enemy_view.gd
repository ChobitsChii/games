class_name EnemyView
extends Node2D
## Grafische Darstellung eines Gegners auf dem Spielfeld.

var enemy: GameModel.SimEnemy
var _walk_cycle: float = 0.0
var _flash_timer: float = 0.0


func setup(p_enemy: GameModel.SimEnemy) -> void:
	enemy = p_enemy
	queue_redraw()


func play_hit_flash() -> void:
	_flash_timer = 0.12
	queue_redraw()


func update_view(delta: float) -> void:
	if enemy == null:
		return
	_walk_cycle += delta * 6.0
	if _flash_timer > 0.0:
		_flash_timer -= delta
	queue_redraw()


func _draw() -> void:
	if enemy == null or enemy.data == null:
		return

	var edata := enemy.data
	var id := edata.id

	var bob := sin(_walk_cycle) * 4.0
	var jump_offset := 0.0
	if enemy.is_jumping and enemy.jump_progress > 0.0:
		jump_offset = -sin(enemy.jump_progress * PI) * 50.0

	var center := Vector2(0, bob + jump_offset)

	# Weicher Schatten am Boden
	draw_circle(Vector2(0, 44), 36.0 if not edata.is_boss else 65.0, Color(0, 0, 0, 0.25))

	var is_flashing := (_flash_timer > 0.0)

	match id:
		"runner":
			_draw_runner(center, is_flashing)
		"fast_runner":
			_draw_fast_runner(center, is_flashing)
		"tank":
			_draw_tank(center, is_flashing)
		"jumper":
			_draw_jumper(center, is_flashing)
		"shield":
			_draw_shield(center, is_flashing)
		"boss":
			_draw_boss(center, is_flashing)
		_:
			draw_circle(center, 30.0, edata.color)

	# Frost-Aura wenn verlangsamt
	if enemy.slow_timer > 0.0:
		draw_circle(center, 36.0 if not edata.is_boss else 70.0, Color(0.3, 0.8, 1.0, 0.3))

	# Lebensbalken (wenn beschädigt oder Boss)
	if enemy.current_hp < enemy.max_hp or edata.is_boss:
		var bar_w := 70.0 if not edata.is_boss else 140.0
		var bar_h := 8.0 if not edata.is_boss else 14.0
		var bar_x := -bar_w * 0.5
		var bar_y := center.y - (55.0 if not edata.is_boss else 95.0)
		var pct := clampf(float(enemy.current_hp) / float(enemy.max_hp), 0.0, 1.0)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.1, 0.1, 0.1, 0.8), true)
		draw_rect(Rect2(bar_x + 1, bar_y + 1, (bar_w - 2) * pct, bar_h - 2), Color(0.9, 0.2, 0.2, 0.9), true)


func _draw_runner(pos: Vector2, flash: bool) -> void:
	var col := Color.WHITE if flash else Color("ef5350")
	# Körper
	draw_circle(pos, 28.0, col)
	# Beine
	var leg_swing := sin(_walk_cycle) * 12.0
	draw_line(pos + Vector2(-10, 20), pos + Vector2(-10 + leg_swing, 40), col.darkened(0.3), 6.0)
	draw_line(pos + Vector2(10, 20), pos + Vector2(10 - leg_swing, 40), col.darkened(0.3), 6.0)
	# Augen (schauen nach links)
	draw_circle(pos + Vector2(-12, -6), 5.0, Color("1a0a0a"))
	draw_circle(pos + Vector2(-4, -6), 5.0, Color("1a0a0a"))


func _draw_fast_runner(pos: Vector2, flash: bool) -> void:
	var col := Color.WHITE if flash else Color("ffa726")
	# Schlanker, schneller Körper
	draw_circle(pos, 24.0, col)
	# Flitzende Beine
	var leg_swing := sin(_walk_cycle * 1.5) * 16.0
	draw_line(pos + Vector2(-8, 16), pos + Vector2(-8 + leg_swing, 38), col.darkened(0.3), 5.0)
	draw_line(pos + Vector2(8, 16), pos + Vector2(8 - leg_swing, 38), col.darkened(0.3), 5.0)
	# Brille / Visier
	draw_rect(Rect2(pos.x - 22, pos.y - 12, 20, 12), Color("29b6f6"), true)


func _draw_tank(pos: Vector2, flash: bool) -> void:
	var col := Color.WHITE if flash else Color("78909c")
	# Massiger, breiter Körper
	draw_rect(Rect2(pos.x - 34, pos.y - 36, 68, 72), col, true)
	draw_rect(Rect2(pos.x - 34, pos.y - 36, 68, 72), col.darkened(0.4), false, 4.0)
	# Helmvisier
	draw_rect(Rect2(pos.x - 26, pos.y - 16, 24, 8), Color("263238"), true)
	# Panzerplatten
	draw_line(pos + Vector2(-28, 6), pos + Vector2(28, 6), col.darkened(0.3), 3.0)


func _draw_jumper(pos: Vector2, flash: bool) -> void:
	var col := Color.WHITE if flash else Color("66bb6a")
	# Kobold mit Federbeinen
	draw_circle(pos, 24.0, col)
	# Feder
	var spring_y := pos.y + 20.0
	for i in range(3):
		var y_off := spring_y + float(i * 6)
		draw_line(Vector2(pos.x - 8, y_off), Vector2(pos.x + 8, y_off + 3), Color("37474f"), 4.0)
	# Große wache Augen
	draw_circle(pos + Vector2(-10, -6), 6.0, Color("1b5e20"))
	draw_circle(pos + Vector2(-12, -7), 2.0, Color.WHITE)


func _draw_shield(pos: Vector2, flash: bool) -> void:
	var col := Color.WHITE if flash else Color("c0ca33")
	# Träger
	draw_circle(pos + Vector2(10, 0), 26.0, col)
	# Großer Schild vor dem Körper (links)
	var shield_col := Color("8d6e63") if not flash else Color.WHITE
	draw_rect(Rect2(pos.x - 32, pos.y - 36, 22, 72), shield_col, true)
	draw_rect(Rect2(pos.x - 32, pos.y - 36, 22, 72), Color("ffca28"), false, 3.0)
	# Niete auf dem Schild
	draw_circle(pos + Vector2(-21, 0), 5.0, Color("ffca28"))


func _draw_boss(pos: Vector2, flash: bool) -> void:
	var col := Color.WHITE if flash else Color("d32f2f")
	# Riesiger Giga-Boss
	draw_rect(Rect2(pos.x - 56, pos.y - 68, 112, 136), col, true)
	draw_rect(Rect2(pos.x - 56, pos.y - 68, 112, 136), col.darkened(0.5), false, 6.0)
	# Stachelkrone
	var crown := PackedVector2Array([
		pos + Vector2(-50, -68),
		pos + Vector2(-30, -96),
		pos + Vector2(0, -74),
		pos + Vector2(30, -96),
		pos + Vector2(50, -68)
	])
	draw_colored_polygon(crown, Color("ffd700"))
	# Glühende Augen
	draw_circle(pos + Vector2(-26, -24), 10.0, Color("ffebee"))
	draw_circle(pos + Vector2(26, -24), 10.0, Color("ffebee"))
	draw_circle(pos + Vector2(-28, -24), 5.0, Color("b71c1c"))
	draw_circle(pos + Vector2(24, -24), 5.0, Color("b71c1c"))
	# Zähne
	draw_line(pos + Vector2(-32, 24), pos + Vector2(32, 24), Color("212121"), 6.0)
