class_name CpuPlayer
extends RefCounted
## KI-Gegner für Block Stack basierend auf Dellacherie-Heuristik.
## Testet alle Drehungen und Spalten und wählt die bestbewertete Platzierung.

var logic: GameLogic
var rng: RandomNumberGenerator

# Schwierigkeitsparameter
var think_delay: float = 0.35 # Sekunden zwischen Aktionen
var error_rate: float = 0.0 # Wahrscheinlichkeit für suboptimalen Zug
var use_hold: bool = true

var _timer: float = 0.0
var _target_col: int = -1
var _target_rot: int = -1
var _use_hold_this_turn: bool = false
var _planned: bool = false


func _init(game_logic: GameLogic, random_generator: RandomNumberGenerator = null) -> void:
	logic = game_logic
	if random_generator != null:
		rng = random_generator
	else:
		rng = RandomNumberGenerator.new()
		rng.randomize()


func set_difficulty(difficulty: String) -> void:
	match difficulty:
		"easy":
			think_delay = 0.65
			error_rate = 0.25
			use_hold = false
		"medium":
			think_delay = 0.35
			error_rate = 0.08
			use_hold = true
		"hard":
			think_delay = 0.15
			error_rate = 0.0
			use_hold = true


func update(delta: float) -> void:
	if logic == null or logic.state == GameLogic.State.GAME_OVER:
		return

	_timer += delta
	if _timer < think_delay:
		return
	_timer = 0.0

	if not _planned:
		_plan_best_move()
		_planned = true
		return

	# Hold ausführen, falls geplant
	if _use_hold_this_turn:
		_use_hold_this_turn = false
		if logic.hold():
			_plan_best_move()
			return

	# Drehung anpassen
	if logic.current_rot != _target_rot:
		logic.rotate(true)
		return

	# Horizontale Position anpassen
	if logic.current_pos.x < _target_col:
		logic.move_horizontal(1)
		return
	elif logic.current_pos.x > _target_col:
		logic.move_horizontal(-1)
		return

	# Richtige Position und Drehung erreicht -> Hard Drop
	logic.hard_drop()
	_planned = false


func _plan_best_move() -> void:
	var best_eval := -999999.0
	var best_col := logic.current_pos.x
	var best_rot := 0
	var want_hold := false

	# 1. Züge mit aktuellem Stein bewerten
	var moves := _evaluate_all_placements(logic.current_piece)
	if not moves.is_empty():
		moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
		var chosen: Dictionary = moves[0]
		# Bei Fehlerquote eventuell zweitbesten Zug nehmen
		if error_rate > 0.0 and moves.size() > 1 and rng.randf() < error_rate:
			chosen = moves[1]
		best_eval = chosen["score"]
		best_col = chosen["col"]
		best_rot = chosen["rot"]

	# 2. Falls Hold erlaubt ist, Hold-Stein testen
	if use_hold and logic.can_hold:
		var candidate_piece := logic.hold_piece if logic.hold_piece != "" else logic.bag.peek(1)[0]
		var hold_moves := _evaluate_all_placements(candidate_piece)
		if not hold_moves.is_empty():
			hold_moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
			var hold_best: Dictionary = hold_moves[0]
			if hold_best["score"] > best_eval + 15.0: # Merklicher Vorteil für Hold nötig
				best_col = hold_best["col"]
				best_rot = hold_best["rot"]
				want_hold = true

	_target_col = best_col
	_target_rot = best_rot
	_use_hold_this_turn = want_hold


func _evaluate_all_placements(piece_type: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for rot in range(4):
		for col in range(-2, StackConfig.COLS + 2):
			# Testen, ob der Stein von oben nach unten fallen kann
			var spawn_y := 0
			if not logic.matrix.can_fit(piece_type, rot, Vector2i(col, spawn_y)):
				continue

			var drop_y := spawn_y
			while logic.matrix.can_fit(piece_type, rot, Vector2i(col, drop_y + 1)):
				drop_y += 1

			# Platzierung in einer Kopie der Matrix simulieren
			var sim := logic.matrix.clone()
			sim.lock_piece(piece_type, rot, Vector2i(col, drop_y))
			var full_lines := sim.find_full_lines()
			var cleared := full_lines.size()
			sim.clear_lines(full_lines)

			# Dellacherie Bewertungsfunktion:
			# score = -0.51 * aggregate_height + 0.76 * cleared_lines - 0.36 * holes - 0.18 * bumpiness
			var agg_height := float(sim.get_aggregate_height())
			var holes := float(sim.count_holes())
			var bumpiness := float(sim.get_bumpiness())
			var cleared_val := float(cleared)

			var score: float = -0.51 * agg_height + (0.76 * cleared_val * 4.0) - (0.36 * holes * 8.0) - (0.18 * bumpiness)
			results.append({
				"col": col,
				"rot": rot,
				"score": score,
			})

	return results
