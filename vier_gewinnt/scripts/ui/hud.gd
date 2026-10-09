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
@onready var pause_modal: Control = %PauseModal
@onready var btn_resume: Button = %BtnResume
@onready var btn_modal_restart: Button = %BtnModalRestart
@onready var btn_modal_menu: Button = %BtnModalMenu
@onready var btn_fullscreen: Button = %BtnFullscreen

var controller: GameController
var _hint_hide_timer: float = 0.0


func _ready() -> void:
	$RootControl.theme = _build_hud_theme()

	if turn_indicator != null:
		turn_indicator.hud = self
	pause_modal.visible = false
	hint_label.visible = false

	var ds := _get_display_service()
	if ds != null and ds.has_signal("mode_changed"):
		ds.mode_changed.connect(func(_m: int) -> void: _update_fullscreen_button_text())
	_update_fullscreen_button_text()

	btn_hint.pressed.connect(_on_hint_pressed)
	btn_undo.pressed.connect(_on_undo_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_pause.pressed.connect(_on_pause_pressed)

	btn_resume.pressed.connect(_on_resume_pressed)
	btn_modal_restart.pressed.connect(_on_modal_restart_pressed)
	btn_modal_menu.pressed.connect(_on_modal_menu_pressed)
	btn_fullscreen.pressed.connect(_on_fullscreen_pressed)


func _process(delta: float) -> void:
	if _hint_hide_timer > 0.0:
		_hint_hide_timer -= delta
		if _hint_hide_timer <= 0.0:
			_hide_hint()


func setup(p_controller: GameController) -> void:
	controller = p_controller
	controller.state_changed.connect(_on_state_changed)
	controller.game_ended.connect(_on_game_ended)
	controller.hint_ready.connect(_on_hint_ready)
	controller.disc_dropped.connect(_on_disc_dropped)
	controller.undo_performed.connect(_on_undo_performed)
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


func _on_state_changed(new_state: GameController.State) -> void:
	if new_state != GameController.State.PLAYER_TURN:
		_hide_hint()
	_update_ui()


func _update_ui() -> void:
	if controller == null or btn_undo == null:
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


func _on_disc_dropped(_col: int, _row: int, _player: int) -> void:
	_hide_hint()


func _on_game_ended(winner: int, _winning: Array[Vector2i]) -> void:
	btn_hint.disabled = true
	btn_undo.disabled = true
	_hide_hint()

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
	_hint_hide_timer = 4.0


func _hide_hint() -> void:
	_hint_hide_timer = 0.0
	if hint_label != null:
		hint_label.visible = false


func _on_hint_pressed() -> void:
	if controller != null:
		controller.request_hint()


func _on_undo_pressed() -> void:
	if controller != null and controller.request_undo():
		var sfx := SoundEffects.get_instance()
		if sfx != null:
			sfx.play_undo()


func _on_undo_performed() -> void:
	_hide_hint()
	_update_ui()


func _on_restart_pressed() -> void:
	_hide_hint()
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
	var ds := _get_display_service()
	if ds != null and ds.has_method("toggle"):
		ds.toggle()
	_update_fullscreen_button_text()


func _update_fullscreen_button_text() -> void:
	var ds := _get_display_service()
	if ds != null and "mode" in ds and ds.mode != 0:
		btn_fullscreen.text = "DISPLAY_WINDOWED"
	else:
		btn_fullscreen.text = "DISPLAY_FULLSCREEN"


func _build_hud_theme() -> Theme:
	var hud_theme := Theme.new()
	hud_theme.default_font_size = 20

	var accent: Color = GameConfig.PALETTE["board_rim"]
	var accent_alt: Color = GameConfig.PALETTE["win_gold"]
	var panel_col: Color = GameConfig.PALETTE["panel"]
	var text_col: Color = GameConfig.PALETTE["text"]
	var text_dim: Color = GameConfig.PALETTE["text_dim"]

	var normal := _create_box(Color(panel_col.r, panel_col.g, panel_col.b, 0.9), Color(accent.r, accent.g, accent.b, 0.45), 2, 12, Color(0, 0, 0, 0.35), 6)
	var hover := _create_box(Color(accent.r, accent.g, accent.b, 0.3), accent, 2, 12, Color(accent.r, accent.g, accent.b, 0.6), 14)
	var pressed := _create_box(Color(accent.r, accent.g, accent.b, 0.5), accent_alt, 2, 12, Color(accent_alt.r, accent_alt.g, accent_alt.b, 0.6), 10)
	var disabled := _create_box(Color(panel_col.r, panel_col.g, panel_col.b, 0.45), Color(text_dim.r, text_dim.g, text_dim.b, 0.2), 1, 12)
	var focus := _create_box(Color(0, 0, 0, 0), accent_alt, 2, 12)
	focus.draw_center = false

	hud_theme.set_stylebox("normal", "Button", normal)
	hud_theme.set_stylebox("hover", "Button", hover)
	hud_theme.set_stylebox("pressed", "Button", pressed)
	hud_theme.set_stylebox("disabled", "Button", disabled)
	hud_theme.set_stylebox("focus", "Button", focus)
	hud_theme.set_color("font_color", "Button", text_col)
	hud_theme.set_color("font_hover_color", "Button", Color.WHITE)
	hud_theme.set_color("font_pressed_color", "Button", Color.WHITE)
	hud_theme.set_color("font_disabled_color", "Button", text_dim)

	var modal_panel := _create_box(Color(0.06, 0.08, 0.15, 0.97), Color(accent.r, accent.g, accent.b, 0.75), 2, 20, Color(0, 0, 0, 0.75), 28)
	hud_theme.set_stylebox("panel", "PanelContainer", modal_panel)
	return hud_theme


func _create_box(bg: Color, border: Color, border_w: int = 2, radius: int = 12, shadow: Color = Color(0, 0, 0, 0), shadow_sz: int = 0) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(border_w)
	b.set_corner_radius_all(radius)
	b.shadow_color = shadow
	b.shadow_size = shadow_sz
	b.content_margin_left = 18
	b.content_margin_right = 18
	b.content_margin_top = 8
	b.content_margin_bottom = 8
	return b


func _get_display_service() -> Node:
	if Engine.get_main_loop() != null and Engine.get_main_loop() is SceneTree:
		var root := (Engine.get_main_loop() as SceneTree).root
		if root != null and root.has_node("DisplayService"):
			return root.get_node("DisplayService")
	return null
