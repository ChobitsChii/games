class_name LevelSelect
extends Control
## Levelauswahl für Lane Defenders: 2 Welten mit je 5 Leveln.

@onready var _world1_container: GridContainer = %World1Grid
@onready var _world2_container: GridContainer = %World2Grid
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	theme = ThemeFactory.build(LaneDefendersConfig.PALETTE)
	_back_button.pressed.connect(_on_back_pressed)
	_populate_levels()
	_back_button.grab_focus()


func _populate_levels() -> void:
	# Welt 1
	for i in range(1, 6):
		var lvl_id := "1-%d" % i
		_create_level_button(_world1_container, lvl_id, i == 1)

	# Welt 2
	for i in range(1, 6):
		var lvl_id := "2-%d" % i
		_create_level_button(_world2_container, lvl_id, false)


func _create_level_button(parent: Container, lvl_id: String, default_unlocked: bool) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(200, 95)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 26)

	var is_unlocked := default_unlocked or bool(SaveService.get_value("lane_defenders", "unlocked_" + lvl_id, false))
	var stars: int = int(SaveService.get_value("lane_defenders", "stars_" + lvl_id, 0))

	if is_unlocked:
		var star_str := "★".repeat(stars) + "☆".repeat(3 - stars) if stars > 0 else "☆☆☆"
		btn.text = "%s\n%s" % [lvl_id, star_str]
		btn.pressed.connect(_on_level_selected.bind(lvl_id))
	else:
		btn.text = "%s\n%s" % [lvl_id, tr("LEVEL_LOCKED")]
		btn.disabled = true

	parent.add_child(btn)


func _on_level_selected(lvl_id: String) -> void:
	SaveService.set_value("session", "selected_level", lvl_id)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
