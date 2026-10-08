class_name Hud
extends Control
## HUD für Block Stack: Punktestand, Level, Hold, Next, Zeit, Banner und Pause-Menü.

signal resume_pressed()
signal restart_pressed()
signal menu_pressed()

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

@onready var _banner: Control = %ActionBanner
@onready var _banner_main: Label = %BannerMainLabel
@onready var _banner_sub: Label = %BannerSubLabel

@onready var _pause_overlay: Control = %PauseOverlay
@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _menu_button: Button = %MenuButton

@onready var _result_overlay: Control = %ResultOverlay
@onready var _result_title: Label = %ResultTitle
@onready var _result_hint: Label = %ResultHint
@onready var _result_retry_button: Button = %ResultRetryButton
@onready var _result_menu_button: Button = %ResultMenuButton

var _banner_timer: float = 0.0


func _ready() -> void:
	_resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	_restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	_menu_button.pressed.connect(func() -> void: menu_pressed.emit())
	_result_retry_button.pressed.connect(func() -> void: restart_pressed.emit())
	_result_menu_button.pressed.connect(func() -> void: menu_pressed.emit())
	_pause_overlay.visible = false
	_result_overlay.visible = false
	_banner.visible = false


func _process(delta: float) -> void:
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			_banner.visible = false


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
		_resume_button.grab_focus()


func show_game_over(title_key: String = "MSG_GAME_OVER", hint_key: String = "MSG_GAME_OVER_HINT") -> void:
	_result_title.text = tr(title_key)
	_result_hint.text = tr(hint_key)
	_result_overlay.visible = true
	_result_retry_button.grab_focus()


func hide_result() -> void:
	_result_overlay.visible = false
