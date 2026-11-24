class_name CryptTheme
extends RefCounted
## Dark-Fantasy UI-Theme für Crypt Dash mit Noto Serif Display-Überschriften, Obsidian-Panels und Cyan/Gold-Akzenten.

static func _get_cache() -> Dictionary:
	var ml := Engine.get_main_loop()
	if ml is SceneTree and (ml as SceneTree).root != null:
		var root := (ml as SceneTree).root
		if not root.has_meta("_crypt_theme_cache"):
			root.set_meta("_crypt_theme_cache", {})
		return root.get_meta("_crypt_theme_cache") as Dictionary
	return {}


static func _cached_font(key: String, path: String) -> Font:
	var cache := _get_cache()
	if cache.has(key):
		return cache[key] as Font
	if ResourceLoader.exists(path):
		var f := load(path) as Font
		if f != null and Engine.get_main_loop() is SceneTree:
			cache[key] = f
		return f
	return null


static func get_display_font() -> Font:
	return _cached_font("display_font", "res://assets/fonts/NotoSerif-Bold.ttf")


static func get_semibold_font() -> Font:
	return _cached_font("semibold_font", "res://assets/fonts/NotoSans-SemiBold.ttf")


static func get_body_font() -> Font:
	return _cached_font("body_font", "res://assets/fonts/NotoSans-Regular.ttf")


static func make_glass_card(
		bg: Color = Color(0.05, 0.08, 0.14, 0.92),
		border: Color = Color(0.24, 0.56, 0.72, 0.65),
		border_w: int = 2,
		radius: int = 14,
		shadow: Color = Color(0.0, 0.0, 0.0, 0.65),
		shadow_sz: int = 16) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_w)
	box.set_corner_radius_all(radius)
	box.shadow_color = shadow
	box.shadow_size = shadow_sz
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box


static func style_display_label(lbl: Label, size_px: int = 38, color: Color = Color("38bdf8")) -> void:
	if lbl == null:
		return
	var df := get_display_font()
	if df != null:
		lbl.add_theme_font_override("font", df)
	lbl.add_theme_font_size_override("font_size", size_px)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color("020617"))
	lbl.add_theme_constant_override("outline_size", 5)


static func build() -> Theme:
	var cache := _get_cache()
	if cache.has("theme"):
		return cache["theme"] as Theme

	var theme := Theme.new()
	var ui_font := get_semibold_font()
	if ui_font != null:
		theme.default_font = ui_font
	theme.default_font_size = 22

	theme.set_color("font_color", "Label", Color("f1f5f9"))

	var normal := make_glass_card(
		Color(0.06, 0.09, 0.16, 0.90),
		Color(0.26, 0.36, 0.52, 0.75),
		2, 12,
		Color(0.0, 0.0, 0.0, 0.55), 8
	)
	var hover := make_glass_card(
		Color(0.08, 0.18, 0.28, 0.96),
		Color("38bdf8"),
		2, 12,
		Color(0.08, 0.72, 0.92, 0.42), 14
	)
	var pressed := make_glass_card(
		Color(0.05, 0.25, 0.36, 0.98),
		Color("facc15"),
		2, 12,
		Color(0.98, 0.80, 0.08, 0.35), 10
	)
	var disabled := make_glass_card(
		Color(0.04, 0.06, 0.11, 0.65),
		Color(0.18, 0.22, 0.30, 0.38),
		2, 12,
		Color(0.0, 0.0, 0.0, 0.0), 0
	)
	var focus := make_glass_card(
		Color(0.0, 0.0, 0.0, 0.0),
		Color("67e8f9"),
		3, 12,
		Color(0.0, 0.0, 0.0, 0.0), 0
	)
	focus.draw_center = false

	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_color("font_color", "Button", Color("f1f5f9"))
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color("fef08a"))
	theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color("64748b"))

	theme.set_stylebox("panel", "PanelContainer", make_glass_card(
		Color(0.05, 0.07, 0.13, 0.94),
		Color(0.24, 0.52, 0.68, 0.62),
		2, 16,
		Color(0.0, 0.0, 0.0, 0.7), 22
	))

	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.04, 0.06, 0.10, 0.94)
	pb_bg.border_color = Color(0.20, 0.30, 0.44, 0.8)
	pb_bg.set_border_width_all(1)
	pb_bg.set_corner_radius_all(6)

	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = Color("06b6d4")
	pb_fill.set_corner_radius_all(6)

	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)

	var sb_track := StyleBoxFlat.new()
	sb_track.bg_color = Color(0.04, 0.06, 0.10, 0.7)
	sb_track.set_corner_radius_all(6)
	var sb_grab := StyleBoxFlat.new()
	sb_grab.bg_color = Color(0.24, 0.52, 0.68, 0.75)
	sb_grab.set_corner_radius_all(6)
	var sb_grab_hi := StyleBoxFlat.new()
	sb_grab_hi.bg_color = Color("38bdf8")
	sb_grab_hi.set_corner_radius_all(6)

	theme.set_stylebox("scroll", "VScrollBar", sb_track)
	theme.set_stylebox("grabber", "VScrollBar", sb_grab)
	theme.set_stylebox("grabber_highlight", "VScrollBar", sb_grab_hi)
	theme.set_stylebox("grabber_pressed", "VScrollBar", sb_grab_hi)

	if Engine.get_main_loop() is SceneTree:
		cache["theme"] = theme
	return theme
