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
	# Geister ignorieren Wände
	collision_mask = 0


func _physics_process(delta: float) -> void:
	_hover_phase += delta * 4.0
	super._physics_process(delta)


func _draw() -> void:
	# Leicht transparenter geisterhafter Cyan-Schein
	var pulse: float = sin(_hover_phase) * 0.15 + 0.65
	draw_circle(Vector2.ZERO, 20.0, Color(0.2, 0.9, 0.8, pulse * 0.4))
	draw_circle(Vector2.ZERO, 15.0, Color(0.5, 1.0, 0.9, pulse))
	draw_circle(Vector2(-4, -2), 3.0, Color("0f172a"))
	draw_circle(Vector2(4, -2), 3.0, Color("0f172a"))
