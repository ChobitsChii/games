extends Node
## Smoke-Test für Block Stack: Menü und automatisches Spiel prüfen.

const SMOKE_FRAMES := 600

var _frames := 0
var _game: Node2D


func _ready() -> void:
	var splash: Control = (load("res://scenes/splash_screen.tscn") as PackedScene).instantiate()
	add_child(splash)
	splash.queue_free()
	var menu: Control = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	menu.queue_free()

	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	_game.autoplay = true
	add_child(_game)


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames >= SMOKE_FRAMES:
		if _game.logic.score > 0:
			_finish("")
		else:
			_finish("FEHLER: Nach %d Frames wurde kein Punkt erzielt" % _frames)


func _finish(error: String) -> void:
	set_physics_process(false)
	var ok_msg := ""
	if error == "" and _game and is_instance_valid(_game):
		ok_msg = "Smoke-Test ok: Punkte=%d, Zeilen=%d, Level=%d" % [_game.logic.score, _game.logic.lines, _game.logic.level]
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
		print(ok_msg)
		get_tree().quit(0)
	else:
		printerr(error)
		get_tree().quit(1)
