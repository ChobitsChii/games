extends Control
## Hauptmenü: Spielen, Optionen, Credits, Beenden und der gespeicherte Rekord.

@onready var _title: Label = %Title
@onready var _best_label: Label = %BestLabel
@onready var _play_button: Button = %PlayButton
@onready var _options_button: Button = %OptionsButton
@onready var _credits_button: Button = %CreditsButton
@onready var _quit_button: Button = %QuitButton

var _time := 0.0


func _ready() -> void:
	theme = BreakoutStyle.build_theme()
	_title.add_theme_font_override("font", BreakoutStyle.FONT_BOLD)
	_best_label.add_theme_color_override("font_color", BreakoutConfig.PALETTE["warn"])
	_play_button.pressed.connect(_go.bind("res://scenes/game.tscn"))
	_options_button.pressed.connect(_go.bind("res://scenes/options.tscn"))
	_credits_button.pressed.connect(_go.bind("res://scenes/credits.tscn"))
	_quit_button.pressed.connect(get_tree().quit)
	# Im Browser gibt es nichts zu beenden.
	_quit_button.visible = not OS.has_feature("web")
	LocaleService.language_changed.connect(func(_code: String) -> void: _refresh())
	Transition.fade_in(self)
	_refresh()
	_play_button.grab_focus()


func _process(delta: float) -> void:
	# Der Titel pulsiert leicht; Werte über 1 lassen ihn im Glow leuchten.
	_time += delta
	var glow := 1.25 + 0.2 * sin(_time * 1.8)
	_title.modulate = Color(glow, glow, glow, 1.0)


func _refresh() -> void:
	var best: int = SaveService.get_value("highscore", "best", 0)
	_best_label.text = tr("HUD_BEST_FMT") % best
	_best_label.visible = best > 0


func _go(scene_path: String) -> void:
	Sfx.play(&"ui_click")
	Transition.change_scene(get_tree(), scene_path)
