extends Control
## Hauptmenü von Block Stack: Modusauswahl, Sprache, Anzeige und Beenden.

@onready var _marathon_button: Button = %MarathonButton
@onready var _sprint_button: Button = %SprintButton
@onready var _ultra_button: Button = %UltraButton
@onready var _duel_button: Button = %DuelButton
@onready var _language_button: Button = %LanguageButton
@onready var _display_button: Button = %DisplayButton
@onready var _options_button: Button = %OptionsButton
@onready var _controls_button: Button = %ControlsButton
@onready var _credits_button: Button = %CreditsButton
@onready var _quit_button: Button = %QuitButton
@onready var _controls_overlay: Control = %ControlsOverlay
@onready var _close_controls_button: Button = %CloseControlsButton
@onready var _credits_overlay: Control = %CreditsOverlay
@onready var _close_credits_button: Button = %CloseCreditsButton
@onready var _options_overlay: Control = %OptionsOverlay
@onready var _close_options_button: Button = %CloseOptionsButton
@onready var _das_button: Button = %DasButton
@onready var _arr_button: Button = %ArrButton
@onready var _colorblind_button: Button = %ColorblindButton
@onready var _music_button: Button = %MusicButton
@onready var _sfx_button: Button = %SfxButton


func _ready() -> void:
	theme = ThemeFactory.build(StackConfig.PALETTE)
	_marathon_button.pressed.connect(_start_mode.bind("marathon"))
	_sprint_button.pressed.connect(_start_mode.bind("sprint"))
	_ultra_button.pressed.connect(_start_mode.bind("ultra"))
	_duel_button.pressed.connect(_start_mode.bind("duel"))
	_language_button.pressed.connect(LocaleService.cycle_language)
	_display_button.pressed.connect(DisplayService.cycle_mode)
	_options_button.pressed.connect(_toggle_options.bind(true))
	_close_options_button.pressed.connect(_toggle_options.bind(false))
	_das_button.pressed.connect(_on_das_pressed)
	_arr_button.pressed.connect(_on_arr_pressed)
	_colorblind_button.pressed.connect(_on_colorblind_pressed)
	_music_button.pressed.connect(_on_music_pressed)
	_sfx_button.pressed.connect(_on_sfx_pressed)
	_controls_button.pressed.connect(_toggle_controls.bind(true))
	_close_controls_button.pressed.connect(_toggle_controls.bind(false))
	_credits_button.pressed.connect(_toggle_credits.bind(true))
	_close_credits_button.pressed.connect(_toggle_credits.bind(false))
	_quit_button.pressed.connect(get_tree().quit)
	_quit_button.visible = not OS.has_feature("web") and not OS.has_feature("android")
	_display_button.visible = not OS.has_feature("android")
	LocaleService.language_changed.connect(func(_code: String) -> void: _refresh())
	DisplayService.mode_changed.connect(func(_mode: int) -> void: _refresh())
	_refresh()
	AudioService.play_music_theme("puzzle")
	_marathon_button.grab_focus()


func _toggle_options(open: bool) -> void:
	_options_overlay.visible = open
	if open:
		_refresh()
		_das_button.grab_focus()
	else:
		_options_button.grab_focus()


func _on_das_pressed() -> void:
	HandlingSettings.set_das_ms(HandlingSettings.next_das_ms(HandlingSettings.get_das_ms()))
	_refresh()


func _on_arr_pressed() -> void:
	HandlingSettings.set_arr_ms(HandlingSettings.next_arr_ms(HandlingSettings.get_arr_ms()))
	_refresh()


func _on_colorblind_pressed() -> void:
	HandlingSettings.set_colorblind(not HandlingSettings.is_colorblind())
	_refresh()


func _on_music_pressed() -> void:
	AudioService.cycle_volume("Music")
	_refresh()


func _on_sfx_pressed() -> void:
	AudioService.cycle_volume("Sfx")
	_refresh()


func _toggle_controls(open: bool) -> void:
	_controls_overlay.visible = open
	if open:
		_close_controls_button.grab_focus()
	else:
		_controls_button.grab_focus()


func _toggle_credits(open: bool) -> void:
	_credits_overlay.visible = open
	if open:
		_close_credits_button.grab_focus()
	else:
		_credits_button.grab_focus()


func _refresh() -> void:
	_language_button.text = "%s: %s" % [tr("COMMON_LANGUAGE"), LocaleService.get_language_name()]
	_display_button.text = "%s: %s" % [tr("COMMON_DISPLAY_MODE"), tr(DisplayService.get_mode_key())]
	_das_button.text = tr("MENU_DAS_FMT") % HandlingSettings.get_das_ms()
	_arr_button.text = tr("MENU_ARR_FMT") % HandlingSettings.get_arr_ms()
	var cb_state := tr("MENU_ON") if HandlingSettings.is_colorblind() else tr("MENU_OFF")
	_colorblind_button.text = tr("MENU_COLORBLIND") % cb_state
	_music_button.text = AudioService.format_volume_label("COMMON_VOLUME_MUSIC", "Music")
	_sfx_button.text = AudioService.format_volume_label("COMMON_VOLUME_SFX", "Sfx")


func _start_mode(mode: String) -> void:
	# Speichert den ausgewählten Modus temporär oder übergibt ihn an die Spielszene.
	SaveService.set_value("session", "selected_mode", mode)
	get_tree().change_scene_to_file("res://scenes/game.tscn")
