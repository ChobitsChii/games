extends Node
## Smoke-Test für Lane Defenders: Das Spiel läuft mit automatischem Spieler ohne Fehler.
## Aufruf: godot --headless --fixed-fps 480 --path lane_defenders res://tests/smoke.tscn

const PHYSICS_FRAMES := 1800

var _game: Game
var _frames := 0


func _ready() -> void:
	# 1. Menü muss sich fehlerfrei aufbauen lassen
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
	if error == "":
		print("Smoke-Test ok: Level=%s, Leben=%d, Energie=%d" % [
			_game.current_level.level_id,
			_game.model.lives,
			_game.model.energy
		])
		get_tree().quit(0)
	else:
		printerr(error)
		get_tree().quit(1)
	set_physics_process(false)
