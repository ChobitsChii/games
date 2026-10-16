class_name BreakoutStyle
extends RefCounted
## Gemeinsame Schriften und das UI-Theme von Neon Breakout.
## Schrift: Rajdhani (SIL Open Font License), eingetragen in CREDITS.md.

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")
const FONT_BOLD: Font = preload("res://assets/fonts/Rajdhani-Bold.ttf")


## UI-Theme aus der Palette (ThemeFactory) mit der Spielschrift.
static func build_theme() -> Theme:
	var theme := ThemeFactory.build(BreakoutConfig.PALETTE)
	theme.default_font = FONT
	theme.default_font_size = 40
	return theme
