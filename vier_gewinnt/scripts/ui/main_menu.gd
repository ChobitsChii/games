class_name MainMenu
extends Control
## Hauptmenü von Connect Four Deluxe: Spielstart, KI-Wahl, Einstellungen, Statistik, Credits.

@onready var btn_play_ai: Button = %BtnPlayAI
@onready var btn_play_hotseat: Button = %BtnPlayHotseat
@onready var btn_difficulty: Button = %BtnDifficulty
@onready var btn_starter: Button = %BtnStarter
@onready var btn_colorblind: Button = %BtnColorblind
@onready var btn_language: Button = %BtnLanguage
@onready var btn_display: Button = %BtnDisplay
@onready var btn_stats: Button = %BtnStats
@onready var btn_credits: Button = %BtnCredits
@onready var btn_quit: Button = %BtnQuit

@onready var stats_modal: PanelContainer = %StatsModal
@onready var stats_label_easy: Label = %StatsLabelEasy
@onready var stats_label_med: Label = %StatsLabelMed
@onready var stats_label_hard: Label = %StatsLabelHard
@onready var stats_label_hotseat: Label = %StatsLabelHotseat
@onready var btn_reset_stats: Button = %BtnResetStats
@onready var btn_close_stats: Button = %BtnCloseStats

@onready var credits_modal: PanelContainer = %CreditsModal
@onready var credits_content: Label = %CreditsContent
@onready var btn_close_credits: Button = %BtnCloseCredits

var _difficulty := ConnectFourAI.Difficulty.MEDIUM
var _starter := GameController.Starter.PLAYER_1
var _colorblind := false


func _ready() -> void:
	# Modernes Theme aus GameConfig.PALETTE aufbauen
	theme = ThemeFactory.build({
		"accent": GameConfig.PALETTE["board_rim"],
		"accent_alt": GameConfig.PALETTE["win_gold"],
		"panel": GameConfig.PALETTE["panel"],
		"text": GameConfig.PALETTE["text"],
		"text_dim": GameConfig.PALETTE["text_dim"],
	})

	_load_saved_settings()
	_update_button_texts()

	var ls := _get_locale_service()
	if ls != null and ls.has_signal("language_changed"):
		ls.language_changed.connect(func(_code: String) -> void: _update_button_texts())

	var ds := _get_display_service()
	if ds != null and ds.has_signal("mode_changed"):
		ds.mode_changed.connect(func(_mode: int) -> void: _update_button_texts())

	stats_modal.visible = false
	credits_modal.visible = false

	btn_play_ai.pressed.connect(_on_play_ai)
	btn_play_hotseat.pressed.connect(_on_play_hotseat)
	btn_difficulty.pressed.connect(_on_toggle_difficulty)
	btn_starter.pressed.connect(_on_toggle_starter)
	btn_colorblind.pressed.connect(_on_toggle_colorblind)
	btn_language.pressed.connect(_on_toggle_language)
	btn_display.pressed.connect(_on_toggle_display)
	btn_stats.pressed.connect(_on_open_stats)
	btn_credits.pressed.connect(_on_open_credits)
	btn_quit.pressed.connect(_on_quit)

	btn_reset_stats.pressed.connect(_on_reset_stats)
	btn_close_stats.pressed.connect(func() -> void: stats_modal.visible = false)
	btn_close_credits.pressed.connect(func() -> void: credits_modal.visible = false)

	# Web-Export: Beenden-Button ausblenden
	if OS.has_feature("web"):
		btn_quit.visible = false


func _load_saved_settings() -> void:
	var save_service := _get_save_service()
	if save_service != null:
		_difficulty = save_service.get_value("connect_four", "difficulty", ConnectFourAI.Difficulty.MEDIUM)
		_starter = save_service.get_value("connect_four", "starter", GameController.Starter.PLAYER_1)
		_colorblind = save_service.get_value("connect_four", "colorblind", false)


func _save_settings() -> void:
	var save_service := _get_save_service()
	if save_service != null:
		save_service.set_value("connect_four", "difficulty", _difficulty)
		save_service.set_value("connect_four", "starter", _starter)
		save_service.set_value("connect_four", "colorblind", _colorblind)
		save_service.save()


func _update_button_texts() -> void:
	match _difficulty:
		ConnectFourAI.Difficulty.EASY:
			btn_difficulty.text = "MENU_DIFF_EASY"
		ConnectFourAI.Difficulty.MEDIUM:
			btn_difficulty.text = "MENU_DIFF_MEDIUM"
		ConnectFourAI.Difficulty.HARD:
			btn_difficulty.text = "MENU_DIFF_HARD"

	match _starter:
		GameController.Starter.PLAYER_1:
			btn_starter.text = "MENU_STARTER_PLAYER1"
		GameController.Starter.PLAYER_2_OR_AI:
			btn_starter.text = "MENU_STARTER_PLAYER2"
		GameController.Starter.RANDOM:
			btn_starter.text = "MENU_STARTER_RANDOM"

	btn_colorblind.text = "MENU_COLORBLIND_ON" if _colorblind else "MENU_COLORBLIND_OFF"

	var ls := _get_locale_service()
	var lang_name: String = ls.get_language_name() if (ls != null and ls.has_method("get_language_name")) else "Deutsch"
	btn_language.text = "%s: %s" % [tr("COMMON_LANGUAGE"), lang_name]

	var ds := _get_display_service()
	var mode_key: String = ds.get_mode_key() if (ds != null and ds.has_method("get_mode_key")) else "DISPLAY_WINDOWED"
	btn_display.text = "%s: %s" % [tr("COMMON_DISPLAY_MODE"), tr(mode_key)]


