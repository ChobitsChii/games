class_name BaseEnemy
extends CharacterBody2D
## Gemeinsame Basisklasse für alle Gegner in Crypt Dash.
## Zustandsautomat: IDLE -> CHASE -> ATTACK -> STUNNED -> DEAD

enum State {
	IDLE,
	CHASE,
	ATTACK,
	STUNNED,
	DEAD,
}

@export var max_health: int = 4
@export var move_speed: float = 160.0
@export var souls_value: int = 1
@export var contact_damage: int = 1

var state: State = State.IDLE
var player: Player
var current_health: int = 4

var _health: HealthComponent
var _hurtbox: HurtboxComponent
var _hitbox: HitboxComponent
var _attack_timer: float = 0.0


func _ready() -> void:
	z_index = 5
	collision_layer = 8 # Gegner (Layer 4)
	collision_mask = 1 | 8 # Wände + andere Gegner

	_health = HealthComponent.new()
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	add_child(_health)
	_health.init_health(max_health)
	current_health = max_health

	_hurtbox = HurtboxComponent.new()
	_hurtbox.is_player = false
	_hurtbox.hit_received.connect(_on_hit_received)
	var h_shape := CollisionShape2D.new()
	var h_circle := CircleShape2D.new()
	h_circle.radius = 18.0
	h_shape.shape = h_circle
	_hurtbox.add_child(h_shape)
	add_child(_hurtbox)

	_hitbox = HitboxComponent.new()
	_hitbox.is_player = false
	_hitbox.damage = contact_damage
	_hitbox.source_node = self
	var hit_shape := CollisionShape2D.new()
	var hit_circle := CircleShape2D.new()
	hit_circle.radius = 18.0
	hit_shape.shape = hit_circle
	_hitbox.add_child(hit_shape)
	add_child(_hitbox)

	var body_col := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 18.0
	body_col.shape = body_circle
	add_child(body_col)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if player == null or not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player = players[0]

	_update_ai(delta)
	queue_redraw()


func _update_ai(delta: float) -> void:
	if player == null:
		return

	var dist := global_position.distance_to(player.global_position)
	var dir := (player.global_position - global_position).normalized()

	match state:
		State.IDLE:
			if dist < 600.0:
				state = State.CHASE
		State.CHASE:
			velocity = dir * move_speed
			move_and_slide()
			if dist < 45.0:
				state = State.ATTACK
				_attack_timer = 0.5
		State.ATTACK:
			velocity = Vector2.ZERO
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				state = State.CHASE
		State.STUNNED:
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				state = State.CHASE


func _on_hit_received(dmg: int, knockback: Vector2, _from_player: bool) -> void:
	if state == State.DEAD:
		return
	_health.take_damage(dmg)
	if state == State.DEAD:
		return
	velocity += knockback
	EventBus.enemy_damaged.emit(self, dmg)


func _on_health_changed(c: int, _m: int) -> void:
	current_health = c


func _on_died() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if _hurtbox != null and is_instance_valid(_hurtbox):
		_hurtbox.set_deferred("monitoring", false)
		_hurtbox.set_deferred("monitorable", false)
	if _hitbox != null and is_instance_valid(_hitbox):
		_hitbox.set_deferred("monitoring", false)
		_hitbox.set_deferred("monitorable", false)
	EventBus.enemy_died.emit(self, souls_value)
	queue_free()


func _draw() -> void:
	# Basis-Schatten
	draw_circle(Vector2(0, 6), 16.0, Color(0, 0, 0, 0.3))
