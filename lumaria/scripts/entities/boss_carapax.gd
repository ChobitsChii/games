class_name BossCarapax
extends EnemyBase
## Zweiter Dungeon-Boss: Carapax, der Kristall-Panzerkrabbler.
## Der Wächter der Klingen-Krypta.
## Mechanik:
## - Frontalpanzer: Immun gegen frontale Schwerthiebe.
## - Angriffe: Panzerscheren-Ansturm (Charge) und Gezeiten-Kristallstachel (Wellenfächer).
## - Schwachpunkt: Kinetisches Fangseil hakt sich im Panzer fest und wirft Carapax
##   auf den Rücken (Overturned Stun für 3.5s). In dieser Phase ist der weiche Bauch
##   für Schwertkombos vollkommen verwundbar!
## - Phase 2 (unter 50% HP): Enrage! Höhere Angriffsgeschwindigkeit und 5er-Projektilfächer.
## - Belohnung: Zweites Spektral-Prisma (Gezeiten-Prisma).

signal boss_defeated_signal()

enum BossState { IDLE, CHARGING, ATTACK_WAVE, OVERTURNED_STUN, RECOVERING, DYING }

const PROJECTILE_SCENE := preload("res://scenes/objects/thorn_projectile.tscn")
const REWARD_CHEST_SCENE := preload("res://scenes/objects/treasure_chest.tscn")

var boss_state: BossState = BossState.IDLE
var is_overturned: bool = false
var is_phase_2: bool = false

var _state_timer: float = 2.0
var _charge_target_pos: Vector2 = Vector2.ZERO
var _player: Player = null
var _wobble_phase: float = 0.0


func _init() -> void:
	max_health = 250
	current_health = 250
	speed = 60.0
	contact_damage = 1
	knockback_resistance = 1.0


func _ready() -> void:
	super._ready()
	add_to_group("bosses")


func _process_ai(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()

	_wobble_phase += delta * 3.0

	# Phase 2 Prüfung (unter 50% HP)
	if not is_phase_2 and current_health <= (max_health / 2):
		_enter_phase_2()

	_state_timer -= delta

	match boss_state:
		BossState.IDLE:
			_process_idle(delta)
			if _state_timer <= 0.0:
				_choose_next_attack()

		BossState.CHARGING:
			_process_charge(delta)

		BossState.ATTACK_WAVE:
			if _state_timer <= 0.0:
				boss_state = BossState.IDLE
				_state_timer = 1.2 if is_phase_2 else 1.8

		BossState.OVERTURNED_STUN:
			_process_overturned(delta)
			if _state_timer <= 0.0:
				_recover_from_stun()

		BossState.RECOVERING:
			if _state_timer <= 0.0:
				boss_state = BossState.IDLE
				_state_timer = 1.0


func _process_idle(delta: float) -> void:
	if _player and is_instance_valid(_player):
		var to_player := (_player.global_position - global_position).normalized()
		velocity = to_player * speed
		if _sprite:
			_sprite.scale = Vector2(0.55 + sin(_wobble_phase) * 0.02, 0.55 - sin(_wobble_phase) * 0.02)
			_sprite.rotation = sin(_wobble_phase) * 0.04
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _choose_next_attack() -> void:
	if _player == null:
		_state_timer = 1.0
		return

	if randf() < 0.6:
		_start_charge()
	else:
		_start_wave_attack()


func _start_charge() -> void:
	boss_state = BossState.CHARGING
	_charge_target_pos = _player.global_position
	var charge_speed := 340.0 if is_phase_2 else 270.0
	var dir := (_charge_target_pos - global_position).normalized()
	velocity = dir * charge_speed
	_state_timer = 1.4

	AudioManager.play_sfx("dash", 0.9)
	# Telegraph Sprite-Flash
	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate", Color(1.4, 1.2, 0.7), 0.2)
		tw.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.2)


