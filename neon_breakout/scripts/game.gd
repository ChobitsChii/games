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
## Endlos-Modus: Erreichen Blöcke diese Höhe, ist das Spiel vorbei.
const ENDLESS_LIMIT_Y := PADDLE_Y - 110.0
const ENDLESS_PUSH_SECONDS := 0.3
const BOSS_Y := 330.0
## Demo-Modus: so lange bleibt "Game Over" stehen, bevor es von vorn losgeht.
const DEMO_RESTART_SECONDS := 2.5
const POWERUP_TIP_EVENTS := {
	PowerUps.Kind.WIDE: &"wide",
	PowerUps.Kind.MULTI: &"multi",
	PowerUps.Kind.LASER: &"laser",
	PowerUps.Kind.STICKY: &"sticky",
	PowerUps.Kind.SLOW: &"slow",
	PowerUps.Kind.LIFE: &"life",
}

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
## Anzahl eingesammelter Power-Ups (für Tests und Statistik).
var items_collected := 0
## Spielmodus (siehe GameMode). Wird beim Start aus `GameMode.selected` übernommen.
var mode: int = GameMode.Id.CLASSIC

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

# Modus-Zustand
var _best_key := ""
var _chaos := ChaosEvents.new()
var _coach := DemoCoach.new()
var _run_time := 0.0
var _level_time := 0.0
var _level_bricks := 0
var _rows_spawned := 0
var _row_timer := 0.0
var _boss: Boss = null
var _ghost_tween: Tween
# Demo-Zielplanung (wird nur neu berechnet, wenn sich Bahn oder Blöcke ändern).
var _demo_plan_ratio := 0.0
var _demo_plan_dirty := true
var _demo_plan_landing_x := NAN
var _demo_plan_ball: Ball = null
var _demo_last_ratio := NAN
var _demo_misses := 0
var _demo_sticky_x := NAN

@onready var _paddle: Paddle = $Paddle
@onready var _bricks: Node2D = $Bricks
@onready var _walls: StaticBody2D = $Walls
@onready var _hud: Hud = $Hud
@onready var _camera: Camera2D = $Camera


func _ready() -> void:
	_init_seed()
	_setup_mode()
	_build_walls()
	_paddle.set_bounds(BreakoutConfig.FIELD.position.x, BreakoutConfig.FIELD.end.x)
	_paddle.global_position = Vector2(BreakoutConfig.FIELD.get_center().x, PADDLE_Y)
	_register_ball($Ball)
	_hud.pause_pressed.connect(_on_pause_button_pressed)
	_hud.resume_pressed.connect(_set_paused.bind(false))
	_hud.menu_pressed.connect(_to_menu)
	_hud.set_score(score)
	_hud.set_best(best)
	_hud.set_lives(lives)
	_hud.set_lives_visible(GameMode.has_lives(mode))
	_hud.set_best_visible(_best_key != "")
	Music.set_muffled(false)
	Transition.fade_in(self)
	_start_level()


