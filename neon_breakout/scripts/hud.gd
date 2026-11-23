class_name Hud
extends CanvasLayer
## Anzeige: Punkte, Rekord, Level, Leben, Meldungen und Pause-Menü.
## Texte werden aus gespeicherten Werten/Schlüsseln erzeugt und bei einem
## Sprachwechsel neu gesetzt.

const TIP_SECONDS := 6.0

signal pause_pressed
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
var _info_label: Label
var _tip_label: Label
var _tip_key := ""
var _tip_tween: Tween
var _pause_button: Button

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
	_build_mode_labels()
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


## Modus-Anzeige rechts unter der Combo (z. B. Zeit, Reihen, Boss) – schon fertig formatierter Text.
func set_info(text: String) -> void:
	if _info_label != null and _info_label.text != text:
		_info_label.text = text


## Tipp links am Rand (Demo-Modus). Bleibt einige Sekunden stehen und blendet dann aus.
func show_tip(key: String) -> void:
	_tip_key = key
	_tip_label.text = tr(key)
	if _tip_tween != null:
		_tip_tween.kill()
	_tip_label.modulate.a = 0.0
	_tip_tween = create_tween()
	_tip_tween.tween_property(_tip_label, "modulate:a", 1.0, 0.3)
	_tip_tween.tween_property(_tip_label, "modulate:a", 0.0, 0.6).set_delay(TIP_SECONDS)


func set_lives_visible(value: bool) -> void:
	_lives_label.visible = value


func set_best_visible(value: bool) -> void:
	_best_label.visible = value


## Aktive Power-Ups als Liste von {key, value}. Nur bei Änderung wird der Text neu gesetzt.
func set_effects(entries: Array) -> void:
	_effect_entries = entries
	_refresh_effects()


## Kurze Meldung in der Spielfeldmitte (z. B. beim Einsammeln eines Power-Ups).
func show_toast(key: String, color: Color) -> void:
	show_toast_text(tr(key), color)


## Wie `show_toast`, aber mit fertig formatiertem Text (z. B. Zeiten).
func show_toast_text(text: String, color: Color) -> void:
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_label.text = text
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
	if _pause_button != null:
		_pause_button.visible = not value
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
	if _tip_key != "":
		_tip_label.text = tr(_tip_key)
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


func _build_mode_labels() -> void:
	_info_label = Label.new()
	_info_label.position = Vector2(1580.0, 250.0)
	_info_label.size = Vector2(310.0, 200.0)
	_info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.add_theme_font_size_override("font_size", 34)
	_info_label.add_theme_color_override("font_color", BreakoutConfig.PALETTE["text"])
	_root.add_child(_info_label)
	_tip_label = Label.new()
	_tip_label.position = Vector2(30.0, 520.0)
	_tip_label.size = Vector2(310.0, 480.0)
	_tip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.add_theme_font_size_override("font_size", 32)
	_tip_label.add_theme_color_override("font_color", BreakoutConfig.PALETTE["accent"])
	_tip_label.modulate.a = 0.0
	_root.add_child(_tip_label)
	_pause_button = Button.new()
	_pause_button.text = "COMMON_PAUSED"
	_pause_button.position = Vector2(1610.0, 960.0)
	_pause_button.size = Vector2(250.0, 64.0)
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.pressed.connect(func() -> void:
		Sfx.play(&"ui_click")
		pause_pressed.emit())
	_root.add_child(_pause_button)
