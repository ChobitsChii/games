class_name BossFloragorg
extends EnemyBase
## Erster Dungeon-Boss: Floragorg, der Urwald-Koloss.
## Ein riesiger antiker Natur-Titan im Wurzel-Schrein.
## Mechanik:
## - Phase 1: Ranken-Spikes aus dem Boden, Dornenfächer.
## - Verwundbarkeit: Der Prismentrom-Kern öffnet sich. Treffer mit dem
##   Prisma-Bumerang betäubt Floragorg und senkt den Kern in Schwertreichweite!
## - Phase 2 (unter 50% HP): Enrage! Schnellere Wurzel-Stöße & Minion-Spawns.
## - Belohnung: Erstes Spektral-Prisma (Sonnen-Prisma) & volle Vitalitäts-Sphäre.

signal boss_defeated_signal()

enum BossState { IDLE, ATTACK_SPIKES, ATTACK_THORNS, VULNERABLE, STUNNED, DYING }

const SPIKE_SCENE := preload("res://scenes/objects/root_spike.tscn")
const PROJECTILE_SCENE := preload("res://scenes/objects/thorn_projectile.tscn")
const SUN_PRISM_SCENE := preload("res://scenes/objects/treasure_chest.tscn")

var boss_state: BossState = BossState.IDLE
var is_phase_2: bool = false
var _state_timer: float = 2.0
var _pulse_phase: float = 0.0
var _player: Player = null

@onready var _core_hurtbox: Area2D = $CoreHurtbox
@onready var _core_glow: ColorRect = $CoreGlow


func _init() -> void:
	max_health = 200
	current_health = 200
	speed = 0.0
	contact_damage = 1
	knockback_resistance = 1.0


func _ready() -> void:
	super._ready()
	if _core_hurtbox:
		_core_hurtbox.area_entered.connect(_on_core_area_entered)
	if _core_glow:
		_core_glow.visible = false


