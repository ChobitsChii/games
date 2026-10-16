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
## Treffer in Folge ohne Schlägerkontakt: lässt die Töne höher klingen.
var _streak := 0
var _shake := 0.0
var _slowmo_until_msec := 0
## Eigener Zufall nur für die Optik, damit er den Spielverlauf (Seed) nicht verändert.
var _fx_rng := RandomNumberGenerator.new()

@onready var _paddle: Paddle = $Paddle
@onready var _ball: Ball = $Ball
@onready var _bricks: Node2D = $Bricks
@onready var _walls: StaticBody2D = $Walls
@onready var _hud: Hud = $Hud
@onready var _camera: Camera2D = $Camera


func _ready() -> void:
	_init_seed()
	best = SaveService.get_value("highscore", "best", 0)
	_build_walls()
	_paddle.set_bounds(BreakoutConfig.FIELD.position.x, BreakoutConfig.FIELD.end.x)
	_paddle.global_position = Vector2(BreakoutConfig.FIELD.get_center().x, PADDLE_Y)
	_ball.paddle = _paddle
	_ball.bottom_y = BreakoutConfig.FIELD.end.y + 60.0
	_ball.lost.connect(_on_ball_lost)
	_ball.bounced.connect(_on_ball_bounced)
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


func _process(delta: float) -> void:
	# Bildschirmwackeln klingt schnell aus.
	if _shake > 0.0:
		_shake *= exp(-delta * 9.0)
		if _shake < 0.3:
			_shake = 0.0
		_camera.offset = Vector2(_fx_rng.randf_range(-1.0, 1.0), _fx_rng.randf_range(-1.0, 1.0)) * _shake
	elif _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO
	# Zeitlupe endet nach Echtzeit (nicht nach Spielzeit, die ja verlangsamt ist).
	if Engine.time_scale < 1.0 and Time.get_ticks_msec() >= _slowmo_until_msec:
		Engine.time_scale = 1.0


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and state in [State.READY, State.PLAYING]:
		_set_paused(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("launch"):
		_confirm()


func _draw() -> void:
	var field := BreakoutConfig.FIELD
	var accent: Color = BreakoutConfig.PALETTE["accent"]
	draw_rect(field, Color(BreakoutConfig.PALETTE["panel"], 0.5))
	# Leuchtender Rahmen: weiche Außenringe plus heller Kern (Wert über 1 für den Glow).
	draw_rect(field.grow(10.0), Color(accent, 0.05), false, 18.0, true)
	draw_rect(field.grow(4.0), Color(accent, 0.12), false, 8.0, true)
	draw_rect(field, Color(accent.r * 1.4, accent.g * 1.4, accent.b * 1.4, 0.95), false, 3.0, true)


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
			brick.appear(row_index * 0.05 + col_index * 0.02)
			brick.hit_taken.connect(_on_brick_hit)
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
	Sfx.play(&"launch")
	_streak = 0
	_ball.launch(Vector2(rng.randf_range(-0.35, 0.35), -1.0))
	_set_state(State.PLAYING)


func _on_brick_destroyed(brick: Brick) -> void:
	score += BreakoutMath.brick_points(brick.max_hp)
	_bricks_destroyed += 1
	_bricks_remaining -= 1
	_ball.speed = BreakoutMath.speed_for(level, _bricks_destroyed)
	_hud.set_score(score)
	Burst.spawn(self, brick.position, brick.get_color(), FxSettings.scaled(22), 380.0, 0.6)
	add_shake(3.0)
	if _bricks_remaining <= 0:
		_ball.stop()
		_set_state(State.LEVEL_CLEAR)
		_hud.show_message("MSG_LEVEL_CLEAR", "MSG_LEVEL_CLEAR_HINT")
		Sfx.play(&"level_clear")
		add_shake(9.0)
		if not autoplay:
			Engine.time_scale = 0.3
			_slowmo_until_msec = Time.get_ticks_msec() + 450


func _on_ball_lost() -> void:
	lives -= 1
	_hud.set_lives(lives)
	_streak = 0
	Sfx.play(&"life_lost")
	add_shake(18.0)
	_hud.flash(Color(1.0, 0.1, 0.25), 0.35)
	if lives > 0:
		_prepare_launch()
		return
	if score > best:
		best = score
		SaveService.set_value("highscore", "best", best)
		_hud.set_best(best)
	_set_state(State.GAME_OVER)
	_hud.show_message("MSG_GAME_OVER", "MSG_GAME_OVER_HINT")
	Sfx.play(&"game_over")


## Jeder Treffer: Ton (höher bei Serien), Funken, kleines Wackeln.
func _on_brick_hit(brick: Brick, will_break: bool) -> void:
	if brick.indestructible:
		Sfx.play(&"metal")
		Burst.spawn(self, brick.position, brick.get_color(), FxSettings.scaled(5), 220.0, 0.3, Vector2.ZERO, 180.0, 0.7)
		return
	_streak += 1
	var pitch := 1.0 + 0.06 * minf(_streak, 12.0)
	Sfx.play(&"brick_break" if will_break else &"brick_hit", pitch)
	if not will_break:
		Burst.spawn(self, brick.position, brick.get_color(), FxSettings.scaled(7), 260.0, 0.35, Vector2.ZERO, 180.0, 0.8)
		add_shake(1.5)


func _on_ball_bounced(kind: StringName, hit_position: Vector2) -> void:
	match kind:
		&"paddle":
			_streak = 0
			Sfx.play(&"paddle")
			_paddle.pulse()
			var accent: Color = BreakoutConfig.PALETTE["accent"]
			Burst.spawn(self, hit_position, accent, FxSettings.scaled(8), 300.0, 0.35, Vector2.UP, 70.0, 0.7)
		&"wall":
			Sfx.play(&"wall", 1.0, -4.0)


## Bildschirmwackeln (Stärke in Pixeln), abschaltbar in den Optionen.
func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount * FxSettings.shake_scale())


func _set_paused(value: bool) -> void:
	_paused = value
	get_tree().paused = value
	_hud.show_pause(value)


func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
