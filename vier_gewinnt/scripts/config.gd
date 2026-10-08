class_name GameConfig
extends RefCounted
## Globale Konfiguration für Connect Four Deluxe: Farben, Maße, Layout.

const COLS := 7
const ROWS := 6

const PALETTE := {
	"bg": Color("0b0e17"),
	"panel": Color("131826"),
	"board_front": Color("1a4a8d"),
	"board_rim": Color("2563eb"),
	"board_back": Color("0d2547"),
	"accent": Color("38bdf8"),
	"accent_alt": Color("f59e0b"),
	"text": Color("f1f5f9"),
	"text_dim": Color("94a3b8"),
	"player1": Color("ef4444"), # Rot
	"player1_glow": Color("f87171"),
	"player2": Color("eab308"), # Gelb
	"player2_glow": Color("facc15"),
	"slot_empty": Color("070a12"),
	"slot_highlight": Color("1e293b", 0.6),
	"win_gold": Color("fbbf24"),
}

const DISC_RADIUS := 52.0
const CELL_SPACING := 124.0
const BOARD_WIDTH := CELL_SPACING * COLS + 40.0
const BOARD_HEIGHT := CELL_SPACING * ROWS + 40.0

const ANIM_DROP_DURATION := 0.42
const ANIM_BOUNCE := 0.12
