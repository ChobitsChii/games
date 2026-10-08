extends Node
## Smoke-Test für Block Stack: Menü und Spielinstanzierung prüfen.

const SMOKE_FRAMES := 120

var _frames := 0
var _game: Node2D


func _ready() -> void:
	var menu: Control = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	menu.queue_free()

	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	_game.autoplay = true
	add_child(_game)


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames >= SMOKE_FRAMES:
		print("Smoke-Test ok: frames=%d" % _frames)
		get_tree().quit(0)
		set_physics_process(false)
