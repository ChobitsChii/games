extends Node
## Smoke-Test: Das Spiel läuft mit automatischem Spieler eine Weile ohne Fehler.
## Dabei werden alle Power-Ups ausgelöst (als fallende Items direkt auf dem Schläger)
## und geprüft, ob sie wirken.
## Aufruf: godot --headless --fixed-fps 480 --path neon_breakout res://tests/smoke.tscn
## (--fixed-fps 480 lässt die Physik ungebremst schneller als in Echtzeit laufen)

const PHYSICS_FRAMES := 2400
const ITEM_INTERVAL := 250
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


func _ready() -> void:
	# Menü muss sich aufbauen lassen.
	var menu: Control = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	menu.queue_free()

	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	_game.autoplay = true
	add_child(_game)
	_paddle = _game.get_node("Paddle")
	_start_lives = _game.lives


func _physics_process(_delta: float) -> void:
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
	if error == "":
		print("Smoke-Test ok: Punkte=%d, Level=%d, Leben=%d, Bälle=%d" % [_game.score, _game.level, _game.lives, _game.ball_count()])
		get_tree().quit(0)
	else:
		printerr(error)
		get_tree().quit(1)
