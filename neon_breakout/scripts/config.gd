class_name BreakoutConfig
extends RefCounted
## Zentrale Konstanten: Spielfeld und Farbpalette.

## Spielfeld in Viewport-Koordinaten (1920x1080). Unten ist es offen.
const FIELD := Rect2(360, 120, 1200, 960)

const BRICK_COLUMNS := 10

## Farbpalette (wird auch für das UI-Theme verwendet).
const PALETTE := {
	"bg": Color("0a0b1a"),
	"panel": Color("151836"),
	"accent": Color("00e5ff"),
	"accent_alt": Color("ff2bd6"),
	"warn": Color("ffd23f"),
	"text": Color("e8ecff"),
	"text_dim": Color("8b93c9"),
}

## Blockfarben nach Trefferpunkten.
const BRICK_COLORS := {
	1: Color("27c7ff"),
	2: Color("9b5cff"),
	3: Color("ff2bd6"),
}
const BRICK_COLOR_UNBREAKABLE := Color("5a6296")
