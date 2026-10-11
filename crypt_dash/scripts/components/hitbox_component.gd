class_name HitboxComponent
extends Area2D
## Hitbox, die Schaden an Hurtboxes austeilt.

signal hit_landed(target: Node2D)

@export var damage: int = 1
@export var is_player: bool = false
@export var knockback_force: float = 250.0

var source_node: Node2D


func _init() -> void:
	collision_layer = 4  # Layer 3: Hitboxes
	collision_mask = 0
