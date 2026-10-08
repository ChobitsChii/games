class_name StackConfig
extends RefCounted
## Zentrale Konfiguration für Block Stack: Maße, Farben und Standardwerte.

const COLS := 10
const VISIBLE_ROWS := 20
const BUFFER_ROWS := 2
const TOTAL_ROWS := 22
const CELL_SIZE := 44.0

const PALETTE := {
	"bg": Color("080a18"),
	"panel": Color("111630"),
	"accent": Color("00e5ff"),
	"accent_alt": Color("ff007f"),
	"warn": Color("ffb300"),
	"text": Color("eef2ff"),
	"text_dim": Color("7f8bb8"),
}

const PIECE_COLORS := {
	"I": Color("00e5ff"),
	"J": Color("2979ff"),
	"L": Color("ff9100"),
	"O": Color("ffd600"),
	"S": Color("00e676"),
	"T": Color("d500f9"),
	"Z": Color("ff1744"),
	"GARBAGE": Color("808ca8"),
}

const DEFAULT_DAS := 0.17
const DEFAULT_ARR := 0.05
const DEFAULT_LOCK_DELAY := 0.5
const MAX_LOCK_RESETS := 15
