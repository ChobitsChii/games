class_name CryptAlmanacModal
extends Control
## Zeigt das Bestiarium & Item-Lexikon von Crypt Dash mit hochauflösenden Porträts und Relikt-Icons.

signal closed

const ENEMIES := [
	{"id": "skeleton", "name": "ENEMY_SKELETON", "desc": "ALMANAC_SKELETON_DESC", "role": "ALMANAC_MELEE"},
	{"id": "archer", "name": "ENEMY_ARCHER", "desc": "ALMANAC_ARCHER_DESC", "role": "ALMANAC_RANGED"},
	{"id": "ghost", "name": "ENEMY_GHOST", "desc": "ALMANAC_GHOST_DESC", "role": "ALMANAC_PHANTOM"},
	{"id": "slime", "name": "ENEMY_SLIME", "desc": "ALMANAC_SLIME_DESC", "role": "ALMANAC_SPLITTER"},
	{"id": "summoner", "name": "ENEMY_SUMMONER", "desc": "ALMANAC_SUMMONER_DESC", "role": "ALMANAC_MAGICIAN"},
	{"id": "boss1", "name": "BOSS_FLOOR_1", "desc": "ALMANAC_BOSS1_DESC", "role": "ALMANAC_BOSS"},
	{"id": "boss2", "name": "BOSS_FLOOR_2", "desc": "ALMANAC_BOSS2_DESC", "role": "ALMANAC_BOSS"},
	{"id": "boss3", "name": "BOSS_FLOOR_3", "desc": "ALMANAC_BOSS3_DESC", "role": "ALMANAC_BOSS"},
]

@onready var _enemies_grid: GridContainer = %EnemiesGrid
@onready var _items_grid: GridContainer = %ItemsGrid
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	theme = CryptTheme.build()
	var title_lbl := get_node_or_null("Center/Panel/Margin/Box/Title") as Label
	if title_lbl != null:
		CryptTheme.style_display_label(title_lbl, 40, Color("38bdf8"))
	var en_hdr := get_node_or_null("Center/Panel/Margin/Box/Scroll/ScrollMargin/SectionsVBox/EnemiesHeader") as Label
	if en_hdr != null:
		CryptTheme.style_display_label(en_hdr, 28, Color("f87171"))
	var it_hdr := get_node_or_null("Center/Panel/Margin/Box/Scroll/ScrollMargin/SectionsVBox/ItemsHeader") as Label
	if it_hdr != null:
		CryptTheme.style_display_label(it_hdr, 28, Color("38bdf8"))

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

	for e in ENEMIES:
		_enemies_grid.add_child(_create_enemy_card(e))

	for it in ItemCatalog.get_all_items():
		_items_grid.add_child(_create_item_card(it))


func _create_icon_badge(tex_path: String, box_size: float, border_col: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(box_size, box_size)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := CryptTheme.make_glass_card(
		Color(0.03, 0.05, 0.10, 0.96),
		border_col,
		2, 12,
		Color(0.0, 0.0, 0.0, 0.5), 6
	)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	badge.add_theme_stylebox_override("panel", sb)

	var icon_rect := TextureRect.new()
	icon_rect.texture = CryptAssets.get_texture(tex_path)
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	badge.add_child(icon_rect)
	return badge


func _create_enemy_card(data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(530, 124)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", CryptTheme.make_glass_card(
		Color(0.06, 0.08, 0.14, 0.92),
		Color(0.65, 0.22, 0.24, 0.45),
		1, 12, Color(0.0, 0.0, 0.0, 0.4), 8
	))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	var is_boss: bool = str(data["id"]).begins_with("boss")
	var badge_border := Color("f97316") if is_boss else Color("ef4444")
	hbox.add_child(_create_icon_badge(CryptAssets.get_enemy_portrait_path(str(data["id"])), 78.0, badge_border))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var title := Label.new()
	title.text = tr(data["name"])
	CryptTheme.style_display_label(title, 22, Color("fb923c") if is_boss else Color("f87171"))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "%s • %s" % [tr(data["role"]), tr(data["desc"])]
	var bf := CryptTheme.get_body_font()
	if bf != null:
		desc.add_theme_font_override("font", bf)
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color("cbd5e1"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	return panel


func _create_item_card(it: ItemData) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(530, 114)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", CryptTheme.make_glass_card(
		Color(0.06, 0.08, 0.14, 0.92),
		Color(0.18, 0.56, 0.72, 0.45),
		1, 12, Color(0.0, 0.0, 0.0, 0.4), 8
	))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	hbox.add_child(_create_icon_badge(CryptAssets.get_item_icon_path(it.id), 72.0, Color("38bdf8")))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var title := Label.new()
	title.text = tr(it.name_key)
	CryptTheme.style_display_label(title, 22, Color("38bdf8"))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = tr(it.desc_key)
	var bf := CryptTheme.get_body_font()
	if bf != null:
		desc.add_theme_font_override("font", bf)
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color("cbd5e1"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	return panel
