extends Node2D
## Hauptspielszene für Block Stack.
## Unterstützt Marathon, Sprint (40 Zeilen), Ultra (2 Min) und Duell gegen CPU.

const HUD_SCENE: PackedScene = preload("res://scenes/hud.tscn")

@export var autoplay := false

var mode: String = "marathon"
var rng := RandomNumberGenerator.new()

var logic: GameLogic
var cpu_logic: GameLogic
var cpu_ai: CpuPlayer
var player_ai: CpuPlayer # Für Autoplay

var is_duel: bool = false
var game_time: float = 0.0
var ultra_time_left: float = 120.0
var is_active: bool = false
var is_paused: bool = false

# DAS und ARR Einstellungen
var das: float = StackConfig.DEFAULT_DAS
var arr: float = StackConfig.DEFAULT_ARR
var _left_held := false
var _right_held := false
var _soft_drop_held := false
var _das_timer := 0.0

# Rekorde
var best_marathon_score: int = 0
var best_sprint_time: float = 9999.0
var best_ultra_score: int = 0

@onready var _board_view: BoardView = $BoardView
@onready var _cpu_board_view: BoardView = $CpuBoardView
@onready var _player_label: Label = $PlayerLabel
@onready var _cpu_label: Label = $CpuLabel
@onready var _hud: Hud = $Hud

var _sound: SoundEffects


func _ready() -> void:
	_init_seed()
	_load_settings_and_highscores()

	_sound = SoundEffects.new()
	add_child(_sound)

	mode = SaveService.get_value("session", "selected_mode", "marathon")
	is_duel = (mode == "duel")

	_setup_game()


func _init_seed() -> void:
	rng.randomize()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			rng.seed = arg.trim_prefix("--seed=").to_int()
	print("Block Stack – Seed: %d" % rng.seed)


func _load_settings_and_highscores() -> void:
	das = SaveService.get_value("handling", "das", StackConfig.DEFAULT_DAS)
	arr = SaveService.get_value("handling", "arr", StackConfig.DEFAULT_ARR)
	best_marathon_score = SaveService.get_value("highscore", "marathon", 0)
	best_sprint_time = SaveService.get_value("highscore", "sprint", 9999.0)
	best_ultra_score = SaveService.get_value("highscore", "ultra", 0)


func _setup_game() -> void:
	logic = GameLogic.new(rng, 1)
	_board_view.set_logic(logic)

	logic.lines_cleared.connect(_on_player_lines_cleared)
	logic.game_over_triggered.connect(_on_player_game_over)

	if is_duel:
		# Duell-Modus: 2 Bretter nebeneinander
		_board_view.set_board_position(Vector2(380, 100))
		_cpu_board_view.set_board_position(Vector2(1100, 100))
		_board_view.visible = true
		_cpu_board_view.visible = true
		_player_label.visible = true
		_cpu_label.visible = true
		_hud.set_layout_mode(true)

		var cpu_rng := RandomNumberGenerator.new()
		cpu_rng.seed = rng.seed + 101
		cpu_logic = GameLogic.new(cpu_rng, 1)
		_cpu_board_view.set_logic(cpu_logic)
		cpu_ai = CpuPlayer.new(cpu_logic, cpu_rng)
		cpu_ai.set_difficulty("medium")

		cpu_logic.lines_cleared.connect(_on_cpu_lines_cleared)
		cpu_logic.game_over_triggered.connect(_on_cpu_game_over)
	else:
		# Einzelspieler: Brett in der Mitte
		_board_view.set_board_position(Vector2(740, 100))
		_cpu_board_view.visible = false
		_cpu_label.visible = false
		_player_label.visible = false
		_hud.set_layout_mode(false)

	if autoplay:
		player_ai = CpuPlayer.new(logic, rng)
		player_ai.think_delay = 0.05
		player_ai.error_rate = 0.0

	_hud.resume_pressed.connect(_set_paused.bind(false))
	_hud.restart_pressed.connect(_restart_game)
	_hud.menu_pressed.connect(_to_menu)
	_hud.controls_opened.connect(func() -> void: _set_paused(true))
	_hud.controls_closed.connect(func() -> void: _set_paused(false))

	_update_hud()
	is_active = true


func _physics_process(delta: float) -> void:
	if not is_active or is_paused:
		return

	game_time += delta

	# Modus-spezifische Zeitprüfungen
	if mode == "ultra":
		ultra_time_left -= delta
		_hud.set_time(maxf(0.0, ultra_time_left))
		if ultra_time_left <= 0.0:
			_end_ultra_mode()
			return
	else:
		_hud.set_time(game_time)

	# Autopilot für Tests
	if autoplay and player_ai != null:
		player_ai.update(delta)

	# Eingaben mit DAS und ARR
	if not autoplay:
		_process_handling(delta)

	# Spiellogik aktualisieren
	logic.update(delta, _soft_drop_held)

	# CPU-Gegner im Duell
	if is_duel and cpu_ai != null and cpu_logic != null:
		cpu_ai.update(delta)
		cpu_logic.update(delta)

	_update_hud()