func _process_charge(_delta: float) -> void:
	move_and_slide()
	if _state_timer <= 0.0:
		velocity = Vector2.ZERO
		boss_state = BossState.IDLE
		_state_timer = 1.4 if is_phase_2 else 2.0


func _start_wave_attack() -> void:
	boss_state = BossState.ATTACK_WAVE
	velocity = Vector2.ZERO
	_state_timer = 1.0

	AudioManager.play_sfx("slash", 0.8)
	var count: int = 5 if is_phase_2 else 3
	var base_dir := (_player.global_position - global_position).normalized() if _player else Vector2.DOWN
	var base_angle := base_dir.angle()
	var spread := PI * 0.45

	for i in range(count):
		var t := float(i) / float(count - 1) if count > 1 else 0.5
		var angle := base_angle - spread * 0.5 + spread * t
		var dir := Vector2.from_angle(angle)
		_spawn_wave_projectile(dir)


func _spawn_wave_projectile(dir: Vector2) -> void:
	var proj = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position + dir * 40.0
	proj.launch(dir, 290.0 if is_phase_2 else 230.0)


## Schwachpunkt-Treffer mit dem Kinetischen Fangseil
func tether_hook_hit() -> void:
	if boss_state == BossState.DYING:
		return

	# Fangseil wirft Carapax auf den Rücken!
	is_overturned = true
	boss_state = BossState.OVERTURNED_STUN
	_state_timer = 3.5
	velocity = Vector2.ZERO

	AudioManager.play_sfx("break", 1.2)
	AudioManager.play_sfx("hit", 1.5)

	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "rotation", PI, 0.35)
		tw.parallel().tween_property(_sprite, "modulate", Color(0.6, 1.4, 2.0), 0.35)


func _process_overturned(delta: float) -> void:
	# Hilfloses Strampeln auf dem Rücken
	if _sprite:
		_sprite.scale = Vector2(0.55 + sin(_wobble_phase * 4.0) * 0.04, 0.55 - sin(_wobble_phase * 4.0) * 0.04)


func _recover_from_stun() -> void:
	is_overturned = false
	boss_state = BossState.RECOVERING
	_state_timer = 0.8

	AudioManager.play_sfx("parry", 1.2)
	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "rotation", 0.0, 0.3)
		var base_col := Color(1.3, 0.8, 0.8) if is_phase_2 else Color(1.0, 1.0, 1.0)
		tw.parallel().tween_property(_sprite, "modulate", base_col, 0.3)


func _enter_phase_2() -> void:
	is_phase_2 = true
	speed = 95.0
	AudioManager.play_sfx("break", 1.4)
	EventBus.show_toast_requested.emit(tr("BOSS_CARAPAX_NAME") + " - ENRAGE!")
	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate", Color(1.4, 0.8, 0.8), 0.3)


## Modifizierte Schadensannahme mit Frontpanzerung
func take_hit(damage: int, attacker_pos: Vector2, force: float = 340.0) -> void:
	if boss_state == BossState.DYING:
		return

	var effective_damage: int = damage
	if not is_overturned:
		# Frontaler Panzer blockiert Schwerthiebe fast vollständig (85% Reduktion)
		effective_damage = maxi(1, int(damage * 0.15))
		AudioManager.play_sfx("parry", 1.6)
		super.take_hit(effective_damage, attacker_pos, force * 0.1)
	else:
		# Auf dem Rücken: Voller Schaden!
		AudioManager.play_sfx("hit", 1.1)
		super.take_hit(damage, attacker_pos, force * 0.3)


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	take_hit(amount, global_position - knockback, knockback.length())


func die() -> void:
	boss_state = BossState.DYING
	velocity = Vector2.ZERO
	AudioManager.play_sfx("explosion", 1.1)
	boss_defeated_signal.emit()
	EventBus.boss_defeated.emit("carapax")

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
	chest.chest_id = "chest_tide_prism"
	chest.item_type = "tide_prism"


func _find_player() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	var players := tree.get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Player:
		_player = players[0] as Player
