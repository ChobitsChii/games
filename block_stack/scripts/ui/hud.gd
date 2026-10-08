class_name Hud
extends CanvasLayer
## HUD für Block Stack: CanvasLayer für auflösungsunabhängige, zentrierte Menüs.
## Punktestand, Level, Hold, Next, Zeit, Banner, Pause-, Steuerungs- und Ergebnis-Overlay.

signal resume_pressed()
signal restart_pressed()
signal menu_pressed()
signal controls_opened()
signal controls_closed()

@onready var _root: Control = %Root
@onready var _score_label: Label = %ScoreLabel
@onready var _best_label: Label = %BestLabel
@onready var _level_label: Label = %LevelLabel
@onready var _lines_label: Label = %LinesLabel
@onready var _time_label: Label = %TimeLabel
@onready var _hold_preview: PiecePreview = %HoldPreview
@onready var _next_previews: Array[PiecePreview] = [
	%NextPreview0,
	%NextPreview1,
	%NextPreview2,
	%NextPreview3,
	%NextPreview4,
]

@onready var _left_panel: PanelContainer = %LeftPanel
@onready var _right_panel: PanelContainer = %RightPanel
@onready var _cpu_panel: PanelContainer = %CpuPanel
@onready var _cpu_score_label: Label = %CpuScoreLabel
@onready var _cpu_lines_label: Label = %CpuLinesLabel

@onready var _ingame_controls_button: Button = %InGameControlsButton

@onready var _banner: Control = %ActionBanner
@onready var _banner_main: Label = %BannerMainLabel
@onready var _banner_sub: Label = %BannerSubLabel

@onready var _pause_overlay: Control = %PauseOverlay
@onready var _resume_button: Button = %ResumeButton
@onready var _pause_controls_button: Button = %PauseControlsButton
@onready var _restart_button: Button = %RestartButton
@onready var _menu_button: Button = %MenuButton

@onready var _result_overlay: Control = %ResultOverlay
@onready var _result_title: Label = %ResultTitle
@onready var _result_hint: Label = %ResultHint
@onready var _result_retry_button: Button = %ResultRetryButton
@onready var _result_menu_button: Button = %ResultMenuButton

@onready var _controls_overlay: Control = %ControlsOverlay
@onready var _close_controls_button: Button = %CloseControlsButton

var _banner_timer: float = 0.0
var _opened_controls_from_pause: bool = false


func _ready() -> void:
	_root.theme = ThemeFactory.build(StackConfig.PALETTE)

	_resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	_restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	_menu_button.pressed.connect(func() -> void: menu_pressed.emit())
	_result_retry_button.pressed.connect(func() -> void: restart_pressed.emit())
	_result_menu_button.pressed.connect(func() -> void: menu_pressed.emit())

	_pause_controls_button.pressed.connect(_on_pause_controls_clicked)
	if _ingame_controls_button != null:
		_ingame_controls_button.pressed.connect(_on_ingame_controls_clicked)
	_close_controls_button.pressed.connect(_close_controls)

	_pause_overlay.visible = false
	_result_overlay.visible = false
	_controls_overlay.visible = false
	_banner.visible = false


func _process(delta: float) -> void:
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			_banner.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _controls_overlay.visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_close_controls()
		get_viewport().set_input_as_handled()
	elif _pause_overlay.visible and event.is_action_pressed("pause"):
		resume_pressed.emit()
		get_viewport().set_input_as_handled()


func set_layout_mode(is_duel: bool) -> void:
	if is_duel:
		_left_panel.position = Vector2(100, 100)
		_right_panel.position = Vector2(850, 100)
		_right_panel.custom_minimum_size = Vector2(220, 720)
		_right_panel.size = Vector2(220, 720)
		if _cpu_panel != null:
			_cpu_panel.visible = true
			_cpu_panel.position = Vector2(1580, 100)
	else:
		_left_panel.position = Vector2(410, 100)
		_right_panel.position = Vector2(1260, 100)
		_right_panel.custom_minimum_size = Vector2(240, 720)
		_right_panel.size = Vector2(240, 720)
		if _cpu_panel != null:
			_cpu_panel.visible = false


func set_cpu_stats(score: int, lines: int) -> void:
	if _cpu_score_label != null:
		_cpu_score_label.text = tr("HUD_SCORE_FMT") % score
	if _cpu_lines_label != null:
		_cpu_lines_label.text = tr("HUD_LINES_FMT") % lines


func set_score(val: int) -> void:
	_score_label.text = tr("HUD_SCORE_FMT") % val


func set_best(val: int) -> void:
	_best_label.text = tr("HUD_BEST_FMT") % val


func set_level(val: int) -> void:
	_level_label.text = tr("HUD_LEVEL_FMT") % val


func set_lines(val: int) -> void:
	_lines_label.text = tr("HUD_LINES_FMT") % val


func set_time(seconds: float) -> void:
	var total_sec := int(seconds)
	var mins := total_sec / 60
	var secs := total_sec % 60
	_time_label.text = tr("HUD_TIME_FMT") % ("%02d:%02d" % [mins, secs])


func set_hold(piece_type: String) -> void:
	_hold_preview.set_piece(piece_type)


func set_next(queue: Array[String]) -> void:
	for i in range(_next_previews.size()):
		if i < queue.size():
			_next_previews[i].set_piece(queue[i])
		else:
			_next_previews[i].set_piece("")


func show_action(main_key: String, sub_key: String = "") -> void:
	_banner_main.text = tr(main_key)
	_banner_sub.text = tr(sub_key) if sub_key != "" else ""
	_banner.visible = true
	_banner_timer = 2.0


func show_pause(paused: bool) -> void:
	_pause_overlay.visible = paused
	if paused:
		_controls_overlay.visible = false
		_resume_button.grab_focus()


func show_game_over(title_key: String = "MSG_GAME_OVER", hint_key: String = "MSG_GAME_OVER_HINT") -> void:
	_pause_overlay.visible = false
	_controls_overlay.visible = false
	_result_title.text = tr(title_key)
	_result_hint.text = tr(hint_key)
	_result_overlay.visible = true
	_result_retry_button.grab_focus()


func hide_result() -> void:
	_result_overlay.visible = false


func is_overlay_visible() -> bool:
	return _pause_overlay.visible or _result_overlay.visible or _controls_overlay.visible


func _on_pause_controls_clicked() -> void:
	_opened_controls_from_pause = true
	_pause_overlay.visible = false
	_controls_overlay.visible = true
	_close_controls_button.grab_focus()


func _on_ingame_controls_clicked() -> void:
	_opened_controls_from_pause = false
	controls_opened.emit()
	_controls_overlay.visible = true
	_close_controls_button.grab_focus()


func _close_controls() -> void:
	_controls_overlay.visible = false
	if _opened_controls_from_pause:
		_pause_overlay.visible = true
		_pause_controls_button.grab_focus()
	else:
		controls_closed.emit()
		if _ingame_controls_button != null and _ingame_controls_button.is_inside_tree():
			_ingame_controls_button.grab_focus()
