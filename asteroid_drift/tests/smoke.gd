extends Node
## Smoke-Test: Das Spiel läuft mit automatischem Spieler eine Weile ohne Fehler.
## Aufruf: godot --headless --fixed-fps 480 --path asteroid_drift res://tests/smoke.tscn

const PHYSICS_FRAMES := 1400

var _game: Node2D
var _frames := 0


func _ready() -> void:
	# 1. Splash Screen prüfen
	var splash: Control = (load("res://scenes/splash_screen.tscn") as PackedScene).instantiate()
	add_child(splash)
	splash.queue_free()

	# 2. Menü prüfen
	var menu: Control = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	menu.queue_free()

	# 3. Spiel mit Autopilot starten
	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	_game.autoplay = true
	add_child(_game)


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _game.state == _game.State.GAME_OVER:
		_finish("FEHLER: Autopilot hat das Spiel verloren")
	elif _frames >= PHYSICS_FRAMES:
		if _game.score > 0:
			_finish("")
		else:
			_finish("FEHLER: Nach %d Frames wurde kein Punkt erzielt" % _frames)


func _finish(error: String) -> void:
	if error == "":
		print("Smoke-Test ok: Punkte=%d, Welle=%d, Leben=%d" % [_game.score, _game.wave, _game.lives])
		get_tree().quit(0)
	else:
		printerr(error)
		get_tree().quit(1)
	set_physics_process(false)
