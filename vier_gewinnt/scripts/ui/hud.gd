class_name HUD
extends CanvasLayer
## Steuert die Benutzeroberfläche im laufenden Spiel (Status, Aktionen, Pausemenü).

signal restart_pressed()
signal menu_pressed()
signal undo_pressed()
signal hint_pressed()

@onready var status_label: Label = %StatusLabel
@onready var turn_indicator: Control = %TurnIndicator
@onready var hint_label: Label = %HintLabel
@onready var btn_hint: Button = %BtnHint
@onready var btn_undo: Button = %BtnUndo
@onready var btn_restart: Button = %BtnRestart
@onready var btn_pause: Button = %BtnPause
@onready var pause_modal: PanelContainer = %PauseModal
@onready var btn_resume: Button = %BtnResume
@onready var btn_modal_restart: Button = %BtnModalRestart
@onready var btn_modal_menu: Button = %BtnModalMenu
@onready var btn_fullscreen: Button = %BtnFullscreen

var controller: GameController


func _ready() -> void:
	if turn_indicator != null:
		turn_indicator.hud = self
	pause_modal.visible = false
	hint_label.visible = false

	btn_hint.pressed.connect(_on_hint_pressed)
	btn_undo.pressed.connect(_on_undo_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_pause.pressed.connect(_on_pause_pressed)

	btn_resume.pressed.connect(_on_resume_pressed)
	btn_modal_restart.pressed.connect(_on_modal_restart_pressed)
	btn_modal_menu.pressed.connect(_on_modal_menu_pressed)
	btn_fullscreen.pressed.connect(_on_fullscreen_pressed)


func setup(p_controller: GameController) -> void:
	controller = p_controller
	controller.state_changed.connect(_on_state_changed)
	controller.game_ended.connect(_on_game_ended)
	controller.hint_ready.connect(_on_hint_ready)
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
	elif event.is_action_pressed("undo"):
		_on_undo_pressed()
	elif event.is_action_pressed("hint"):
		_on_hint_pressed()
	elif event.is_action_pressed("restart"):
		_on_restart_pressed()
	elif event.is_action_pressed("toggle_fullscreen"):
		_on_fullscreen_pressed()


func _on_state_changed(_new_state: GameController.State) -> void:
	_update_ui()


func _update_ui() -> void:
	if controller == null:
		return

	btn_undo.disabled = (controller.board.moves == 0 or controller.state == GameController.State.DROPPING or controller.state == GameController.State.AI_THINKING)
	btn_hint.disabled = (controller.state != GameController.State.PLAYER_TURN)

	if controller.state == GameController.State.GAME_OVER:
		return

	if controller.mode == GameController.GameMode.AI:
		if controller.state == GameController.State.AI_THINKING:
			status_label.text = "GAME_TURN_CPU"
		else:
			status_label.text = "GAME_TURN_PLAYER1" if controller.human_player == Board.CELL_PLAYER_1 else "GAME_TURN_PLAYER2"
	else:
		if controller.board.current_player() == Board.CELL_PLAYER_1:
			status_label.text = "GAME_TURN_PLAYER1"
		else:
			status_label.text = "GAME_TURN_PLAYER2"

	turn_indicator.queue_redraw()


func _on_game_ended(winner: int, _winning: Array[Vector2i]) -> void:
	btn_hint.disabled = true
	btn_undo.disabled = true
	hint_label.visible = false

	if winner == Board.CELL_EMPTY:
		status_label.text = "GAME_DRAW"
	elif controller.mode == GameController.GameMode.AI:
		if winner == controller.human_player:
			status_label.text = "GAME_WIN_PLAYER1"
		else:
			status_label.text = "GAME_WIN_CPU"
	else:
		if winner == Board.CELL_PLAYER_1:
			status_label.text = "GAME_WIN_PLAYER1"
		else:
			status_label.text = "GAME_WIN_PLAYER2"

	turn_indicator.queue_redraw()


func _on_hint_ready(col: int) -> void:
	var sfx := SoundEffects.get_instance()
	if sfx != null:
		sfx.play_hint()
	hint_label.text = tr("GAME_HINT_COL") % (col + 1)
	hint_label.visible = true


func _on_hint_pressed() -> void:
	if controller != null:
		controller.request_hint()


func _on_undo_pressed() -> void:
	hint_label.visible = false
	if controller != null and controller.request_undo():
		var sfx := SoundEffects.get_instance()
		if sfx != null:
			sfx.play_undo()
		_update_ui()


func _on_restart_pressed() -> void:
	hint_label.visible = false
	pause_modal.visible = false
	restart_pressed.emit()


func _on_pause_pressed() -> void:
	_toggle_pause()


func _toggle_pause() -> void:
	pause_modal.visible = not pause_modal.visible
	var sfx := SoundEffects.get_instance()
	if sfx != null:
		sfx.play_button()


func _on_resume_pressed() -> void:
	pause_modal.visible = false
	var sfx := SoundEffects.get_instance()
	if sfx != null:
		sfx.play_button()


func _on_modal_restart_pressed() -> void:
	pause_modal.visible = false
	restart_pressed.emit()


func _on_modal_menu_pressed() -> void:
	pause_modal.visible = false
	menu_pressed.emit()


func _on_fullscreen_pressed() -> void:
	var display_service := _get_display_service()
	if display_service != null and display_service.has_method("toggle_fullscreen"):
		display_service.toggle_fullscreen()


func _get_display_service() -> Node:
	if Engine.get_main_loop() != null:
		var root := (Engine.get_main_loop() as SceneTree).root
		if root != null and root.has_node("DisplayService"):
			return root.get_node("DisplayService")
	return null
