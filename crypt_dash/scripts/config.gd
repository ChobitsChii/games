class_name CryptDashConfig
extends RefCounted
## Konfiguration und Farbpalette für Crypt Dash.
## Modernes Farbschema: Dunkles Violett/Schiefer, leuchtendes Türkis/Cyan, warmes Fackel-Orange.

const PALETTE := {
	"background": Color("070a14"),     # Tiefes Krypta-Dunkelblau
	"panel": Color("0e1626"),          # Dunkles Schiefer-Panel
	"panel_border": Color("1e293b"),   # Subtiler Rand
	"primary": Color("06b6d4"),        # Leuchtendes Cyan (Dash / Mana)
	"primary_hover": Color("22d3ee"),
	"primary_pressed": Color("0891b2"),
	"accent": Color("f97316"),         # Warmes Fackel-Orange
	"accent_secondary": Color("8b5cf6"),# Mystisches Violett
	"text": Color("f8fafc"),           # Fast weiß für perfekte Lesbarkeit
	"text_muted": Color("94a3b8"),     # Gedämpftes Grau
	"focus": Color("38bdf8"),
	"health": Color("ef4444"),         # Rubinrot für Leben
	"shield": Color("3b82f6"),         # Schildblau
	"souls": Color("a855f7"),          # Seelen-Lila
}

const TILE_SIZE := 64
const ROOM_WIDTH_TILES := 20
const ROOM_HEIGHT_TILES := 11
const ROOM_PIXEL_WIDTH := ROOM_WIDTH_TILES * TILE_SIZE   # 1280
const ROOM_PIXEL_HEIGHT := ROOM_HEIGHT_TILES * TILE_SIZE # 704