func _physics_process(delta: float) -> void:
	_state_time += delta
	_coach.advance(delta)
	if autoplay:
		if GameMode.is_demo(mode):
			_update_demo_paddle()
		else:
			_paddle.auto_target_x = NAN
			_paddle.auto_target = _most_urgent_ball()
		if state in [State.READY, State.LEVEL_CLEAR] and _input_unlocked():
			_confirm()
	if GameMode.is_demo(mode) and state == State.GAME_OVER and _state_time >= DEMO_RESTART_SECONDS:
		get_tree().reload_current_scene()
	if is_instance_valid(_boss):
		_boss.active = state == State.PLAYING
	if state == State.PLAYING:
		_tick_mode(delta)
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
	_update_info()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	Music.set_muffled(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_pause_button_pressed()


func _on_pause_button_pressed() -> void:
	if GameMode.is_demo(mode):
		_to_menu()
	elif state in [State.READY, State.PLAYING]:
		_set_paused(not _paused)
	elif state == State.GAME_OVER:
		_to_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state in [State.READY, State.PLAYING]:
			_set_paused(true)
			get_viewport().set_input_as_handled()
		elif GameMode.is_demo(mode):
			get_viewport().set_input_as_handled()
			_to_menu()
		return
	if GameMode.is_demo(mode):
		if event.is_action_pressed("toggle_fullscreen"):
			return
		var key := event as InputEventKey
		var exit_key := key != null and key.pressed and not key.echo \
				and not (key.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META])
		var click := event as InputEventMouseButton
		var exit_click := click != null and click.pressed
		if event.is_action_pressed("launch") or exit_key or exit_click:
			get_viewport().set_input_as_handled()
			_to_menu()
		return
	if event.is_action_pressed("launch"):
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
			_demo_plan_dirty = true
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
			if GameMode.has_lives(mode):
				lives = mini(lives + 1, PowerUps.MAX_LIVES)
				_hud.set_lives(lives)
			Sfx.play(&"life_up")
	_hud.show_toast(PowerUps.NAME_KEYS[kind], PowerUps.COLORS[kind])
	_demo_tip(POWERUP_TIP_EVENTS[kind])


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
	_boss = null
	_bricks_destroyed = 0
	_bricks_remaining = 0
	_level_time = 0.0
	match mode:
		GameMode.Id.ENDLESS:
			_build_endless()
		GameMode.Id.BOSS:
			_build_boss()
		_:
			_build_level_bricks()
	_level_bricks = _bricks_remaining
	_hud.set_level(level)
	Music.set_level(level)
	_prepare_launch()
	_demo_tip(&"level_start")


func _build_level_bricks() -> void:
	var rows: Array = BreakoutLevels.get_level(level)
	for row_index in rows.size():
		var row: String = rows[row_index]
		for col_index in row.length():
			var kind := row[col_index]
			if kind == ".":
				continue
			_add_brick(kind, _brick_position(col_index, row_index), row_index * 0.05 + col_index * 0.02)


func _brick_position(col_index: int, row_index: int) -> Vector2:
	var center_x := BreakoutConfig.FIELD.get_center().x
	return Vector2(
			center_x + (col_index - (BreakoutConfig.BRICK_COLUMNS - 1) * 0.5) * BRICK_STEP.x,
			FIRST_ROW_Y + row_index * BRICK_STEP.y)


func _add_brick(kind: String, pos: Vector2, delay: float) -> Brick:
	var brick: Brick = BRICK_SCENE.instantiate()
	brick.position = pos
	_bricks.add_child(brick)
	brick.setup(kind)
	brick.appear(delay)
	brick.hit_taken.connect(_on_brick_hit)
	if not brick.indestructible:
		_bricks_remaining += 1
		brick.destroyed.connect(_on_brick_destroyed)
	return brick


## Bereitet den Start vor (nach Levelbeginn und nach Lebensverlust): Effekte, Items,
## Laser und Zusatzbälle verschwinden, der Ball klebt wieder in der Schlägermitte.
func _prepare_launch() -> void:
	_reset_effects()
	_reset_demo_plan()
	_set_streak(0)
	_update_ball_speeds()
	_balls[0].stick_to_paddle()
	_set_state(State.READY)
	_hud.show_message("MSG_READY", "MSG_READY_HINT")


func _reset_effects() -> void:
	effects.clear()
	_chaos_reset()
	_paddle.animate_width(Paddle.SIZE.x, 0.15)
	for node in get_tree().get_nodes_in_group("pu_items") + get_tree().get_nodes_in_group("pu_shots") \
			+ get_tree().get_nodes_in_group("boss_shots"):
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


## Der dringendste Ball für den Autopiloten: fallende Bälle nach Ankunftszeit am Schläger,
## erst wenn alle steigen, der am schnellsten zurückkehrende.
func _most_urgent_ball() -> Ball:
	var hit_y := PADDLE_Y - Paddle.SIZE.y * 0.5 - Ball.RADIUS
	var top_y := BreakoutConfig.FIELD.position.y + Ball.RADIUS
	var best_ball: Ball = _balls[0]
	var best_time := INF
	for ball in _balls:
		var t := DemoCoach.time_to_paddle(ball.global_position, ball.velocity, top_y, hit_y) if ball.mode == Ball.Mode.FLYING else INF
		if t < best_time:
			best_time = t
			best_ball = ball
	return best_ball


