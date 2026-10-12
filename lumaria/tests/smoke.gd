extends Node
## Smoke-Test für Lumaria: The Prismatic Odyssey:
## 1. Menü fehlerfrei instanziieren
## 2. Spiel mit Autopilot starten und Spieler-Interaktionen testen
## 3. Dialogsystem mit Dorfältester Morwen testen

const PHYSICS_FRAMES := 600

var _game: Game
var _frames := 0
var _dialogue_tested := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 1. Menü testen
	var menu: Control = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	menu.queue_free()

	# 2. Dungeon 1 Wurzel-Schrein testen
	var dungeon1: Node2D = (load("res://scenes/world/shrine_roots.tscn") as PackedScene).instantiate()
	add_child(dungeon1)
	dungeon1.queue_free()

	# 3. Flüsternde Untiefen & Dungeon 2 Klingen-Krypta testen
	var shallows: Node2D = (load("res://scenes/world/shallows.tscn") as PackedScene).instantiate()
	add_child(shallows)
	shallows.queue_free()

	var dungeon2: Node2D = (load("res://scenes/world/crypt_blade.tscn") as PackedScene).instantiate()
	add_child(dungeon2)
	dungeon2.queue_free()

	# 4. Spiel starten mit Autopilot
	_game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	_game.autoplay = true
	add_child(_game)


func _physics_process(_delta: float) -> void:
	_frames += 1

	# Interaktiven Dialog-Test während Autopilot einstreuen
	if _frames == 120 and _game.dialogue_box:
		_game.dialogue_box.start_dialogue("morwen")
	elif _frames == 160 and _game.dialogue_box and _game.dialogue_box.visible:
		_game.dialogue_box.advance()
	elif _frames == 200 and _game.dialogue_box and _game.dialogue_box.visible:
		_game.dialogue_box._on_choice_pressed("ready")
		_dialogue_tested = true
	elif _frames == 240 and _game.inventory_menu:
		_game.inventory_menu.open(_game.inventory)
	elif _frames == 270 and _game.inventory_menu and _game.inventory_menu.visible:
		_game.inventory_menu.close()

	if _frames >= PHYSICS_FRAMES:
		if _game.player != null and is_instance_valid(_game.player):
			if not _dialogue_tested:
				_finish("FEHLER: Dialogtest wurde nicht ausgeführt")
			else:
				_finish("")
		else:
			_finish("FEHLER: Spieler existiert nach %d Frames nicht mehr" % _frames)


func _finish(error: String) -> void:
	if error == "":
		print("Smoke-Test ok: Spieler=%s, Leben=%d/%d, Lumen=%d, DialogOk=%s" % [
			_game.player.name,
			_game.inventory.current_vitality_quarters,
			_game.inventory.max_vitality_quarters,
			_game.inventory.lumen,
			str(_dialogue_tested)
		])
		get_tree().quit(0)
	else:
		printerr(error)
		get_tree().quit(1)
	set_physics_process(false)
