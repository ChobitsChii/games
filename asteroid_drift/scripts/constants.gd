class_name Constants
extends RefCounted
## Zentrale Konstanten und Tuning-Werte für Asteroid Drift.

const VIEWPORT_WIDTH := 1920.0
const VIEWPORT_HEIGHT := 1080.0
const VIEWPORT_RECT := Rect2(0.0, 0.0, VIEWPORT_WIDTH, VIEWPORT_HEIGHT)

# Schiff-Parameter
const SHIP_THRUST := 600.0
const SHIP_DAMPING := 0.6
const SHIP_MAX_SPEED := 700.0
const SHIP_TURN_SPEED := 4.0 # Radiant pro Sekunde
const SHIP_FIRE_RATE := 0.25 # Sekunden zwischen Schüssen
const SHIP_BULLET_SPEED := 900.0
const SHIP_BULLET_LIFETIME := 1.0
const SHIP_INVULNERABILITY_TIME := 2.0
const SHIP_SAFE_SPAWN_RADIUS := 200.0
const SHIP_SHIELD_MAX_DEFAULT := 1.0
const SHIP_SHIELD_RECHARGE_DELAY := 4.0
const SHIP_SHIELD_RECHARGE_RATE := 0.5
const SHIP_HYPERSPACE_FAIL_CHANCE := 0.15

# Asteroiden-Parameter
enum AsteroidSize {
	LARGE,
	MEDIUM,
	SMALL
}

const ASTEROID_CONFIG := {
	AsteroidSize.LARGE: {
		"radius": 80.0,
		"score": 20,
		"splits_into": AsteroidSize.MEDIUM,
		"split_count": 2,
		"base_speed": 100.0,
	},
	AsteroidSize.MEDIUM: {
		"radius": 45.0,
		"score": 50,
		"splits_into": AsteroidSize.SMALL,
		"split_count": 2,
		"base_speed": 150.0,
	},
	AsteroidSize.SMALL: {
		"radius": 22.0,
		"score": 100,
		"splits_into": -1,
		"split_count": 0,
		"base_speed": 220.0,
	}
}

const ASTEROID_SPLIT_SPEED_FACTOR := 1.3
const ASTEROID_COLLISION_RADIUS_FACTOR := 0.85
const ASTEROID_MIN_VERTICES := 10
const ASTEROID_MAX_VERTICES := 14

# Wellen-Parameter
const WAVE_MIN_SPAWN_DIST := 300.0
const BASE_LARGE_ASTEROIDS := 3
const MAX_LARGE_ASTEROIDS := 12
const SPEED_FACTOR_PER_WAVE := 0.05

# Gegner-Parameter
const UFO_LARGE_SPEED := 130.0
const UFO_LARGE_HP := 3
const UFO_LARGE_SCORE := 200
const UFO_LARGE_FIRE_INTERVAL := 2.5

const UFO_SMALL_SPEED := 220.0
const UFO_SMALL_HP := 1
const UFO_SMALL_SCORE := 400
const UFO_SMALL_FIRE_INTERVAL := 1.8

const MINE_SPEED := 95.0
const MINE_HP := 2
const MINE_SCORE := 150
const MINE_TRIGGER_DIST := 140.0

# Farbpalette für Theme und Visuals
const PALETTE := {
	"accent": Color(0.0, 0.9, 1.0, 1.0),      # Cyan
	"accent_alt": Color(1.0, 0.45, 0.1, 1.0),  # Neon Orange
	"panel": Color(0.04, 0.07, 0.16, 0.95),   # Dunkles Space-Blau
	"text": Color(0.92, 0.96, 1.0, 1.0),      # Eisweiß
	"text_dim": Color(0.45, 0.55, 0.72, 1.0),  # Dimm-Blau
	"warning": Color(1.0, 0.2, 0.25, 1.0),    # Gefahr-Rot
	"success": Color(0.2, 0.9, 0.4, 1.0),     # Schild-Grün
}