func _ball_speed() -> float:
	var factor := PowerUps.SLOW_FACTOR if effects.is_active(PowerUps.Kind.SLOW) else 1.0
	if _chaos.is_active(ChaosEvents.Kind.FAST):
		factor *= ChaosEvents.FAST_FACTOR
	return BreakoutMath.speed_for(level, _bricks_destroyed) * factor * GameMode.speed_factor(mode)


func _update_ball_speeds() -> void:
	var speed := _ball_speed()
	for ball in _balls:
		ball.set_speed(speed)


func _tick_effects(delta: float) -> void:
	for kind in effects.tick(delta):
		match kind:
			PowerUps.Kind.WIDE:
				_paddle.animate_width(Paddle.SIZE.x)
				_demo_plan_dirty = true
			PowerUps.Kind.SLOW:
				_update_ball_speeds()
			PowerUps.Kind.STICKY:
				_release_stuck_balls()


## Der Autopilot löst klebende Bälle nach kurzer Zeit (ein Mensch drückt dafür die Starttaste).
## Im Demo-Modus fährt er erst in Zielposition und schießt dann gezielt ab.
func _auto_release_stuck(delta: float) -> void:
	if not autoplay or not any_ball_stuck():
		_stuck_time = 0.0
		return
	_stuck_time += delta
	if GameMode.is_demo(mode):
		var aligned := not is_nan(_demo_sticky_x) and absf(_paddle.global_position.x - _demo_sticky_x) < 10.0
		if (_stuck_time >= 0.18 and aligned) or _stuck_time >= 0.8:
			_stuck_time = 0.0
			_demo_sticky_x = NAN
			_release_stuck_balls()
		return
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
	if _chaos.is_active(ChaosEvents.Kind.DOUBLE):
		points *= ChaosEvents.DOUBLE_FACTOR
	score += points
	ScorePopup.spawn(self, brick.position, points, multiplier)
	_bricks_destroyed += 1
	_bricks_remaining -= 1
	_demo_plan_dirty = true
	_demo_misses = 0
	_demo_last_ratio = NAN
	_update_ball_speeds()
	_hud.set_score(score)
	Burst.spawn(self, brick.position, brick.get_color(), FxSettings.scaled(22), 380.0, 0.6)
	add_shake(3.0)
	var endless := mode == GameMode.Id.ENDLESS
	if _bricks_remaining > 0 or endless:
		if state == State.PLAYING and PowerUps.should_drop(rng, drop_chance):
			spawn_item(brick.position, PowerUps.pick(rng))
		if endless and _bricks_remaining <= 0 and state == State.PLAYING:
			_endless_cleared()
		return
	for ball in _balls:
		ball.stop()
	for item in get_tree().get_nodes_in_group("pu_items"):
		item.queue_free()
	for shot in get_tree().get_nodes_in_group("boss_shots"):
		shot.queue_free()
	_on_level_cleared()


## Alle Blöcke weg: Meldung, Jubel und je nach Modus Bonus oder Ende des Laufs.
func _on_level_cleared() -> void:
	var title_key := "MSG_LEVEL_CLEAR"
	var hint_key := "MSG_LEVEL_CLEAR_HINT"
	var run_done := false
	match mode:
		GameMode.Id.BOSS:
			title_key = "MSG_BOSS_DOWN"
		GameMode.Id.TIME_ATTACK:
			run_done = _finish_time_attack_level()
			if run_done:
				title_key = "MSG_RUN_DONE"
				hint_key = "MSG_GAME_OVER_HINT"
	_set_state(State.GAME_OVER if run_done else State.LEVEL_CLEAR)
	if run_done:
		_save_best()
	_hud.show_message(title_key, hint_key)
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
	if _damage_player():
		_prepare_launch()


