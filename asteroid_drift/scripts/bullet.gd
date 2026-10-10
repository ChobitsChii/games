class_name Bullet
extends Area2D
## Projektil für Spieler und Feinde mit Lebensdauer und Wrap-around.

@export var is_enemy: bool = false
@export var is_explosive: bool = false

var velocity := Vector2.ZERO
var lifetime := Constants.SHIP_BULLET_LIFETIME
var _age := 0.0

@onready var line_trail: Line2D = $LineTrail
@onready var glow_poly: Polygon2D = $GlowPoly


func _ready() -> void:
	monitoring = true
	monitorable = true
	# Setze Collision Masks passend
	if is_enemy:
		collision_layer = 1 << 4 # layer 5: enemy_bullets
		collision_mask = (1 << 0) # layer 1: player
		if glow_poly:
			glow_poly.color = Color(1.0, 0.25, 0.3, 0.95)
	else:
		collision_layer = 1 << 2 # layer 3: player_bullets
		collision_mask = (1 << 1) | (1 << 3) # layer 2: asteroids, layer 4: enemies
		if glow_poly:
			glow_poly.color = Color(0.1, 0.9, 1.0, 0.95)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	global_position += velocity * delta
	global_position = ScreenWrap.wrap_position(global_position, Constants.VIEWPORT_RECT)


func destroy() -> void:
	queue_free()
