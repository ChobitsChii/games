class_name BreakoutMath
extends RefCounted
## Reine Spiellogik ohne Nodes, daher leicht testbar.

const BASE_SPEED := 640.0
const LEVEL_SPEED_STEP := 40.0
const BRICK_SPEED_STEP := 3.0
const MAX_SPEED := 1100.0
## Maximaler Abprallwinkel am Schlägerrand, gemessen von der Senkrechten (60 Grad).
const MAX_BOUNCE_ANGLE := PI / 3.0
## Mindestanteil der vertikalen Geschwindigkeit, damit der Ball nie fast waagerecht fliegt.
const MIN_VERTICAL_RATIO := 0.25


## Neue Ballrichtung (Länge = speed) beim Treffer des Schlägers.
## Mitte: senkrecht nach oben, Rand: bis zu MAX_BOUNCE_ANGLE schräg.
static func paddle_bounce(ball_x: float, paddle_x: float, paddle_width: float, speed: float) -> Vector2:
	var offset := clampf((ball_x - paddle_x) / (paddle_width * 0.5), -1.0, 1.0)
	var angle := offset * MAX_BOUNCE_ANGLE
	return Vector2(sin(angle), -cos(angle)) * speed


## Ballgeschwindigkeit abhängig von Level und zerstörten Blöcken.
static func speed_for(level: int, bricks_destroyed: int) -> float:
	var speed := BASE_SPEED + (level - 1) * LEVEL_SPEED_STEP + bricks_destroyed * BRICK_SPEED_STEP
	return minf(speed, MAX_SPEED)


## Verhindert (fast) waagerechte Flugbahnen. Die Länge des Vektors bleibt erhalten.
static func enforce_min_vertical(velocity: Vector2, min_ratio: float = MIN_VERTICAL_RATIO) -> Vector2:
	var speed := velocity.length()
	if speed == 0.0:
		return velocity
	var min_y := speed * min_ratio
	if absf(velocity.y) >= min_y:
		return velocity
	var y := min_y * (signf(velocity.y) if velocity.y != 0.0 else -1.0)
	var x := signf(velocity.x) * sqrt(speed * speed - y * y)
	return Vector2(x, y)


static func brick_points(max_hp: int) -> int:
	return 10 * max_hp
