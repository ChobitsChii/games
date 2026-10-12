class_name BoneWarrior
extends EnemyBase
## Antiker Knochen-Krieger in Lumaria.
## Gepanzertes Skelett mit Schild und Klinge.
## Blockt frontale Angriffe ab, solange er nicht durch den Prisma-Bumerang betäubt ist!

const DETECTION_RADIUS := 340.0
const ATTACK_RANGE := 58.0

var _step_phase: float = 0.0
var _attack_cooldown: float = 0.0
var _telegraph_timer: float = 0.0
var _is_telegraphing: bool = false
var _player: Player = null


func _init() -> void:
	max_health = 50
	current_health = 50
	speed = 110.0
	contact_damage = 1
	knockback_resistance = 0.5


func _ready() -> void:
	super._ready()


func _process_ai(delta: float) -> void:
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta

	if _player == null or not is_instance_valid(_player):
		_find_player()
		velocity = velocity.move_toward(Vector2.ZERO, delta * 300.0)
		move_and_slide()
		return

	var dist: float = global_position.distance_to(_player.global_position)

	if _is_telegraphing:
		_telegraph_timer -= delta
		velocity = Vector2.ZERO
		if _sprite != null:
			_sprite.modulate = Color(1.8, 0.5, 0.2) if fmod(_telegraph_timer, 0.1) < 0.05 else Color.WHITE
		if _telegraph_timer <= 0.0:
			_is_telegraphing = false
			if _sprite != null:
				_sprite.modulate = Color.WHITE
			_perform_heavy_slash()
		move_and_slide()
		return

	if dist <= DETECTION_RADIUS:
		var dir := (_player.global_position - global_position).normalized()
		facing_direction = dir
		if _sprite != null:
			_sprite.flip_h = (dir.x < 0)

		if dist <= ATTACK_RANGE and _attack_cooldown <= 0.0:
			_is_telegraphing = true
			_telegraph_timer = 0.5
			return

		velocity = dir * speed
		_step_phase += delta * 9.0
		if _sprite != null:
			_sprite.position.y = -36.0 + sin(_step_phase) * 3.5
	else:
		velocity = velocity.move_toward(Vector2.ZERO, delta * 200.0)

	move_and_slide()

	for i in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = col.get_collider()
		if collider is Player:
			collider.take_hit(20, global_position)


func take_hit(damage: int, attacker_pos: Vector2, force: float = 340.0) -> void:
	# Schildblock-Logik: Wenn nicht betäubt und Treffer von vorne kommt, Blocken!
	if not is_stunned and current_health > 0:
		var hit_dir: Vector2 = (attacker_pos - global_position).normalized()
		# Wenn Spieler vor dem Skelett steht (Dot-Produkt positiv):
		if facing_direction.dot(hit_dir) > 0.2:
			AudioManager.play_sfx("parry", 1.1)
			# Schild reflektiert Großteil des Schadens
			if _sprite != null:
				var tween := create_tween()
				if tween:
					tween.tween_property(_sprite, "modulate", Color(1.2, 1.2, 2.0), 0.08)
					tween.tween_property(_sprite, "modulate", Color.WHITE, 0.1)
			# Geringer Rückstoß
			velocity = CombatCalculator.calculate_knockback(attacker_pos, global_position, force * 0.4, 0.8)
			return

	super.take_hit(damage, attacker_pos, force)


func _perform_heavy_slash() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var lunge_dir := (_player.global_position - global_position).normalized()
	velocity = lunge_dir * 280.0
	_attack_cooldown = 1.6
	AudioManager.play_sfx("slash", 0.85)

	if global_position.distance_to(_player.global_position) < 70.0:
		_player.take_hit(25, global_position)


func _find_player() -> void:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("player")
	if not nodes.is_empty() and nodes[0] is Player:
		_player = nodes[0] as Player
	elif get_parent().has_node("Player"):
		_player = get_parent().get_node("Player") as Player