func _process_handling(delta: float) -> void:
	if _left_held and not _right_held:
		_das_timer += delta
		if _das_timer >= das:
			while _das_timer >= das + arr:
				logic.move_horizontal(-1)
				_das_timer -= arr
	elif _right_held and not _left_held:
		_das_timer += delta
		if _das_timer >= das:
			while _das_timer >= das + arr:
				logic.move_horizontal(1)
				_das_timer -= arr
	else:
		_das_timer = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if logic == null or logic.game_over or not is_active:
			return
		_set_paused(not is_paused)
		get_viewport().set_input_as_handled()
		return

	if not is_active or is_paused or autoplay:
		return

	if event.is_action_pressed("move_left"):
		_left_held = true
		_das_timer = 0.0
		if logic.move_horizontal(-1):
			_sound.play_move()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("move_left"):
		_left_held = false

	if event.is_action_pressed("move_right"):
		_right_held = true
		_das_timer = 0.0
		if logic.move_horizontal(1):
			_sound.play_move()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("move_right"):
		_right_held = false

	if event.is_action_pressed("soft_drop"):
		_soft_drop_held = true
		logic.soft_drop_step()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("soft_drop"):
		_soft_drop_held = false

	if event.is_action_pressed("hard_drop"):
		logic.hard_drop()
		_sound.play_drop()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("rotate_cw"):
		if logic.rotate(true):
			_sound.play_rotate()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("rotate_ccw"):
		if logic.rotate(false):
			_sound.play_rotate()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("hold"):
		if logic.hold():
			_sound.play_rotate()
		get_viewport().set_input_as_handled()


func _update_hud() -> void:
	_hud.set_score(logic.score)
	_hud.set_level(logic.level)
	_hud.set_lines(logic.lines)
	_hud.set_hold(logic.hold_piece)
	_hud.set_next(logic.bag.peek(5))

	var current_best := best_marathon_score
	if mode == "ultra":
		current_best = best_ultra_score
	_hud.set_best(current_best)

	if is_duel and cpu_logic != null:
		_hud.set_cpu_stats(cpu_logic.score, cpu_logic.lines)


func _on_player_lines_cleared(count: int, clear_name: String, _points: int, lines_total: int, garbage_to_send: int) -> void:
	if clear_name != "":
		_hud.show_action(clear_name)

	if count >= 4:
		_sound.play_quad()
	elif count > 0:
		_sound.play_clear(count)

	# Duell: Müll an CPU schicken
	if is_duel and cpu_logic != null and garbage_to_send > 0:
		cpu_logic.queue_garbage(garbage_to_send)

	# Sprint-Modus: 40 Zeilen geschafft?
	if mode == "sprint" and lines_total >= 40:
		_end_sprint_mode()


func _on_cpu_lines_cleared(_count: int, _clear_name: String, _pts: int, _tot: int, garbage_to_send: int) -> void:
	if garbage_to_send > 0 and logic != null:
		logic.queue_garbage(garbage_to_send)


func _on_player_game_over() -> void:
	is_active = false
	_set_paused(false)
	_sound.play_game_over()
	if is_duel:
		_hud.show_game_over("MSG_CPU_WINS", "MSG_GAME_OVER_HINT")
	else:
		if mode == "marathon" and logic.score > best_marathon_score:
			best_marathon_score = logic.score
			SaveService.set_value("highscore", "marathon", best_marathon_score)
		_hud.show_game_over("MSG_GAME_OVER", "MSG_GAME_OVER_HINT")


func _on_cpu_game_over() -> void:
	is_active = false
	_set_paused(false)
	_hud.show_game_over("MSG_PLAYER_WINS", "MSG_VICTORY_HINT")


func _end_sprint_mode() -> void:
	is_active = false
	_set_paused(false)
	if game_time < best_sprint_time:
		best_sprint_time = game_time
		SaveService.set_value("highscore", "sprint", best_sprint_time)
	_hud.show_game_over("MSG_VICTORY", "MSG_VICTORY_HINT")


func _end_ultra_mode() -> void:
	is_active = false
	_set_paused(false)
	if logic.score > best_ultra_score:
		best_ultra_score = logic.score
		SaveService.set_value("highscore", "ultra", best_ultra_score)
	_hud.show_game_over("MSG_VICTORY", "MSG_VICTORY_HINT")


func _set_paused(value: bool) -> void:
	is_paused = value
	get_tree().paused = value
	_hud.show_pause(value)


func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
