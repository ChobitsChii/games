extends Control
## Hauptmenü: Spielen, Sprache, Anzeigemodus, Beenden.

@onready var _play_button: Button = %PlayButton
@onready var _language_button: Button = %LanguageButton
@onready var _display_button: Button = %DisplayButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	theme = ThemeFactory.build(BreakoutConfig.PALETTE)
	_play_button.pressed.connect(_on_play_pressed)
	_language_button.pressed.connect(LocaleService.cycle_language)
	_display_button.pressed.connect(DisplayService.cycle_mode)
	_quit_button.pressed.connect(get_tree().quit)
	# Im Browser gibt es nichts zu beenden.
	_quit_button.visible = not OS.has_feature("web")
	LocaleService.language_changed.connect(func(_code: String) -> void: _refresh())
	DisplayService.mode_changed.connect(func(_mode: int) -> void: _refresh())
	_refresh()
	_play_button.grab_focus()


func _refresh() -> void:
	_language_button.text = "%s: %s" % [tr("COMMON_LANGUAGE"), LocaleService.get_language_name()]
	_display_button.text = "%s: %s" % [tr("COMMON_DISPLAY_MODE"), tr(DisplayService.get_mode_key())]


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
