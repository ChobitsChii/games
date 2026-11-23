extends Node
## Smoke-Test für Lane Defenders: Das Spiel läuft mit automatischem Spieler ohne Fehler.
## Aufruf: godot --headless --fixed-fps 480 --path lane_defenders res://tests/smoke.tscn

const PHYSICS_FRAMES := 1800

var _game: Game
var _frames := 0


func _ready() -> void:
	# 1. Splash & Menü müssen sich fehlerfrei aufbauen lassen
	var splash: Control = (load("res://scenes/splash_screen.tscn") as PackedScene).instantiate()
	add_child(splash)
	splash.queue_free()
	var menu: Control = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	menu.queue_free()

	# 2. Levelauswahl muss sich fehlerfrei aufbauen lassen
	var lvl_select: Control = (load("res://scenes/level_select.tscn") as PackedScene).instantiate()
	add_child(lvl_select)
	lvl_select.queue_free()

	# 3. Spielszene mit Autopilot starten
	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	_game.autoplay = true
	add_child(_game)


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _game.model.state == GameModel.State.LOST:
		_finish("FEHLER: Autopilot hat das Spiel verloren")
	elif _frames >= PHYSICS_FRAMES:
		if _game.model.grid.get_all_units().size() > 0:
			_finish("")
		else:
			_finish("FEHLER: Nach %d Frames wurden keine Einheiten platziert" % _frames)


func _finish(error: String) -> void:
	set_physics_process(false)
	var ok_msg := ""
	if error == "" and _game and is_instance_valid(_game):
		ok_msg = "Smoke-Test ok: Level=%s, Leben=%d, Energie=%d" % [
			_game.current_level.level_id,
			_game.model.lives,
			_game.model.energy
		]
	if _game and is_instance_valid(_game):
		if _game.sfx:
			_game.sfx.stop_all()
		_game.queue_free()
	AudioService.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	OS.delay_msec(300)
	if error == "":
		print(ok_msg)
		get_tree().quit(0)
	else:
		printerr(error)
		get_tree().quit(1)
