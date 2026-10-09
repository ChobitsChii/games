class_name GameController
extends RefCounted
## Zentraler Spielablauf und Zustandssteuerung für Connect Four Deluxe.
## Verwaltet Spielmodi (KI, Hotseat), Spielzustände, Züge, Undo und Statistiken.

enum GameMode {
	AI,
	HOTSEAT,
}

enum State {
	MENU,
	PLAYER_TURN,
	DROPPING,
	AI_THINKING,
	GAME_OVER,
}

enum Starter {
	PLAYER_1,
	PLAYER_2_OR_AI,
	RANDOM,
}

signal state_changed(new_state: State)
signal disc_dropped(col: int, row: int, player: int)
signal move_completed(col: int, row: int, player: int)
signal game_ended(winner: int, winning_cells: Array[Vector2i])
signal hint_ready(col: int)
signal undo_performed()
signal stats_updated()

var board: Board
var ai: ConnectFourAI
var mode: GameMode = GameMode.AI
var difficulty: ConnectFourAI.Difficulty = ConnectFourAI.Difficulty.MEDIUM
var starter: Starter = Starter.PLAYER_1
var state: State = State.MENU

var human_player: int = Board.CELL_PLAYER_1
var colorblind_mode: bool = false
var selected_col: int = 3
var is_autoplay: bool = false
var rng: RandomNumberGenerator


func _init() -> void:
	board = Board.new()
	ai = ConnectFourAI.new()
	rng = RandomNumberGenerator.new()
	rng.randomize()
	_load_settings()


func start_game(p_mode: GameMode, p_difficulty: ConnectFourAI.Difficulty = ConnectFourAI.Difficulty.MEDIUM, p_starter: Starter = Starter.PLAYER_1) -> void:
	mode = p_mode
	difficulty = p_difficulty
	starter = p_starter
	board.reset()
	selected_col = 3

	var first_player := Board.CELL_PLAYER_1
	match starter:
		Starter.PLAYER_1:
			first_player = Board.CELL_PLAYER_1
		Starter.PLAYER_2_OR_AI:
			first_player = Board.CELL_PLAYER_2
		Starter.RANDOM:
			first_player = Board.CELL_PLAYER_1 if (rng.randi() % 2 == 0) else Board.CELL_PLAYER_2

	if mode == GameMode.AI:
		human_player = Board.CELL_PLAYER_1
		if first_player == Board.CELL_PLAYER_2:
			# KI beginnt: Human ist Spieler 2, KI ist Spieler 1
			human_player = Board.CELL_PLAYER_2

	_change_state(State.PLAYER_TURN)
	_check_next_turn()


func set_selected_column(col: int) -> void:
	if col >= 0 and col < Board.WIDTH:
		selected_col = col


func move_column_left() -> void:
	var c := selected_col - 1
	while c >= 0:
		if board.can_play(c):
			selected_col = c
			return
		c -= 1


func move_column_right() -> void:
	var c := selected_col + 1
	while c < Board.WIDTH:
		if board.can_play(c):
			selected_col = c
			return
		c += 1


func request_drop(col: int = -1) -> bool:
	if state != State.PLAYER_TURN:
		return false

	var target_col := col if col != -1 else selected_col
	if not board.can_play(target_col):
		return false

	var current_p := board.current_player()
	var row := board.get_column_height(target_col)
	board.play(target_col)

	_change_state(State.DROPPING)
	disc_dropped.emit(target_col, row, current_p)
	return true


## Wird aufgerufen, sobald die Fall-Animation im View abgeschlossen ist.
func on_drop_animation_finished() -> void:
	var last_col := board.last_move()
	var last_row := board.last_move_row()
	var last_p := board.last_player()
	move_completed.emit(last_col, last_row, last_p)

	if board.has_won():
		_handle_win(last_p)
	elif board.is_draw():
		_handle_draw()
	else:
		_change_state(State.PLAYER_TURN)
		_check_next_turn()


func request_undo() -> bool:
	if state != State.PLAYER_TURN or board.moves == 0:
		return false

	var ok := false
	if mode == GameMode.HOTSEAT:
		ok = board.undo()
		if ok:
			_change_state(State.PLAYER_TURN)
	else:
		# Im KI-Modus: 2 Züge zurück (KI und Spieler)
		if board.moves >= 2:
			board.undo()
			board.undo()
			_change_state(State.PLAYER_TURN)
			ok = true
		elif board.moves == 1 and board.current_player() != human_player:
			board.undo()
			_change_state(State.PLAYER_TURN)
			ok = true

	if ok:
		undo_performed.emit()
	return ok


func request_hint() -> void:
	if state != State.PLAYER_TURN:
		return
	var hint_col := ai.get_hint(board)
	if hint_col != -1:
		selected_col = hint_col
		hint_ready.emit(hint_col)


func process_ai_turn() -> void:
	if state != State.AI_THINKING:
		return

	var ai_col: int
	if is_autoplay:
		ai_col = ai.choose_move(board, difficulty, rng)
	else:
		ai_col = await ai.choose_move_async(board, difficulty, rng)

	if ai_col != -1 and board.can_play(ai_col):
		var current_p := board.current_player()
		var row := board.get_column_height(ai_col)
		board.play(ai_col)
		_change_state(State.DROPPING)
		disc_dropped.emit(ai_col, row, current_p)


