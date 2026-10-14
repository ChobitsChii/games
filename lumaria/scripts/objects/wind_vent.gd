class_name WindVent
extends Area2D
## Winddüse / Turbine in der Sturm-Bastion.
## Bläst starke Aufwinde in eine definierte Richtung (UP, DOWN, LEFT, RIGHT),
## die den Spieler tragen oder Schall-Bomben über Abgründe wehen.

@export var blow_direction: Vector2 = Vector2.UP
@export var wind_force: float = 320.0
@export var is_active: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _rotation_speed: float = 8.0


func _ready() -> void:
	add_to_group("wind_vents")


func _physics_process(delta: float) -> void:
	if not is_active:
		return

	# Turbinen-Rotor dreht sich
	if sprite:
		sprite.rotation += delta * _rotation_speed

	# Schiebe alle überlappenden Körper in Windrichtung
	for body in get_overlapping_bodies():
		if body is CharacterBody2D:
			body.velocity += blow_direction.normalized() * (wind_force * delta * 15.0)
		elif body.has_method("apply_wind_force"):
			body.apply_wind_force(blow_direction.normalized() * wind_force * delta)


func set_vent_active(active: bool) -> void:
	is_active = active
	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0) if active else Color(0.5, 0.5, 0.6, 0.4)
