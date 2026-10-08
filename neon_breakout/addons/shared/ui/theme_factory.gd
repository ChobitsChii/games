class_name ThemeFactory
extends RefCounted
## Baut ein modernes UI-Theme (abgerundet, Glow bei Hover) aus einer Farbpalette.
##
## Pflicht-Schlüssel der Palette: accent, accent_alt, panel, text, text_dim.


static func build(palette: Dictionary) -> Theme:
	var accent: Color = palette["accent"]
	var accent_alt: Color = palette["accent_alt"]
	var panel: Color = palette["panel"]
	var text: Color = palette["text"]
	var text_dim: Color = palette["text_dim"]

	var theme := Theme.new()
	theme.default_font_size = 34

	theme.set_color("font_color", "Label", text)

	var normal := _box(Color(panel, 0.9), Color(accent, 0.45))
	var hover := _box(Color(accent, 0.22), accent, 2, 14, Color(accent, 0.55), 16)
	var pressed := _box(Color(accent, 0.4), accent_alt, 2, 14, Color(accent_alt, 0.5), 10)
	var disabled := _box(Color(panel, 0.5), Color(text_dim, 0.25))
	var focus := _box(Color(0, 0, 0, 0), accent_alt, 3)
	focus.draw_center = false

	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_color("font_color", "Button", text)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", text_dim)

	theme.set_stylebox("panel", "PanelContainer", _box(Color(panel, 0.96), Color(accent, 0.55), 2, 22, Color(0, 0, 0, 0.5), 24))
	return theme


static func _box(
		bg: Color,
		border: Color,
		border_width: int = 2,
		radius: int = 14,
		shadow: Color = Color(0, 0, 0, 0),
		shadow_size: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.shadow_color = shadow
	box.shadow_size = shadow_size
	box.content_margin_left = 28
	box.content_margin_right = 28
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	return box
