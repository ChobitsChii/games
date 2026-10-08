extends Node
## Smoke-Test für Connect Four Deluxe: Menü und automatisches Spiel prüfen.

const SMOKE_FRAMES := 300

var _frames := 0
var _game: Game


func _ready() -> void:
	# 1. Menü muss sich fehlerfrei instanziieren lassen
	var menu: Control = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	menu.queue_free()

	# 2. Spiel im Autoplay-Modus starten
	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	_game.autoplay = true
	add_child(_game)


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames >= SMOKE_FRAMES:
		if _game.moves_played > 0:
			print("Connect Four Deluxe – Seed: %d" % _game.controller.rng.seed)
			print("Smoke-Test ok: Züge=%d, Beendet=%s" % [_game.moves_played, str(_game.is_finished)])
			get_tree().quit(0)
		else:
			printerr("FEHLER: Nach %d Frames wurde kein Zug ausgeführt" % _frames)
			get_tree().quit(1)
		set_physics_process(false)
