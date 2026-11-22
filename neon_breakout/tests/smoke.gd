extends Node
## Smoke-Test: Das Spiel läuft mit automatischem Spieler eine Weile ohne Fehler.
## Dabei werden alle Power-Ups ausgelöst (als fallende Items direkt auf dem Schläger)
## und geprüft, ob sie wirken.
## Aufruf: godot --headless --fixed-fps 480 --path neon_breakout res://tests/smoke.tscn
## (--fixed-fps 480 lässt die Physik ungebremst schneller als in Echtzeit laufen)

const PHYSICS_FRAMES := 2400
const ITEM_INTERVAL := 250
## Danach läuft jeder Spielmodus kurz mit dem Autopiloten (Spielzeit wird per Kniff verkürzt).
const MODE_FRAMES := 1500
const MODES: Array = [
	GameMode.Id.TIME_ATTACK, GameMode.Id.ENDLESS, GameMode.Id.CHAOS,
	GameMode.Id.BOSS, GameMode.Id.ZEN, GameMode.Id.DEMO,
]
const KINDS: Array = [
	PowerUps.Kind.WIDE, PowerUps.Kind.MULTI, PowerUps.Kind.LASER,
	PowerUps.Kind.SLOW, PowerUps.Kind.STICKY, PowerUps.Kind.LIFE, PowerUps.Kind.MULTI,
]

var _game: Node2D
var _paddle: Paddle
var _frames := 0
var _next_kind := 0
var _start_lives := 0
var _saw := {"wide": false, "multi": false, "laser": false, "slow": false, "sticky": false, "life": false}
var _laser_min := 99.0
var _mode_index := -1
var _mode_frames := 0
var _saw_chaos := false
var _saw_shot := false
var _items_spawned := 0
var _snipe_phase := false
var _snipe_frames := 0


func _ready() -> void:
	# Menü muss sich aufbauen lassen.
	var menu: Control = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	menu.queue_free()
	for path in ["res://scenes/mode_select.tscn", "res://scenes/options.tscn", "res://scenes/credits.tscn"]:
		var screen: Control = (load(path) as PackedScene).instantiate()
		add_child(screen)
		screen.queue_free()

	GameMode.selected = GameMode.Id.CLASSIC
	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	_game.autoplay = true
	add_child(_game)
	_paddle = _game.get_node("Paddle")
	_start_lives = _game.lives


func _physics_process(_delta: float) -> void:
	if _snipe_phase:
		_snipe_step()
		return
	if _mode_index >= 0:
		_mode_step()
		return
	_frames += 1
	if _frames % ITEM_INTERVAL == 0 and _next_kind < KINDS.size() and _game.state == _game.State.PLAYING:
		_game.spawn_item(_paddle.global_position + Vector2(0.0, -10.0), KINDS[_next_kind])
		_next_kind += 1
	_observe()
	if _game.state == _game.State.GAME_OVER:
		_finish("FEHLER: Autopilot hat das Spiel verloren")
	elif _frames >= PHYSICS_FRAMES:
		_finish(_verdict())


## Merkt sich, welche Power-Ups beobachtet wurden.
func _observe() -> void:
	if _paddle.width > Paddle.SIZE.x * 1.2:
		_saw["wide"] = true
	if _game.ball_count() >= 3:
		_saw["multi"] = true
	if _game.effects.is_active(PowerUps.Kind.LASER):
		_laser_min = minf(_laser_min, _game.effects.remaining(PowerUps.Kind.LASER))
		if _laser_min < PowerUps.AMOUNTS[PowerUps.Kind.LASER]:
			_saw["laser"] = true
	if _game.effects.is_active(PowerUps.Kind.SLOW):
		_saw["slow"] = true
	if _game.effects.is_active(PowerUps.Kind.STICKY) and _game.any_ball_stuck() and _game.state == _game.State.PLAYING:
		_saw["sticky"] = true
	if _game.lives > _start_lives:
		_saw["life"] = true


func _verdict() -> String:
	if _game.score <= 0:
		return "FEHLER: Nach %d Frames wurde kein Punkt erzielt" % _frames
	for key: String in _saw:
		if not _saw[key]:
			return "FEHLER: Power-Up '%s' wurde nicht beobachtet" % key
	return ""


func _finish(error: String) -> void:
	set_physics_process(false)
	# Klänge stoppen und der Audio-Engine kurz Zeit geben, damit beim Beenden nichts übrig bleibt.
	Sfx.stop_all()
	await get_tree().process_frame
	OS.delay_msec(300)
	if error == "" and _mode_index < 0:
		print("Smoke-Test ok: Punkte=%d, Level=%d, Leben=%d, Bälle=%d" % [_game.score, _game.level, _game.lives, _game.ball_count()])
		_start_mode(0)
	elif error == "" and not _snipe_phase:
		print("Modus-Test ok: %s, Punkte=%d" % [GameMode.NAME_KEYS[MODES[_mode_index]], _game.score])
		if _mode_index + 1 < MODES.size():
			_start_mode(_mode_index + 1)
		else:
			_start_snipe_test()
	elif error == "":
		print("Demo-Zieltest ok: letzter Eckblock in %d Frames getroffen" % _snipe_frames)
		get_tree().quit(0)
	else:
		printerr(error)
		get_tree().quit(1)


