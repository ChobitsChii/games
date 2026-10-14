class_name BossMalakor
extends EnemyBase
## Der finale Endboss: Malakor, der Rissfürst.
## Beherrscher der Dimensionsrisse im Turm des Ewigen Prismas.
## 3 epische Phasen:
## - Phase 1: Schattenduelle (Teleport-Dash & Schwertduell mit Timing-Parry)
## - Phase 2: Kristallbarriere (3 Elementar-Orbs müssen mit Bumerang, Fangseil & Bombe gebrochen werden)
## - Phase 3: Kosmischer Riss-Souverän (Meteorsturm & finale Schwertkombos)
## Belohnung: Das vollendete Ewige Prisma & Rettung von Lumaria!

signal boss_defeated_signal()
signal phase_transition(phase: int)

enum BossPhase { SHADOW_DUEL = 1, PRISMATIC_SHATTER = 2, VOID_SOVEREIGN = 3, DYING = 4 }

const PROJECTILE_SCENE := preload("res://scenes/objects/thorn_projectile.tscn")
const REWARD_CHEST_SCENE := preload("res://scenes/objects/treasure_chest.tscn")

var phase: BossPhase = BossPhase.SHADOW_DUEL
var trial_state: TowerTrialState

var _state_timer: float = 2.0
var _player: Player = null
var _pulse_phase: float = 0.0
var _teleport_timer: float = 0.0


func _init() -> void:
	max_health = 360
	current_health = 360
	speed = 140.0
	contact_damage = 2
	knockback_resistance = 1.0


func _ready() -> void:
	super._ready()
	add_to_group("bosses")
	trial_state = TowerTrialState.new()


func _process_ai(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()

	_pulse_phase += delta * 3.5

	match phase:
		BossPhase.SHADOW_DUEL:
			_process_phase_1(delta)
			if current_health <= 240:
				_transition_to_phase(BossPhase.PRISMATIC_SHATTER)

		BossPhase.PRISMATIC_SHATTER:
			_process_phase_2(delta)
			if current_health <= 120 and trial_state.malakor_barrier_elements.is_empty():
				_transition_to_phase(BossPhase.VOID_SOVEREIGN)

		BossPhase.VOID_SOVEREIGN:
			_process_phase_3(delta)


func _process_phase_1(delta: float) -> void:
	# Teleport-Dash und Schwertangriff
	_teleport_timer += delta
	if _teleport_timer >= 2.2:
		_teleport_timer = 0.0
		_shadow_teleport_slash()
	else:
		if _player:
			velocity = (_player.global_position - global_position).normalized() * speed
		move_and_slide()


func _shadow_teleport_slash() -> void:
	if _player == null:
		return
	AudioManager.play_sfx("dash", 1.3)
	# Hinter den Spieler teleportieren
	var offset := -_player.facing_direction * 75.0
	global_position = _player.global_position + offset

	if _sprite:
		_sprite.modulate = Color(2.5, 0.4, 1.8)
		create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.3)

	# Schneller 360° Schwertschwung
	AudioManager.play_sfx("slash", 1.4)
	for i in range(4):
		var dir := Vector2.from_angle(i * PI * 0.5)
		_spawn_void_bolt(dir)


func _process_phase_2(delta: float) -> void:
	# Schwebt in der Mitte der Halle
	velocity = Vector2.ZERO
	if _sprite:
		_sprite.position.y = sin(_pulse_phase) * 8.0
		# Schild-Leuchten je nach verbleibenden Barrieren
		_sprite.modulate = Color(1.2, 0.8, 1.6)

	_state_timer -= delta
	if _state_timer <= 0.0:
		_state_timer = 1.8
		# Schießt zielsuchende Void-Projektile
		if _player:
			_spawn_void_bolt((_player.global_position - global_position).normalized())


func break_element(element: String) -> void:
	if phase != BossPhase.PRISMATIC_SHATTER:
		return
	if trial_state.break_barrier_element(element):
		AudioManager.play_sfx("break", 1.4)
		if trial_state.malakor_barrier_elements.is_empty():
			# Barriere komplett zusammengebrochen!
			current_health = mini(current_health, 120)
			_transition_to_phase(BossPhase.VOID_SOVEREIGN)


func _process_phase_3(delta: float) -> void:
	# Kosmischer Riss-Souverän: Höchste Aggressivität
	speed = 190.0
	if _player:
		velocity = (_player.global_position - global_position).normalized() * speed
	move_and_slide()

	_state_timer -= delta
	if _state_timer <= 0.0:
		_state_timer = 1.4
		# Meteor-Fächer
		var base_dir := (_player.global_position - global_position).normalized() if _player else Vector2.DOWN
		for i in range(5):
			var ang := base_dir.angle() - 0.6 + i * 0.3
			_spawn_void_bolt(Vector2.from_angle(ang))


func _spawn_void_bolt(dir: Vector2) -> void:
	var proj = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position + dir * 30.0
	proj.launch(dir, 290.0)


func _transition_to_phase(new_phase: BossPhase) -> void:
	phase = new_phase
	phase_transition.emit(int(phase))
	AudioManager.play_sfx("explosion", 1.2)
	AudioManager.play_sfx("parry", 1.6)

	if is_inside_tree():
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0] is Player:
			players[0].camera_shake_requested.emit(0.8)

	EventBus.show_toast_requested.emit(tr("BOSS_MALAKOR_NAME") + " - PHASE %d!" % int(phase))


func take_hit(damage: int, attacker_pos: Vector2, force: float = 340.0) -> void:
	if phase == BossPhase.DYING:
		return

	if phase == BossPhase.PRISMATIC_SHATTER and not trial_state.malakor_barrier_elements.is_empty():
		# Barriere ist aktiv: Schadensimmunität gegen Standard-Angriffe!
		AudioManager.play_sfx("parry", 1.7)
		super.take_hit(1, attacker_pos, 0.0)
		return

	super.take_hit(damage, attacker_pos, force * 0.2)


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	take_hit(amount, global_position - knockback, knockback.length())


func die() -> void:
	phase = BossPhase.DYING
	velocity = Vector2.ZERO
	AudioManager.play_sfx("explosion", 1.3)
	boss_defeated_signal.emit()
	EventBus.boss_defeated.emit("malakor")

	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "scale", Vector2(1.2, 1.2), 0.5)
		tw.parallel().tween_property(_sprite, "modulate", Color(3.0, 3.0, 3.0, 0.0), 0.8)
		tw.tween_callback(func() -> void:
			_spawn_eternal_prism_altar()
			queue_free()
		)
	else:
		_spawn_eternal_prism_altar()
		queue_free()


func _spawn_eternal_prism_altar() -> void:
	var chest := REWARD_CHEST_SCENE.instantiate()
	get_parent().add_child(chest)
	chest.global_position = global_position
	chest.chest_id = "chest_eternal_prism"
	chest.item_type = "eternal_prism"


func _find_player() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	var players := tree.get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Player:
		_player = players[0] as Player
