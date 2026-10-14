class_name MainMenu
extends Control
## Hauptmenü von Lumaria: The Prismatic Odyssey.

@onready var _play_button: Button = %PlayButton
@onready var _how_to_play_button: Button = %HowToPlayButton
@onready var _credits_button: Button = %CreditsButton
@onready var _language_button: Button = %LanguageButton
@onready var _display_button: Button = %DisplayButton
@onready var _quit_button: Button = %QuitButton

@onready var _how_to_play_overlay: Control = %HowToPlayOverlay
@onready var _close_how_button: Button = %CloseHowButton
@onready var _credits_overlay: Control = %CreditsOverlay
@onready var _close_credits_button: Button = %CloseCreditsButton


func _ready() -> void:
	AudioManager.play_music("village")
	_play_button.pressed.connect(_on_play_pressed)
	_how_to_play_button.pressed.connect(_toggle_how_to_play.bind(true))
	_close_how_button.pressed.connect(_toggle_how_to_play.bind(false))
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
	get_tree().change_scene_to_file("res://scenes/game.tscn")


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
