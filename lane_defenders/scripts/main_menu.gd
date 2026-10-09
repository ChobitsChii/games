class_name MainMenu
extends Control
## Hauptmenü von Lane Defenders: Spielstart, Levelauswahl, Optionen und Credits.

@onready var _play_button: Button = %PlayButton
@onready var _level_select_button: Button = %LevelSelectButton
@onready var _how_to_play_button: Button = %HowToPlayButton
@onready var _almanac_button: Button = %AlmanacButton
@onready var _credits_button: Button = %CreditsButton
@onready var _language_button: Button = %LanguageButton
@onready var _display_button: Button = %DisplayButton
@onready var _quit_button: Button = %QuitButton

@onready var _how_to_play_overlay: Control = %HowToPlayOverlay
@onready var _close_how_button: Button = %CloseHowButton
@onready var _almanac_overlay: AlmanacModal = %AlmanacOverlay
@onready var _credits_overlay: Control = %CreditsOverlay
@onready var _close_credits_button: Button = %CloseCreditsButton


func _ready() -> void:
	theme = ThemeFactory.build(LaneDefendersConfig.PALETTE)
	_play_button.pressed.connect(_on_play_pressed)
	_level_select_button.pressed.connect(_on_level_select_pressed)
	_how_to_play_button.pressed.connect(_toggle_how_to_play.bind(true))
	_close_how_button.pressed.connect(_toggle_how_to_play.bind(false))
	_almanac_button.pressed.connect(func() -> void: _almanac_overlay.open())
	_credits_button.pressed.connect(_toggle_credits.bind(true))
	_close_credits_button.pressed.connect(_toggle_credits.bind(false))
	_language_button.pressed.connect(LocaleService.cycle_language)
	_display_button.pressed.connect(DisplayService.cycle_mode)
	_quit_button.pressed.connect(get_tree().quit)
	_quit_button.visible = not OS.has_feature("web")

	LocaleService.language_changed.connect(func(_code: String) -> void: _refresh())
	DisplayService.mode_changed.connect(func(_mode: int) -> void: _refresh())
	_refresh()
	_play_button.grab_focus()


func _refresh() -> void:
	_language_button.text = "%s: %s" % [tr("COMMON_LANGUAGE"), LocaleService.get_language_name()]
	_display_button.text = "%s: %s" % [tr("COMMON_DISPLAY_MODE"), tr(DisplayService.get_mode_key())]


func _on_play_pressed() -> void:
	# Finde das höchste freigeschaltete Level
	var current_id := "1-1"
	for w in range(1, 5):
		for n in range(1, 6):
			var test_id := "%d-%d" % [w, n]
			if bool(SaveService.get_value("lane_defenders", "unlocked_" + test_id, test_id == "1-1")):
				current_id = test_id
	SaveService.set_value("session", "selected_level", current_id)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_level_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _toggle_how_to_play(open: bool) -> void:
	_how_to_play_overlay.visible = open
	if open:
		_close_how_button.grab_focus()
	else:
		_how_to_play_button.grab_focus()


func _toggle_credits(open: bool) -> void:
	_credits_overlay.visible = open
	if open:
		_close_credits_button.grab_focus()
	else:
		_credits_button.grab_focus()
