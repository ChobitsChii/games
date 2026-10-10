class_name Game
extends Node2D
## Haupt-Spielszene von Connect Four Deluxe.
## Verbindet GameController, BoardView, HUD und Audio.

@export var autoplay: bool = false

@onready var board_view: BoardView = $BoardView
@onready var hud: HUD = $HUD

var controller: GameController
var sound_effects: SoundEffects

# Für den Smoke-Test
var moves_played: int = 0
var is_finished: bool = false


func _ready() -> void:
	sound_effects = SoundEffects.new()
	add_child(sound_effects)

	controller = GameController.new()
	if autoplay:
		controller.is_autoplay = true

	board_view.setup(controller)
	hud.setup(controller)

	board_view.column_clicked.connect(_on_column_clicked)
	hud.restart_pressed.connect(_on_restart_pressed)
	hud.menu_pressed.connect(_on_menu_pressed)
	controller.move_completed.connect(_on_move_completed)
	controller.game_ended.connect(_on_game_ended)

	# Modus und Einstellungen aus SaveService laden
	var mode := GameController.GameMode.AI
	var diff := ConnectFourAI.Difficulty.MEDIUM
	var starter := GameController.Starter.PLAYER_1
	var save_service: Node = Engine.get_main_loop().root.get_node_or_null("SaveService") if Engine.get_main_loop() != null else null
	if save_service != null:
		mode = save_service.get_value("session", "mode", GameController.GameMode.AI)
		diff = save_service.get_value("connect_four", "difficulty", ConnectFourAI.Difficulty.MEDIUM)
		starter = save_service.get_value("connect_four", "starter", GameController.Starter.PLAYER_1)

	controller.start_game(mode, diff, starter)


func _input(event: InputEvent) -> void:
	if autoplay or controller == null:
		return

	# Menü-Fokus Navigation: Pfeiltaste nach oben springt ins Menü, Pfeiltaste nach unten zurück aufs Brett
	if event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_UP):
		if hud != null and not hud.is_top_bar_focused():
			hud.focus_top_bar()
			get_viewport().set_input_as_handled()
			return
	elif event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_DOWN):
		if hud != null and hud.is_top_bar_focused():
			hud.release_menu_focus()
			get_viewport().set_input_as_handled()
			return

	# Wenn die TopBar fokussiert ist, navigieren Links/Rechts/Enter durch die Buttons
	if hud != null and hud.is_top_bar_focused():
		return

	# Spielsteinbewegung auf dem Brett:
	if event.is_action_pressed("move_left"):
		controller.move_column_left()
		if sound_effects != null:
			sound_effects.play_hover()
		board_view.queue_redraw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		controller.move_column_right()
		if sound_effects != null:
			sound_effects.play_hover()
		board_view.queue_redraw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("drop"):
		controller.request_drop()
		get_viewport().set_input_as_handled()


func _on_column_clicked(col: int) -> void:
	if controller != null:
		controller.request_drop(col)


func _on_move_completed(_col: int, _row: int, _player: int) -> void:
	moves_played += 1


func _on_game_ended(_winner: int, _winning: Array[Vector2i]) -> void:
	is_finished = true


func _on_restart_pressed() -> void:
	moves_played = 0
	is_finished = false
	board_view.reset_view()
	controller.start_game(controller.mode, controller.difficulty, controller.starter)


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
