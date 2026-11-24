class_name BaseBoss
extends CharacterBody2D
## Basisklasse für Bosse in Crypt Dash mit etagenspezifischen Sprites, Phase-Licht, Telegraphen und Boss-HUD-Signalen.

signal boss_died(boss_name: String)

@export var boss_display_name_key: String = "BOSS_FLOOR_1"
@export var max_health: int = 50

var runner: BossPatternRunner
var current_health: int = 50
var player: Player
var floor_number: int = 1

var _hurtbox: HurtboxComponent
var _hitbox: HitboxComponent
var _attack_timer: float = 0.0
var _visual: EntityVisual
var _boss_light: PointLight2D
var _ring_time: float = 0.0
var _phase_stun_timer: float = 0.0


func _ready() -> void:
	z_index = 6
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 1 | 8

	runner = BossPatternRunner.new()
	_setup_phases()
	current_health = max_health

	_hurtbox = HurtboxComponent.new()
	_hurtbox.is_player = false
	_hurtbox.hit_received.connect(_on_hit_received)
	var h_shape := CollisionShape2D.new()
	var h_circle := CircleShape2D.new()
	h_circle.radius = 40.0
	h_shape.shape = h_circle
	_hurtbox.add_child(h_shape)
	add_child(_hurtbox)

	_hitbox = HitboxComponent.new()
	_hitbox.is_player = false
	_hitbox.damage = 2
	_hitbox.source_node = self
	var hit_shape := CollisionShape2D.new()
	var hit_circle := CircleShape2D.new()
	hit_circle.radius = 38.0
	hit_shape.shape = hit_circle
	_hitbox.add_child(hit_shape)
	add_child(_hitbox)

	var body_col := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 38.0
	body_col.shape = body_circle
	add_child(body_col)

	_visual = EntityVisual.new()
	_visual.setup(CryptAssets.get_texture(_get_boss_sprite_path()), 148.0, Vector2(0.7, 0.55), false, 0.0, 0.8)
	add_child(_visual)

	_boss_light = PointLight2D.new()
	_boss_light.texture = CryptAssets.get_radial_light_texture()
	_boss_light.color = _get_phase_color()
	_boss_light.energy = 1.4
	_boss_light.texture_scale = 3.2
	add_child(_boss_light)

	if is_inside_tree():
		EventBus.boss_spawned.emit(tr(boss_display_name_key), current_health, max_health)


func _get_boss_sprite_path() -> String:
	match clampi(floor_number, 1, 3):
		2:
			return "res://assets/sprites/boss_vex.png"
		3:
			return "res://assets/sprites/boss_thanatos.png"
		_:
			return "res://assets/sprites/boss_malok.png"


func _get_phase_color() -> Color:
	if runner != null:
		if runner.current_phase_idx == 1:
			return Color("ef4444")
		if runner.current_phase_idx >= 2:
			return Color("a855f7")
	return Color("f97316")


func _setup_phases() -> void:
	var p1 := [
		BossPhase.create("idle", 1.5, "idle"),
		BossPhase.create("charge", 2.0, "charge"),
		BossPhase.create("spiral", 2.5, "spiral_shot"),
	]
	var p2 := [
		BossPhase.create("slam", 1.5, "slam"),
		BossPhase.create("summon", 2.0, "summon"),
		BossPhase.create("spiral_fast", 2.0, "spiral_shot"),
	]
	var p3 := [
		BossPhase.create("frenzy_charge", 1.2, "charge"),
		BossPhase.create("death_spiral", 2.0, "spiral_shot"),
	]
	runner.init_boss(max_health, [p1, p2, p3])


func _physics_process(delta: float) -> void:
	if runner.state == BossPatternRunner.BossState.DEFEATED:
		return

	_ring_time += delta
	if _phase_stun_timer > 0.0:
		_phase_stun_timer -= delta
		return

	if player == null or not is_instance_valid(player):
		var p_nodes := get_tree().get_nodes_in_group("player")
		if not p_nodes.is_empty():
			player = p_nodes[0]

	runner.update(delta)
	_execute_current_pattern(delta)

	if _visual != null:
		var look := player.global_position - global_position if player != null and is_instance_valid(player) else velocity
		_visual.update_motion(delta, velocity, look)

	if _boss_light != null:
		_boss_light.color = _get_phase_color()

	queue_redraw()