## Startet den Spielmodus Nr. `index` aus MODES in einem frischen Spiel.
func _start_mode(index: int) -> void:
	_mode_index = index
	_mode_frames = 0
	_saw_chaos = false
	_saw_shot = false
	_items_spawned = 0
	_game.queue_free()
	await get_tree().process_frame
	GameMode.selected = MODES[index]
	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	_game.autoplay = true
	add_child(_game)
	_paddle = _game.get_node("Paddle")
	# Kniff: Zeitgesteuerte Ereignisse kommen gleich, damit der Test kurz bleibt.
	_game._chaos._timer = 0.2
	_game._row_timer = 0.5
	set_physics_process(true)


func _mode_step() -> void:
	_mode_frames += 1
	var mode: int = MODES[_mode_index]
	if _game.get_tree().get_nodes_in_group("boss_shots").size() > 0:
		_saw_shot = true
	if not _game._chaos.active_kinds().is_empty():
		_saw_chaos = true
	if mode == GameMode.Id.BOSS and is_instance_valid(_game._boss):
		_game._boss._attack_timer = minf(_game._boss._attack_timer, 0.05 if _mode_frames == 300 else 99.0)
	# Demo: Von oben fallen Power-Ups an wechselnden Stellen, der Autopilot soll die meisten fangen.
	if mode == GameMode.Id.DEMO and _mode_frames % 200 == 0 and _mode_frames <= 1200 and _game.state == _game.State.PLAYING:
		var field := BreakoutConfig.FIELD
		var x := field.position.x + field.size.x * (0.15 + 0.7 * fmod(_mode_frames / 200.0 * 0.37, 1.0))
		_game.spawn_item(Vector2(x, field.position.y + 200.0), PowerUps.Kind.SLOW)
		_items_spawned += 1
	if _mode_frames < MODE_FRAMES:
		return
	var error := ""
	if _game.score <= 0:
		error = "FEHLER: Modus %s: kein Punkt erzielt" % GameMode.NAME_KEYS[mode]
	match mode:
		GameMode.Id.CHAOS:
			if not _saw_chaos:
				error = "FEHLER: Chaos-Modus: kein Ereignis beobachtet"
		GameMode.Id.ENDLESS:
			if _game._rows_spawned <= EndlessRules.START_ROWS:
				error = "FEHLER: Endlos-Modus: es kamen keine neuen Reihen"
		GameMode.Id.BOSS:
			if not is_instance_valid(_game._boss) and _game.state != _game.State.LEVEL_CLEAR:
				error = "FEHLER: Boss-Modus: Boss fehlt"
			elif not _saw_shot:
				error = "FEHLER: Boss-Modus: Boss hat nie geschossen"
		GameMode.Id.DEMO:
			if _game._coach.times_shown("TIP_START") < 1:
				error = "FEHLER: Demo-Modus: kein Tipp angezeigt"
			elif _items_spawned >= 3 and _game.items_collected < _items_spawned - 1:
				error = "FEHLER: Demo-Modus: nur %d von %d Power-Ups eingesammelt" % [_game.items_collected, _items_spawned]
		GameMode.Id.ZEN:
			if _game.lives != _game.START_LIVES:
				error = "FEHLER: Zen-Modus: Leben haben sich verändert"
	_finish(error)


## Prüft, dass der Demo-Autopilot einen einzelnen letzten Eckblock zügig gezielt abräumt.
func _start_snipe_test() -> void:
	_snipe_phase = true
	_snipe_frames = 0
	_game.queue_free()
	await get_tree().process_frame
	GameMode.selected = GameMode.Id.DEMO
	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	add_child(_game)
	# Alle Blöcke bis auf den einzelnen Eckblock links oben entfernen.
	var bricks_node: Node2D = _game.get_node("Bricks")
	var kept: Brick = null
	for child in bricks_node.get_children():
		var brick := child as Brick
		if brick == null:
			continue
		if kept == null:
			kept = brick
		else:
			bricks_node.remove_child(brick)
			brick.queue_free()
	_game._bricks_remaining = 1
	_game._reset_demo_plan()
	# Ball von rechts oben schräg nach rechts unten fallen lassen, damit der Autopilot gezielt zurückschießen muss.
	var ball: Ball = _game._balls[0]
	ball.global_position = Vector2(1280.0, 520.0)
	ball.launch(Vector2(0.25, 1.0))
	_game._set_state(_game.State.PLAYING)
	set_physics_process(true)


func _snipe_step() -> void:
	_snipe_frames += 1
	if _game.state == _game.State.LEVEL_CLEAR:
		_finish("")
		return
	if _game.state == _game.State.GAME_OVER:
		_finish("FEHLER: Demo-Zieltest hat verloren")
		return
	if _snipe_frames >= 600:
		_finish("FEHLER: Demo-Zieltest hat den letzten Eckblock nicht innerhalb von 600 Frames getroffen")