func _process_ai(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()

	_pulse_phase += delta * 2.5
	if _sprite:
		_sprite.scale = Vector2(0.55 + sin(_pulse_phase) * 0.015, 0.55 - sin(_pulse_phase) * 0.015)

	# Phase 2 Prüfung (unter 50% HP)
	if not is_phase_2 and current_health <= (max_health / 2):
		_enter_phase_2()

	_state_timer -= delta
	if _state_timer <= 0.0:
		_advance_boss_state()


func _advance_boss_state() -> void:
	match boss_state:
		BossState.IDLE:
			# Abwechselnd Spikes oder Dornen
			if randf() < 0.55:
				_start_spikes()
			else:
				_start_thorns()

		BossState.ATTACK_SPIKES, BossState.ATTACK_THORNS:
			# Nach Angriff öffnet sich der verwundbare Kern!
			_open_vulnerable_core()

		BossState.VULNERABLE:
			# Zeitfenster verpasst: Kern schließt sich wieder
			_close_core()

		BossState.STUNNED:
			# Erholt sich aus dem Stun
			_recover_from_stun()


func _start_spikes() -> void:
	boss_state = BossState.ATTACK_SPIKES
	_state_timer = 1.2 if is_phase_2 else 1.6
	AudioManager.play_sfx("break", 0.9)

	if _player == null:
		return

	# Erzeuge Wurzel-Spikes an der Position des Spielers
	var spike_count: int = 4 if is_phase_2 else 2
	for i in range(spike_count):
		var offset := Vector2(randf_range(-60, 60), randf_range(-60, 60))
		var spike: RootSpike = SPIKE_SCENE.instantiate()
		spike.global_position = _player.global_position + offset
		get_parent().call_deferred("add_child", spike)


func _start_thorns() -> void:
	boss_state = BossState.ATTACK_THORNS
	_state_timer = 1.2 if is_phase_2 else 1.5

	if _player == null:
		return

	var center_dir := (_player.global_position - global_position).normalized()
	var angles := [-0.25, 0.0, 0.25]
	if is_phase_2:
		angles = [-0.35, -0.15, 0.15, 0.35]

	for ang in angles:
		var dir := center_dir.rotated(ang)
		var proj: ThornProjectile = PROJECTILE_SCENE.instantiate()
		proj.global_position = global_position + dir * 60.0
		proj.launch(dir)
		get_parent().call_deferred("add_child", proj)

	AudioManager.play_sfx("slash", 1.1)


func _open_vulnerable_core() -> void:
	boss_state = BossState.VULNERABLE
	_state_timer = 2.8 if is_phase_2 else 3.5 # Zeitfenster für den Bumerang
	if _core_glow:
		_core_glow.visible = true
	if _sprite:
		_sprite.modulate = Color(1.2, 1.4, 2.0)
	AudioManager.play_sfx("dialogue_blip", 1.5)


func _close_core() -> void:
	boss_state = BossState.IDLE
	_state_timer = 1.2
	if _core_glow:
		_core_glow.visible = false
	if _sprite:
		_sprite.modulate = Color.WHITE


func _on_core_area_entered(area: Area2D) -> void:
	# Prisma-Bumerang trifft den offenen Kern -> Betäubung!
	if boss_state == BossState.VULNERABLE and area is PrismaticBoomerang:
		stun_boss()
	elif boss_state == BossState.STUNNED:
		if area.name == "SwordHitbox" or area.name == "SpinHitbox":
			take_hit(CombatCalculator.calculate_sword_damage(1, area.name == "SpinHitbox"), area.global_position, 0.0)


func stun_boss() -> void:
	boss_state = BossState.STUNNED
	_state_timer = 3.2 # 3.2 Sekunden freies Schlagen
	AudioManager.play_sfx("parry", 1.8)

	if _core_glow:
		_core_glow.visible = true
		_core_glow.color = Color(1.8, 1.8, 0.4, 0.8) # Goldgelber Stun-Glanz
	if _sprite:
		_sprite.modulate = Color(1.5, 1.5, 0.5)

	# Kopf sinkt herunter
	if _sprite:
		var tween := create_tween()
		if tween:
			tween.tween_property(_sprite, "position:y", 20.0, 0.2).set_trans(Tween.TRANS_BOUNCE)

	if _player:
		_player.camera_shake_requested.emit(0.4)


func _recover_from_stun() -> void:
	boss_state = BossState.IDLE
	_state_timer = 1.5
	if _core_glow:
		_core_glow.visible = false
		_core_glow.color = Color(0.2, 0.85, 1.0, 0.7)
	if _sprite:
		_sprite.modulate = Color.WHITE
		var tween := create_tween()
		if tween:
			tween.tween_property(_sprite, "position:y", -10.0, 0.25)


func _enter_phase_2() -> void:
	is_phase_2 = true
	AudioManager.play_sfx("explosion", 1.2)
	if _player:
		_player.camera_shake_requested.emit(0.6)

	# Rotes Wut-Aufleuchten
	if _sprite:
		var tween := create_tween()
		if tween:
			tween.tween_property(_sprite, "modulate", Color(2.2, 0.5, 0.5), 0.2)
			tween.tween_property(_sprite, "modulate", Color.WHITE, 0.3)


func take_hit(damage: int, attacker_pos: Vector2, force: float = 340.0) -> void:
	# Außerhalb des Stuns reduziert die dicke Rinde den Schaden um 75%
	var effective_damage: int = damage
	if boss_state != BossState.STUNNED:
		effective_damage = maxi(1, int(damage * 0.25))

	super.take_hit(effective_damage, attacker_pos, 0.0) # Boss bleibt unbeweglich


func die() -> void:
	boss_state = BossState.DYING
	AudioManager.play_sfx("explosion", 0.8)

	if _player:
		_player.camera_shake_requested.emit(0.9)

	boss_defeated_signal.emit()
	EventBus.boss_defeated.emit("floragorg")

	# Epische Trophäen-Truhe mit Sonnen-Prisma in der Mitte des Altars spawnen
	var chest: TreasureChest = SUN_PRISM_SCENE.instantiate()
	chest.chest_id = "chest_sun_prism"
	chest.item_type = "sun_prism"
	chest.global_position = global_position + Vector2(0, 80)
	get_parent().call_deferred("add_child", chest)

	# Boss zerfällt zu versteinertem Holz
	if _sprite:
		var tween := create_tween()
		tween.tween_property(_sprite, "modulate", Color(0.3, 0.3, 0.3, 0.0), 1.2)
		tween.tween_callback(queue_free)
	else:
		queue_free()


func _find_player() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	var nodes: Array[Node] = tree.get_nodes_in_group("player")
	if not nodes.is_empty() and nodes[0] is Player:
		_player = nodes[0] as Player
	elif get_parent() != null and get_parent().has_node("Player"):
		_player = get_parent().get_node("Player") as Player