func _on_play_ai() -> void:
	_save_settings()
	var ss := _get_save_service()
	if ss != null:
		ss.set_value("session", "mode", GameController.GameMode.AI)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_play_hotseat() -> void:
	_save_settings()
	var ss := _get_save_service()
	if ss != null:
		ss.set_value("session", "mode", GameController.GameMode.HOTSEAT)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_toggle_difficulty() -> void:
	match _difficulty:
		ConnectFourAI.Difficulty.EASY:
			_difficulty = ConnectFourAI.Difficulty.MEDIUM
		ConnectFourAI.Difficulty.MEDIUM:
			_difficulty = ConnectFourAI.Difficulty.HARD
		ConnectFourAI.Difficulty.HARD:
			_difficulty = ConnectFourAI.Difficulty.EASY
	_update_button_texts()
	_save_settings()


func _on_toggle_starter() -> void:
	match _starter:
		GameController.Starter.PLAYER_1:
			_starter = GameController.Starter.PLAYER_2_OR_AI
		GameController.Starter.PLAYER_2_OR_AI:
			_starter = GameController.Starter.RANDOM
		GameController.Starter.RANDOM:
			_starter = GameController.Starter.PLAYER_1
	_update_button_texts()
	_save_settings()


func _on_toggle_colorblind() -> void:
	_colorblind = not _colorblind
	_update_button_texts()
	_save_settings()


func _on_toggle_language() -> void:
	var ls := _get_locale_service()
	if ls != null and ls.has_method("cycle_language"):
		ls.cycle_language()
	_update_button_texts()


func _on_toggle_display() -> void:
	var ds := _get_display_service()
	if ds != null and ds.has_method("cycle_mode"):
		ds.cycle_mode()
	_update_button_texts()


func _on_open_stats() -> void:
	_refresh_stats_display()
	stats_modal.visible = true


func _refresh_stats_display() -> void:
	var save_service := _get_save_service()
	if save_service != null:
		var e_w: int = save_service.get_value("connect_four", "easy_wins", 0)
		var e_l: int = save_service.get_value("connect_four", "easy_losses", 0)
		var e_d: int = save_service.get_value("connect_four", "easy_draws", 0)
		stats_label_easy.text = tr("HUD_STATS_EASY") % [e_w, e_l, e_d]

		var m_w: int = save_service.get_value("connect_four", "medium_wins", 0)
		var m_l: int = save_service.get_value("connect_four", "medium_losses", 0)
		var m_d: int = save_service.get_value("connect_four", "medium_draws", 0)
		stats_label_med.text = tr("HUD_STATS_MEDIUM") % [m_w, m_l, m_d]

		var h_w: int = save_service.get_value("connect_four", "hard_wins", 0)
		var h_l: int = save_service.get_value("connect_four", "hard_losses", 0)
		var h_d: int = save_service.get_value("connect_four", "hard_draws", 0)
		stats_label_hard.text = tr("HUD_STATS_HARD") % [h_w, h_l, h_d]

		var hs_1: int = save_service.get_value("connect_four", "hotseat_p1", 0)
		var hs_2: int = save_service.get_value("connect_four", "hotseat_p2", 0)
		var hs_d: int = save_service.get_value("connect_four", "hotseat_draws", 0)
		stats_label_hotseat.text = tr("HUD_STATS_HOTSEAT") % [hs_1, hs_2, hs_d]


func _on_reset_stats() -> void:
	var save_service := _get_save_service()
	if save_service != null:
		for prefix in ["easy", "medium", "hard"]:
			save_service.set_value("connect_four", prefix + "_wins", 0)
			save_service.set_value("connect_four", prefix + "_losses", 0)
			save_service.set_value("connect_four", prefix + "_draws", 0)
		save_service.set_value("connect_four", "hotseat_p1", 0)
		save_service.set_value("connect_four", "hotseat_p2", 0)
		save_service.set_value("connect_four", "hotseat_draws", 0)
		save_service.save()
	_refresh_stats_display()


func _on_open_credits() -> void:
	credits_content.text = tr("MENU_CREDITS_TEXT")
	credits_modal.visible = true


func _on_quit() -> void:
	get_tree().quit(0)


func _get_save_service() -> Node:
	if Engine.get_main_loop() != null:
		var root := (Engine.get_main_loop() as SceneTree).root
		if root != null and root.has_node("SaveService"):
			return root.get_node("SaveService")
	return null


func _get_locale_service() -> Node:
	if Engine.get_main_loop() != null:
		var root := (Engine.get_main_loop() as SceneTree).root
		if root != null and root.has_node("LocaleService"):
			return root.get_node("LocaleService")
	return null


func _get_display_service() -> Node:
	if Engine.get_main_loop() != null:
		var root := (Engine.get_main_loop() as SceneTree).root
		if root != null and root.has_node("DisplayService"):
			return root.get_node("DisplayService")
	return null