## Ein Leben geht verloren (Zen-Modus: keins). Gibt true zurück, solange das Spiel weitergeht;
## sonst ist es Game Over.
func _damage_player() -> bool:
	if GameMode.has_lives(mode):
		lives -= 1
	_hud.set_lives(lives)
	_set_streak(0)
	Sfx.play(&"life_lost")
	add_shake(18.0)
	_hud.flash(Color(1.0, 0.1, 0.25), 0.35)
	_demo_tip(&"life_lost")
	if lives > 0:
		return true
	_game_over(&"MSG_GAME_OVER")
	return false


func _game_over(title_key: StringName) -> void:
	lives = 0
	_hud.set_lives(lives)
	for ball in _balls:
		ball.stop()
	_save_best()
	_reset_effects()
	_set_state(State.GAME_OVER)
	_hud.show_message(String(title_key), "MSG_GAME_OVER_HINT")
	Sfx.play(&"game_over")
	Music.set_muffled(true)


## Jeder Treffer: Ton (höher bei Serien), Funken, kleines Wackeln.
func _on_brick_hit(brick: Brick, will_break: bool) -> void:
	if brick.indestructible:
		_demo_tip(&"unbreakable")
		_demo_plan_dirty = true
		Sfx.play(&"metal")
		Burst.spawn(self, brick.position, brick.get_color(), FxSettings.scaled(5), 220.0, 0.3, Vector2.ZERO, 180.0, 0.7)
		return
	_demo_misses = 0
	_demo_last_ratio = NAN
	_demo_plan_dirty = true
	_set_streak(_streak + 1)
	if brick is Boss:
		_on_boss_hit(brick)
	if _streak % COMBO_MILESTONE == 0:
		_combo_milestone()
	var pitch := 1.0 + 0.06 * minf(_streak, 12.0)
	Sfx.play(&"brick_break" if will_break else &"brick_hit", pitch)
	if not will_break:
		Burst.spawn(self, brick.position, brick.get_color(), FxSettings.scaled(7), 260.0, 0.35, Vector2.ZERO, 180.0, 0.8)
		add_shake(1.5)


func _on_ball_bounced(kind: StringName, hit_position: Vector2, ball: Ball) -> void:
	_demo_plan_dirty = true
	match kind:
		&"paddle":
			_set_streak(0)
			Sfx.play(&"paddle")
			_paddle.pulse()
			if GameMode.is_demo(mode):
				var ratio := DemoCoach.hit_ratio(ball.global_position.x, _paddle.global_position.x, _paddle.width)
				_demo_last_ratio = ratio
				_demo_misses += 1
				_demo_tip(DemoCoach.paddle_event(ratio))
			var accent: Color = BreakoutConfig.PALETTE["accent"]
			Burst.spawn(self, hit_position, accent, FxSettings.scaled(8), 300.0, 0.35, Vector2.UP, 70.0, 0.7)
			if state == State.PLAYING and ball.mode == Ball.Mode.FLYING and effects.is_active(PowerUps.Kind.STICKY):
				var limit := _paddle.width * 0.5 - Ball.RADIUS
				ball.stick_to_paddle(clampf(ball.global_position.x - _paddle.global_position.x, -limit, limit))
				_demo_sticky_x = NAN
				Sfx.play(&"stick")
		&"wall":
			Sfx.play(&"wall", 1.0, -4.0)


func _on_item_collected(kind: PowerUps.Kind) -> void:
	if state != State.PLAYING:
		return
	items_collected += 1
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
	for kind in _chaos.active_kinds():
		entries.append({"key": ChaosEvents.NAME_KEYS[kind], "value": "%d s" % int(ceil(_chaos.remaining(kind)))})
	return entries


## Kleiner Jubel bei einer Combo-Serie: Ton, Blitz, goldene Funken über dem Schläger.
func _combo_milestone() -> void:
	Sfx.play(&"combo", 1.0 + 0.04 * minf(_streak / float(COMBO_MILESTONE), 6.0))
	_hud.flash(BreakoutConfig.PALETTE["warn"], 0.12)
	_demo_tip(&"combo")
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


