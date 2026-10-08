class_name ConnectFourAI
extends RefCounted
## KI für Connect Four (Vier gewinnt).
## Stufen: LEICHT, MITTEL, SCHWER.
## Bitboard-Engine mit Negamax, Alpha-Beta-Pruning und Transposition-Table.

enum Difficulty {
	EASY,
	MEDIUM,
	HARD,
}

const WIN_SCORE := 100000
const DRAW_SCORE := 0

const TT_EXACT := 0
const TT_LOWER := 1
const TT_UPPER := 2

const BOTTOM_MASK := 0x01010101010101 # Bit 0 jeder Spalte (Zeile 0)
const BOARD_MASK := 0x1F3E7CF9F3E7CF   # Alle 42 gültigen Brett-Bits
const COL_MASKS: Array[int] = [
	0x3F,
	0x3F << 7,
	0x3F << 14,
	0x3F << 21,
	0x3F << 28,
	0x3F << 35,
	0x3F << 42,
]

static var WINDOWS: PackedInt64Array = _init_windows()

var _transposition_table: Dictionary = {}
var _nodes_evaluated := 0
var _stop_search := false
var _search_start_usec := 0
var _time_limit_usec := 800000 # 800 ms
var _last_frame_usec := 0


static func _init_windows() -> PackedInt64Array:
	var arr := PackedInt64Array()
	# Horizontal (4 x 6 = 24)
	for r in range(6):
		for c in range(4):
			arr.append((1 << (c * 7 + r)) | (1 << ((c + 1) * 7 + r)) | (1 << ((c + 2) * 7 + r)) | (1 << ((c + 3) * 7 + r)))
	# Vertikal (7 x 3 = 21)
	for c in range(7):
		for r in range(3):
			arr.append((1 << (c * 7 + r)) | (1 << (c * 7 + r + 1)) | (1 << (c * 7 + r + 2)) | (1 << (c * 7 + r + 3)))
	# Diagonal / (4 x 3 = 12)
	for c in range(4):
		for r in range(3):
			arr.append((1 << (c * 7 + r)) | (1 << ((c + 1) * 7 + r + 1)) | (1 << ((c + 2) * 7 + r + 2)) | (1 << ((c + 3) * 7 + r + 3)))
	# Diagonal \ (4 x 3 = 12)
	for c in range(4):
		for r in range(3, 6):
			arr.append((1 << (c * 7 + r)) | (1 << ((c + 1) * 7 + r - 1)) | (1 << ((c + 2) * 7 + r - 2)) | (1 << ((c + 3) * 7 + r - 3)))
	return arr


## Zählt gesetzte Bits (Brian-Kernighan).
static func popcount(n: int) -> int:
	var count := 0
	while n != 0:
		n &= n - 1
		count += 1
	return count


## Findet alle Gewinnpositionen für einen Spieler (Bitmaske).
static func compute_winning_spots(player_bb: int, occupied_mask: int) -> int:
	var threats := 0
	for s in [1, 7, 6, 8]:
		var p := player_bb
		var w0: int = (p >> s) & (p >> (2 * s)) & (p >> (3 * s))
		var w1: int = (p << s) & (p >> s) & (p >> (2 * s))
		var w2: int = (p << (2 * s)) & (p << s) & (p >> s)
		var w3: int = (p << (3 * s)) & (p << (2 * s)) & (p << s)
		threats |= (w0 | w1 | w2 | w3)
	return threats & BOARD_MASK & ~occupied_mask


## Prüft, ob ein Spieler mit einem legalen Zug sofort gewinnen kann.
static func find_immediate_win(player_bb: int, current_mask: int) -> int:
	for col in Board.MOVE_ORDER:
		if (current_mask & (1 << (col * 7 + 5))) == 0:
			var move_bit: int = current_mask + (1 << (col * 7))
			var new_bb: int = player_bb | (move_bit & ~current_mask)
			if Board.is_win(new_bb):
				return col
	return -1


## Wählt synchron einen Zug für den aktuellen Spieler aus.
func choose_move(board: Board, difficulty: Difficulty, rng: RandomNumberGenerator = null) -> int:
	var legal := board.get_legal_moves()
	if legal.is_empty():
		return -1
	if legal.size() == 1:
		return legal[0]

	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	match difficulty:
		Difficulty.EASY:
			return _choose_move_easy(board, legal, rng)
		Difficulty.MEDIUM:
			return _choose_move_medium(board, rng)
		Difficulty.HARD:
			return _choose_move_hard_sync(board, rng)

	return legal[0]


