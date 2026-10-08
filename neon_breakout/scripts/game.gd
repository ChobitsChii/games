extends Node2D
## Spielablauf von Neon Breakout: Zustände, Level-Aufbau, Punkte und Leben.
##
## Für Fehlerberichte wird der Zufalls-Seed ausgegeben. Er lässt sich mit
## `godot --path neon_breakout -- --seed=12345` vorgeben.

enum State { READY, PLAYING, LEVEL_CLEAR, GAME_OVER }

const BRICK_SCENE: PackedScene = preload("res://scenes/brick.tscn")
const START_LIVES := 3
const PADDLE_Y := 1010.0
const BRICK_STEP := Vector2(114.0, 44.0)
const FIRST_ROW_Y := 220.0
## Kurze Sperre nach Zustandswechseln, damit Dauerklicken nichts überspringt.
const INPUT_LOCK_SECONDS := 0.6

## Automatischer Spieler für Tests (Schläger folgt dem Ball, Start ohne Eingabe).
@export var autoplay := false

var state: State = State.READY
var level := 1
var score := 0
var lives := START_LIVES
var best := 0
var rng := RandomNumberGenerator.new()

var _bricks_destroyed := 0
var _bricks_remaining := 0
var _paused := false
var _state_time := 0.0

@onready var _paddle: Paddle = $Paddle
@onready var _ball: Ball = $Ball
@onready var _bricks: Node2D = $Bricks
@onready var _walls: StaticBody2D = $Walls
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_init_seed()
	best = SaveService.get_value("highscore", "best", 0)
	_build_walls()
	_paddle.set_bounds(BreakoutConfig.FIELD.position.x, BreakoutConfig.FIELD.end.x)
	_paddle.global_position = Vector2(BreakoutConfig.FIELD.get_center().x, PADDLE_Y)
	_ball.paddle = _paddle
	_ball.bottom_y = BreakoutConfig.FIELD.end.y + 60.0
	_ball.lost.connect(_on_ball_lost)
	_hud.resume_pressed.connect(_set_paused.bind(false))
	_hud.menu_pressed.connect(_to_menu)
	if autoplay:
		_paddle.auto_target = _ball
	_hud.set_score(score)
	_hud.set_best(best)
	_hud.set_lives(lives)
	_start_level()


func _physics_process(delta: float) -> void:
	_state_time += delta
	if autoplay and state in [State.READY, State.LEVEL_CLEAR] and _input_unlocked():
		_confirm()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and state in [State.READY, State.PLAYING]:
		_set_paused(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("launch"):
		_confirm()


func _draw() -> void:
	var field := BreakoutConfig.FIELD
	var accent: Color = BreakoutConfig.PALETTE["accent"]
	draw_rect(field, Color(BreakoutConfig.PALETTE["panel"], 0.55))
	# Dezentes Gitter als Platzhalter für den späteren Hintergrund-Shader.
	var grid := Color(accent, 0.05)
	for x in range(int(field.position.x) + 60, int(field.end.x), 60):
		draw_line(Vector2(x, field.position.y), Vector2(x, field.end.y), grid, 1.0, true)
	for y in range(int(field.position.y) + 60, int(field.end.y), 60):
		draw_line(Vector2(field.position.x, y), Vector2(field.end.x, y), grid, 1.0, true)
	draw_rect(field, Color(accent, 0.8), false, 3.0, true)


func _init_seed() -> void:
	rng.randomize()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			rng.seed = arg.trim_prefix("--seed=").to_int()
	print("Neon Breakout – Seed: %d" % rng.seed)


func _build_walls() -> void:
	var field := BreakoutConfig.FIELD
	var thickness := 40.0
	_add_wall(Vector2(field.position.x - thickness * 0.5, field.get_center().y), Vector2(thickness, 2400.0))
	_add_wall(Vector2(field.end.x + thickness * 0.5, field.get_center().y), Vector2(thickness, 2400.0))
	_add_wall(Vector2(field.get_center().x, field.position.y - thickness * 0.5), Vector2(field.size.x + thickness * 2.0, thickness))


func _add_wall(center: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = center
	_walls.add_child(collision)


func _start_level() -> void:
	for brick in _bricks.get_children():
		brick.queue_free()
	_bricks_destroyed = 0
	_bricks_remaining = 0
	var rows: Array = BreakoutLevels.get_level(level)
	var center_x := BreakoutConfig.FIELD.get_center().x
	for row_index in rows.size():
		var row: String = rows[row_index]
		for col_index in row.length():
			var kind := row[col_index]
			if kind == ".":
				continue
			var brick: Brick = BRICK_SCENE.instantiate()
			brick.position = Vector2(
					center_x + (col_index - (BreakoutConfig.BRICK_COLUMNS - 1) * 0.5) * BRICK_STEP.x,
					FIRST_ROW_Y + row_index * BRICK_STEP.y)
			_bricks.add_child(brick)
			brick.setup(kind)
			if not brick.indestructible:
				_bricks_remaining += 1
				brick.destroyed.connect(_on_brick_destroyed)
	_hud.set_level(level)
	_ball.speed = BreakoutMath.speed_for(level, 0)
	_prepare_launch()


func _prepare_launch() -> void:
	_ball.stick_to_paddle()
	_set_state(State.READY)
	_hud.show_message("MSG_READY", "MSG_READY_HINT")


func _set_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _input_unlocked() -> bool:
	return _state_time >= INPUT_LOCK_SECONDS


## Bestätigen-Aktion: Ball starten, nächstes Level oder Neustart.
func _confirm() -> void:
	if _paused or not _input_unlocked():
		return
	match state:
		State.READY:
			_launch_ball()
		State.LEVEL_CLEAR:
			level += 1
			_start_level()
		State.GAME_OVER:
			get_tree().reload_current_scene()


func _launch_ball() -> void:
	_hud.hide_message()
	_ball.launch(Vector2(rng.randf_range(-0.35, 0.35), -1.0))
	_set_state(State.PLAYING)


func _on_brick_destroyed(brick: Brick) -> void:
	score += BreakoutMath.brick_points(brick.max_hp)
	_bricks_destroyed += 1
	_bricks_remaining -= 1
	_ball.speed = BreakoutMath.speed_for(level, _bricks_destroyed)
	_hud.set_score(score)
	if _bricks_remaining <= 0:
		_ball.stop()
		_set_state(State.LEVEL_CLEAR)
		_hud.show_message("MSG_LEVEL_CLEAR", "MSG_LEVEL_CLEAR_HINT")


func _on_ball_lost() -> void:
	lives -= 1
	_hud.set_lives(lives)
	if lives > 0:
		_prepare_launch()
		return
	if score > best:
		best = score
		SaveService.set_value("highscore", "best", best)
		_hud.set_best(best)
	_set_state(State.GAME_OVER)
	_hud.show_message("MSG_GAME_OVER", "MSG_GAME_OVER_HINT")


func _set_paused(value: bool) -> void:
	_paused = value
	get_tree().paused = value
	_hud.show_pause(value)


func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
