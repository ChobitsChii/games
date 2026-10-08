class_name LaneDefendersConfig
extends RefCounted
## Zentrale Konfiguration für Lane Defenders: Maße, Zeiten und Farbpalette.

const LANES := 5
const COLS := 9
const CELL_WIDTH := 140.0
const CELL_HEIGHT := 140.0
const GRID_ORIGIN := Vector2(260.0, 200.0)

const SPAWN_X := 1620.0
const BASE_X := 260.0

const INITIAL_ENERGY := 150
const INITIAL_LIVES := 3

const SKY_ENERGY_INTERVAL := 8.0
const SKY_ENERGY_AMOUNT := 25
const SKY_ENERGY_LIFETIME := 7.0

const PROJECTILE_SPEED := 550.0

const PALETTE := {
	"bg": Color("0c1a10"),
	"panel": Color("14281a"),
	"accent": Color("3ddc84"),
	"accent_alt": Color("ffd700"),
	"warn": Color("ff4d4d"),
	"text": Color("f4faf5"),
	"text_dim": Color("7fa689"),
	"grid_cell_even": Color(0.12, 0.24, 0.15, 0.75),
	"grid_cell_odd": Color(0.10, 0.21, 0.13, 0.75),
	"grid_cell_hover": Color(0.24, 0.55, 0.32, 0.4),
	"grid_cell_border": Color(0.18, 0.38, 0.22, 0.5),
}