## Speichert den Rekord, falls er übertroffen wurde (auch beim Verlassen mitten im Spiel).
## Der Demo-Modus speichert nichts.
func _save_best() -> void:
	if _best_key != "" and score > best:
		best = score
		SaveService.set_value("highscore", _best_key, best)
		_hud.set_best(best)


func _to_menu() -> void:
	_save_best()
	get_tree().paused = false
	Music.set_muffled(false)
	Transition.change_scene(get_tree(), "res://scenes/main_menu.tscn")


# ---------------------------------------------------------------------------
# Spielmodi
# ---------------------------------------------------------------------------

func _setup_mode() -> void:
	mode = GameMode.selected if GameMode.is_valid(GameMode.selected) else GameMode.Id.CLASSIC
	if GameMode.is_demo(mode):
		autoplay = true
	drop_chance = GameMode.drop_chance(mode)
	_best_key = GameMode.best_key(mode)
	best = SaveService.get_value("highscore", _best_key, 0) if _best_key != "" else 0


## Pro Spielschritt, nur im Zustand PLAYING.
func _tick_mode(delta: float) -> void:
	_run_time += delta
	_level_time += delta
	match mode:
		GameMode.Id.CHAOS:
			_chaos_update(delta)
		GameMode.Id.ENDLESS:
			_row_timer -= delta
			if _row_timer <= 0.0:
				_endless_push()


## Text für die Modus-Anzeige rechts neben dem Spielfeld.
func _update_info() -> void:
	match mode:
		GameMode.Id.TIME_ATTACK:
			var lines := PackedStringArray([tr("TA_TIME"), TimeAttack.format_time(_run_time)])
			var best_level: float = SaveService.get_value("highscore", "besttime_%d" % level, 0.0)
			if best_level > 0.0:
				lines.append(tr("TA_BEST_LEVEL_FMT") % TimeAttack.format_time(best_level))
			_hud.set_info("\n".join(lines))
		GameMode.Id.ENDLESS:
			_hud.set_info(tr("ENDLESS_ROWS_FMT") % _rows_spawned)
		GameMode.Id.BOSS:
			_hud.set_info(tr("BOSS_FMT") % level)
		GameMode.Id.DEMO:
			_hud.set_info(tr("MODE_DEMO_HINT"))
		GameMode.Id.ZEN:
			_hud.set_info(tr("MODE_ZEN"))
		_:
			_hud.set_info("")


func _demo_tip(event: StringName) -> void:
	if not GameMode.is_demo(mode):
		return
	var key := _coach.tip_for(event)
	if key != "":
		_hud.show_tip(key)


func _reset_demo_plan() -> void:
	_demo_plan_dirty = true
	_demo_plan_landing_x = NAN
	_demo_plan_ball = null
	_demo_last_ratio = NAN
	_demo_misses = 0
	_demo_sticky_x = NAN


