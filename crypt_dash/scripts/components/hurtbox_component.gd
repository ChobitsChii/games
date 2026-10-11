class_name HurtboxComponent
extends Area2D
## Hurtbox, die Treffer von Hitboxes registriert.

signal hit_received(damage: int, knockback: Vector2, from_player: bool)

@export var is_player: bool = false
var invulnerable: bool = false


func _init() -> void:
	collision_layer = 0
	collision_mask = 4 # Hört auf Hitboxes (Layer 3)


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if invulnerable:
		return
	if area is HitboxComponent:
		var hitbox: HitboxComponent = area
		# Kein Friendly Fire (Spieler trifft nicht Spieler, Gegner nicht Gegner)
		if hitbox.is_player == is_player:
			return

		var knock_dir := Vector2.ZERO
		if hitbox.source_node != null and is_instance_valid(hitbox.source_node):
			knock_dir = (global_position - hitbox.source_node.global_position).normalized()
		elif hitbox != null:
			knock_dir = (global_position - hitbox.global_position).normalized()

		var knockback: Vector2 = knock_dir * hitbox.knockback_force
		hitbox.hit_landed.emit(self)
		hit_received.emit(hitbox.damage, knockback, hitbox.is_player)
