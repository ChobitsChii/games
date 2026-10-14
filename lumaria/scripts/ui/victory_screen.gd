class_name VictoryScreen
extends Control
## Sieges- und Epilog-Bildschirm von Lumaria: The Prismatic Odyssey.
## Wird nach dem Sieg über Malakor und dem Sammeln des Ewigen Prismas angezeigt.
## Zeigt die Rettung von Lumaria, Helden-Statistiken und Menü-Optionen.

@onready var title_label: Label = %TitleLabel
@onready var epilogue_title: Label = %EpilogueTitle
@onready var epilogue_text: Label = %EpilogueText
@onready var stats_header: Label = %StatsHeader
@onready var stat_time: Label = %StatTime
@onready var stat_prisms: Label = %StatPrisms
@onready var stat_lumen: Label = %StatLumen

@onready var prism_sprite: TextureRect = %PrismIcon
@onready var continue_btn: Button = %ContinueButton
@onready var menu_btn: Button = %MainMenuButton

var _pulse_time: float = 0.0


func _ready() -> void:
	AudioManager.play_sfx("parry", 1.2)
	AudioManager.play_music("victory")

	title_label.text = tr("VICTORY_TITLE")
	epilogue_title.text = tr("VICTORY_EPILOGUE_TITLE")
	epilogue_text.text = tr("VICTORY_EPILOGUE_TEXT")
	stats_header.text = tr("VICTORY_STATS")

	stat_time.text = tr("VICTORY_STAT_TIME") % "00:42:15"
	stat_prisms.text = tr("VICTORY_STAT_PRISMS") % 4
	stat_lumen.text = tr("VICTORY_STAT_LUMEN") % 350

	continue_btn.text = tr("BTN_CONTINUE_EXPLORING")
	menu_btn.text = tr("BTN_RETURN_MAIN_MENU")

	continue_btn.pressed.connect(_on_continue_exploring)
	menu_btn.pressed.connect(_on_return_main_menu)

	continue_btn.grab_focus()


func _process(delta: float) -> void:
	_pulse_time += delta * 2.5
	if prism_sprite:
		prism_sprite.scale = Vector2.ONE * (1.0 + sin(_pulse_time) * 0.08)
		prism_sprite.modulate = Color(
			1.0 + sin(_pulse_time) * 0.2,
			1.0 + sin(_pulse_time + 1.0) * 0.2,
			1.0 + sin(_pulse_time + 2.0) * 0.2
		)


func _on_continue_exploring() -> void:
	AudioManager.play_sfx("dash", 1.2)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_return_main_menu() -> void:
	AudioManager.play_sfx("dash", 1.0)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