## Steuert den Schläger im Demo-Modus: sagt den Landepunkt des Balls voraus, berechnet
## den exakten Abprallwinkel (direkt oder über Wand-/Deckenbande) auf einen freien Block
## und sammelt Power-Ups ein, wenn genug Zeit bleibt.
func _update_demo_paddle() -> void:
	var hit_y := PADDLE_Y - Paddle.SIZE.y * 0.5 - Ball.RADIUS
	_paddle.auto_target = null
	if state == State.PLAYING and any_ball_stuck():
		var stuck := _first_stuck_ball()
		if stuck != null:
			if is_nan(_demo_sticky_x):
				var offset := stuck.global_position.x - _paddle.global_position.x
				_demo_sticky_x = DemoCoach.plan_sticky_x(offset, stuck.release_direction(),
						hit_y, BreakoutConfig.FIELD, _brick_snapshots(), _paddle.width, _paddle.global_position.x)
			_paddle.auto_target_x = _demo_sticky_x
			return
	_demo_sticky_x = NAN
	var ball := _most_urgent_ball()
	if ball == null or ball.mode != Ball.Mode.FLYING:
		_paddle.auto_target_x = BreakoutConfig.FIELD.get_center().x
		return
	var landing_x := DemoCoach.predict_landing_x(ball.global_position, ball.velocity, BreakoutConfig.FIELD, hit_y)
	# Ist genug Zeit, sammelt der Demo-Autopilot fallende Power-Ups ein.
	var item := _demo_item_to_chase(ball, landing_x)
	if item != null:
		_paddle.auto_target_x = item.global_position.x
		return
	if ball.velocity.y <= 1.0:
		# Ball steigt: bei aktivem Laser kurz unter einen freien Block fahren, wenn genug Zeit ist.
		if state == State.PLAYING and effects.is_active(PowerUps.Kind.LASER):
			var laser_x := DemoCoach.laser_target_x(_paddle.global_position.x, _paddle.width,
					BreakoutConfig.FIELD, _brick_snapshots())
			if not is_nan(laser_x) and DemoCoach.can_detour(ball.global_position.y, ball.velocity.y,
					BreakoutConfig.FIELD.position.y, PADDLE_Y,
					absf(laser_x - _paddle.global_position.x),
					absf(laser_x - ball.global_position.x) + _paddle.width * 0.45, _paddle.move_speed):
				_paddle.auto_target_x = laser_x
				return
		_paddle.auto_target_x = ball.global_position.x
		return
	# Ball fällt: Schussplan nur neu berechnen, wenn sich Bahn oder Blöcke geändert haben.
	if _demo_plan_dirty or _demo_plan_ball != ball or is_nan(_demo_plan_landing_x) \
			or absf(landing_x - _demo_plan_landing_x) > 8.0:
		var avoid := _demo_last_ratio if _demo_misses >= 2 else NAN
		_demo_plan_ratio = DemoCoach.plan_shot(landing_x, hit_y, BreakoutConfig.FIELD,
				_brick_snapshots(), _paddle.width, avoid)
		_demo_plan_landing_x = landing_x
		_demo_plan_ball = ball
		_demo_plan_dirty = false
	_paddle.auto_target_x = landing_x - _demo_plan_ratio * (_paddle.width * 0.5)


func _first_stuck_ball() -> Ball:
	for ball in _balls:
		if ball.mode == Ball.Mode.STUCK:
			return ball
	return null


## Reine Blockdaten (Position, unzerstörbar, Trefferpunkte) für die Zielberechnung.
func _brick_snapshots() -> Array:
	var result: Array = []
	for node in _bricks.get_children():
		var brick := node as Brick
		if brick == null or brick.is_queued_for_deletion():
			continue
		if not brick.indestructible and brick.hp <= 0:
			continue
		result.append({"pos": brick.position, "indestructible": brick.indestructible, "hp": brick.hp})
	return result


## Das tiefste Power-Up, das der Schläger erreichen kann, ohne den Ball zu verpassen (sonst null).
func _demo_item_to_chase(ball: Ball, landing_x: float) -> PowerUpItem:
	if ball == null or ball.mode != Ball.Mode.FLYING:
		return null
	var best_item: PowerUpItem = null
	for node in get_tree().get_nodes_in_group("pu_items"):
		var item := node as PowerUpItem
		if item == null or item.is_queued_for_deletion() or item.global_position.y > PADDLE_Y + 12.0:
			continue
		if best_item != null and item.position.y < best_item.position.y:
			continue
		var to_item := absf(item.global_position.x - _paddle.global_position.x)
		var time_left := maxf(PADDLE_Y - item.global_position.y, 0.0) / PowerUps.FALL_SPEED
		if to_item / maxf(_paddle.move_speed, 1.0) > time_left + 0.08:
			continue
		var item_to_ball := absf(item.global_position.x - landing_x) + _paddle.width * 0.45
		if DemoCoach.can_detour(ball.global_position.y, ball.velocity.y, BreakoutConfig.FIELD.position.y,
				PADDLE_Y, to_item, item_to_ball, _paddle.move_speed):
			best_item = item
	return best_item


# --- Chaos ------------------------------------------------------------------

