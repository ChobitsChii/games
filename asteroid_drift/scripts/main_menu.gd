extends Control
## Hauptmenü mit Parallax-Hintergrund, Highscore, Sprach- und Vollbild-Optionen.

@onready var start_btn: Button = %StartButton
@onready var controls_btn: Button = %ControlsButton
@onready var language_btn: Button = %LanguageButton
@onready var fullscreen_btn: Button = %FullscreenButton
@onready var credits_btn: Button = %CreditsButton
@onready var quit_btn: Button = %QuitButton

@onready var highscore_label: Label = %HighscoreLabel
@onready var controls_panel: PanelContainer = %ControlsPanel
@onready var credits_panel: PanelContainer = %CreditsPanel
@onready var bg_rect: TextureRect = %BackgroundRect

var _audio_mgr: AudioManager


func _ready() -> void:
	theme = ThemeFactory.build(Constants.PALETTE)

	_audio_mgr = AudioManager.new()
	add_child(_audio_mgr)

	if OS.has_feature("web"):
		quit_btn.visible = false

	start_btn.pressed.connect(_on_start_pressed)
	controls_btn.pressed.connect(_on_controls_pressed)
	language_btn.pressed.connect(_on_language_pressed)
	fullscreen_btn.pressed.connect(_on_fullscreen_pressed)
	credits_btn.pressed.connect(_on_credits_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	%CloseControlsButton.pressed.connect(func() -> void:
		_audio_mgr.play("click")
		controls_panel.visible = false
	)
	%CloseCreditsButton.pressed.connect(func() -> void:
		_audio_mgr.play("click")
		credits_panel.visible = false
	)

	_update_highscore_display()
	_update_language_button_text()
	_update_fullscreen_button_text()

	# Subtile Hintergrund-Schwebung
	var tween := create_tween().set_loops()
	tween.tween_property(bg_rect, "position:y", -15.0, 4.0).as_relative()
	tween.tween_property(bg_rect, "position:y", 15.0, 4.0).as_relative()


func _update_highscore_display() -> void:
	var highscore: int = int(SaveService.get_value("highscore", "best", 0))
	highscore_label.text = tr("HUD_HIGH_SCORE_FMT") % highscore


func _update_language_button_text() -> void:
	language_btn.text = "%s: %s" % [tr("COMMON_LANGUAGE"), LocaleService.get_language_name()]


func _update_fullscreen_button_text() -> void:
	fullscreen_btn.text = "%s: %s" % [tr("COMMON_DISPLAY_MODE"), tr(DisplayService.get_mode_key())]


func _on_start_pressed() -> void:
	_audio_mgr.play("click")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	)


func _on_controls_pressed() -> void:
	_audio_mgr.play("click")
	controls_panel.visible = true
	credits_panel.visible = false


func _on_language_pressed() -> void:
	_audio_mgr.play("click")
	LocaleService.cycle_language()
	_update_highscore_display()
	_update_language_button_text()
	_update_fullscreen_button_text()


func _on_fullscreen_pressed() -> void:
	_audio_mgr.play("click")
	DisplayService.cycle_mode()
	_update_fullscreen_button_text()


func _on_credits_pressed() -> void:
	_audio_mgr.play("click")
	credits_panel.visible = true
	controls_panel.visible = false


func _on_quit_pressed() -> void:
	_audio_mgr.play("click")
	get_tree().quit()
