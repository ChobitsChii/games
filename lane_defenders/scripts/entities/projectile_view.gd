class_name ProjectileView
extends Node2D
## Grafische Darstellung eines Projektils.

var projectile: GameModel.SimProjectile


func setup(p_proj: GameModel.SimProjectile) -> void:
	projectile = p_proj
	queue_redraw()


func _draw() -> void:
	if projectile == null:
		return

	if projectile.is_area:
		# Große violette Mörserbombe
		draw_circle(Vector2.ZERO, 16.0, Color("ab47bc"))
		draw_circle(Vector2.ZERO, 10.0, Color("e1bee7"))
	elif projectile.slow_duration > 0.0:
		# Eis-Geschoss
		draw_circle(Vector2.ZERO, 12.0, Color("80d8ff"))
		draw_circle(Vector2.ZERO, 8.0, Color.WHITE)
	else:
		# Standard-Erbsenschuss / Energiebolzen
		draw_circle(Vector2.ZERO, 11.0, projectile.color)
		draw_circle(Vector2.ZERO, 6.0, Color.WHITE)
