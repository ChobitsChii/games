class_name Hud
extends CanvasLayer
## Anzeige: Punkte, Rekord, Level, Leben, Meldungen und Pause-Menü.
## Texte werden aus gespeicherten Werten/Schlüsseln erzeugt und bei einem
## Sprachwechsel neu gesetzt.

signal resume_pressed
signal menu_pressed

var _score := 0
var _best := 0
var _level := 1
var _lives := 3
var _title_key := ""
var _hint_key := ""

@onready var _root: Control = %Root
@onready var _score_label: Label = %ScoreLabel
@onready var _best_label: Label = %BestLabel
@onready var _level_label: Label = %LevelLabel
@onready var _lives_label: Label = %LivesLabel
@onready var _message: Control = %Message
@onready var _title_label: Label = %TitleLabel
@onready var _hint_label: Label = %HintLabel
@onready var _pause_layer: Control = %PauseLayer
@onready var _resume_button: Button = %ResumeButton
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	_root.theme = ThemeFactory.build(BreakoutConfig.PALETTE)
	_resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	_menu_button.pressed.connect(func() -> void: menu_pressed.emit())
	LocaleService.language_changed.connect(func(_code: String) -> void: _refresh())
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _pause_layer.visible and event.is_action_pressed("pause"):
		resume_pressed.emit()
		get_viewport().set_input_as_handled()


func set_score(value: int) -> void:
	_score = value
	_refresh()


func set_best(value: int) -> void:
	_best = value
	_refresh()


func set_level(value: int) -> void:
	_level = value
	_refresh()


func set_lives(value: int) -> void:
	_lives = value
	_refresh()


func show_message(title_key: String, hint_key: String) -> void:
	_title_key = title_key
	_hint_key = hint_key
	_message.visible = true
	_refresh()


func hide_message() -> void:
	_title_key = ""
	_hint_key = ""
	_message.visible = false


func show_pause(value: bool) -> void:
	_pause_layer.visible = value
	if value:
		_resume_button.grab_focus()


func _refresh() -> void:
	if not is_node_ready():
		return
	_score_label.text = tr("HUD_SCORE_FMT") % _score
	_best_label.text = tr("HUD_BEST_FMT") % _best
	_level_label.text = tr("HUD_LEVEL_FMT") % _level
	_lives_label.text = tr("HUD_LIVES_FMT") % _lives
	if _title_key != "":
		_title_label.text = tr(_title_key)
		_hint_label.text = tr(_hint_key)
