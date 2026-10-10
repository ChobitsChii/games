class_name Asteroid
extends Area2D
## Prozeduraler Asteroid mit Vektor-Optik, Physik-Drift und Zerfall.

signal destroyed(asteroid: Asteroid, split_data: Array[Dictionary], score: int)

@export var size: Constants.AsteroidSize = Constants.AsteroidSize.LARGE

var velocity := Vector2.ZERO
var spin_speed := 0.0
var radius := 80.0
var score_value := 20
var max_hp := 1
var hp := 1

@onready var poly: Polygon2D = $Polygon2D
@onready var outline: Line2D = $Line2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 1 << 1 # layer 2: asteroids
	collision_mask = (1 << 0) | (1 << 2) # layer 1: player, layer 3: player_bullets

	area_entered.connect(_on_area_entered)


func setup(
		new_size: Constants.AsteroidSize,
		start_pos: Vector2,
		start_vel: Vector2,
		rng: RandomNumberGenerator) -> void:
	size = new_size
	global_position = start_pos
	velocity = start_vel
	spin_speed = rng.randf_range(-1.5, 1.5)

	var cfg: Dictionary = Constants.ASTEROID_CONFIG.get(size, {})
	radius = float(cfg.get("radius", 80.0))
	score_value = int(cfg.get("score", 20))

	# HP: Groß = 2 Treffer (macht größere Asteroiden widerstandsfähiger!), Mittel = 1, Klein = 1
	max_hp = 2 if size == Constants.AsteroidSize.LARGE else 1
	hp = max_hp

	_build_visuals(rng)


func _build_visuals(rng: RandomNumberGenerator) -> void:
	var vertex_count: int = rng.randi_range(Constants.ASTEROID_MIN_VERTICES, Constants.ASTEROID_MAX_VERTICES)
	var pts := AsteroidMath.generate_polygon(radius, vertex_count, rng)

	if poly:
		poly.polygon = pts
		# Farbnuance je nach Größe
		match size:
			Constants.AsteroidSize.LARGE:
				poly.color = Color(0.08, 0.12, 0.22, 0.95)
			Constants.AsteroidSize.MEDIUM:
				poly.color = Color(0.07, 0.15, 0.26, 0.95)
			Constants.AsteroidSize.SMALL:
				poly.color = Color(0.06, 0.18, 0.30, 0.95)

	if outline:
		var loop := pts.duplicate()
		loop.append(pts[0])
		outline.points = loop
		outline.width = 3.0 if size == Constants.AsteroidSize.LARGE else 2.0
		outline.default_color = Color(0.2, 0.75, 1.0, 0.9)

	if collision_shape:
		var circle := CircleShape2D.new()
		circle.radius = AsteroidMath.get_collision_radius(radius)
		collision_shape.shape = circle


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	rotation += spin_speed * delta
	global_position = ScreenWrap.wrap_position(global_position, Constants.VIEWPORT_RECT)


func take_hit(damage: int, rng: RandomNumberGenerator) -> void:
	hp -= damage
	# Flash-Effekt
	var orig_color: Color = outline.default_color
	outline.default_color = Color(1.0, 1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(outline, "default_color", orig_color, 0.1)

	if hp <= 0:
		var splits := AsteroidMath.split_asteroid(size, global_position, velocity, rng)
		destroyed.emit(self, splits, score_value)
		queue_free()


func _on_area_entered(other: Area2D) -> void:
	if other is Bullet and not other.is_enemy:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		take_hit(1, rng)
		other.destroy()
