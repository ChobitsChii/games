class_name BoardView
extends Control
## Rendert das Spielfeld von Block Stack in moderner Glas-Optik.
## Verwendet Vektor-/Canvas-Primitiven ohne Pixel-Art.

@export var cell_size: float = StackConfig.CELL_SIZE
@export var border_color: Color = Color(0.0, 0.9, 1.0, 0.85)

var logic: GameLogic
var flash_rows: Array[int] = []
var flash_alpha: float = 0.0

var _shake_amount: float = 0.0
var _base_position: Vector2 = Vector2.ZERO
var _particles: Array[Dictionary] = []


func _ready() -> void:
	custom_minimum_size = Vector2(StackConfig.COLS * cell_size, StackConfig.VISIBLE_ROWS * cell_size)
	if _base_position == Vector2.ZERO:
		_base_position = position


func set_board_position(pos: Vector2) -> void:
	_base_position = pos
	position = pos


func set_logic(game_logic: GameLogic) -> void:
	logic = game_logic
	if logic:
		logic.piece_moved.connect(func(_p: Vector2i, _r: int) -> void: queue_redraw())
		logic.piece_spawned.connect(func(_t: String, _p: Vector2i, _r: int) -> void: queue_redraw())
		logic.piece_locked.connect(func(_t: String, _c: Array[Vector2i]) -> void: queue_redraw())
		logic.lines_cleared.connect(_on_lines_cleared)
	queue_redraw()


func shake(amount: float) -> void:
	_shake_amount = maxf(_shake_amount, amount)


func _process(delta: float) -> void:
	var needs_redraw := false
	if flash_alpha > 0.0:
		flash_alpha = maxf(0.0, flash_alpha - delta * 3.5)
		needs_redraw = true

	# Shake-Effekt abklingen lassen
	if _shake_amount > 0.0:
		_shake_amount = maxf(0.0, _shake_amount - delta * 25.0)
		position = _base_position + Vector2(randf_range(-_shake_amount, _shake_amount), randf_range(-_shake_amount, _shake_amount))
		if _shake_amount <= 0.0:
			position = _base_position
	elif position != _base_position:
		position = _base_position

	# Partikel aktualisieren
	if not _particles.is_empty():
		needs_redraw = true
		var i := _particles.size() - 1
		while i >= 0:
			var p: Dictionary = _particles[i]
			p["pos"] += p["vel"] * delta
			p["life"] -= delta
			if p["life"] <= 0.0:
				_particles.remove_at(i)
			i -= 1

	if needs_redraw:
		queue_redraw()


func _on_lines_cleared(count: int, _name: String, _pts: int, _total: int, _garb: int) -> void:
	if logic and count > 0:
		flash_rows = logic.last_cleared_rows.duplicate()
		flash_alpha = 1.0
		if count >= 4:
			shake(12.0)
		else:
			shake(4.0 * float(count))
		_spawn_clear_particles(flash_rows)
		queue_redraw()


func _spawn_clear_particles(rows: Array[int]) -> void:
	for r in rows:
		var vis_r := r - StackConfig.BUFFER_ROWS
		if vis_r >= 0 and vis_r < StackConfig.VISIBLE_ROWS:
			var y := (float(vis_r) + 0.5) * cell_size
			for c in range(StackConfig.COLS):
				var x := (float(c) + 0.5) * cell_size
				for p in range(4):
					_particles.append({
						"pos": Vector2(x + randf_range(-10, 10), y + randf_range(-10, 10)),
						"vel": Vector2(randf_range(-120, 120), randf_range(-180, 80)),
						"color": Color(0.0, 0.9, 1.0, 0.9),
						"life": randf_range(0.3, 0.6),
						"max_life": 0.6,
						"size": randf_range(3.0, 7.0),
					})


