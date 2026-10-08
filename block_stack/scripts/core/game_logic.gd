class_name GameLogic
extends RefCounted
## Reine Spiellogik für Block Stack (ohne Nodes, vollständig testbar).
## Steuert Zustände, Gravitation, SRS-Bewegung, Hold, Ghost, Lock Delay,
## T-Spin-Erkennung, Punkte und Müllberechnung.

signal state_changed(new_state: int)
signal piece_spawned(type: String, pos: Vector2i, rot: int)
signal piece_moved(pos: Vector2i, rot: int)
signal piece_locked(type: String, cells: Array[Vector2i])
signal lines_cleared(count: int, clear_name: String, points: int, lines_total: int, garbage_sent: int)
signal garbage_received(count: int)
signal game_over_triggered()

enum State { SPAWN, FALL, LOCK, CLEAR, GAME_OVER }

var matrix: Matrix
var bag: Bag
var rng: RandomNumberGenerator

var state: State = State.SPAWN
var current_piece: String = ""
var current_pos: Vector2i = Vector2i.ZERO
var current_rot: int = 0
var hold_piece: String = ""
var can_hold: bool = true

var score: int = 0
var lines: int = 0
var level: int = 1
var combo: int = -1
var b2b: bool = false
var game_over: bool = false

# Timing und Verzögerungen
var fall_timer: float = 0.0
var lock_timer: float = 0.0
var lock_resets: int = 0
var is_on_floor: bool = false
var lock_delay: float = StackConfig.DEFAULT_LOCK_DELAY

# Zuletzt ausgeführte Aktion (für T-Spin-Erkennung)
var last_action_was_rotate: bool = false

# Eingehender Müll im Duell
var pending_garbage: int = 0
var last_garbage_hole_col: int = -1

# Letzte geräumte Zeilen für Animation
var last_cleared_rows: Array[int] = []


func _init(random_generator: RandomNumberGenerator = null, initial_level: int = 1) -> void:
	if random_generator != null:
		rng = random_generator
	else:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	matrix = Matrix.new()
	bag = Bag.new(rng)
	level = initial_level
	last_garbage_hole_col = rng.randi_range(0, StackConfig.COLS - 1)
	spawn_next()


func get_gravity_interval() -> float:
	# Formel aus Plan: (0.8 - (level - 1) * 0.007)^(level - 1)
	var base: float = maxf(0.01, 0.8 - float(level - 1) * 0.007)
	return maxf(0.015, pow(base, float(level - 1)))


func update(delta: float, is_soft_dropping: bool = false) -> void:
	if state == State.GAME_OVER:
		return

	if state == State.SPAWN:
		spawn_next()
		return

	if state == State.CLEAR:
		# Zeilenanimation beendet -> Nächster Stein
		state = State.SPAWN
		state_changed.emit(state)
		spawn_next()
		return

	var gravity := get_gravity_interval()
	if is_soft_dropping:
		gravity = minf(gravity, gravity / 20.0)

	fall_timer += delta

	# Fallen lassen
	if fall_timer >= gravity:
		fall_timer = 0.0
		var next_pos := current_pos + Vector2i(0, 1)
		if matrix.can_fit(current_piece, current_rot, next_pos):
			current_pos = next_pos
			last_action_was_rotate = false
			piece_moved.emit(current_pos, current_rot)
			if is_soft_dropping:
				score += 1
		else:
			is_on_floor = true

	# Lock Delay prüfen
	if not matrix.can_fit(current_piece, current_rot, current_pos + Vector2i(0, 1)):
		is_on_floor = true
		lock_timer += delta
		if lock_timer >= lock_delay:
			lock_and_process()
	else:
		is_on_floor = false
		lock_timer = 0.0


func spawn_next(allow_hold: bool = true) -> void:
	# Falls Müll ansteht, jetzt am Boden einfügen
	if pending_garbage > 0:
		matrix.add_garbage(pending_garbage, last_garbage_hole_col)
		pending_garbage = 0

	current_piece = bag.pop()
	current_rot = 0
	current_pos = Piece.get_spawn_pos(current_piece)
	can_hold = allow_hold
	lock_timer = 0.0
	lock_resets = 0
	fall_timer = 0.0
	is_on_floor = false
	last_action_was_rotate = false

	# Wenn der neue Stein sofort kollidiert -> Game Over
	if not matrix.can_fit(current_piece, current_rot, current_pos):
		trigger_game_over()
		return

	state = State.FALL
	state_changed.emit(state)
	piece_spawned.emit(current_piece, current_pos, current_rot)


func move_horizontal(dir: int) -> bool:
	if state != State.FALL and state != State.LOCK:
		return false
	var target_pos := current_pos + Vector2i(dir, 0)
	if matrix.can_fit(current_piece, current_rot, target_pos):
		current_pos = target_pos
		last_action_was_rotate = false
		_on_piece_manipulated()
		piece_moved.emit(current_pos, current_rot)
		return true
	return false


func soft_drop_step() -> bool:
	if state != State.FALL and state != State.LOCK:
		return false
	var target_pos := current_pos + Vector2i(0, 1)
	if matrix.can_fit(current_piece, current_rot, target_pos):
		current_pos = target_pos
		score += 1
		last_action_was_rotate = false
		piece_moved.emit(current_pos, current_rot)
		return true
	return false


func hard_drop() -> int:
	if state != State.FALL and state != State.LOCK:
		return 0
	var drop_distance := 0
	while matrix.can_fit(current_piece, current_rot, current_pos + Vector2i(0, 1)):
		current_pos.y += 1
		drop_distance += 1

	score += drop_distance * 2
	lock_and_process()
	return drop_distance


