class_name BoardView
extends Control
## Moderne 2.5D-Präsentation des Connect-Four-Spielbretts.
## Unterstützt Maus-, Tastatur- und Gamepad-Steuerung, fallende Steine mit Easing,
## Glanz-Effekte, Partikel und Farbenblind-Symbole.

signal column_clicked(col: int)

@export var cell_spacing: float = GameConfig.CELL_SPACING
@export var disc_radius: float = GameConfig.DISC_RADIUS

var controller: GameController

var _falling_discs: Array[Dictionary] = []
var _particles: Array[Dictionary] = []
var _winning_cells: Array[Vector2i] = []
var _win_pulse_time: float = 0.0
var _hover_arrow_time: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(GameConfig.BOARD_WIDTH, GameConfig.BOARD_HEIGHT + 140.0)


func setup(p_controller: GameController) -> void:
	controller = p_controller
	controller.disc_dropped.connect(_on_disc_dropped)
	controller.game_ended.connect(_on_game_ended)
	controller.state_changed.connect(func(_s: GameController.State) -> void: queue_redraw())
	queue_redraw()


func _process(delta: float) -> void:
	var needs_redraw := false

	_hover_arrow_time += delta * 4.0

	if not _winning_cells.is_empty():
		_win_pulse_time += delta * 5.0
		needs_redraw = true

	# Fallende Steine animieren
	var i := _falling_discs.size() - 1
	while i >= 0:
		var d: Dictionary = _falling_discs[i]
		d["progress"] += delta / GameConfig.ANIM_DROP_DURATION
		if d["progress"] >= 1.0:
			d["progress"] = 1.0
			_falling_discs.remove_at(i)
			# Sound & Staubpartikel beim Aufprall
			var sfx := SoundEffects.get_instance()
			if sfx != null:
				sfx.play_drop()
			_spawn_impact_particles(d["col"], d["row"], d["player"])
			if controller != null:
				controller.on_drop_animation_finished()
		needs_redraw = true
		i -= 1

	# Partikel aktualisieren
	if not _particles.is_empty():
		needs_redraw = true
		var p_idx := _particles.size() - 1
		while p_idx >= 0:
			var pt: Dictionary = _particles[p_idx]
			pt["pos"] += pt["vel"] * delta
			pt["vel"].y += 380.0 * delta # Schwerkraft
			pt["life"] -= delta
			if pt["life"] <= 0.0:
				_particles.remove_at(p_idx)
			p_idx -= 1

	if needs_redraw:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if controller == null or controller.state != GameController.State.PLAYER_TURN:
		return

	if event is InputEventMouseMotion:
		var col := _x_to_column(event.position.x)
		if col != -1 and col != controller.selected_col:
			controller.set_selected_column(col)
			var sfx := SoundEffects.get_instance()
			if sfx != null:
				sfx.play_hover()
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var col := _x_to_column(event.position.x)
		if col != -1:
			column_clicked.emit(col)


func _on_disc_dropped(col: int, row: int, player: int) -> void:
	var start_y := _get_cell_center(col, 5).y - disc_radius * 3.0
	var target_y := _get_cell_center(col, row).y

	_falling_discs.append({
		"col": col,
		"row": row,
		"player": player,
		"start_y": start_y,
		"target_y": target_y,
		"progress": 0.0,
	})
	queue_redraw()


func _on_game_ended(winner: int, winning: Array[Vector2i]) -> void:
	_winning_cells = winning
	var sfx := SoundEffects.get_instance()
	if sfx != null:
		if winner != Board.CELL_EMPTY:
			sfx.play_win()
			_spawn_win_confetti()
		else:
			sfx.play_draw()
	queue_redraw()


func reset_view() -> void:
	_falling_discs.clear()
	_particles.clear()
	_winning_cells.clear()
	_win_pulse_time = 0.0
	queue_redraw()


