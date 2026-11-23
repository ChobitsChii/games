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
			_finish("")
		else:
			_finish("FEHLER: Nach %d Frames wurde kein Zug ausgeführt" % _frames)


func _finish(error: String) -> void:
	set_physics_process(false)
	var ok_msg := ""
	var seed_msg := ""
	if error == "" and _game and is_instance_valid(_game):
		seed_msg = "Connect Four Deluxe – Seed: %d" % _game.controller.rng.seed
		ok_msg = "Smoke-Test ok: Züge=%d, Beendet=%s" % [_game.moves_played, str(_game.is_finished)]
	var sfx := SoundEffects.get_instance()
	if sfx:
		sfx.stop_all()
	AudioService.stop_all()
	if _game and is_instance_valid(_game):
		_game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	OS.delay_msec(300)
	if error == "":
		if seed_msg != "":
			print(seed_msg)
		print(ok_msg)
		get_tree().quit(0)
	else:
		printerr(error)
		get_tree().quit(1)
