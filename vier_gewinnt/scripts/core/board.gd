class_name Board
extends RefCounted
## Reine Spiellogik für Connect Four (Vier gewinnt).
## UI- und Node-frei, vollständig testbar.
## Verwendet 64-Bit-Bitboards (7 Spalten x 7 Bit, Zeile 6 als Sperrbit).

const WIDTH := 7
const HEIGHT := 6
const MAX_MOVES := 42

const CELL_EMPTY := 0
const CELL_PLAYER_1 := 1
const CELL_PLAYER_2 := 2

## Spaltenreihenfolge für Züge (Mitte zuerst für bessere Astbeschneidung)
const MOVE_ORDER: Array[int] = [3, 2, 4, 1, 5, 0, 6]

## Bitboard der Steine des Spielers, der aktuell am Zug ist
var position: int = 0
## Bitboard aller belegten Felder
var mask: int = 0
## Bisherige Anzahl von Zügen
var moves: int = 0

## Historie für Undo
var state_history: Array[Dictionary] = []
var move_history: Array[int] = []


func reset() -> void:
	position = 0
	mask = 0
	moves = 0
	state_history.clear()
	move_history.clear()


## Prüft, ob ein Zug in Spalte col erlaubt ist.
func can_play(col: int) -> bool:
	if col < 0 or col >= WIDTH:
		return false
	# Zeile 5 (oberste gültige Zeile) darf noch nicht belegt sein
	return (mask & (1 << (col * 7 + 5))) == 0


## Führt einen Zug in Spalte col aus.
## Gibt true zurück, wenn der Zug gültig war.
func play(col: int) -> bool:
	if not can_play(col):
		return false
	state_history.append({"pos": position, "mask": mask, "moves": moves})
	move_history.append(col)
	position ^= mask
	mask |= mask + (1 << (col * 7))
	moves += 1
	return true


## Macht den letzten Zug rückgängig.
func undo() -> bool:
	if state_history.is_empty():
		return false
	var prev: Dictionary = state_history.pop_back()
	position = prev["pos"]
	mask = prev["mask"]
	moves = prev["moves"]
	move_history.pop_back()
	return true


## Prüft, ob ein gegebenes Bitboard eine 4er-Reihe enthält.
static func is_win(bb: int) -> bool:
	# Richtungen: 1 (vertikal), 7 (horizontal), 6 (anti-diagonal \), 8 (diagonal /)
	for s in [1, 7, 6, 8]:
		var m: int = bb & (bb >> s)
		if (m & (m >> (2 * s))) != 0:
			return true
	return false


## Hat der Spieler gewonnen, der gerade gezogen hat?
func has_won() -> bool:
	return is_win(mask ^ position)


## Ist das Spiel unentschieden (volles Brett ohne Sieger)?
func is_draw() -> bool:
	return moves >= MAX_MOVES and not has_won()


## Ist das Spiel beendet?
func is_game_over() -> bool:
	return has_won() or moves >= MAX_MOVES


## Gibt den aktuellen Spieler zurück (1 = Spieler 1, 2 = Spieler 2).
func current_player() -> int:
	return CELL_PLAYER_1 if (moves % 2 == 0) else CELL_PLAYER_2


## Gibt den Spieler zurück, der zuletzt gezogen hat (oder 0, wenn noch kein Zug).
func last_player() -> int:
	if moves == 0:
		return CELL_EMPTY
	return CELL_PLAYER_2 if (moves % 2 == 0) else CELL_PLAYER_1


## Gibt die zuletzt gespielte Spalte zurück (-1 falls kein Zug).
func last_move() -> int:
	if move_history.is_empty():
		return -1
	return move_history[move_history.size() - 1]


## Gibt die Zeile des zuletzt platzierten Steins zurück (-1 falls kein Zug).
func last_move_row() -> int:
	var col := last_move()
	if col == -1:
		return -1
	return get_column_height(col) - 1


## Anzahl Steine in der angegebenen Spalte (0 bis 6).
func get_column_height(col: int) -> int:
	if col < 0 or col >= WIDTH:
		return 0
	var col_bits: int = (mask >> (col * 7)) & 0x3F # 6 Bits für Zeilen 0..5
	var count := 0
	while col_bits > 0:
		count += col_bits & 1
		col_bits >>= 1
	return count


## Gibt den Inhalt einer Zelle zurück (CELL_EMPTY, CELL_PLAYER_1, CELL_PLAYER_2).
## row 0 ist unten, row 5 ist oben.
func get_cell(col: int, row: int) -> int:
	if col < 0 or col >= WIDTH or row < 0 or row >= HEIGHT:
		return CELL_EMPTY
	var bit: int = 1 << (col * 7 + row)
	if (mask & bit) == 0:
		return CELL_EMPTY

	var p1_bb: int = position if (moves % 2 == 0) else (mask ^ position)
	if (p1_bb & bit) != 0:
		return CELL_PLAYER_1
	return CELL_PLAYER_2


## Liefert alle legalen Züge (Spalten 0..6), sortiert nach MOVE_ORDER.
func get_legal_moves() -> Array[int]:
	var legal: Array[int] = []
	for col in MOVE_ORDER:
		if can_play(col):
			legal.append(col)
	return legal


## Liefert die Koordinaten der 4 gewinnenden Felder als Vector2i(col, row).
func get_winning_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var winner_bb: int = mask ^ position
	if not is_win(winner_bb):
		return result

	for s in [1, 7, 6, 8]:
		var m: int = winner_bb & (winner_bb >> s)
		var w: int = m & (m >> (2 * s))
		if w != 0:
			# Finden des gesetzten Bits in w
			for b in range(WIDTH * 7):
				if (w & (1 << b)) != 0:
					for step in range(4):
						var bit_idx: int = b + step * s
						var c: int = bit_idx / 7
						var r: int = bit_idx % 7
						result.append(Vector2i(c, r))
					return result
	return result


## Klont den aktuellen Zustand des Brettes.
func clone() -> Board:
	var copy := Board.new()
	copy.position = position
	copy.mask = mask
	copy.moves = moves
	copy.move_history = move_history.duplicate()
	for s in state_history:
		copy.state_history.append(s.duplicate())
	return copy
