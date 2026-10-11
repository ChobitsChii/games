class_name Projectile
extends Area2D
## Universelles Projektil für Spieler und Gegner.

@export var speed: float = 650.0
@export var damage: int = 1
@export var is_player: bool = true
@export var pierce: bool = false
@export var life_time: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0
var _hitbox: HitboxComponent


func _ready() -> void:
	z_index = 12
	collision_layer = 0
	collision_mask = 1 # Wände (Layer 1)
	body_entered.connect(_on_body_entered)

	_hitbox = HitboxComponent.new()
	_hitbox.damage = damage
	_hitbox.is_player = is_player
	_hitbox.source_node = self
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	_hitbox.add_child(shape)
	add_child(_hitbox)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_time_alive += delta
	if _time_alive >= life_time:
		queue_free()


func _draw() -> void:
	var color := Color("22d3ee") if is_player else Color("f87171")
	# Stylischer Leucht-Glow und Kern
	draw_circle(Vector2.ZERO, 9.0, Color(color.r, color.g, color.b, 0.35))
	draw_circle(Vector2.ZERO, 6.0, color)
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)


func _on_body_entered(_body: Node2D) -> void:
	# Wand getroffen
	queue_free()
