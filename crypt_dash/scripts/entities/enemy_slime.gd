class_name EnemySlime
extends BaseEnemy
## Schleim: Teilt sich beim Tod in zwei kleinere Schleime, falls split_level > 0.

@export var split_level: int = 1


func _init() -> void:
	max_health = 4
	move_speed = 120.0
	souls_value = 1
	contact_damage = 1


func _on_died() -> void:
	if split_level > 0:
		for offset in [Vector2(-20, 0), Vector2(20, 0)]:
			var mini_slime := EnemySlime.new()
			mini_slime.split_level = split_level - 1
			mini_slime.max_health = 2
			mini_slime.move_speed = 170.0
			mini_slime.global_position = global_position + offset
			get_parent().call_deferred("add_child", mini_slime)

	super._on_died()


func _draw() -> void:
	super._draw()
	var radius := 18.0 if split_level > 0 else 12.0
	# Leucht-Aura
	draw_circle(Vector2.ZERO, radius + 4.0, Color(0.5, 0.9, 0.1, 0.35))
	# Scharfe Outline
	draw_circle(Vector2.ZERO, radius + 1.5, Color("14532d"))
	# Giftiges Säure-Grün
	draw_circle(Vector2.ZERO, radius, Color("84cc16"))
	draw_circle(Vector2(0, -3), radius * 0.65, Color("bef264"))
	# Gelbe Augen
	draw_circle(Vector2(-4, -2), 3.5, Color("fef08a"))
	draw_circle(Vector2(4, -2), 3.5, Color("fef08a"))
	draw_circle(Vector2(-4, -2), 1.5, Color("1e293b"))
	draw_circle(Vector2(4, -2), 1.5, Color("1e293b"))
