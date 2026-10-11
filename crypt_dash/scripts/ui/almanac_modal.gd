class_name CryptAlmanacModal
extends Control
## Zeigt das Bestiarium & Item-Lexikon von Crypt Dash an.

signal closed

const ENEMIES := [
	{"name": "ENEMY_SKELETON", "desc": "ALMANAC_SKELETON_DESC", "role": "ALMANAC_MELEE"},
	{"name": "ENEMY_ARCHER", "desc": "ALMANAC_ARCHER_DESC", "role": "ALMANAC_RANGED"},
	{"name": "ENEMY_GHOST", "desc": "ALMANAC_GHOST_DESC", "role": "ALMANAC_PHANTOM"},
	{"name": "ENEMY_SLIME", "desc": "ALMANAC_SLIME_DESC", "role": "ALMANAC_SPLITTER"},
	{"name": "ENEMY_SUMMONER", "desc": "ALMANAC_SUMMONER_DESC", "role": "ALMANAC_MAGICIAN"},
	{"name": "BOSS_FLOOR_1", "desc": "ALMANAC_BOSS1_DESC", "role": "ALMANAC_BOSS"},
	{"name": "BOSS_FLOOR_2", "desc": "ALMANAC_BOSS2_DESC", "role": "ALMANAC_BOSS"},
	{"name": "BOSS_FLOOR_3", "desc": "ALMANAC_BOSS3_DESC", "role": "ALMANAC_BOSS"},
]

@onready var _enemies_grid: GridContainer = %EnemiesGrid
@onready var _items_grid: GridContainer = %ItemsGrid
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_populate()


func open() -> void:
	visible = true
	_close_button.grab_focus()


func _on_close_pressed() -> void:
	visible = false
	closed.emit()


func _populate() -> void:
	for c in _enemies_grid.get_children():
		c.queue_free()
	for c in _items_grid.get_children():
		c.queue_free()

	# Gegner & Bosse
	for e in ENEMIES:
		_enemies_grid.add_child(_create_card(tr(e["name"]), "%s • %s" % [tr(e["role"]), tr(e["desc"])], Color("ef4444")))

	# Items & Relikte
	for it in ItemCatalog.get_all_items():
		_items_grid.add_child(_create_card(tr(it.name_key), tr(it.desc_key), Color("06b6d4")))


func _create_card(title_text: String, desc_text: String, accent_color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 110)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", accent_color)
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = desc_text
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color("94a3b8"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	return panel
