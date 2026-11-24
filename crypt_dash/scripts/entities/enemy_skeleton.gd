class_name EnemySkeleton
extends BaseEnemy
## Skelettkrieger: Nahkämpfer, läuft direkt auf den Spieler zu.

func _init() -> void:
	max_health = 4
	move_speed = 190.0
	souls_value = 1
	contact_damage = 1


func get_sprite_path() -> String:
	return "res://assets/sprites/enemy_skeleton.png"


func get_sprite_size() -> float:
	return 66.0


func get_death_color() -> Color:
	return Color("e2e8f0")
