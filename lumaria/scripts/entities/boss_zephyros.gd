class_name BossZephyros
extends EnemyBase
## Dritter Dungeon-Boss: Zephyros, die Sturmkrone.
## Der titanische Himmels-Raubvogel-Golem in der Sturm-Bastion.
## Mechanik:
## - Windschild: Im Flug durch einen Wirbelsturm vor Schwerthieben geschützt.
## - Angriffe: Rasierfeder-Fächer, Sturmböen-Schub und Sturzflug-Attacke.
## - Schwachpunkt: Eine detonierende Schall-Bombe bringt die Luftströme zum
##   Kollabieren und lässt Zephyros für 4.0 Sekunden auf den Boden stürzen!
## - Phase 2 (unter 50% HP): Tempest-Enrage! Schnellere Flugphasen und doppelte Federfächer.
## - Belohnung: Drittes Spektral-Prisma (Sturm-Prisma).

signal boss_defeated_signal()

enum BossState { FLYING_IDLE, DIVE_BOMB, FEATHER_BARRAGE, GROUNDED_STUN, RECOVERING, DYING }

const PROJECTILE_SCENE := preload("res://scenes/objects/thorn_projectile.tscn")
const REWARD_CHEST_SCENE := preload("res://scenes/objects/treasure_chest.tscn")

var boss_state: BossState = BossState.FLYING_IDLE
var is_grounded: bool = false
var is_phase_2: bool = false

var _state_timer: float = 2.0
var _player: Player = null
var _hover_phase: float = 0.0
var _dive_target: Vector2 = Vector2.ZERO


func _init() -> void:
	max_health = 300
	current_health = 300
	speed = 85.0
	contact_damage = 1
	knockback_resistance = 1.0


func _ready() -> void:
	super._ready()
	add_to_group("bosses")


func _process_ai(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()

	_hover_phase += delta * 4.0

	# Phase 2 Prüfung
	if not is_phase_2 and current_health <= (max_health / 2):
		_enter_phase_2()

	_state_timer -= delta

	match boss_state:
		BossState.FLYING_IDLE:
			_process_flying(delta)
			if _state_timer <= 0.0:
				_choose_next_attack()

		BossState.FEATHER_BARRAGE:
			if _state_timer <= 0.0:
				boss_state = BossState.FLYING_IDLE
				_state_timer = 1.5 if is_phase_2 else 2.2

		BossState.DIVE_BOMB:
			_process_dive(delta)

		BossState.GROUNDED_STUN:
			_process_grounded(delta)
			if _state_timer <= 0.0:
				_take_off_again()

		BossState.RECOVERING:
			if _state_timer <= 0.0:
				boss_state = BossState.FLYING_IDLE
				_state_timer = 1.2


func _process_flying(delta: float) -> void:
	if _player and is_instance_valid(_player):
		var to_player := (_player.global_position - global_position).normalized()
		velocity = to_player * speed
		if _sprite:
			_sprite.scale = Vector2(0.55 + sin(_hover_phase) * 0.03, 0.55 - sin(_hover_phase) * 0.03)
			_sprite.rotation = sin(_hover_phase * 0.5) * 0.06
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _choose_next_attack() -> void:
	if _player == null:
		_state_timer = 1.0
		return

	if randf() < 0.5:
		_start_feather_barrage()
	else:
		_start_dive_bomb()


func _start_feather_barrage() -> void:
	boss_state = BossState.FEATHER_BARRAGE
	velocity = Vector2.ZERO
	_state_timer = 1.0
	AudioManager.play_sfx("slash", 1.2)

	var count: int = 6 if is_phase_2 else 4
	var base_dir := (_player.global_position - global_position).normalized() if _player else Vector2.DOWN
	var base_angle := base_dir.angle()
	var spread := PI * 0.5

	for i in range(count):
		var t := float(i) / float(count - 1) if count > 1 else 0.5
		var angle := base_angle - spread * 0.5 + spread * t
		var dir := Vector2.from_angle(angle)
		_spawn_feather_projectile(dir)


func _spawn_feather_projectile(dir: Vector2) -> void:
	var proj = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position + dir * 35.0
	proj.launch(dir, 320.0 if is_phase_2 else 250.0)


func _start_dive_bomb() -> void:
	boss_state = BossState.DIVE_BOMB
	_dive_target = _player.global_position if _player else global_position + Vector2.DOWN * 200.0
	var dir := (_dive_target - global_position).normalized()
	velocity = dir * (420.0 if is_phase_2 else 320.0)
	_state_timer = 1.2
	AudioManager.play_sfx("dash", 0.8)


func _process_dive(_delta: float) -> void:
	move_and_slide()
	if _state_timer <= 0.0 or global_position.distance_squared_to(_dive_target) < 900.0:
		velocity = Vector2.ZERO
		boss_state = BossState.FLYING_IDLE
		_state_timer = 1.5


## Schwachpunkt: Treffer mit Schall-Bombe lässt Zephyros abstürzen
func bomb_blast_hit() -> void:
	if boss_state == BossState.DYING:
		return

	is_grounded = true
	boss_state = BossState.GROUNDED_STUN
	_state_timer = 4.0
	velocity = Vector2.ZERO

	AudioManager.play_sfx("break", 1.3)
	AudioManager.play_sfx("explosion", 0.9)

	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "position:y", 25.0, 0.25)
		tw.parallel().tween_property(_sprite, "modulate", Color(0.6, 1.4, 0.8), 0.25)


