class_name EnemySkeleton
extends BaseEnemy
## Skelettkrieger: Nahkämpfer, läuft direkt auf den Spieler zu.

func _init() -> void:
	max_health = 4
	move_speed = 190.0
	souls_value = 1
	contact_damage = 1


func _draw() -> void:
	super._draw()
	# Knochen-Weiß / Antik
	draw_circle(Vector2.ZERO, 16.0, Color("e2e8f0"))
	draw_circle(Vector2(-5, -3), 3.5, Color("0f172a")) # Dunkle Augenhöhlen
	draw_circle(Vector2(5, -3), 3.5, Color("0f172a"))
	draw_line(Vector2(-5, 6), Vector2(5, 6), Color("0f172a"), 2.0) # Zähne