## Asynchroner Aufruf für UI / Web.
func choose_move_async(board: Board, difficulty: Difficulty, rng: RandomNumberGenerator = null) -> int:
	var legal := board.get_legal_moves()
	if legal.is_empty():
		return -1
	if legal.size() == 1:
		return legal[0]

	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	if difficulty == Difficulty.EASY:
		return _choose_move_easy(board, legal, rng)
	elif difficulty == Difficulty.MEDIUM:
		return _choose_move_medium(board, rng)

	return await _choose_move_hard_async(board, rng)


## Gibt einen Zug-Tipp (Hinweis) für den aktuellen Spieler.
func get_hint(board: Board) -> int:
	return choose_move(board, Difficulty.HARD)


# --- LEICHT ---
func _choose_move_easy(board: Board, legal: Array[int], rng: RandomNumberGenerator) -> int:
	var current_p_bb := board.position
	var opp_bb := board.mask ^ board.position

	var win_move := find_immediate_win(current_p_bb, board.mask)
	if win_move != -1:
		return win_move

	var block_move := find_immediate_win(opp_bb, board.mask)
	if block_move != -1:
		return block_move

	var safe_moves: Array[int] = []
	for col in legal:
		var next_mask: int = board.mask | (board.mask + (1 << (col * 7)))
		var opp_win := find_immediate_win(opp_bb, next_mask)
		if opp_win == -1:
			safe_moves.append(col)

	var candidate_moves := safe_moves if not safe_moves.is_empty() else legal
	return candidate_moves[rng.randi_range(0, candidate_moves.size() - 1)]


# --- MITTEL (Tiefe 4, einfache Bewertung) ---
func _choose_move_medium(board: Board, rng: RandomNumberGenerator) -> int:
	var current_p_bb := board.position
	var opp_bb := board.mask ^ board.position

	var win_move := find_immediate_win(current_p_bb, board.mask)
	if win_move != -1:
		return win_move

	var block_move := find_immediate_win(opp_bb, board.mask)
	if block_move != -1:
		return block_move

	var best_score := -WIN_SCORE * 2
	var best_moves: Array[int] = []
	var alpha := -WIN_SCORE * 2
	var beta := WIN_SCORE * 2

	for col in Board.MOVE_ORDER:
		if not board.can_play(col):
			continue
		var next_pos := board.position ^ board.mask
		var next_mask := board.mask | (board.mask + (1 << (col * 7)))

		if Board.is_win(next_mask ^ next_pos):
			return col

		var score := -_negamax_simple(next_pos, next_mask, board.moves + 1, 2, -beta, -alpha)
		if score > best_score:
			best_score = score
			best_moves = [col]
			alpha = max(alpha, score)
		elif score == best_score:
			best_moves.append(col)

	if best_moves.is_empty():
		return board.get_legal_moves()[0]

	# Auf Stufe Mittel: Gelegentliche Ungenauigkeit (kein perfekter Meister)
	if rng.randf() < 0.35 and best_moves.size() > 1:
		return best_moves[rng.randi_range(1, best_moves.size() - 1)]
	elif rng.randf() < 0.30:
		var legal := board.get_legal_moves()
		var safe: Array[int] = []
		for c in legal:
			var nm: int = board.mask | (board.mask + (1 << (c * 7)))
			if find_immediate_win(opp_bb, nm) == -1:
				safe.append(c)
		if safe.size() > 1:
			return safe[rng.randi_range(0, safe.size() - 1)]

	return best_moves[0]


func _negamax_simple(pos: int, msk: int, mvs: int, depth: int, alpha: int, beta: int) -> int:
	if Board.is_win(pos ^ msk):
		return -(WIN_SCORE - mvs)
	if mvs >= Board.MAX_MOVES:
		return DRAW_SCORE
	if depth <= 0:
		var p := pos
		var o := msk ^ pos
		var c3 := popcount(p & COL_MASKS[3]) - popcount(o & COL_MASKS[3])
		var c24 := (popcount(p & COL_MASKS[2]) + popcount(p & COL_MASKS[4])) - (popcount(o & COL_MASKS[2]) + popcount(o & COL_MASKS[4]))
		return c3 * 3 + c24

	var best_score := -WIN_SCORE * 2
	for col in Board.MOVE_ORDER:
		if (msk & (1 << (col * 7 + 5))) != 0:
			continue
		var next_pos := pos ^ msk
		var next_mask := msk | (msk + (1 << (col * 7)))
		var score := -_negamax_simple(next_pos, next_mask, mvs + 1, depth - 1, -beta, -alpha)
		if score > best_score:
			best_score = score
		alpha = max(alpha, score)
		if alpha >= beta:
			break
	return best_score


