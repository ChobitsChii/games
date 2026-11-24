class_name EnemyGhost
extends BaseEnemy
## Geist: Schwebt durch Wände (keine Wandkollision), pulsiert mystisch.

var _hover_phase: float = 0.0


func _init() -> void:
	max_health = 3
	move_speed = 130.0
	souls_value = 2
	contact_damage = 1


func _ready() -> void:
	super._ready()
	collision_mask = 0
	if _visual != null:
		_visual.set_tint(Color(1.0, 1.0, 1.0, 0.84))


func get_sprite_path() -> String:
	return "res://assets/sprites/enemy_ghost.png"


func get_sprite_size() -> float:
	return 66.0


func get_death_color() -> Color:
	return Color("5eead4")


func get_hover_amplitude() -> float:
	return 5.5


func get_bounce_strength() -> float:
	return 0.2


func _physics_process(delta: float) -> void:
	_hover_phase += delta * 4.0
	super._physics_process(delta)
	if _visual != null:
		var pulse := 0.72 + sin(_hover_phase) * 0.14
		_visual.set_tint(Color(1.0, 1.0, 1.0, pulse))