func _draw() -> void:
	var origin_x := (size.x - GameConfig.BOARD_WIDTH) * 0.5
	var origin_y := 120.0
	var board_rect := Rect2(origin_x, origin_y, GameConfig.BOARD_WIDTH, GameConfig.BOARD_HEIGHT)

	# 1. Tisch-/Hintergrund-Schatten
	var shadow_rect := Rect2(origin_x + 8, origin_y + 16, GameConfig.BOARD_WIDTH, GameConfig.BOARD_HEIGHT + 20)
	draw_rect(shadow_rect, Color(0, 0, 0, 0.45), true)

	# 2. Rückwand des Bretts (hinter den Löchern)
	draw_rect(board_rect, GameConfig.PALETTE["board_back"])

	# 3. Bereits platzierte Steine auf der Rückwand zeichnen
	if controller != null:
		for c in range(Board.WIDTH):
			for r in range(Board.HEIGHT):
				# Falls der Stein gerade im Flug ist, hier noch nicht zeichnen
				var is_dropping := false
				for d in _falling_discs:
					if d["col"] == c and d["row"] == r:
						is_dropping = true
						break
				if is_dropping:
					continue

				var cell_val := controller.board.get_cell(c, r)
				if cell_val != Board.CELL_EMPTY:
					var center := _get_cell_center(c, r)
					var is_win_disc := _winning_cells.has(Vector2i(c, r))
					_draw_disc(center, disc_radius, cell_val, is_win_disc)

	# 4. Fallende Steine zeichnen
	for d in _falling_discs:
		var c: int = d["col"]
		var prog: float = d["progress"]
		# Easing mit leichtem Bounce am Ende
		var eased_prog := _ease_out_bounce(prog)
		var cur_y: float = lerpf(d["start_y"], d["target_y"], eased_prog)
		var center := Vector2(_get_cell_center(c, 0).x, cur_y)
		_draw_disc(center, disc_radius, d["player"], false)

	# 5. Vorderwand des Bretts (Blaue Front mit runden Gucklöchern)
	# Zeichnen als abgerundetes Rechteck mit Aussparungen (Raster)
	_draw_board_front(board_rect)

	# 6. Spalten-Hover-Vorschau und Einwurf-Indikator
	if controller != null and controller.state == GameController.State.PLAYER_TURN:
		var sel_c := controller.selected_col
		if controller.board.can_play(sel_c):
			var top_cell := _get_cell_center(sel_c, 5)
			var hover_y := origin_y - disc_radius - 16.0 + sin(_hover_arrow_time) * 6.0
			var hover_center := Vector2(top_cell.x, hover_y)
			var turn_player := controller.board.current_player()
			_draw_disc(hover_center, disc_radius * 0.9, turn_player, false, 0.75)

			# Dezent leuchtender Einwurf-Pfeil
			var arrow_tip := hover_center + Vector2(0, disc_radius * 0.95 + 8)
			var arrow_col := GameConfig.PALETTE["accent"]
			draw_line(arrow_tip, arrow_tip + Vector2(-12, -12), arrow_col, 3.0)
			draw_line(arrow_tip, arrow_tip + Vector2(12, -12), arrow_col, 3.0)

	# 7. Gewinner-Linie und Hervorhebung
	if not _winning_cells.is_empty():
		_draw_winning_highlight()

	# 8. Partikel zeichnen
	for pt in _particles:
		var alpha: float = clampf(pt["life"] / pt["max_life"], 0.0, 1.0)
		var col: Color = pt["color"]
		col.a *= alpha
		draw_circle(pt["pos"], pt["size"] * alpha, col)


func _draw_board_front(board_rect: Rect2) -> void:
	# Front-Rahmen mit sanftem Farbverlauf
	var front_col: Color = GameConfig.PALETTE["board_front"]
	var rim_col: Color = GameConfig.PALETTE["board_rim"]

	draw_rect(board_rect, front_col, true)
	draw_rect(board_rect, rim_col, false, 5.0)

	# Füße / Standbeine des Bretts
	var leg_w := 34.0
	var leg_h := 36.0
	draw_rect(Rect2(board_rect.position.x - 14, board_rect.end.y - 10, leg_w + 14, leg_h), front_col.darkened(0.2))
	draw_rect(Rect2(board_rect.end.x - leg_w, board_rect.end.y - 10, leg_w + 14, leg_h), front_col.darkened(0.2))

	# Aussparungen für jedes der 7x6 Felder zeichnen
	for c in range(Board.WIDTH):
		for r in range(Board.HEIGHT):
			var center := _get_cell_center(c, r)
			var is_empty := (controller == null or controller.board.get_cell(c, r) == Board.CELL_EMPTY)

			if is_empty:
				# Leeres Loch: Dunkle Tiefenöffnung
				draw_circle(center, disc_radius, GameConfig.PALETTE["slot_empty"])

			# Innere Lichtkante (Bevel-Look)
			draw_arc(center, disc_radius, 0.0, TAU, 32, Color(1, 1, 1, 0.22), 2.0)
			# Äußerer Schattenring
			draw_arc(center, disc_radius + 2.0, PI * 0.5, PI * 1.5, 24, Color(0, 0, 0, 0.45), 2.5)


