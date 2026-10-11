class_name CryptAlmanacModal
extends Control
## Zeigt das Bestiarium & Item-Lexikon von Crypt Dash an.

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
		_enemies_grid.add_child(_create_enemy_card(e))

	# Items & Relikte
	for it in ItemCatalog.get_all_items():
		_items_grid.add_child(_create_item_card(it))


func _create_enemy_card(data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(530, 120)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	margin.add_child(hbox)

	# Portrait Preview Control
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(72, 72)
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.draw.connect(_draw_enemy_portrait.bind(preview, data["id"]))
	hbox.add_child(preview)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var title := Label.new()
	title.text = tr(data["name"])
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("ef4444"))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "%s • %s" % [tr(data["role"]), tr(data["desc"])]
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color("94a3b8"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	return panel


func _create_item_card(it: ItemData) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(530, 110)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	margin.add_child(hbox)

	var preview := Control.new()
	preview.custom_minimum_size = Vector2(64, 64)
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.draw.connect(_draw_item_icon.bind(preview, it.id))
	hbox.add_child(preview)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var title := Label.new()
	title.text = tr(it.name_key)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("06b6d4"))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = tr(it.desc_key)
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color("94a3b8"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	return panel


func _draw_enemy_portrait(node: Control, enemy_id: String) -> void:
	var center := node.size * 0.5
	# Sockel / Portrait-Rahmen
	node.draw_circle(center, 34.0, Color("090d16"))
	node.draw_arc(center, 34.0, 0, TAU, 32, Color("334155"), 2.0)

	match enemy_id:
		"skeleton":
			node.draw_circle(center, 22.0, Color("0f172a"))
			node.draw_circle(center, 19.0, Color("f1f5f9"))
			node.draw_circle(center + Vector2(-6, -2), 4.5, Color("ef4444"))
			node.draw_circle(center + Vector2(6, -2), 4.5, Color("ef4444"))
			node.draw_circle(center + Vector2(-6, -2), 2.0, Color.WHITE)
			node.draw_circle(center + Vector2(6, -2), 2.0, Color.WHITE)
			node.draw_rect(Rect2(center.x - 7, center.y + 7, 14, 5), Color("334155"))
		"archer":
			node.draw_circle(center, 22.0, Color("0f172a"))
			node.draw_circle(center, 19.0, Color("16a34a"))
			node.draw_circle(center + Vector2(0, -3), 13.0, Color("f8fafc"))
			node.draw_circle(center + Vector2(-5, -3), 4.0, Color("f97316"))
			node.draw_circle(center + Vector2(5, -3), 4.0, Color("f97316"))
			node.draw_circle(center + Vector2(-5, -3), 2.0, Color.WHITE)
			node.draw_circle(center + Vector2(5, -3), 2.0, Color.WHITE)
			node.draw_arc(center + Vector2(14, 0), 12.0, -PI/2, PI/2, 12, Color("fbbf24"), 3.0)
		"ghost":
			node.draw_circle(center, 25.0, Color(0.2, 0.9, 0.8, 0.35))
			node.draw_circle(center, 19.0, Color(0.5, 1.0, 0.9, 0.85))
			node.draw_circle(center + Vector2(-5, -3), 4.0, Color("0f172a"))
			node.draw_circle(center + Vector2(5, -3), 4.0, Color("0f172a"))
		"slime":
			node.draw_circle(center, 25.0, Color(0.5, 0.9, 0.1, 0.35))
			node.draw_circle(center, 22.0, Color("14532d"))
			node.draw_circle(center, 20.0, Color("84cc16"))
			node.draw_circle(center + Vector2(0, -4), 13.0, Color("bef264"))
			node.draw_circle(center + Vector2(-5, -3), 4.0, Color("fef08a"))
			node.draw_circle(center + Vector2(5, -3), 4.0, Color("fef08a"))
		"summoner":
			node.draw_circle(center, 22.0, Color("3b0764"))
			node.draw_circle(center, 19.0, Color("6b21a8"))
			node.draw_circle(center, 13.0, Color("a855f7"))
			node.draw_circle(center, 6.0, Color("facc15")) # Amulett
		"boss1": # Knochenfürst Malok
			node.draw_circle(center, 26.0, Color(0.97, 0.45, 0.08, 0.4))
			node.draw_circle(center, 23.0, Color("f97316"))
			node.draw_circle(center, 15.0, Color("0f172a"))
			node.draw_line(center + Vector2(-10, -14), center + Vector2(-16, -26), Color("f97316"), 3.5)
			node.draw_line(center + Vector2(10, -14), center + Vector2(16, -26), Color("f97316"), 3.5)
		"boss2": # Schattenweberin Vex
			node.draw_circle(center, 26.0, Color(0.86, 0.15, 0.15, 0.4))
			node.draw_circle(center, 23.0, Color("dc2626"))
			node.draw_circle(center, 15.0, Color("0f172a"))
			node.draw_line(center + Vector2(-10, -14), center + Vector2(-16, -26), Color("dc2626"), 3.5)
			node.draw_line(center + Vector2(10, -14), center + Vector2(16, -26), Color("dc2626"), 3.5)
		"boss3": # Fürst Thanatos
			node.draw_circle(center, 26.0, Color(0.58, 0.2, 0.92, 0.4))
			node.draw_circle(center, 23.0, Color("9333ea"))
			node.draw_circle(center, 15.0, Color("0f172a"))
			node.draw_line(center + Vector2(-10, -14), center + Vector2(-16, -26), Color("9333ea"), 3.5)
			node.draw_line(center + Vector2(10, -14), center + Vector2(16, -26), Color("9333ea"), 3.5)


func _draw_item_icon(node: Control, item_id: String) -> void:
	var center := node.size * 0.5
	node.draw_circle(center, 28.0, Color("090d16"))
	node.draw_arc(center, 28.0, 0, TAU, 32, Color("0284c7"), 2.0)

	match item_id:
		"spread":
			node.draw_line(center, center + Vector2(-12, -14), Color("38bdf8"), 2.5)
			node.draw_line(center, center + Vector2(0, -18), Color("38bdf8"), 2.5)
			node.draw_line(center, center + Vector2(12, -14), Color("38bdf8"), 2.5)
		"pierce":
			node.draw_line(center + Vector2(0, 16), center + Vector2(0, -16), Color("a855f7"), 3.0)
			node.draw_circle(center + Vector2(0, -16), 3.0, Color.WHITE)
		"vamp":
			node.draw_circle(center, 14.0, Color("b91c1c"))
			node.draw_circle(center + Vector2(-4, -2), 3.0, Color.WHITE)
			node.draw_circle(center + Vector2(4, -2), 3.0, Color.WHITE)
		"shield":
			node.draw_circle(center, 15.0, Color("0284c7"))
			node.draw_arc(center, 17.0, 0, TAU, 16, Color("38bdf8"), 2.0)
		"lightning":
			var pts := PackedVector2Array([
				center + Vector2(4, -16),
				center + Vector2(-6, 0),
				center + Vector2(2, 2),
				center + Vector2(-4, 16)
			])
			node.draw_polyline(pts, Color("facc15"), 3.0)
		"dash_extra":
			node.draw_circle(center + Vector2(-6, 0), 10.0, Color(0.2, 0.9, 0.8, 0.5))
			node.draw_circle(center + Vector2(6, 0), 10.0, Color("38bdf8"))
		"magnet":
			node.draw_arc(center, 14.0, PI, TAU, 16, Color("ef4444"), 4.0)
		"boots":
			node.draw_rect(Rect2(center.x - 12, center.y - 4, 24, 10), Color("f59e0b"))
			node.draw_circle(center + Vector2(-6, 10), 4.0, Color("d97706"))
			node.draw_circle(center + Vector2(6, 10), 4.0, Color("d97706"))
		"heavy":
			node.draw_line(center + Vector2(0, 14), center + Vector2(0, -10), Color("78716c"), 3.0)
			node.draw_rect(Rect2(center.x - 10, center.y - 14, 20, 8), Color("e2e8f0"))
		"haste":
			node.draw_circle(center, 15.0, Color("10b981"))
			node.draw_line(center, center + Vector2(0, -10), Color.WHITE, 2.0)
			node.draw_line(center, center + Vector2(8, 0), Color.WHITE, 2.0)
		"heart_container":
			node.draw_circle(center + Vector2(-6, -4), 9.0, Color("ef4444"))
			node.draw_circle(center + Vector2(6, -4), 9.0, Color("ef4444"))
			node.draw_circle(center + Vector2(0, 4), 9.0, Color("ef4444"))
		"flame_aura":
			node.draw_circle(center, 16.0, Color("ea580c"))
			node.draw_circle(center, 9.0, Color("facc15"))
		"berserk":
			node.draw_circle(center, 16.0, Color("991b1b"))
			node.draw_line(center + Vector2(-8, -8), center + Vector2(8, 8), Color("fca5a5"), 2.0)
			node.draw_line(center + Vector2(8, -8), center + Vector2(-8, 8), Color("fca5a5"), 2.0)
		"frost":
			node.draw_line(center + Vector2(0, -14), center + Vector2(0, 14), Color("bae6fd"), 2.5)
			node.draw_line(center + Vector2(-14, 0), center + Vector2(14, 0), Color("bae6fd"), 2.5)
		"crit":
			node.draw_circle(center, 14.0, Color("f59e0b"))
			node.draw_circle(center, 6.0, Color("dc2626"))
			node.draw_circle(center, 2.0, Color.WHITE)
		_:
			node.draw_circle(center, 14.0, Color("38bdf8"))
