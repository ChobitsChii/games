class_name EnemySlime
extends BaseEnemy
## Schleim: Teilt sich beim Tod in zwei kleinere Schleime, falls split_level > 0.

@export var split_level: int = 1


func _init() -> void:
	max_health = 4
	move_speed = 120.0
	souls_value = 1
	contact_damage = 1


func get_sprite_path() -> String:
	return "res://assets/sprites/enemy_slime.png"


func get_sprite_size() -> float:
	return 64.0 if split_level > 0 else 44.0


func get_death_color() -> Color:
	return Color("84cc16")


func get_bounce_strength() -> float:
	return 1.45


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