func _chaos_update(delta: float) -> void:
	var kind := _chaos.advance(delta, rng)
	if kind >= 0:
		_chaos_apply(kind)
	for ended in _chaos.tick(delta):
		_chaos_end(ended)


func _chaos_apply(kind: int) -> void:
	_hud.show_toast(ChaosEvents.NAME_KEYS[kind], ChaosEvents.color_for(kind))
	Sfx.play(&"powerup", 0.6 if kind not in ChaosEvents.GOOD else 1.2)
	_hud.flash(ChaosEvents.color_for(kind), 0.15)
	match kind:
		ChaosEvents.Kind.REVERSE:
			_paddle.inverted = true
		ChaosEvents.Kind.GHOST:
			_fade_bricks(0.07)
		ChaosEvents.Kind.FAST:
			_update_ball_speeds()
		ChaosEvents.Kind.SHRINK:
			_paddle.animate_width(Paddle.SIZE.x * ChaosEvents.SHRINK_FACTOR)
		ChaosEvents.Kind.RAIN:
			var field := BreakoutConfig.FIELD
			for i in ChaosEvents.RAIN_ITEMS:
				var x := rng.randf_range(field.position.x + 80.0, field.end.x - 80.0)
				spawn_item(Vector2(x, field.position.y + 30.0 - i * 90.0), PowerUps.pick(rng))


func _chaos_end(kind: int) -> void:
	match kind:
		ChaosEvents.Kind.REVERSE:
			_paddle.inverted = false
		ChaosEvents.Kind.GHOST:
			_fade_bricks(1.0)
		ChaosEvents.Kind.FAST:
			_update_ball_speeds()
		ChaosEvents.Kind.SHRINK:
			_paddle.animate_width(Paddle.SIZE.x * (PowerUps.WIDE_FACTOR if effects.is_active(PowerUps.Kind.WIDE) else 1.0))


## Beendet alle Chaos-Ereignisse sofort (Lebensverlust, Levelwechsel).
func _chaos_reset() -> void:
	_chaos.clear()
	_paddle.inverted = false
	_fade_bricks(1.0, 0.0)
	_update_ball_speeds_if_ready()


func _update_ball_speeds_if_ready() -> void:
	if not _balls.is_empty():
		_update_ball_speeds()


func _fade_bricks(alpha: float, duration: float = 0.4) -> void:
	if _ghost_tween != null:
		_ghost_tween.kill()
	if duration <= 0.0:
		_bricks.modulate.a = alpha
		return
	_ghost_tween = create_tween()
	_ghost_tween.tween_property(_bricks, "modulate:a", alpha, duration)


# --- Zeitangriff ------------------------------------------------------------

## Wertet ein geschafftes Level aus. Gibt true zurück, wenn der letzte Level geschafft ist.
func _finish_time_attack_level() -> bool:
	var bonus := TimeAttack.bonus(_level_time, _level_bricks)
	score += bonus
	_hud.set_score(score)
	var key := "besttime_%d" % level
	var best_level: float = SaveService.get_value("highscore", key, 0.0)
	var record := TimeAttack.is_record(_level_time, best_level)
	if record:
		SaveService.set_value("highscore", key, _level_time)
	var text := tr("TA_LEVEL_FMT") % [TimeAttack.format_time(_level_time), bonus]
	if record:
		text += "  " + tr("TA_RECORD")
	_hud.show_toast_text(text, BreakoutConfig.PALETTE["warn"])
	if level < BreakoutLevels.count():
		return false
	var best_total: float = SaveService.get_value("highscore", "besttime_total", 0.0)
	var total_record := TimeAttack.is_record(_run_time, best_total)
	if total_record:
		SaveService.set_value("highscore", "besttime_total", _run_time)
	_hud.show_toast_text(tr("TA_TOTAL_FMT") % TimeAttack.format_time(_run_time) + ("  " + tr("TA_RECORD") if total_record else ""), BreakoutConfig.PALETTE["accent"])
	return true


# --- Endlos -----------------------------------------------------------------