func _check_next_turn() -> void:
	if board.is_game_over():
		return

	if mode == GameMode.AI:
		if board.current_player() != human_player or is_autoplay:
			_change_state(State.AI_THINKING)
			process_ai_turn()
		else:
			_change_state(State.PLAYER_TURN)
	else:
		_change_state(State.PLAYER_TURN)


func _handle_win(winner: int) -> void:
	_change_state(State.GAME_OVER)
	var winning := board.get_winning_cells()
	_update_stats_win(winner)
	game_ended.emit(winner, winning)


func _handle_draw() -> void:
	_change_state(State.GAME_OVER)
	_update_stats_draw()
	game_ended.emit(Board.CELL_EMPTY, [] as Array[Vector2i])


func _change_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(state)


# --- STATISTIKEN & SPEICHERN ---
func _load_settings() -> void:
	var save_service: Node = Engine.get_singleton("SaveService") if Engine.has_singleton("SaveService") else null
	if save_service == null and Engine.get_main_loop() != null:
		var root := (Engine.get_main_loop() as SceneTree).root
		if root != null and root.has_node("SaveService"):
			save_service = root.get_node("SaveService")

	if save_service != null:
		colorblind_mode = save_service.get_value("connect_four", "colorblind", false)


func get_stats(diff: ConnectFourAI.Difficulty) -> Dictionary:
	var save_service := _get_save_service()
	var key_prefix := _diff_key_prefix(diff)
	var wins: int = 0
	var losses: int = 0
	var draws: int = 0
	if save_service != null:
		wins = save_service.get_value("connect_four", key_prefix + "_wins", 0)
		losses = save_service.get_value("connect_four", key_prefix + "_losses", 0)
		draws = save_service.get_value("connect_four", key_prefix + "_draws", 0)
	return {"wins": wins, "losses": losses, "draws": draws}


func get_hotseat_stats() -> Dictionary:
	var save_service := _get_save_service()
	var p1_wins: int = 0
	var p2_wins: int = 0
	var draws: int = 0
	if save_service != null:
		p1_wins = save_service.get_value("connect_four", "hotseat_p1", 0)
		p2_wins = save_service.get_value("connect_four", "hotseat_p2", 0)
		draws = save_service.get_value("connect_four", "hotseat_draws", 0)
	return {"p1": p1_wins, "p2": p2_wins, "draws": draws}


func reset_stats() -> void:
	var save_service := _get_save_service()
	if save_service != null:
		for d in [ConnectFourAI.Difficulty.EASY, ConnectFourAI.Difficulty.MEDIUM, ConnectFourAI.Difficulty.HARD]:
			var prefix := _diff_key_prefix(d)
			save_service.set_value("connect_four", prefix + "_wins", 0)
			save_service.set_value("connect_four", prefix + "_losses", 0)
			save_service.set_value("connect_four", prefix + "_draws", 0)
		save_service.set_value("connect_four", "hotseat_p1", 0)
		save_service.set_value("connect_four", "hotseat_p2", 0)
		save_service.set_value("connect_four", "hotseat_draws", 0)
		save_service.save()
	stats_updated.emit()


func _update_stats_win(winner: int) -> void:
	var save_service := _get_save_service()
	if save_service == null:
		return

	if mode == GameMode.AI:
		var prefix := _diff_key_prefix(difficulty)
		if winner == human_player:
			var w: int = save_service.get_value("connect_four", prefix + "_wins", 0) + 1
			save_service.set_value("connect_four", prefix + "_wins", w)
		else:
			var l: int = save_service.get_value("connect_four", prefix + "_losses", 0) + 1
			save_service.set_value("connect_four", prefix + "_losses", l)
	else:
		if winner == Board.CELL_PLAYER_1:
			var w1: int = save_service.get_value("connect_four", "hotseat_p1", 0) + 1
			save_service.set_value("connect_four", "hotseat_p1", w1)
		else:
			var w2: int = save_service.get_value("connect_four", "hotseat_p2", 0) + 1
			save_service.set_value("connect_four", "hotseat_p2", w2)
	save_service.save()
	stats_updated.emit()


func _update_stats_draw() -> void:
	var save_service := _get_save_service()
	if save_service == null:
		return

	if mode == GameMode.AI:
		var prefix := _diff_key_prefix(difficulty)
		var d: int = save_service.get_value("connect_four", prefix + "_draws", 0) + 1
		save_service.set_value("connect_four", prefix + "_draws", d)
	else:
		var d: int = save_service.get_value("connect_four", "hotseat_draws", 0) + 1
		save_service.set_value("connect_four", "hotseat_draws", d)
	save_service.save()
	stats_updated.emit()


func _diff_key_prefix(diff: ConnectFourAI.Difficulty) -> String:
	match diff:
		ConnectFourAI.Difficulty.EASY:
			return "easy"
		ConnectFourAI.Difficulty.MEDIUM:
			return "medium"
		ConnectFourAI.Difficulty.HARD:
			return "hard"
	return "medium"


func _get_save_service() -> Node:
	if Engine.get_main_loop() != null:
		var root := (Engine.get_main_loop() as SceneTree).root
		if root != null and root.has_node("SaveService"):
			return root.get_node("SaveService")
	return null
