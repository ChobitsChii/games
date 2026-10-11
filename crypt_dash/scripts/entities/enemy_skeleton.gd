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
	# Scharfer Schatten & Outline
	draw_circle(Vector2.ZERO, 19.0, Color("0f172a"))
	# Knochen-Weiß
	draw_circle(Vector2.ZERO, 17.0, Color("f1f5f9"))
	# Rote glühende Augen
	draw_circle(Vector2(-5, -2), 4.0, Color("ef4444"))
	draw_circle(Vector2(5, -2), 4.0, Color("ef4444"))
	draw_circle(Vector2(-5, -2), 1.5, Color.WHITE)
	draw_circle(Vector2(5, -2), 1.5, Color.WHITE)
	# Kiefer / Zähne
	draw_rect(Rect2(-6, 5, 12, 4), Color("334155"))
