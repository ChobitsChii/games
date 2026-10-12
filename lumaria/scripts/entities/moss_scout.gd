class_name MossScout
extends EnemyBase
## Wald-Goblin Moos-Scout in Lumaria.
## Verfolgt den Spieler flink, setzt zum Dolchstich an und taumelt bei Treffern.

const DETECTION_RADIUS := 380.0
const ATTACK_RANGE := 52.0

var _step_phase: float = 0.0
var _attack_cooldown: float = 0.0
var _telegraph_timer: float = 0.0
var _is_telegraphing: bool = false
var _player: Player = null


func _init() -> void:
	max_health = 40
	current_health = 40
	speed = 160.0
	contact_damage = 1


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
		# Gelb/rotes Warnblinken vor dem Stich
		_sprite.modulate = Color(1.5, 0.4, 0.4) if fmod(_telegraph_timer, 0.1) < 0.05 else Color.WHITE
		if _telegraph_timer <= 0.0:
			_is_telegraphing = false
			_sprite.modulate = Color.WHITE
			_perform_lunge()
		move_and_slide()
		return

	if dist <= DETECTION_RADIUS:
		var dir := (_player.global_position - global_position).normalized()
		_sprite.flip_h = (dir.x < 0)

		if dist <= ATTACK_RANGE and _attack_cooldown <= 0.0:
			# Angriff telegrafieren (1.0s Telegraf laut Plan)
			_is_telegraphing = true
			_telegraph_timer = 0.45
			return

		velocity = dir * speed
		_step_phase += delta * 12.0
		_sprite.position.y = -36.0 + sin(_step_phase) * 4.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, delta * 200.0)

	move_and_slide()

	# Kontaktschaden prüfen
	for i in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = col.get_collider()
		if collider is Player:
			collider.take_hit(20, global_position)


func _perform_lunge() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var lunge_dir := (_player.global_position - global_position).normalized()
	velocity = lunge_dir * 320.0
	_attack_cooldown = 1.4
	AudioManager.play_sfx("slash", 1.2)

	# Wenn Spieler in Reichweite, Treffer registrieren
	if global_position.distance_to(_player.global_position) < 65.0:
		_player.take_hit(20, global_position)


func _find_player() -> void:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("player")
	if not nodes.is_empty() and nodes[0] is Player:
		_player = nodes[0] as Player
	elif get_parent().has_node("Player"):
		_player = get_parent().get_node("Player") as Player