# --- SCHWER (Synchron, Tiefe 6/8, Alpha-Beta, Iterative Deepening) ---
func _choose_move_hard_sync(board: Board, _rng: RandomNumberGenerator) -> int:
	var current_p_bb := board.position
	var opp_bb := board.mask ^ board.position

	var win_move := find_immediate_win(current_p_bb, board.mask)
	if win_move != -1:
		return win_move

	var block_move := find_immediate_win(opp_bb, board.mask)
	if block_move != -1:
		return block_move

	_transposition_table.clear()
	_nodes_evaluated = 0
	_stop_search = false
	_search_start_usec = Time.get_ticks_usec()

	var best_overall_move := board.get_legal_moves()[0]

	for depth in [4, 6]:
		var best_score := -WIN_SCORE * 2
		var best_move_for_depth := -1
		var alpha := -WIN_SCORE * 2
		var beta := WIN_SCORE * 2

		for col in Board.MOVE_ORDER:
			if not board.can_play(col):
				continue
			var next_pos := board.position ^ board.mask
			var next_mask := board.mask | (board.mask + (1 << (col * 7)))

			if Board.is_win(next_mask ^ next_pos):
				return col

			var opp_direct := find_immediate_win(next_pos, next_mask)
			var score: int
			if opp_direct != -1:
				score = -(WIN_SCORE - (board.moves + 2))
			else:
				score = -_negamax_sync(next_pos, next_mask, board.moves + 1, depth - 1, -beta, -alpha)

			if _stop_search:
				break

			if score > best_score:
				best_score = score
				best_move_for_depth = col
				alpha = max(alpha, score)

		if not _stop_search and best_move_for_depth != -1:
			best_overall_move = best_move_for_depth
			if best_score >= WIN_SCORE - 50:
				break

		if _stop_search or (Time.get_ticks_usec() - _search_start_usec) >= _time_limit_usec:
			break

	return best_overall_move


# --- SCHWER (Asynchron / Coroutine für UI) ---
func _choose_move_hard_async(board: Board, _rng: RandomNumberGenerator) -> int:
	var current_p_bb := board.position
	var opp_bb := board.mask ^ board.position

	var win_move := find_immediate_win(current_p_bb, board.mask)
	if win_move != -1:
		return win_move

	var block_move := find_immediate_win(opp_bb, board.mask)
	if block_move != -1:
		return block_move

	_transposition_table.clear()
	_nodes_evaluated = 0
	_stop_search = false
	_search_start_usec = Time.get_ticks_usec()
	_last_frame_usec = _search_start_usec

	var best_overall_move := board.get_legal_moves()[0]

	for depth in [4, 6, 8]:
		var best_score := -WIN_SCORE * 2
		var best_move_for_depth := -1
		var alpha := -WIN_SCORE * 2
		var beta := WIN_SCORE * 2

		for col in Board.MOVE_ORDER:
			if not board.can_play(col):
				continue
			var next_pos := board.position ^ board.mask
			var next_mask := board.mask | (board.mask + (1 << (col * 7)))

			if Board.is_win(next_mask ^ next_pos):
				return col

			var opp_direct := find_immediate_win(next_pos, next_mask)
			var score: int
			if opp_direct != -1:
				score = -(WIN_SCORE - (board.moves + 2))
			else:
				score = -await _negamax_async(next_pos, next_mask, board.moves + 1, depth - 1, -beta, -alpha)

			if _stop_search:
				break

			if score > best_score:
				best_score = score
				best_move_for_depth = col
				alpha = max(alpha, score)

		if not _stop_search and best_move_for_depth != -1:
			best_overall_move = best_move_for_depth
			if best_score >= WIN_SCORE - 50:
				break

		if _stop_search or (Time.get_ticks_usec() - _search_start_usec) >= _time_limit_usec:
			break

	return best_overall_move


