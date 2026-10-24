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
var _pop_tweens: Dictionary = {}
var _flash_tween: Tween
var _message_tween: Tween
var _toast_tween: Tween
var _combo := 0
var _multiplier := 1.0
var _effect_entries: Array = []
var _effects_text := ""

@onready var _root: Control = %Root
@onready var _flash: ColorRect = %Flash
@onready var _score_label: Label = %ScoreLabel
@onready var _best_label: Label = %BestLabel
@onready var _level_label: Label = %LevelLabel
@onready var _lives_label: Label = %LivesLabel
@onready var _effects_label: Label = %EffectsLabel
@onready var _combo_label: Label = %ComboLabel
@onready var _toast_label: Label = %ToastLabel
@onready var _message: Control = %Message
@onready var _title_label: Label = %TitleLabel
@onready var _hint_label: Label = %HintLabel
@onready var _pause_layer: Control = %PauseLayer
@onready var _resume_button: Button = %ResumeButton
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	_root.theme = BreakoutStyle.build_theme()
	_title_label.add_theme_font_override("font", BreakoutStyle.FONT_BOLD)
	_title_label.add_theme_color_override("font_color", BreakoutConfig.PALETTE["accent"])
	_combo_label.add_theme_font_override("font", BreakoutStyle.FONT_BOLD)
	_combo_label.add_theme_color_override("font_color", BreakoutConfig.PALETTE["warn"])
	_toast_label.add_theme_font_override("font", BreakoutStyle.FONT_BOLD)
	_effects_label.add_theme_color_override("font_color", BreakoutConfig.PALETTE["text_dim"])
	_resume_button.pressed.connect(func() -> void:
		Sfx.play(&"ui_click")
		resume_pressed.emit())
	_menu_button.pressed.connect(func() -> void:
		Sfx.play(&"ui_click")
		menu_pressed.emit())
	LocaleService.language_changed.connect(func(_code: String) -> void: _refresh())
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _pause_layer.visible and event.is_action_pressed("pause"):
		resume_pressed.emit()
		get_viewport().set_input_as_handled()


func set_score(value: int) -> void:
	if value > _score:
		_pop(_score_label)
	_score = value
	_refresh()


func set_best(value: int) -> void:
	_best = value
	_refresh()


func set_level(value: int) -> void:
	_level = value
	_refresh()


func set_lives(value: int) -> void:
	if value < _lives:
		_pop(_lives_label)
	_lives = value
	_refresh()


func show_message(title_key: String, hint_key: String) -> void:
	_title_key = title_key
	_hint_key = hint_key
	_message.visible = true
	_refresh()
	if _message_tween != null:
		_message_tween.kill()
	_message.modulate.a = 0.0
	_message_tween = create_tween()
	_message_tween.tween_property(_message, "modulate:a", 1.0, 0.3)


## Combo (Blöcke seit dem letzten Schlägerkontakt) und Punkte-Multiplikator.
func set_combo(combo: int, multiplier: float) -> void:
	var grew := combo > _combo
	_combo = combo
	_multiplier = multiplier
	_refresh_combo()
	if grew and combo >= 2:
		_pop(_combo_label)


## Aktive Power-Ups als Liste von {key, value}. Nur bei Änderung wird der Text neu gesetzt.
func set_effects(entries: Array) -> void:
	_effect_entries = entries
	_refresh_effects()


## Kurze Meldung in der Spielfeldmitte (z. B. beim Einsammeln eines Power-Ups).
func show_toast(key: String, color: Color) -> void:
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_label.text = tr(key)
	_toast_label.add_theme_color_override("font_color", Color(color.r * 1.3, color.g * 1.3, color.b * 1.3, 1.0))
	_toast_label.pivot_offset = Vector2(_toast_label.size.x * 0.5, _toast_label.size.y * 0.5)
	_toast_label.modulate.a = 1.0
	_toast_label.scale = Vector2.ONE * 1.3
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.5).set_delay(0.9)


func hide_message() -> void:
	_title_key = ""
	_hint_key = ""
	_message.visible = false


func show_pause(value: bool) -> void:
	_pause_layer.visible = value
	if value:
		_resume_button.grab_focus()


## Farbiger Blitz über den ganzen Bildschirm (z. B. bei Lebensverlust).
func flash(color: Color, strength: float = 0.35) -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	_flash.color = Color(color, strength)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, 0.45)


## Kurzes Aufpoppen einer Anzeige.
func _pop(label: Label) -> void:
	if _pop_tweens.has(label) and _pop_tweens[label] != null:
		(_pop_tweens[label] as Tween).kill()
	label.pivot_offset = Vector2(label.size.x * 0.5, label.size.y * 0.5)
	label.scale = Vector2.ONE * 1.25
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop_tweens[label] = tween


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
	_refresh_combo()
	_effects_text = ""
	_refresh_effects()


func _refresh_combo() -> void:
	if not is_node_ready():
		return
	if _combo >= 2:
		_combo_label.text = tr("HUD_COMBO_FMT") % ("%.2f" % _multiplier)
	else:
		_combo_label.text = ""


func _refresh_effects() -> void:
	if not is_node_ready():
		return
	var lines := PackedStringArray()
	for entry: Dictionary in _effect_entries:
		lines.append("%s  %s" % [tr(entry["key"]), entry["value"]])
	var text := "\n".join(lines)
	if text != _effects_text:
		_effects_text = text
		_effects_label.text = text
