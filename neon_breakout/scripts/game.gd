extends Node2D
## Spielablauf von Neon Breakout: Zustände, Level-Aufbau, Punkte, Leben, Power-Ups.
##
## Für Fehlerberichte wird der Zufalls-Seed ausgegeben. Er lässt sich mit
## `godot --path neon_breakout -- --seed=12345` vorgeben. Auch die Power-Up-Drops
## laufen über diesen Seed.

enum State { READY, PLAYING, LEVEL_CLEAR, GAME_OVER }

const BRICK_SCENE: PackedScene = preload("res://scenes/brick.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const START_LIVES := 3
const PADDLE_Y := 1010.0
const BRICK_STEP := Vector2(114.0, 44.0)
const FIRST_ROW_Y := 220.0
## Kurze Sperre nach Zustandswechseln, damit Dauerklicken nichts überspringt.
const INPUT_LOCK_SECONDS := 0.6
const LASER_COOLDOWN := 0.22
## Alle so viele Treffer in Folge gibt es einen kleinen Jubel-Effekt.
const COMBO_MILESTONE := 5

## Automatischer Spieler für Tests (Schläger folgt dem Ball, Start ohne Eingabe).
@export var autoplay := false

var state: State = State.READY
var level := 1
var score := 0
var lives := START_LIVES
var best := 0
var rng := RandomNumberGenerator.new()
## Wahrscheinlichkeit für einen Item-Drop (Tests dürfen sie ändern).
var drop_chance := PowerUps.DROP_CHANCE
var effects := EffectTracker.new()

var _balls: Array[Ball] = []
var _bricks_destroyed := 0
var _bricks_remaining := 0
var _paused := false
var _state_time := 0.0
var _laser_cooldown := 0.0
var _stuck_time := 0.0
## Zerstörte Blöcke seit dem letzten Schlägerkontakt: Combo und Tonhöhe.
var _streak := 0
var _shake := 0.0
var _slowmo_until_msec := 0
## Eigener Zufall nur für die Optik, damit er den Spielverlauf (Seed) nicht verändert.
var _fx_rng := RandomNumberGenerator.new()

@onready var _paddle: Paddle = $Paddle
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
	_register_ball($Ball)
	_hud.resume_pressed.connect(_set_paused.bind(false))
	_hud.menu_pressed.connect(_to_menu)
	_hud.set_score(score)
	_hud.set_best(best)
	_hud.set_lives(lives)
	Music.set_muffled(false)
	Transition.fade_in(self)
	_start_level()


func _physics_process(delta: float) -> void:
	_state_time += delta
	if autoplay:
		_paddle.auto_target = _lowest_ball()
		if state in [State.READY, State.LEVEL_CLEAR] and _input_unlocked():
			_confirm()
	if state == State.PLAYING:
		_tick_effects(delta)
		_auto_release_stuck(delta)
		_laser_cooldown = maxf(_laser_cooldown - delta, 0.0)
		if effects.is_active(PowerUps.Kind.LASER) and _laser_cooldown <= 0.0 \
				and not any_ball_stuck() and (autoplay or Input.is_action_pressed("launch")):
			_fire_laser()
	_paddle.laser_glow = effects.is_active(PowerUps.Kind.LASER)


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
	_hud.set_effects(_effect_entries())


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	Music.set_muffled(false)


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


## Wendet ein Power-Up an. Wird beim Einsammeln aufgerufen, Tests dürfen es direkt nutzen.
func apply_powerup(kind: PowerUps.Kind) -> void:
	match kind:
		PowerUps.Kind.WIDE:
			effects.activate(kind, PowerUps.AMOUNTS[kind])
			_paddle.animate_width(Paddle.SIZE.x * PowerUps.WIDE_FACTOR)
			Sfx.play(&"powerup")
		PowerUps.Kind.MULTI:
			_spawn_multiball()
			Sfx.play(&"multiball")
		PowerUps.Kind.LASER:
			effects.activate(kind, PowerUps.AMOUNTS[kind])
			Sfx.play(&"powerup", 1.3)
		PowerUps.Kind.STICKY:
			effects.activate(kind, PowerUps.AMOUNTS[kind])
			Sfx.play(&"powerup", 0.85)
		PowerUps.Kind.SLOW:
			effects.activate(kind, PowerUps.AMOUNTS[kind])
			_update_ball_speeds()
			Sfx.play(&"powerup", 0.7)
		PowerUps.Kind.LIFE:
			lives = mini(lives + 1, PowerUps.MAX_LIVES)
			_hud.set_lives(lives)
			Sfx.play(&"life_up")
	_hud.show_toast(PowerUps.NAME_KEYS[kind], PowerUps.COLORS[kind])


## Lässt ein Item an `pos` fallen (auch für Tests).
func spawn_item(pos: Vector2, kind: PowerUps.Kind) -> PowerUpItem:
	var item := PowerUpItem.new()
	item.kind = kind
	item.paddle = _paddle
	item.bottom_y = BreakoutConfig.FIELD.end.y + 60.0
	item.position = pos
	item.collected.connect(_on_item_collected)
	item.add_to_group("pu_items")
	add_child(item)
	return item


func ball_count() -> int:
	return _balls.size()


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


func _register_ball(ball: Ball) -> void:
	ball.paddle = _paddle
	ball.bottom_y = BreakoutConfig.FIELD.end.y + 60.0
	ball.lost.connect(_on_ball_lost.bind(ball))
	ball.bounced.connect(_on_ball_bounced.bind(ball))
	_balls.append(ball)


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
	Music.set_level(level)
	_prepare_launch()


## Bereitet den Start vor (nach Levelbeginn und nach Lebensverlust): Effekte, Items,
## Laser und Zusatzbälle verschwinden, der Ball klebt wieder in der Schlägermitte.
func _prepare_launch() -> void:
	_reset_effects()
	_set_streak(0)
	_update_ball_speeds()
	_balls[0].stick_to_paddle()
	_set_state(State.READY)
	_hud.show_message("MSG_READY", "MSG_READY_HINT")


func _reset_effects() -> void:
	effects.clear()
	_paddle.animate_width(Paddle.SIZE.x, 0.15)
	for node in get_tree().get_nodes_in_group("pu_items") + get_tree().get_nodes_in_group("pu_shots"):
		node.queue_free()
	# Nur der erste Ball bleibt, Zusatzbälle fallen weg.
	while _balls.size() > 1:
		var extra: Ball = _balls.pop_back()
		extra.queue_free()


func _set_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _input_unlocked() -> bool:
	return _state_time >= INPUT_LOCK_SECONDS


## Bestätigen-Aktion: Ball starten, klebende Bälle lösen, nächstes Level oder Neustart.
func _confirm() -> void:
	if _paused or not _input_unlocked():
		return
	match state:
		State.READY:
			_launch_ball()
		State.PLAYING:
			if any_ball_stuck():
				_release_stuck_balls()
		State.LEVEL_CLEAR:
			level += 1
			_start_level()
		State.GAME_OVER:
			get_tree().reload_current_scene()


func _launch_ball() -> void:
	_hud.hide_message()
	Sfx.play(&"launch")
	_set_streak(0)
	_balls[0].launch(Vector2(rng.randf_range(-0.35, 0.35), -1.0))
	_set_state(State.PLAYING)


## Klebt mindestens ein Ball am Schläger?
func any_ball_stuck() -> bool:
	for ball in _balls:
		if ball.mode == Ball.Mode.STUCK:
			return true
	return false


func _release_stuck_balls() -> void:
	for ball in _balls:
		if ball.mode == Ball.Mode.STUCK:
			ball.launch(ball.release_direction())
			Sfx.play(&"launch")
	# Kein Laser-Schuss im selben Moment, in dem der Ball gelöst wird.
	_laser_cooldown = LASER_COOLDOWN


## Der tiefste Ball ist für den Autopiloten am dringendsten.
func _lowest_ball() -> Node2D:
	var lowest: Ball = _balls[0]
	for ball in _balls:
		if ball.global_position.y > lowest.global_position.y:
			lowest = ball
	return lowest


func _ball_speed() -> float:
	var factor := PowerUps.SLOW_FACTOR if effects.is_active(PowerUps.Kind.SLOW) else 1.0
	return BreakoutMath.speed_for(level, _bricks_destroyed) * factor


func _update_ball_speeds() -> void:
	var speed := _ball_speed()
	for ball in _balls:
		ball.set_speed(speed)


func _tick_effects(delta: float) -> void:
	for kind in effects.tick(delta):
		match kind:
			PowerUps.Kind.WIDE:
				_paddle.animate_width(Paddle.SIZE.x)
			PowerUps.Kind.SLOW:
				_update_ball_speeds()
			PowerUps.Kind.STICKY:
				_release_stuck_balls()


## Der Autopilot löst klebende Bälle nach kurzer Zeit (ein Mensch drückt dafür die Starttaste).
func _auto_release_stuck(delta: float) -> void:
	if not autoplay or not any_ball_stuck():
		_stuck_time = 0.0
		return
	_stuck_time += delta
	if _stuck_time >= 0.4:
		_stuck_time = 0.0
		_release_stuck_balls()


func _fire_laser() -> void:
	if not effects.consume(PowerUps.Kind.LASER):
		return
	_laser_cooldown = LASER_COOLDOWN
	Sfx.play(&"laser", 1.0, -3.0)
	for side in [-1, 1]:
		var shot := LaserShot.new()
		shot.top_y = BreakoutConfig.FIELD.position.y
		shot.add_to_group("pu_shots")
		add_child(shot)
		shot.global_position = _paddle.muzzle(side)


## Aus einem fliegenden Ball werden drei (je ±20 Grad), höchstens MAX_BALLS insgesamt.
func _spawn_multiball() -> void:
	var source: Ball = null
	for ball in _balls:
		if ball.mode == Ball.Mode.FLYING:
			source = ball
			break
	if source == null:
		# Nur klebende Bälle: einen lösen, damit es etwas zum Teilen gibt.
		if not any_ball_stuck():
			return
		_release_stuck_balls()
		for ball in _balls:
			if ball.mode == Ball.Mode.FLYING:
				source = ball
				break
		if source == null:
			return
	for angle in [-PowerUps.MULTI_ANGLE_DEGREES, PowerUps.MULTI_ANGLE_DEGREES]:
		if _balls.size() >= PowerUps.MAX_BALLS:
			break
		var extra: Ball = BALL_SCENE.instantiate()
		add_child(extra)
		_register_ball(extra)
		extra.global_position = source.global_position
		extra.speed = source.speed
		extra.launch(PowerUps.rotated_direction(source.velocity, angle))


func _set_streak(value: int) -> void:
	_streak = value
	_hud.set_combo(_streak, PowerUps.combo_multiplier(_streak))


func _on_brick_destroyed(brick: Brick) -> void:
	var multiplier := PowerUps.combo_multiplier(_streak)
	var points := int(round(BreakoutMath.brick_points(brick.max_hp) * multiplier))
	score += points
	ScorePopup.spawn(self, brick.position, points, multiplier)
	_bricks_destroyed += 1
	_bricks_remaining -= 1
	_update_ball_speeds()
	_hud.set_score(score)
	Burst.spawn(self, brick.position, brick.get_color(), FxSettings.scaled(22), 380.0, 0.6)
	add_shake(3.0)
	if _bricks_remaining > 0:
		if state == State.PLAYING and PowerUps.should_drop(rng, drop_chance):
			spawn_item(brick.position, PowerUps.pick(rng))
		return
	for ball in _balls:
		ball.stop()
	for item in get_tree().get_nodes_in_group("pu_items"):
		item.queue_free()
	_set_state(State.LEVEL_CLEAR)
	_hud.show_message("MSG_LEVEL_CLEAR", "MSG_LEVEL_CLEAR_HINT")
	Sfx.play(&"level_clear")
	add_shake(9.0)
	_celebrate()
	if not autoplay:
		Engine.time_scale = 0.3
		_slowmo_until_msec = Time.get_ticks_msec() + 450


func _on_ball_lost(ball: Ball) -> void:
	if _balls.size() > 1:
		# Es sind noch Bälle im Spiel: Dieser verschwindet, ohne Leben zu kosten.
		_balls.erase(ball)
		ball.queue_free()
		return
	lives -= 1
	_hud.set_lives(lives)
	_set_streak(0)
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
	_reset_effects()
	_set_state(State.GAME_OVER)
	_hud.show_message("MSG_GAME_OVER", "MSG_GAME_OVER_HINT")
	Sfx.play(&"game_over")
	Music.set_muffled(true)


## Jeder Treffer: Ton (höher bei Serien), Funken, kleines Wackeln.
func _on_brick_hit(brick: Brick, will_break: bool) -> void:
	if brick.indestructible:
		Sfx.play(&"metal")
		Burst.spawn(self, brick.position, brick.get_color(), FxSettings.scaled(5), 220.0, 0.3, Vector2.ZERO, 180.0, 0.7)
		return
	_set_streak(_streak + 1)
	if _streak % COMBO_MILESTONE == 0:
		_combo_milestone()
	var pitch := 1.0 + 0.06 * minf(_streak, 12.0)
	Sfx.play(&"brick_break" if will_break else &"brick_hit", pitch)
	if not will_break:
		Burst.spawn(self, brick.position, brick.get_color(), FxSettings.scaled(7), 260.0, 0.35, Vector2.ZERO, 180.0, 0.8)
		add_shake(1.5)


func _on_ball_bounced(kind: StringName, hit_position: Vector2, ball: Ball) -> void:
	match kind:
		&"paddle":
			_set_streak(0)
			Sfx.play(&"paddle")
			_paddle.pulse()
			var accent: Color = BreakoutConfig.PALETTE["accent"]
			Burst.spawn(self, hit_position, accent, FxSettings.scaled(8), 300.0, 0.35, Vector2.UP, 70.0, 0.7)
			if state == State.PLAYING and ball.mode == Ball.Mode.FLYING and effects.is_active(PowerUps.Kind.STICKY):
				var limit := _paddle.width * 0.5 - Ball.RADIUS
				ball.stick_to_paddle(clampf(ball.global_position.x - _paddle.global_position.x, -limit, limit))
				Sfx.play(&"stick")
		&"wall":
			Sfx.play(&"wall", 1.0, -4.0)


func _on_item_collected(kind: PowerUps.Kind) -> void:
	if state != State.PLAYING:
		return
	var color: Color = PowerUps.COLORS[kind]
	Burst.spawn(self, _paddle.global_position + Vector2(0.0, -20.0), color, FxSettings.scaled(16), 340.0, 0.5, Vector2.UP, 90.0, 0.9)
	apply_powerup(kind)


## Zeilen für die Effektanzeige: Combo und aktive Power-Ups.
func _effect_entries() -> Array:
	var entries: Array = []
	for kind in effects.active_kinds():
		var value := int(ceil(effects.remaining(kind)))
		# Zeitbasierte Effekte zeigen Sekunden, der Laser die übrigen Schüsse.
		var text := ("%d s" % value) if PowerUps.is_timed(kind) else ("×%d" % value)
		entries.append({"key": PowerUps.NAME_KEYS[kind], "value": text})
	return entries


## Kleiner Jubel bei einer Combo-Serie: Ton, Blitz, goldene Funken über dem Schläger.
func _combo_milestone() -> void:
	Sfx.play(&"combo", 1.0 + 0.04 * minf(_streak / float(COMBO_MILESTONE), 6.0))
	_hud.flash(BreakoutConfig.PALETTE["warn"], 0.12)
	Burst.spawn(self, _paddle.global_position + Vector2(0.0, -30.0), BreakoutConfig.PALETTE["warn"], FxSettings.scaled(18), 420.0, 0.6, Vector2.UP, 100.0, 0.9)


## Feuerwerk über dem Spielfeld, wenn das Level geschafft ist.
func _celebrate() -> void:
	var field := BreakoutConfig.FIELD
	var colors: Array = BreakoutConfig.BRICK_COLORS.values()
	for i in 7:
		var pos := Vector2(field.position.x + field.size.x * (0.1 + 0.13 * i), field.position.y + field.size.y * _fx_rng.randf_range(0.45, 0.7))
		var color: Color = colors[_fx_rng.randi() % colors.size()]
		Burst.spawn(self, pos, color, FxSettings.scaled(34), _fx_rng.randf_range(520.0, 760.0), 1.1, Vector2.UP, 75.0, 1.1)
	_hud.flash(BreakoutConfig.PALETTE["accent"], 0.22)


## Bildschirmwackeln (Stärke in Pixeln), abschaltbar in den Optionen.
func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount * FxSettings.shake_scale())


func _set_paused(value: bool) -> void:
	_paused = value
	get_tree().paused = value
	Music.set_muffled(value)
	_hud.show_pause(value)


func _to_menu() -> void:
	get_tree().paused = false
	Music.set_muffled(false)
	Transition.change_scene(get_tree(), "res://scenes/main_menu.tscn")