func rotate(clockwise: bool) -> bool:
	if state != State.FALL and state != State.LOCK:
		return false

	var next_rot := posmod(current_rot + (1 if clockwise else -1), 4)
	var kicks := Piece.get_kicks(current_piece, current_rot, next_rot)

	for kick in kicks:
		var target_pos := current_pos + kick
		if matrix.can_fit(current_piece, next_rot, target_pos):
			current_pos = target_pos
			current_rot = next_rot
			last_action_was_rotate = true
			_on_piece_manipulated()
			piece_moved.emit(current_pos, current_rot)
			return true
	return false


func hold() -> bool:
	if (state != State.FALL and state != State.LOCK) or not can_hold:
		return false

	can_hold = false
	var to_hold := current_piece
	if hold_piece == "":
		hold_piece = to_hold
		spawn_next(false)
	else:
		var prev_hold := hold_piece
		hold_piece = to_hold
		current_piece = prev_hold
		current_rot = 0
		current_pos = Piece.get_spawn_pos(current_piece)
		lock_timer = 0.0
		lock_resets = 0
		fall_timer = 0.0
		is_on_floor = false
		last_action_was_rotate = false
		if not matrix.can_fit(current_piece, current_rot, current_pos):
			trigger_game_over()
			return false
		piece_spawned.emit(current_piece, current_pos, current_rot)
	return true


func get_ghost_position() -> Vector2i:
	var ghost := current_pos
	while matrix.can_fit(current_piece, current_rot, ghost + Vector2i(0, 1)):
		ghost.y += 1
	return ghost


func _on_piece_manipulated() -> void:
	if is_on_floor and lock_resets < StackConfig.MAX_LOCK_RESETS:
		lock_timer = 0.0
		lock_resets += 1


func is_t_spin() -> bool:
	if current_piece != "T" or not last_action_was_rotate:
		return false
	# 3-Corner-Regel
	var occupied_corners := 0
	var corners := [
		current_pos,
		current_pos + Vector2i(2, 0),
		current_pos + Vector2i(0, 2),
		current_pos + Vector2i(2, 2),
	]
	for c in corners:
		if c.x < 0 or c.x >= StackConfig.COLS or c.y >= StackConfig.TOTAL_ROWS:
			occupied_corners += 1
		elif c.y >= 0 and matrix.get_cell(c.x, c.y) != "":
			occupied_corners += 1
	return occupied_corners >= 3


func lock_and_process() -> void:
	var tspin := is_t_spin()
	var cells := Piece.get_cells(current_piece, current_rot)
	var locked_cells: Array[Vector2i] = []
	for c in cells:
		locked_cells.append(current_pos + c)

	matrix.lock_piece(current_piece, current_rot, current_pos)
	piece_locked.emit(current_piece, locked_cells)

	# Prüfen, ob alle Blöcke oberhalb des sichtbaren Bereichs platziert wurden (Top-Out)
	var all_above := true
	for cell in locked_cells:
		if cell.y >= StackConfig.BUFFER_ROWS:
			all_above = false
			break
	if all_above:
		trigger_game_over()
		return

	# Volle Zeilen ermitteln
	var full_rows := matrix.find_full_lines()
	last_cleared_rows = full_rows
	var cleared_count := full_rows.size()

	if cleared_count > 0:
		matrix.clear_lines(full_rows)
		lines += cleared_count
		combo += 1

		# Levelaufstieg im Marathon (alle 10 Zeilen)
		level = 1 + int(lines / 10)

		# Punkte und Wertung berechnen
		var base_points := 0
		var clear_name := ""
		var is_difficult := false
		var garbage_to_send := 0

		if tspin:
			is_difficult = true
			match cleared_count:
				1:
					base_points = 800
					clear_name = "MSG_TSPIN_SINGLE"
					garbage_to_send = 2
				2:
					base_points = 1200
					clear_name = "MSG_TSPIN_DOUBLE"
					garbage_to_send = 4
				3:
					base_points = 1600
					clear_name = "MSG_TSPIN_TRIPLE"
					garbage_to_send = 6
				_:
					base_points = 400
					clear_name = "MSG_TSPIN"
		else:
			match cleared_count:
				1:
					base_points = 100
					clear_name = "MSG_SINGLE"
					garbage_to_send = 0
				2:
					base_points = 300
					clear_name = "MSG_DOUBLE"
					garbage_to_send = 1
				3:
					base_points = 500
					clear_name = "MSG_TRIPLE"
					garbage_to_send = 2
				4:
					base_points = 800
					clear_name = "MSG_QUAD"
					is_difficult = true
					garbage_to_send = 4

		# Back-to-Back Bonus (1.5x)
		if is_difficult:
			if b2b:
				base_points = int(float(base_points) * 1.5)
				garbage_to_send += 1
			b2b = true
		else:
			b2b = false

		# Combo Bonus
		if combo > 0:
			base_points += 50 * combo * level
			if combo >= 7:
				garbage_to_send += 3
			elif combo >= 4:
				garbage_to_send += 2
			elif combo >= 2:
				garbage_to_send += 1

		var earned_points := base_points * level
		score += earned_points

		lines_cleared.emit(cleared_count, clear_name, earned_points, lines, garbage_to_send)
		state = State.CLEAR
		state_changed.emit(state)
	else:
		combo = -1
		state = State.SPAWN
		state_changed.emit(state)
		spawn_next()


func queue_garbage(count: int) -> void:
	# Eingehender Müll wird mit eventuell gesendetem Müll verrechnet oder gepuffert
	pending_garbage += count
	last_garbage_hole_col = rng.randi_range(0, StackConfig.COLS - 1)
	garbage_received.emit(pending_garbage)


func trigger_game_over() -> void:
	game_over = true
	state = State.GAME_OVER
	state_changed.emit(state)
	game_over_triggered.emit()
