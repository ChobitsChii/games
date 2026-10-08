extends Control
## Hauptmenü von Block Stack: Modusauswahl, Sprache, Anzeige und Beenden.

@onready var _marathon_button: Button = %MarathonButton
@onready var _sprint_button: Button = %SprintButton
@onready var _ultra_button: Button = %UltraButton
@onready var _duel_button: Button = %DuelButton
@onready var _language_button: Button = %LanguageButton
@onready var _display_button: Button = %DisplayButton
@onready var _credits_button: Button = %CreditsButton
@onready var _quit_button: Button = %QuitButton
@onready var _credits_overlay: Control = %CreditsOverlay
@onready var _close_credits_button: Button = %CloseCreditsButton


func _ready() -> void:
	theme = ThemeFactory.build(StackConfig.PALETTE)
	_marathon_button.pressed.connect(_start_mode.bind("marathon"))
	_sprint_button.pressed.connect(_start_mode.bind("sprint"))
	_ultra_button.pressed.connect(_start_mode.bind("ultra"))
	_duel_button.pressed.connect(_start_mode.bind("duel"))
	_language_button.pressed.connect(LocaleService.cycle_language)
	_display_button.pressed.connect(DisplayService.cycle_mode)
	_credits_button.pressed.connect(_toggle_credits.bind(true))
	_close_credits_button.pressed.connect(_toggle_credits.bind(false))
	_quit_button.pressed.connect(get_tree().quit)
	_quit_button.visible = not OS.has_feature("web")
	LocaleService.language_changed.connect(func(_code: String) -> void: _refresh())
	DisplayService.mode_changed.connect(func(_mode: int) -> void: _refresh())
	_refresh()
	_marathon_button.grab_focus()


func _toggle_credits(open: bool) -> void:
	_credits_overlay.visible = open
	if open:
		_close_credits_button.grab_focus()
	else:
		_credits_button.grab_focus()


func _refresh() -> void:
	_language_button.text = "%s: %s" % [tr("COMMON_LANGUAGE"), LocaleService.get_language_name()]
	_display_button.text = "%s: %s" % [tr("COMMON_DISPLAY_MODE"), tr(DisplayService.get_mode_key())]


func _start_mode(mode: String) -> void:
	# Speichert den ausgewählten Modus temporär oder übergibt ihn an die Spielszene.
	SaveService.set_value("session", "selected_mode", mode)
	get_tree().change_scene_to_file("res://scenes/game.tscn")
