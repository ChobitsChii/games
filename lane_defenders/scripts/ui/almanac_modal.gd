class_name AlmanacModal
extends Control
## Zeigt das Einheiten- und Gegner-Lexikon (Almanach) an.

signal closed

const UNITS := ["generator", "shooter", "double_shooter", "frost", "wall", "mine", "area_launcher"]
const ENEMIES := ["runner", "fast_runner", "tank", "jumper", "shield", "boss"]

@onready var _units_container: GridContainer = %UnitsGrid
@onready var _enemies_container: GridContainer = %EnemiesGrid
@onready var _close_button: Button = %CloseButton

var _populated: bool = false
var _populated_locale: String = ""
var _populated_theme: String = ""


func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)


func is_populated() -> bool:
	return _populated


func open() -> void:
	var current_locale := TranslationServer.get_locale()
	var current_theme := LaneDefendersTheme.get_current()
	if not _populated or _populated_locale != current_locale or _populated_theme != current_theme:
		_populate()
		_populated = true
		_populated_locale = current_locale
		_populated_theme = current_theme
	visible = true
	if _close_button != null and _close_button.is_inside_tree():
		_close_button.grab_focus()


func _on_close_pressed() -> void:
	visible = false
	closed.emit()


func _populate() -> void:
	for child in _units_container.get_children():
		_units_container.remove_child(child)
		child.queue_free()
	for child in _enemies_container.get_children():
		_enemies_container.remove_child(child)
		child.queue_free()

	for u_id in UNITS:
		var path := "res://data/units/%s.tres" % u_id
		if ResourceLoader.exists(path):
			var udata: UnitData = load(path)
			_units_container.add_child(_create_unit_card(udata))

	for e_id in ENEMIES:
		var path := "res://data/enemies/%s.tres" % e_id
		if ResourceLoader.exists(path):
			var edata: EnemyData = load(path)
			_enemies_container.add_child(_create_enemy_card(edata))


func _create_unit_card(udata: UnitData) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(510, 115)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex_path := LaneDefendersTheme.get_unit_texture_path(udata.id)
	if ResourceLoader.exists(tex_path):
		icon.texture = load(tex_path)
	hbox.add_child(icon)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = tr(LaneDefendersTheme.get_unit_name_key(udata.id))
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color("3ee087"))
	vbox.add_child(name_lbl)

	var stat_lbl := Label.new()
	stat_lbl.text = tr("UNIT_STAT_COST") % [udata.cost, udata.cooldown, udata.max_hp]
	stat_lbl.add_theme_font_size_override("font_size", 16)
	stat_lbl.add_theme_color_override("font_color", Color("ffe600"))
	vbox.add_child(stat_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = tr(udata.desc_key)
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	return panel


func _create_enemy_card(edata: EnemyData) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(510, 115)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex_path := "res://assets/enemies/%s.png" % edata.id
	if ResourceLoader.exists(tex_path):
		icon.texture = load(tex_path)
	hbox.add_child(icon)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = tr(edata.name_key)
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color("ff6b6b"))
	vbox.add_child(name_lbl)

	var stat_lbl := Label.new()
	stat_lbl.text = tr("ENEMY_STAT_INFO") % [edata.hp, edata.speed]
	stat_lbl.add_theme_font_size_override("font_size", 16)
	stat_lbl.add_theme_color_override("font_color", Color("ffa07a"))
	vbox.add_child(stat_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = tr(edata.desc_key)
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	return panel