func _build_endless() -> void:
	_rows_spawned = 0
	for row_index in EndlessRules.START_ROWS:
		_add_endless_row(row_index, EndlessRules.generate_row(rng, _rows_spawned))
		_rows_spawned += 1
	level = EndlessRules.level_for(_rows_spawned)
	_row_timer = EndlessRules.interval(_rows_spawned)


func _add_endless_row(row_index: int, row: String) -> void:
	for col_index in row.length():
		if row[col_index] != ".":
			_add_brick(row[col_index], _brick_position(col_index, row_index), row_index * 0.05 + col_index * 0.02)


## Alle Blöcke rücken eine Reihe nach unten, oben kommt eine neue Reihe dazu.
func _endless_push() -> void:
	var lowest := 0.0
	for node in _bricks.get_children():
		var brick := node as Brick
		if brick == null or brick.is_queued_for_deletion():
			continue
		var target_y := brick.position.y + BRICK_STEP.y
		lowest = maxf(lowest, target_y)
		var tween := brick.create_tween()
		tween.tween_property(brick, "position:y", target_y, ENDLESS_PUSH_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_add_endless_row(0, EndlessRules.generate_row(rng, _rows_spawned))
	_rows_spawned += 1
	var new_level := EndlessRules.level_for(_rows_spawned)
	if new_level != level:
		level = new_level
		_hud.set_level(level)
		Music.set_level(level)
	_update_ball_speeds()
	_row_timer = EndlessRules.interval(_rows_spawned)
	add_shake(4.0)
	Sfx.play(&"wall", 0.6)
	if EndlessRules.is_overrun(lowest, ENDLESS_LIMIT_Y):
		_game_over(&"MSG_OVERRUN")


## Alle zerstörbaren Blöcke sind weg: Bonus und sofort eine neue Reihe.
func _endless_cleared() -> void:
	score += EndlessRules.CLEAR_BONUS
	_hud.set_score(score)
	_hud.show_toast("ENDLESS_CLEARED", BreakoutConfig.PALETTE["warn"])
	Sfx.play(&"combo")
	_endless_push()


# --- Boss -------------------------------------------------------------------

func _build_boss() -> void:
	var field := BreakoutConfig.FIELD
	_boss = Boss.new()
	_boss.setup_boss(level, field.get_center().x, field.size.x)
	_boss.position = Vector2(field.get_center().x, BOSS_Y)
	_bricks.add_child(_boss)
	_boss.hit_taken.connect(_on_brick_hit)
	_boss.destroyed.connect(_on_brick_destroyed)
	_boss.shot_fired.connect(_on_boss_shot)
	_boss.phase_changed.connect(_on_boss_phase)
	_bricks_remaining = 1


func _on_boss_shot(pos: Vector2, speed: float) -> void:
	var shot := BossShot.new()
	shot.speed = speed
	shot.paddle = _paddle
	shot.bottom_y = BreakoutConfig.FIELD.end.y + 60.0
	shot.position = pos
	shot.add_to_group("boss_shots")
	shot.hit_paddle.connect(_on_boss_shot_hit)
	add_child(shot)
	Sfx.play(&"laser", 0.6, -6.0)


func _on_boss_shot_hit() -> void:
	if state == State.PLAYING:
		_damage_player()


func _on_boss_phase(phase: int) -> void:
	_hud.show_toast("BOSS_ANGRY" if phase < BossRules.MAX_PHASE else "BOSS_RAGE", Color(1.0, 0.25, 0.3))
	_hud.flash(Color(1.0, 0.2, 0.2), 0.2)
	add_shake(12.0)
	Sfx.play(&"multiball", 0.7)


## Jeder Treffer auf den Boss gibt Punkte und lässt manchmal ein Item fallen.
func _on_boss_hit(boss: Brick) -> void:
	var points := int(round(BossRules.HIT_SCORE * PowerUps.combo_multiplier(_streak)))
	score += points
	_hud.set_score(score)
	if PowerUps.should_drop(rng, drop_chance):
		spawn_item(boss.position + Vector2(0.0, 80.0), PowerUps.pick(rng))
