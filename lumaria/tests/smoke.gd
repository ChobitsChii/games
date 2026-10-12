extends Node
## Smoke-Test für Lumaria: The Prismatic Odyssey:
## 1. Menü fehlerfrei instanziieren
## 2. Spiel mit Autopilot starten und Spieler-Interaktionen testen

const PHYSICS_FRAMES := 600

var _game: Game
var _frames := 0


func _ready() -> void:
	# 1. Menü testen
	var menu: Control = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	menu.queue_free()

	# 2. Spiel starten mit Autopilot
	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	_game.autoplay = true
	add_child(_game)


func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames >= PHYSICS_FRAMES:
		if _game.player != null and is_instance_valid(_game.player):
			_finish("")
		else:
			_finish("FEHLER: Spieler existiert nach %d Frames nicht mehr" % _frames)


func _finish(error: String) -> void:
	if error == "":
		print("Smoke-Test ok: Spieler=%s, Leben=%d/%d, Lumen=%d" % [
			_game.player.name,
			_game.inventory.current_vitality_quarters,
			_game.inventory.max_vitality_quarters,
			_game.inventory.lumen
		])
		get_tree().quit(0)
	else:
		printerr(error)
		get_tree().quit(1)
	set_physics_process(false)