func _draw() -> void:
	var total_w := StackConfig.COLS * cell_size
	var total_h := StackConfig.VISIBLE_ROWS * cell_size
	var board_rect := Rect2(0, 0, total_w, total_h)

	# Glas-Hintergrund
	draw_rect(board_rect, Color(0.05, 0.07, 0.16, 0.82))

	# Dezentes Gitter
	var grid_col := Color(1.0, 1.0, 1.0, 0.04)
	for c in range(1, StackConfig.COLS):
		var x := c * cell_size
		draw_line(Vector2(x, 0), Vector2(x, total_h), grid_col, 1.0)
	for r in range(1, StackConfig.VISIBLE_ROWS):
		var y := r * cell_size
		draw_line(Vector2(0, y), Vector2(total_w, y), grid_col, 1.0)

	# Rahmen mit sanftem Glow
	draw_rect(board_rect, border_color, false, 2.5)

	if logic == null:
		return

	# 1. Platzierte Blöcke in der Matrix zeichnen (nur sichtbare Zeilen 2..21)
	for r in range(StackConfig.BUFFER_ROWS, StackConfig.TOTAL_ROWS):
		var vis_r := r - StackConfig.BUFFER_ROWS
		for c in range(StackConfig.COLS):
			var cell_type := logic.matrix.get_cell(c, r)
			if cell_type != "":
				var col := Piece.get_color(cell_type)
				_draw_block(Vector2(c * cell_size, vis_r * cell_size), cell_size, col, false)

	# 2. Ghost Piece zeichnen
	if logic.state == GameLogic.State.FALL or logic.state == GameLogic.State.LOCK:
		var ghost_pos := logic.get_ghost_position()
		var ghost_cells := Piece.get_cells(logic.current_piece, logic.current_rot)
		var piece_col := Piece.get_color(logic.current_piece)
		for cell in ghost_cells:
			var c := ghost_pos.x + cell.x
			var r := ghost_pos.y + cell.y
			if r >= StackConfig.BUFFER_ROWS and r < StackConfig.TOTAL_ROWS:
				var vis_r := r - StackConfig.BUFFER_ROWS
				_draw_block(Vector2(c * cell_size, vis_r * cell_size), cell_size, piece_col, true)

		# 3. Aktiver fallender Stein
		var active_cells := Piece.get_cells(logic.current_piece, logic.current_rot)
		for cell in active_cells:
			var c := logic.current_pos.x + cell.x
			var r := logic.current_pos.y + cell.y
			if r >= StackConfig.BUFFER_ROWS and r < StackConfig.TOTAL_ROWS:
				var vis_r := r - StackConfig.BUFFER_ROWS
				_draw_block(Vector2(c * cell_size, vis_r * cell_size), cell_size, piece_col, false)

	# 4. Zeilen-Flash bei Räumung
	if flash_alpha > 0.0 and not flash_rows.is_empty():
		for r in flash_rows:
			var vis_r := r - StackConfig.BUFFER_ROWS
			if vis_r >= 0 and vis_r < StackConfig.VISIBLE_ROWS:
				var flash_rect := Rect2(0, vis_r * cell_size, total_w, cell_size)
				draw_rect(flash_rect, Color(1.0, 1.0, 1.0, flash_alpha * 0.75))
				draw_rect(flash_rect, Color(0.0, 0.9, 1.0, flash_alpha * 0.9), false, 2.0)

	# 5. Glaspartikel zeichnen
	for p in _particles:
		var p_alpha: float = clampf(p["life"] / p["max_life"], 0.0, 1.0)
		var p_col: Color = p["color"]
		p_col.a *= p_alpha
		var s: float = p["size"]
		draw_rect(Rect2(p["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), p_col)


func _draw_block(pos: Vector2, size: float, color: Color, is_ghost: bool) -> void:
	var pad := 2.0
	var block_rect := Rect2(pos.x + pad, pos.y + pad, size - pad * 2.0, size - pad * 2.0)

	if is_ghost:
		# Geist: Faint Fill + zarter Rand
		draw_rect(block_rect, Color(color.r, color.g, color.b, 0.18))
		draw_rect(block_rect, Color(color.r, color.g, color.b, 0.55), false, 1.5)
	else:
		# Moderner Glas-Block:
		# 1. Hauptfüllung mit Tiefenfarbe
		draw_rect(block_rect, Color(color.r, color.g, color.b, 0.85))
		# 2. Oberer Glanz-Reflex (Spiegelung)
		var shine_rect := Rect2(block_rect.position.x + 2, block_rect.position.y + 2, block_rect.size.x - 4, block_rect.size.y * 0.38)
		draw_rect(shine_rect, Color(1.0, 1.0, 1.0, 0.32))
		# 3. Zarte Glanzkante oben
		draw_line(
			Vector2(block_rect.position.x + 2, block_rect.position.y + 2),
			Vector2(block_rect.end.x - 2, block_rect.position.y + 2),
			Color(1.0, 1.0, 1.0, 0.65),
			1.5
		)
		# 4. Leuchtender Rahmen
		draw_rect(block_rect, Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 0.95), false, 1.5)
