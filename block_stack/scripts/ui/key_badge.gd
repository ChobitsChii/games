class_name KeyBadge
extends PanelContainer
## Visuelle Tasten-Badge im Keycap-Look mit 3D-Prägung, Text oder SVG-Icon.

@export var key_text: String = ""
@export var key_icon: Texture2D
@export var is_round: bool = false
@export var is_accent: bool = false
@export var min_key_width: float = 38.0
@export var badge_height: float = 38.0
@export var key_font_size: int = 18


func _ready() -> void:
	_apply_style()
	_rebuild_content()


func set_key_text(text: String) -> void:
	key_text = text
	key_icon = null
	if is_inside_tree():
		_rebuild_content()


func set_key_icon(tex: Texture2D) -> void:
	key_icon = tex
	key_text = ""
	if is_inside_tree():
		_rebuild_content()


func _apply_style() -> void:
	custom_minimum_size = Vector2(min_key_width, badge_height)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.09, 0.12, 0.20, 0.95)
	if is_accent:
		box.border_color = Color(0.0, 0.898, 1.0, 0.9)
	else:
		box.border_color = Color(0.24, 0.45, 0.72, 0.8)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 3
	
	if is_round:
		box.set_corner_radius_all(19)
	else:
		box.set_corner_radius_all(6)
		
	box.shadow_color = Color(0, 0, 0, 0.5)
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 2)
	
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 3
	box.content_margin_bottom = 5
	add_theme_stylebox_override("panel", box)


func _rebuild_content() -> void:
	for child in get_children():
		child.queue_free()
	
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	
	if key_icon != null:
		var rect := TextureRect.new()
		rect.texture = key_icon
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(20, 20)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_accent:
			rect.modulate = Color(0.0, 0.898, 1.0, 1.0)
		else:
			rect.modulate = Color(0.9, 0.95, 1.0, 1.0)
		center.add_child(rect)
	elif key_text != "":
		var lbl := Label.new()
		lbl.text = key_text
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", key_font_size)
		if is_accent:
			lbl.add_theme_color_override("font_color", Color(0.0, 0.898, 1.0, 1.0))
		else:
			lbl.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 1.0))
		center.add_child(lbl)


static func create_text_badge(text: String, min_w: float = 38.0, accent: bool = false, font_sz: int = 18) -> KeyBadge:
	var badge := KeyBadge.new()
	badge.key_text = text
	badge.min_key_width = min_w
	badge.is_accent = accent
	badge.key_font_size = font_sz
	return badge


static func create_icon_badge(icon: Texture2D, min_w: float = 38.0, accent: bool = true) -> KeyBadge:
	var badge := KeyBadge.new()
	badge.key_icon = icon
	badge.min_key_width = min_w
	badge.is_accent = accent
	return badge


static func create_round_badge(text: String) -> KeyBadge:
	var badge := KeyBadge.new()
	badge.key_text = text
	badge.is_round = true
	badge.is_accent = true
	badge.min_key_width = 36.0
	badge.badge_height = 36.0
	badge.key_font_size = 18
	return badge