func _draw_disc(center: Vector2, radius: float, player: int, is_win: bool, alpha: float = 1.0) -> void:
	var base_col: Color
	var glow_col: Color
	if player == Board.CELL_PLAYER_1:
		base_col = GameConfig.PALETTE["player1"]
		glow_col = GameConfig.PALETTE["player1_glow"]
	else:
		base_col = GameConfig.PALETTE["player2"]
		glow_col = GameConfig.PALETTE["player2_glow"]

	base_col.a *= alpha
	glow_col.a *= alpha

	# Äußerer Diskus-Körper
	draw_circle(center, radius, base_col)

	# 3D-Kantenring (Licht und Schatten)
	draw_arc(center, radius - 2, 0.0, TAU, 32, base_col.darkened(0.3), 3.0)

	# Glanz-Reflex oben links
	var shine_center := center + Vector2(-radius * 0.28, -radius * 0.28)
	draw_circle(shine_center, radius * 0.38, Color(1, 1, 1, 0.35 * alpha))

	# Farbenblind-Muster (falls aktiv)
	var cb_active := (controller != null and controller.colorblind_mode)
	if cb_active:
		var symbol_col := Color(1, 1, 1, 0.85 * alpha)
		if player == Board.CELL_PLAYER_1:
			# Ring / Kreis
			draw_arc(center, radius * 0.45, 0.0, TAU, 28, symbol_col, 4.0)
		else:
			# Stern / Kreuz
			var sz := radius * 0.45
			draw_line(center - Vector2(sz, 0), center + Vector2(sz, 0), symbol_col, 4.0)
			draw_line(center - Vector2(0, sz), center + Vector2(0, sz), symbol_col, 4.0)

	# Gewinn-Pulsieren
	if is_win:
		var pulse := (sin(_win_pulse_time) + 1.0) * 0.5
		var gold: Color = GameConfig.PALETTE["win_gold"]
		draw_arc(center, radius + 4.0 + pulse * 6.0, 0.0, TAU, 36, Color(gold.r, gold.g, gold.b, 0.9 * pulse), 4.0)


func _draw_winning_highlight() -> void:
	if _winning_cells.size() < 4:
		return

	var gold: Color = GameConfig.PALETTE["win_gold"]
	var pulse := (sin(_win_pulse_time) + 1.0) * 0.5

	# Strahlende Verbindungslinie durch die 4 Steine
	var p0 := _get_cell_center(_winning_cells[0].x, _winning_cells[0].y)
	var p3 := _get_cell_center(_winning_cells[3].x, _winning_cells[3].y)
	draw_line(p0, p3, Color(gold.r, gold.g, gold.b, 0.75 + pulse * 0.25), 6.0)
	draw_line(p0, p3, Color(1, 1, 1, 0.9), 2.5)


func _get_cell_center(col: int, row: int) -> Vector2:
	var origin_x := (size.x - GameConfig.BOARD_WIDTH) * 0.5
	var origin_y := 120.0
	var pad_x := (GameConfig.BOARD_WIDTH - (float(Board.WIDTH - 1) * cell_spacing)) * 0.5
	var pad_y := (GameConfig.BOARD_HEIGHT - (float(Board.HEIGHT - 1) * cell_spacing)) * 0.5

	var x := origin_x + pad_x + float(col) * cell_spacing
	# row 0 ist unten, row 5 ist oben
	var y := origin_y + pad_y + float(Board.HEIGHT - 1 - row) * cell_spacing
	return Vector2(x, y)


func _x_to_column(px: float) -> int:
	var origin_x := (size.x - GameConfig.BOARD_WIDTH) * 0.5
	var pad_x := (GameConfig.BOARD_WIDTH - (float(Board.WIDTH - 1) * cell_spacing)) * 0.5
	var start_x := origin_x + pad_x - cell_spacing * 0.5

	for c in range(Board.WIDTH):
		var left := start_x + float(c) * cell_spacing
		var right := left + cell_spacing
		if px >= left and px < right:
			return c
	return -1


func _ease_out_bounce(t: float) -> float:
	var n1 := 7.5625
	var d1 := 2.75
	if t < 1.0 / d1:
		return n1 * t * t
	elif t < 2.0 / d1:
		t -= 1.5 / d1
		return n1 * t * t + 0.75
	elif t < 2.5 / d1:
		t -= 2.25 / d1
		return n1 * t * t + 0.9375
	else:
		t -= 2.625 / d1
		return n1 * t * t + 0.984375


func _spawn_impact_particles(col: int, row: int, player: int) -> void:
	var center := _get_cell_center(col, row)
	var col_color := GameConfig.PALETTE["player1"] if player == Board.CELL_PLAYER_1 else GameConfig.PALETTE["player2"]

	for i in range(8):
		var angle := randf_range(PI * 1.1, PI * 1.9) # Nach oben spritzen
		var speed := randf_range(80.0, 190.0)
		_particles.append({
			"pos": center + Vector2(randf_range(-14, 14), disc_radius * 0.6),
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed),
			"color": col_color.lightened(0.3),
			"size": randf_range(3.0, 6.0),
			"life": randf_range(0.25, 0.45),
			"max_life": 0.45,
		})


func _spawn_win_confetti() -> void:
	for i in range(40):
		var p_col: Color = GameConfig.PALETTE["win_gold"] if (i % 2 == 0) else Color(1, 1, 1)
		_particles.append({
			"pos": Vector2(randf_range(100, size.x - 100), randf_range(80, 200)),
			"vel": Vector2(randf_range(-140, 140), randf_range(-180, -40)),
			"color": p_col,
			"size": randf_range(4.0, 8.0),
			"life": randf_range(0.8, 1.6),
			"max_life": 1.6,
		})
