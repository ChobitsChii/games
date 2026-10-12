class_name ThornSpitter
extends EnemyBase
## Standhafter Dornen-Spucker in Lumaria.
## Verschießt in regelmäßigen Abständen giftige Dornen auf Kaelen.

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/objects/thorn_projectile.tscn")
const SHOOT_INTERVAL := 2.4
const SIGHT_RADIUS := 450.0

var _shoot_timer: float = 1.0
var _pulse_phase: float = 0.0
var _player: Player = null


func _init() -> void:
	max_health = 30
	current_health = 30
	speed = 0.0
	contact_damage = 1
	knockback_resistance = 0.8


func _ready() -> void:
	super._ready()


func _process_ai(delta: float) -> void:
	_pulse_phase += delta * 3.2
	if _sprite != null:
		_sprite.scale = Vector2(0.36 + sin(_pulse_phase) * 0.02, 0.36 - sin(_pulse_phase) * 0.02)

	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = SHOOT_INTERVAL
		_shoot_at_player()


func _shoot_at_player() -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		if _player == null:
			return

	var dist: float = global_position.distance_to(_player.global_position)
	if dist > SIGHT_RADIUS:
		return

	var dir: Vector2 = (_player.global_position - global_position).normalized()
	var proj: ThornProjectile = PROJECTILE_SCENE.instantiate()
	proj.global_position = global_position + dir * 28.0
	proj.launch(dir)
	get_parent().add_child(proj)
	AudioManager.play_sfx("slash", 1.4)


func _find_player() -> void:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("player")
	if not nodes.is_empty() and nodes[0] is Player:
		_player = nodes[0] as Player
	elif get_parent().has_node("Player"):
		_player = get_parent().get_node("Player") as Player
