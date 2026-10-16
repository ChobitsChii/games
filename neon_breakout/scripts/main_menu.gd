extends Control
## Hauptmenü: Spielen, Sprache, Anzeigemodus, Effekte, Bildschirmwackeln, Beenden.

@onready var _title: Label = %Title
@onready var _play_button: Button = %PlayButton
@onready var _language_button: Button = %LanguageButton
@onready var _display_button: Button = %DisplayButton
@onready var _effects_button: Button = %EffectsButton
@onready var _shake_button: Button = %ShakeButton
@onready var _quit_button: Button = %QuitButton

var _time := 0.0


func _ready() -> void:
	theme = BreakoutStyle.build_theme()
	_title.add_theme_font_override("font", BreakoutStyle.FONT_BOLD)
	_play_button.pressed.connect(_on_play_pressed)
	_language_button.pressed.connect(_click.bind(LocaleService.cycle_language))
	_display_button.pressed.connect(_click.bind(DisplayService.cycle_mode))
	_effects_button.pressed.connect(_click.bind(FxSettings.cycle_quality))
	_shake_button.pressed.connect(_click.bind(FxSettings.toggle_shake))
	_quit_button.pressed.connect(get_tree().quit)
	# Im Browser gibt es nichts zu beenden.
	_quit_button.visible = not OS.has_feature("web")
	LocaleService.language_changed.connect(func(_code: String) -> void: _refresh())
	DisplayService.mode_changed.connect(func(_mode: int) -> void: _refresh())
	FxSettings.changed.connect(_refresh)
	_refresh()
	_play_button.grab_focus()


func _process(delta: float) -> void:
	# Der Titel pulsiert leicht; Werte über 1 lassen ihn im Glow leuchten.
	_time += delta
	var glow := 1.25 + 0.2 * sin(_time * 1.8)
	_title.modulate = Color(glow, glow, glow, 1.0)


func _refresh() -> void:
	_language_button.text = "%s: %s" % [tr("COMMON_LANGUAGE"), LocaleService.get_language_name()]
	_display_button.text = "%s: %s" % [tr("COMMON_DISPLAY_MODE"), tr(DisplayService.get_mode_key())]
	_effects_button.text = "%s: %s" % [tr("FX_QUALITY"), tr(FxSettings.QUALITY_KEYS[FxSettings.quality])]
	_shake_button.text = "%s: %s" % [tr("FX_SHAKE"), tr("FX_ON" if FxSettings.shake_enabled else "FX_OFF")]


func _click(action: Callable) -> void:
	Sfx.play(&"ui_click")
	action.call()


func _on_play_pressed() -> void:
	Sfx.play(&"ui_click")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