# --- NEGAMAX CORE (Synchron) ---
func _negamax_sync(pos: int, msk: int, mvs: int, depth: int, alpha: int, beta: int) -> int:
	_nodes_evaluated += 1

	if Board.is_win(pos ^ msk):
		return -(WIN_SCORE - mvs)

	if mvs >= Board.MAX_MOVES:
		return DRAW_SCORE

	if depth <= 0:
		return _evaluate(pos, msk)

	var orig_alpha := alpha
	var tt_key: int = pos + msk + BOTTOM_MASK
	if _transposition_table.has(tt_key):
		var entry: Dictionary = _transposition_table[tt_key]
		if entry["depth"] >= depth:
			var entry_score: int = entry["score"]
			match entry["flag"]:
				TT_EXACT:
					return entry_score
				TT_LOWER:
					alpha = max(alpha, entry_score)
				TT_UPPER:
					beta = min(beta, entry_score)
			if alpha >= beta:
				return entry_score

	var best_score := -WIN_SCORE * 2

	for col in Board.MOVE_ORDER:
		if (msk & (1 << (col * 7 + 5))) != 0:
			continue
		var next_pos := pos ^ msk
		var next_mask := msk | (msk + (1 << (col * 7)))
		var score := -_negamax_sync(next_pos, next_mask, mvs + 1, depth - 1, -beta, -alpha)

		if score > best_score:
			best_score = score
		alpha = max(alpha, score)
		if alpha >= beta:
			break

	if _transposition_table.size() < 150000:
		var flag := TT_EXACT
		if best_score <= orig_alpha:
			flag = TT_UPPER
		elif best_score >= beta:
			flag = TT_LOWER
		_transposition_table[tt_key] = {"depth": depth, "score": best_score, "flag": flag}

	return best_score


# --- NEGAMAX CORE (Asynchron) ---
func _negamax_async(pos: int, msk: int, mvs: int, depth: int, alpha: int, beta: int) -> int:
	_nodes_evaluated += 1
	if (_nodes_evaluated & 1023) == 0:
		var now := Time.get_ticks_usec()
		if (now - _search_start_usec) >= _time_limit_usec:
			_stop_search = true
			return 0
		if (now - _last_frame_usec) >= 8000:
			var tree := Engine.get_main_loop() as SceneTree
			if tree != null:
				await tree.process_frame
				_last_frame_usec = Time.get_ticks_usec()

	if Board.is_win(pos ^ msk):
		return -(WIN_SCORE - mvs)

	if mvs >= Board.MAX_MOVES:
		return DRAW_SCORE

	if depth <= 0:
		return _evaluate(pos, msk)

	var orig_alpha := alpha
	var tt_key: int = pos + msk + BOTTOM_MASK
	if _transposition_table.has(tt_key):
		var entry: Dictionary = _transposition_table[tt_key]
		if entry["depth"] >= depth:
			var entry_score: int = entry["score"]
			match entry["flag"]:
				TT_EXACT:
					return entry_score
				TT_LOWER:
					alpha = max(alpha, entry_score)
				TT_UPPER:
					beta = min(beta, entry_score)
			if alpha >= beta:
				return entry_score

	var best_score := -WIN_SCORE * 2

	for col in Board.MOVE_ORDER:
		if (msk & (1 << (col * 7 + 5))) != 0:
			continue
		var next_pos := pos ^ msk
		var next_mask := msk | (msk + (1 << (col * 7)))
		var score := -await _negamax_async(next_pos, next_mask, mvs + 1, depth - 1, -beta, -alpha)
		if _stop_search:
			return 0

		if score > best_score:
			best_score = score
		alpha = max(alpha, score)
		if alpha >= beta:
			break

	if _transposition_table.size() < 150000:
		var flag := TT_EXACT
		if best_score <= orig_alpha:
			flag = TT_UPPER
		elif best_score >= beta:
			flag = TT_LOWER
		_transposition_table[tt_key] = {"depth": depth, "score": best_score, "flag": flag}

	return best_score


# --- HEURISTISCHE BEWERTUNG ---
func _evaluate(pos: int, msk: int) -> int:
	var p := pos
	var o := msk ^ pos

	# Zentrumskontrolle (Spalte 3 ist am wichtigsten, dann 2/4)
	var c3 := popcount(p & COL_MASKS[3]) - popcount(o & COL_MASKS[3])
	var c24 := (popcount(p & COL_MASKS[2]) + popcount(p & COL_MASKS[4])) - (popcount(o & COL_MASKS[2]) + popcount(o & COL_MASKS[4]))

	# Bedrohungen (offene 3er-Reihen)
	var threats_p := popcount(compute_winning_spots(p, msk))
	var threats_o := popcount(compute_winning_spots(o, msk))

	return (threats_p - threats_o) * 40 + c3 * 6 + c24 * 2