func _execute_current_pattern(delta: float) -> void:
	var step: BossPhase = runner.get_current_step()
	if step == null or player == null:
		return

	var dir := (player.global_position - global_position).normalized()
	_attack_timer += delta

	match step.action:
		"idle":
			velocity = Vector2.ZERO
		"charge":
			if runner.step_timer < 0.35:
				velocity = Vector2.ZERO
			else:
				velocity = dir * 260.0
				move_and_slide()
		"slam":
			if runner.step_timer < 0.35:
				velocity = Vector2.ZERO
			else:
				velocity = dir * 380.0
				move_and_slide()
		"spiral_shot":
			velocity = Vector2.ZERO
			if _attack_timer >= 0.4:
				_attack_timer = 0.0
				_fire_spiral()
		"summon":
			velocity = Vector2.ZERO
			if _attack_timer >= 1.8:
				_attack_timer = 0.0
				CryptVfx.spawn_burst(get_parent(), global_position, Color("a855f7"), 10, 170.0, 4.0)
				var skel := EnemySkeleton.new()
				skel.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
				get_parent().call_deferred("add_child", skel)


func _fire_spiral() -> void:
	var bullet_count := 8
	var angle_step := TAU / bullet_count
	for i in range(bullet_count):
		var p := Projectile.new()
		p.global_position = global_position
		p.direction = Vector2.RIGHT.rotated(i * angle_step + runner.step_timer * 3.0)
		p.speed = 320.0
		p.damage = 1
		p.is_player = false
		p.visual_style = "boss_bolt"
		p.tint = Color("ef4444")
		get_parent().call_deferred("add_child", p)


func _on_hit_received(dmg: int, _knockback: Vector2, _from_player: bool) -> void:
	if runner.state == BossPatternRunner.BossState.DEFEATED:
		return
	var prev_phase := runner.current_phase_idx
	var dead := runner.take_damage(dmg)
	current_health = runner.hp

	if _visual != null:
		_visual.flash_hit(Color.WHITE, 0.12)
	CryptVfx.spawn_damage_number(get_parent(), global_position + Vector2(0.0, -56.0), dmg)
	CryptVfx.spawn_burst(get_parent(), global_position, _get_phase_color(), 6, 150.0, 3.6)

	EventBus.enemy_damaged.emit(self, dmg)
	EventBus.boss_health_changed.emit(current_health, max_health, runner.current_phase_idx)

	if not dead and runner.current_phase_idx > prev_phase:
		CryptAudio.play_boss_phase()
		_phase_stun_timer = 0.14
		CryptVfx.spawn_burst(get_parent(), global_position, _get_phase_color(), 22, 260.0, 5.5)
		EventBus.screen_shake_requested.emit(12.0, 0.35)

	if dead:
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		if _hurtbox != null and is_instance_valid(_hurtbox):
			_hurtbox.set_deferred("monitoring", false)
			_hurtbox.set_deferred("monitorable", false)
		if _hitbox != null and is_instance_valid(_hitbox):
			_hitbox.set_deferred("monitoring", false)
			_hitbox.set_deferred("monitorable", false)
		CryptVfx.spawn_burst(get_parent(), global_position, _get_phase_color(), 28, 300.0, 6.0)
		CryptVfx.spawn_soul_orbs(get_parent(), global_position, player, 5)
		EventBus.screen_shake_requested.emit(14.0, 0.45)
		EventBus.enemy_died.emit(self, 15)
		EventBus.boss_defeated.emit()
		boss_died.emit(tr(boss_display_name_key))
		queue_free()


func _draw() -> void:
	if runner == null:
		return
	var phase_col := _get_phase_color()
	# Rotierender Runen-Ring unter dem Boss
	var a0 := _ring_time * 1.4
	draw_arc(Vector2(0.0, 22.0), 54.0, a0, a0 + PI * 0.75, 18, Color(phase_col.r, phase_col.g, phase_col.b, 0.42), 3.0)
	draw_arc(Vector2(0.0, 22.0), 54.0, a0 + PI, a0 + PI * 1.75, 18, Color(phase_col.r, phase_col.g, phase_col.b, 0.42), 3.0)

	# Boden-Telegraph vor Sturmangriffen
	var step: BossPhase = runner.get_current_step()
	if step != null and (step.action == "charge" or step.action == "slam") and player != null and is_instance_valid(player):
		var dir := (player.global_position - global_position).normalized()
		var warn_alpha := 0.58 if runner.step_timer < 0.35 else 0.22
		var end_pt := dir * 240.0
		draw_line(Vector2.ZERO, end_pt, Color(0.95, 0.22, 0.22, warn_alpha), 10.0)
		draw_line(Vector2.ZERO, end_pt, Color(1.0, 0.85, 0.45, warn_alpha), 2.5)