func _process_grounded(_delta: float) -> void:
	if _sprite:
		_sprite.scale = Vector2(0.55 + sin(_hover_phase * 3.0) * 0.02, 0.45)


func _take_off_again() -> void:
	is_grounded = false
	boss_state = BossState.RECOVERING
	_state_timer = 0.8
	AudioManager.play_sfx("dash", 1.2)

	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "position:y", 0.0, 0.3)
		var base_col := Color(1.3, 0.9, 0.6) if is_phase_2 else Color.WHITE
		tw.parallel().tween_property(_sprite, "modulate", base_col, 0.3)


func _enter_phase_2() -> void:
	is_phase_2 = true
	speed = 120.0
	AudioManager.play_sfx("break", 1.4)
	EventBus.show_toast_requested.emit(tr("BOSS_ZEPHYROS_NAME") + " - ENRAGE!")
	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate", Color(1.4, 1.1, 0.6), 0.3)


func take_hit(damage: int, attacker_pos: Vector2, force: float = 340.0) -> void:
	if boss_state == BossState.DYING:
		return

	var effective_damage: int = damage
	if not is_grounded:
		# Im Flug prallen Hiebe am Windschild ab (90% Schadensreduktion)
		effective_damage = maxi(1, int(damage * 0.10))
		AudioManager.play_sfx("parry", 1.5)
		super.take_hit(effective_damage, attacker_pos, force * 0.1)
	else:
		# Am Boden nach Bombe: Voller Schaden!
		AudioManager.play_sfx("hit", 1.1)
		super.take_hit(damage, attacker_pos, force * 0.2)


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	take_hit(amount, global_position - knockback, knockback.length())


func die() -> void:
	boss_state = BossState.DYING
	velocity = Vector2.ZERO
	AudioManager.play_sfx("explosion", 1.2)
	boss_defeated_signal.emit()
	EventBus.boss_defeated.emit("zephyros")

	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "scale", Vector2(0.7, 0.7), 0.4)
		tw.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.6)
		tw.tween_callback(func() -> void:
			_spawn_reward_chest()
			queue_free()
		)
	else:
		_spawn_reward_chest()
		queue_free()


func _spawn_reward_chest() -> void:
	var chest := REWARD_CHEST_SCENE.instantiate()
	get_parent().add_child(chest)
	chest.global_position = global_position
	chest.chest_id = "chest_storm_prism"
	chest.item_type = "storm_prism"


func _find_player() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	var players := tree.get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Player:
		_player = players[0] as Player
